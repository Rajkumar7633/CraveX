package services

import (
	"errors"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/zomato-clone/order-service/internal/models"
	"github.com/zomato-clone/order-service/internal/repository"
)

type OrderService interface {
	CreateOrder(userID uuid.UUID, req *models.CreateOrderRequest) (*models.Order, error)
	GetOrder(id uuid.UUID) (*models.Order, error)
	GetOrderByNumber(orderNumber string) (*models.Order, error)
	GetUserOrders(userID uuid.UUID) ([]*models.Order, error)
	GetRestaurantOrders(restaurantID uuid.UUID) ([]*models.Order, error)
	GetRiderOrders(riderID uuid.UUID) ([]*models.Order, error)
	UpdateOrderStatus(id uuid.UUID, status string, notes string, updatedBy uuid.UUID) error
	CancelOrder(id uuid.UUID, reason string, cancelledBy uuid.UUID) error
	AssignRider(orderID uuid.UUID, riderID uuid.UUID) error
}

type orderService struct {
	orderRepo         repository.OrderRepository
	orderItemRepo     repository.OrderItemRepository
	statusHistoryRepo repository.OrderStatusHistoryRepository
}

func NewOrderService(orderRepo repository.OrderRepository, orderItemRepo repository.OrderItemRepository, statusHistoryRepo repository.OrderStatusHistoryRepository) OrderService {
	return &orderService{
		orderRepo:         orderRepo,
		orderItemRepo:     orderItemRepo,
		statusHistoryRepo: statusHistoryRepo,
	}
}

func (s *orderService) CreateOrder(userID uuid.UUID, req *models.CreateOrderRequest) (*models.Order, error) {
	// Generate order number
	orderNumber := generateOrderNumber()

	// Calculate totals
	subtotal := calculateSubtotal(req.Items)
	deliveryFee := 2.99 // Fixed delivery fee for now
	tax := subtotal * 0.08 // 8% tax
	total := subtotal + deliveryFee + tax + req.TipAmount

	// Create order
	order := &models.Order{
		OrderNumber:         orderNumber,
		UserID:              userID,
		RestaurantID:        req.RestaurantID,
		DeliveryAddressID:   req.DeliveryAddressID,
		Status:              "pending",
		Subtotal:            subtotal,
		DeliveryFee:         deliveryFee,
		Tax:                 tax,
		Discount:            0.00,
		PlatformFee:         0.50,
		PackagingFee:        0.99,
		TipAmount:           req.TipAmount,
		TotalAmount:         total,
		PaymentMethod:       req.PaymentMethod,
		PaymentStatus:       "pending",
		CouponCode:          req.CouponCode,
		SpecialInstructions: req.SpecialInstructions,
		ScheduledFor:        req.ScheduledFor,
	}

	if err := s.orderRepo.Create(order); err != nil {
		return nil, err
	}

	// Create order items
	for _, itemReq := range req.Items {
		orderItem := &models.OrderItem{
			OrderID:              order.ID,
			MenuItemID:           itemReq.MenuItemID,
			Quantity:             itemReq.Quantity,
			UnitPrice:            itemReq.UnitPrice,
			Customizations:       itemReq.Customizations,
			SpecialInstructions:  itemReq.SpecialInstructions,
		}

		if err := s.orderItemRepo.Create(orderItem); err != nil {
			return nil, err
		}
	}

	// Create initial status history
	statusHistory := &models.OrderStatusHistory{
		OrderID:   order.ID,
		Status:    "pending",
		Notes:     "Order created",
		UpdatedBy: &userID,
	}

	if err := s.statusHistoryRepo.Create(statusHistory); err != nil {
		return nil, err
	}

	return order, nil
}

func (s *orderService) GetOrder(id uuid.UUID) (*models.Order, error) {
	return s.orderRepo.FindByID(id)
}

func (s *orderService) GetOrderByNumber(orderNumber string) (*models.Order, error) {
	return s.orderRepo.FindByOrderNumber(orderNumber)
}

func (s *orderService) GetUserOrders(userID uuid.UUID) ([]*models.Order, error) {
	return s.orderRepo.FindByUserID(userID)
}

func (s *orderService) GetRestaurantOrders(restaurantID uuid.UUID) ([]*models.Order, error) {
	return s.orderRepo.FindByRestaurantID(restaurantID)
}

func (s *orderService) GetRiderOrders(riderID uuid.UUID) ([]*models.Order, error) {
	return s.orderRepo.FindByRiderID(riderID)
}

func (s *orderService) UpdateOrderStatus(id uuid.UUID, status string, notes string, updatedBy uuid.UUID) error {
	// Validate status transition
	order, err := s.orderRepo.FindByID(id)
	if err != nil {
		return err
	}

	if !isValidStatusTransition(order.Status, status) {
		return errors.New("invalid status transition")
	}

	// Update status
	if err := s.orderRepo.UpdateStatus(id, status); err != nil {
		return err
	}

	// Create status history
	statusHistory := &models.OrderStatusHistory{
		OrderID:   id,
		Status:    status,
		Notes:     notes,
		UpdatedBy: &updatedBy,
	}

	if err := s.statusHistoryRepo.Create(statusHistory); err != nil {
		return err
	}

	return nil
}

func (s *orderService) CancelOrder(id uuid.UUID, reason string, cancelledBy uuid.UUID) error {
	order, err := s.orderRepo.FindByID(id)
	if err != nil {
		return err
	}

	// Check if order can be cancelled
	if !canCancelOrder(order.Status) {
		return errors.New("order cannot be cancelled at this stage")
	}

	now := time.Now()
	order.Status = "cancelled"
	order.CancellationReason = reason
	order.CancelledBy = &cancelledBy
	order.CancelledAt = &now

	if err := s.orderRepo.Update(order); err != nil {
		return err
	}

	// Create status history
	statusHistory := &models.OrderStatusHistory{
		OrderID:   id,
		Status:    "cancelled",
		Notes:     reason,
		UpdatedBy: &cancelledBy,
	}

	return s.statusHistoryRepo.Create(statusHistory)
}

func (s *orderService) AssignRider(orderID uuid.UUID, riderID uuid.UUID) error {
	order, err := s.orderRepo.FindByID(orderID)
	if err != nil {
		return err
	}

	order.RiderID = &riderID
	return s.orderRepo.Update(order)
}

func generateOrderNumber() string {
	return fmt.Sprintf("ORD-%d", time.Now().UnixNano())
}

func calculateSubtotal(items []models.OrderItemRequest) float64 {
	var subtotal float64
	for _, item := range items {
		subtotal += item.UnitPrice * float64(item.Quantity)
	}
	return subtotal
}

func isValidStatusTransition(currentStatus, newStatus string) bool {
	validTransitions := map[string][]string{
		"pending":     {"confirmed", "cancelled"},
		"confirmed":   {"preparing", "cancelled"},
		"preparing":   {"ready", "cancelled"},
		"ready":       {"picked_up", "cancelled"},
		"picked_up":   {"on_the_way"},
		"on_the_way":  {"delivered"},
		"delivered":   {},
		"cancelled":   {},
	}

	if allowed, exists := validTransitions[currentStatus]; exists {
		for _, status := range allowed {
			if status == newStatus {
				return true
			}
		}
	}

	return false
}

func canCancelOrder(status string) bool {
	cancelableStatuses := []string{"pending", "confirmed", "preparing"}
	for _, s := range cancelableStatuses {
		if s == status {
			return true
		}
	}
	return false
}
