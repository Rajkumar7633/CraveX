package services

import (
	"context"
	"errors"
	"fmt"
	"log"
	"time"

	"github.com/google/uuid"
	"github.com/zomato-clone/order-service/internal/messaging"
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
	UpdateOrderStatus(id uuid.UUID, status string, notes string, eventID string, updatedBy uuid.UUID) error
	CancelOrder(id uuid.UUID, reason string, cancelledBy uuid.UUID) error
	AssignRider(orderID uuid.UUID, riderID uuid.UUID) error
}

type orderService struct {
	orderRepo         repository.OrderRepository
	orderItemRepo     repository.OrderItemRepository
	statusHistoryRepo repository.OrderStatusHistoryRepository
	kafkaProducer     *messaging.KafkaProducer
}

func NewOrderService(orderRepo repository.OrderRepository, orderItemRepo repository.OrderItemRepository, statusHistoryRepo repository.OrderStatusHistoryRepository, kafkaProducer *messaging.KafkaProducer) OrderService {
	s := &orderService{
		orderRepo:         orderRepo,
		orderItemRepo:     orderItemRepo,
		statusHistoryRepo: statusHistoryRepo,
		kafkaProducer:     kafkaProducer,
	}
	go s.startEtaRecalculator()
	return s
}

func (s *orderService) CreateOrder(userID uuid.UUID, req *models.CreateOrderRequest) (*models.Order, error) {
	// Generate order number
	orderNumber := generateOrderNumber()

	// Calculate totals using spec cart formula
	itemTotal := calculateSubtotal(req.Items)
	packagingFee := 0.99
	platformFee := 0.50
	deliveryFee := 2.99

	// Surge multiplier check
	hour := time.Now().Hour()
	if (hour >= 12 && hour <= 15) || (hour >= 19 && hour <= 22) {
		deliveryFee = deliveryFee * 1.5 // 50% peak hour surge
	}

	// GST Calculations (5% food vs 18% service charges)
	foodGst := (itemTotal + packagingFee) * 0.05
	deliveryGst := deliveryFee * 0.18
	platformGst := platformFee * 0.18
	tax := foodGst + deliveryGst + platformGst

	// Coupon validation
	discount := 0.00
	if req.CouponCode != "" {
		if req.CouponCode == "CRAVEX50" && itemTotal >= 10.0 {
			discount = itemTotal * 0.50
			if discount > 5.0 {
				discount = 5.0
			}
		}
	}

	// Standard prep time: 15 mins base + 2 mins per item in the order
	prepTimeMins := 15 + len(req.Items)*2
	etaMins := prepTimeMins + 25 // travel + pickup + buffer
	estimatedDeliveryTime := time.Now().Add(time.Duration(etaMins) * time.Minute)

	total := itemTotal + packagingFee + platformFee + deliveryFee + tax - discount + req.TipAmount

	// Create order
	order := &models.Order{
		OrderNumber:           orderNumber,
		UserID:                userID,
		RestaurantID:          req.RestaurantID,
		DeliveryAddressID:     req.DeliveryAddressID,
		Status:                "placed",
		Subtotal:              itemTotal,
		DeliveryFee:           deliveryFee,
		Tax:                   tax,
		Discount:              discount,
		PlatformFee:           platformFee,
		PackagingFee:          packagingFee,
		TipAmount:             req.TipAmount,
		TotalAmount:           total,
		PaymentMethod:         req.PaymentMethod,
		PaymentStatus:         "pending",
		CouponCode:            req.CouponCode,
		SpecialInstructions:   req.SpecialInstructions,
		ScheduledFor:          req.ScheduledFor,
		EstimatedDeliveryTime: &estimatedDeliveryTime,
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
		Status:    "placed",
		Notes:     "Order created",
		EventID:   "init-" + order.ID.String(),
		UpdatedBy: &userID,
	}

	if err := s.statusHistoryRepo.Create(statusHistory); err != nil {
		return nil, err
	}

	// Publish Event to Kafka on creation
	if s.kafkaProducer != nil {
		event := map[string]interface{}{
			"event_id":     "init-" + order.ID.String(),
			"order_id":     order.ID.String(),
			"user_id":      order.UserID.String(),
			"status":       "placed",
			"timestamp":    time.Now().Format(time.RFC3339),
			"order_number": order.OrderNumber,
		}
		_ = s.kafkaProducer.PublishMessage(context.Background(), "order-events", order.ID.String(), event)
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

func (s *orderService) UpdateOrderStatus(id uuid.UUID, status string, notes string, eventID string, updatedBy uuid.UUID) error {
	// Idempotency check
	if eventID != "" {
		existing, _ := s.statusHistoryRepo.FindByEventID(eventID)
		if existing != nil {
			log.Printf("Idempotent hit: event %s already processed", eventID)
			return nil
		}
	}

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
		EventID:   eventID,
		UpdatedBy: &updatedBy,
	}

	if err := s.statusHistoryRepo.Create(statusHistory); err != nil {
		return err
	}

	// Publish Event to Kafka
	if s.kafkaProducer != nil {
		event := map[string]interface{}{
			"event_id":     eventID,
			"order_id":     order.ID.String(),
			"user_id":      order.UserID.String(),
			"status":       status,
			"timestamp":    time.Now().Format(time.RFC3339),
			"order_number": order.OrderNumber,
		}
		_ = s.kafkaProducer.PublishMessage(context.Background(), "order-events", order.ID.String(), event)
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

	eventID := "cancel-" + uuid.New().String()
	// Create status history
	statusHistory := &models.OrderStatusHistory{
		OrderID:   id,
		Status:    "cancelled",
		Notes:     reason,
		EventID:   eventID,
		UpdatedBy: &cancelledBy,
	}

	if err := s.statusHistoryRepo.Create(statusHistory); err != nil {
		return err
	}

	// Publish Event to Kafka on cancellation
	if s.kafkaProducer != nil {
		event := map[string]interface{}{
			"event_id":     eventID,
			"order_id":     order.ID.String(),
			"user_id":      order.UserID.String(),
			"status":       "cancelled",
			"timestamp":    time.Now().Format(time.RFC3339),
			"order_number": order.OrderNumber,
		}
		_ = s.kafkaProducer.PublishMessage(context.Background(), "order-events", order.ID.String(), event)
	}

	return nil
}

func (s *orderService) AssignRider(orderID uuid.UUID, riderID uuid.UUID) error {
	order, err := s.orderRepo.FindByID(orderID)
	if err != nil {
		return err
	}

	order.RiderID = &riderID
	// Set transition state when rider is assigned
	order.Status = "rider_assigned"
	
	if err := s.orderRepo.Update(order); err != nil {
		return err
	}

	eventID := "assign-" + uuid.New().String()
	statusHistory := &models.OrderStatusHistory{
		OrderID:   orderID,
		Status:    "rider_assigned",
		Notes:     "Rider assigned to order",
		EventID:   eventID,
	}
	_ = s.statusHistoryRepo.Create(statusHistory)

	// Publish Event to Kafka on rider assignment
	if s.kafkaProducer != nil {
		event := map[string]interface{}{
			"event_id":     eventID,
			"order_id":     order.ID.String(),
			"user_id":      order.UserID.String(),
			"status":       "rider_assigned",
			"timestamp":    time.Now().Format(time.RFC3339),
			"order_number": order.OrderNumber,
		}
		_ = s.kafkaProducer.PublishMessage(context.Background(), "order-events", order.ID.String(), event)
	}

	// 15s Rejection Cascade Timeout
	go func(oID uuid.UUID, prevRiderID uuid.UUID) {
		time.Sleep(15 * time.Second)
		ord, err := s.orderRepo.FindByID(oID)
		if err != nil {
			return
		}
		// If rider still hasn't moved the order status forward, revert and trigger cascade
		if ord.Status == "rider_assigned" && ord.RiderID != nil && *ord.RiderID == prevRiderID {
			log.Printf("Rider %s failed to accept in 15s. Cascading re-assignment for order %s...", prevRiderID.String(), oID.String())
			ord.Status = "placed"
			ord.RiderID = nil
			_ = s.orderRepo.Update(ord)

			reassignEventID := "cascade-" + uuid.New().String()
			history := &models.OrderStatusHistory{
				OrderID: oID,
				Status:  "placed",
				Notes:   "Rider assignment timed out. Returned to matching pool.",
				EventID: reassignEventID,
			}
			_ = s.statusHistoryRepo.Create(history)
		}
	}(orderID, riderID)

	return nil
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
		"placed":                   {"restaurant_accepted", "cancelled"},
		"restaurant_accepted":     {"preparing", "cancelled"},
		"preparing":               {"ready_for_pickup", "cancelled"},
		"ready_for_pickup":         {"rider_assigned", "cancelled"},
		"rider_assigned":           {"rider_arrived_restaurant", "cancelled"},
		"rider_arrived_restaurant": {"picked_up", "cancelled"},
		"picked_up":               {"rider_arrived_customer", "cancelled"},
		"rider_arrived_customer":   {"delivered", "cancelled"},
		"delivered":               {},
		"cancelled":               {},
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
	cancelableStatuses := map[string]bool{
		"placed":                   true,
		"restaurant_accepted":     true,
		"preparing":               true,
		"ready_for_pickup":         true,
		"rider_assigned":           true,
		"rider_arrived_restaurant": true,
	}
	return cancelableStatuses[status]
}

func (s *orderService) startEtaRecalculator() {
	ticker := time.NewTicker(60 * time.Second)
	go func() {
		for range ticker.C {
			activeOrders, err := s.orderRepo.FindActive()
			if err != nil {
				log.Printf("[ETA Recalculator] Error fetching active orders: %v", err)
				continue
			}

			log.Printf("[ETA Recalculator] Recalculating ETAs for %d active orders", len(activeOrders))

			for _, order := range activeOrders {
				if order.EstimatedDeliveryTime == nil {
					continue
				}

				// Calculate expected remaining duration based on current state
				var remainingMins int
				switch order.Status {
				case "placed":
					remainingMins = 40
				case "restaurant_accepted":
					remainingMins = 35
				case "preparing":
					remainingMins = 25
				case "ready_for_pickup":
					remainingMins = 20
				case "rider_assigned", "rider_arrived_restaurant":
					remainingMins = 15
				case "picked_up":
					remainingMins = 10
				case "rider_arrived_customer":
					remainingMins = 3
				default:
					remainingMins = 30
				}

				// Add item quantity buffer: 1 min per item
				itemCount := 0
				for _, item := range order.OrderItems {
					itemCount += item.Quantity
				}
				remainingMins += itemCount

				newETA := time.Now().Add(time.Duration(remainingMins) * time.Minute)
				delta := newETA.Sub(*order.EstimatedDeliveryTime)
				if delta < 0 {
					delta = -delta
				}

				// Only update if difference is > 2 minutes to prevent spamming
				if delta > 2*time.Minute {
					log.Printf("[ETA Recalculator] Order %s ETA shifted by %v. Updating...", order.OrderNumber, delta)
					order.EstimatedDeliveryTime = &newETA
					_ = s.orderRepo.Update(order)

					// Publish shifted ETA event to Kafka
					if s.kafkaProducer != nil {
						event := map[string]interface{}{
							"event_id":                "eta-shift-" + uuid.New().String(),
							"order_id":                order.ID.String(),
							"estimated_delivery_time": newETA.Format(time.RFC3339),
							"timestamp":               time.Now().Format(time.RFC3339),
							"order_number":            order.OrderNumber,
						}
						_ = s.kafkaProducer.PublishMessage(context.Background(), "order-events", order.ID.String(), event)
					}
				}
			}
		}
	}()
}
