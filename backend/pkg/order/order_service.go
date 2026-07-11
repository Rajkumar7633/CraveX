package order

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

type OrderStatus string

const (
	OrderStatusPending          OrderStatus = "pending"
	OrderStatusConfirmed        OrderStatus = "confirmed"
	OrderStatusPreparing        OrderStatus = "preparing"
	OrderStatusReady           OrderStatus = "ready"
	OrderStatusPickedUp         OrderStatus = "picked_up"
	OrderStatusOnTheWay         OrderStatus = "on_the_way"
	OrderStatusDelivered        OrderStatus = "delivered"
	OrderStatusCancelled        OrderStatus = "cancelled"
	OrderStatusRefunded         OrderStatus = "refunded"
	OrderStatusFailed           OrderStatus = "failed"
)

type Order struct {
	ID                 uuid.UUID    `json:"id"`
	OrderNumber        string       `json:"order_number"`
	UserID             uuid.UUID    `json:"user_id"`
	RestaurantID       uuid.UUID    `json:"restaurant_id"`
	RiderID            *uuid.UUID   `json:"rider_id,omitempty"`
	DeliveryAddressID  uuid.UUID    `json:"delivery_address_id"`
	Status             OrderStatus  `json:"status"`
	Items              []OrderItem  `json:"items"`
	Subtotal           float64      `json:"subtotal"`
	DeliveryFee        float64      `json:"delivery_fee"`
	TaxAmount          float64      `json:"tax_amount"`
	DiscountAmount     float64      `json:"discount_amount"`
	TotalAmount        float64      `json:"total_amount"`
	PaymentMethod      string       `json:"payment_method"`
	PaymentStatus      string       `json:"payment_status"`
	SpecialInstructions string       `json:"special_instructions"`
	EstimatedDeliveryTime time.Time `json:"estimated_delivery_time"`
	ActualDeliveryTime *time.Time   `json:"actual_delivery_time,omitempty"`
	CreatedAt          time.Time    `json:"created_at"`
	UpdatedAt          time.Time    `json:"updated_at"`
	CancelledAt        *time.Time   `json:"cancelled_at,omitempty"`
	CancellationReason string       `json:"cancellation_reason,omitempty"`
}

type OrderItem struct {
	ID           uuid.UUID `json:"id"`
	MenuItemID   uuid.UUID `json:"menu_item_id"`
	Name         string    `json:"name"`
	Quantity     int       `json:"quantity"`
	UnitPrice    float64   `json:"unit_price"`
	Subtotal     float64   `json:"subtotal"`
	SpecialInstructions string `json:"special_instructions,omitempty"`
}

type DeliveryAddress struct {
	ID          uuid.UUID `json:"id"`
	UserID      uuid.UUID `json:"user_id"`
	AddressLine string    `json:"address_line"`
	City        string    `json:"city"`
	State       string    `json:"state"`
	ZipCode     string    `json:"zip_code"`
	Latitude    float64   `json:"latitude"`
	Longitude   float64   `json:"longitude"`
	ContactName string    `json:"contact_name"`
	ContactPhone string   `json:"contact_phone"`
	IsDefault   bool      `json:"is_default"`
}

type OrderService struct {
	cacheService CacheService
	messagingService MessagingService
}

type CacheService interface {
	Get(ctx context.Context, key string) (string, error)
	Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error
	Delete(ctx context.Context, keys ...string) error
}

type MessagingService interface {
	PublishMessage(ctx context.Context, topic string, key string, message interface{}) error
}

func NewOrderService(cacheService CacheService, messagingService MessagingService) *OrderService {
	return &OrderService{
		cacheService: cacheService,
		messagingService: messagingService,
	}
}

func (os *OrderService) CreateOrder(ctx context.Context, order *Order) (*Order, error) {
	// Validate order
	if err := os.validateOrder(order); err != nil {
		return nil, fmt.Errorf("order validation failed: %w", err)
	}

	// Generate order number
	order.OrderNumber = os.generateOrderNumber()
	order.ID = uuid.New()
	order.Status = OrderStatusPending
	order.PaymentStatus = "pending"
	order.CreatedAt = time.Now()
	order.UpdatedAt = time.Now()

	// Calculate totals
	if err := os.calculateOrderTotals(order); err != nil {
		return nil, fmt.Errorf("failed to calculate order totals: %w", err)
	}

	// Set estimated delivery time
	order.EstimatedDeliveryTime = os.calculateEstimatedDeliveryTime(order)

	// Save to database
	if err := os.saveOrderToDB(ctx, order); err != nil {
		return nil, fmt.Errorf("failed to save order: %w", err)
	}

	// Publish order created event
	event := map[string]interface{}{
		"order_id":      order.ID.String(),
		"user_id":       order.UserID.String(),
		"restaurant_id":  order.RestaurantID.String(),
		"total_amount":  order.TotalAmount,
		"status":        order.Status,
		"created_at":    order.CreatedAt,
	}

	if err := os.messagingService.PublishMessage(ctx, "order.created", order.ID.String(), event); err != nil {
		return nil, fmt.Errorf("failed to publish order created event: %w", err)
	}

	// Invalidate cache
	os.cacheService.Delete(ctx, fmt.Sprintf("user_orders:%s", order.UserID.String()))

	return order, nil
}

func (os *OrderService) GetOrderByID(ctx context.Context, id uuid.UUID) (*Order, error) {
	cacheKey := fmt.Sprintf("order:%s", id.String())

	// Try cache first
	var cachedOrder Order
	if _, err := os.cacheService.Get(ctx, cacheKey); err == nil {
		return &cachedOrder, nil
	}

	// Fetch from database
	order, err := os.fetchOrderFromDB(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch order: %w", err)
	}

	// Cache for 15 minutes
	os.cacheService.Set(ctx, cacheKey, order, 15*time.Minute)

	return order, nil
}

func (os *OrderService) GetUserOrders(ctx context.Context, userID uuid.UUID, status *OrderStatus, page, pageSize int) ([]Order, int64, error) {
	cacheKey := fmt.Sprintf("user_orders:%s:%v:%d:%d", userID.String(), status, page, pageSize)

	// Try cache first
	var cachedOrders []Order
	if _, err := os.cacheService.Get(ctx, cacheKey); err == nil {
		return cachedOrders, int64(len(cachedOrders)), nil
	}

	// Fetch from database
	orders, total, err := os.fetchUserOrdersFromDB(ctx, userID, status, page, pageSize)
	if err != nil {
		return nil, 0, fmt.Errorf("failed to fetch user orders: %w", err)
	}

	// Cache for 5 minutes
	os.cacheService.Set(ctx, cacheKey, orders, 5*time.Minute)

	return orders, total, nil
}

func (os *OrderService) UpdateOrderStatus(ctx context.Context, orderID uuid.UUID, newStatus OrderStatus, metadata map[string]interface{}) error {
	// Get current order
	order, err := os.GetOrderByID(ctx, orderID)
	if err != nil {
		return fmt.Errorf("failed to get order: %w", err)
	}

	// Validate status transition
	if err := os.validateStatusTransition(order.Status, newStatus); err != nil {
		return fmt.Errorf("invalid status transition: %w", err)
	}

	// Update order
	oldStatus := order.Status
	order.Status = newStatus
	order.UpdatedAt = time.Now()

	// Handle specific status changes
	if newStatus == OrderStatusDelivered {
		now := time.Now()
		order.ActualDeliveryTime = &now
	}

	if newStatus == OrderStatusCancelled {
		now := time.Now()
		order.CancelledAt = &now
		if reason, ok := metadata["cancellation_reason"]; ok {
			order.CancellationReason = reason.(string)
		}
	}

	// Save to database
	if err := os.updateOrderInDB(ctx, order); err != nil {
		return fmt.Errorf("failed to update order: %w", err)
	}

	// Invalidate cache
	os.cacheService.Delete(ctx, fmt.Sprintf("order:%s", orderID.String()))
	os.cacheService.Delete(ctx, fmt.Sprintf("user_orders:%s", order.UserID.String()))

	// Publish status update event
	event := map[string]interface{}{
		"order_id":     order.ID.String(),
		"old_status":   oldStatus,
		"new_status":   newStatus,
		"updated_at":   order.UpdatedAt,
		"metadata":     metadata,
	}

	if err := os.messagingService.PublishMessage(ctx, "order.updated", orderID.String(), event); err != nil {
		return fmt.Errorf("failed to publish order updated event: %w", err)
	}

	return nil
}

func (os *OrderService) AssignRider(ctx context.Context, orderID, riderID uuid.UUID) error {
	order, err := os.GetOrderByID(ctx, orderID)
	if err != nil {
		return fmt.Errorf("failed to get order: %w", err)
	}

	if order.Status != OrderStatusConfirmed && order.Status != OrderStatusPreparing {
		return fmt.Errorf("order must be confirmed or preparing to assign rider")
	}

	order.RiderID = &riderID
	order.Status = OrderStatusPreparing
	order.UpdatedAt = time.Now()

	if err := os.updateOrderInDB(ctx, order); err != nil {
		return fmt.Errorf("failed to update order: %w", err)
	}

	// Publish rider assigned event
	event := map[string]interface{}{
		"order_id":  orderID.String(),
		"rider_id": riderID.String(),
		"assigned_at": time.Now(),
	}

	if err := os.messagingService.PublishMessage(ctx, "rider.assigned", orderID.String(), event); err != nil {
		return fmt.Errorf("failed to publish rider assigned event: %w", err)
	}

	return nil
}

func (os *OrderService) CancelOrder(ctx context.Context, orderID uuid.UUID, reason string) error {
	order, err := os.GetOrderByID(ctx, orderID)
	if err != nil {
		return fmt.Errorf("failed to get order: %w", err)
	}

	// Check if order can be cancelled
	if !os.canCancelOrder(order) {
		return fmt.Errorf("order cannot be cancelled in current status: %s", order.Status)
	}

	metadata := map[string]interface{}{
		"cancellation_reason": reason,
	}

	return os.UpdateOrderStatus(ctx, orderID, OrderStatusCancelled, metadata)
}

func (os *OrderService) ProcessRefund(ctx context.Context, orderID uuid.UUID) error {
	order, err := os.GetOrderByID(ctx, orderID)
	if err != nil {
		return fmt.Errorf("failed to get order: %w", err)
	}

	if order.Status != OrderStatusCancelled {
		return fmt.Errorf("order must be cancelled to process refund")
	}

	if order.PaymentStatus == "refunded" {
		return fmt.Errorf("order already refunded")
	}

	// Process refund logic here
	// This would integrate with payment service

	order.PaymentStatus = "refunded"
	order.Status = OrderStatusRefunded
	order.UpdatedAt = time.Now()

	if err := os.updateOrderInDB(ctx, order); err != nil {
		return fmt.Errorf("failed to update order: %w", err)
	}

	return nil
}

func (os *OrderService) validateOrder(order *Order) error {
	if order.UserID == uuid.Nil {
		return fmt.Errorf("user ID is required")
	}
	if order.RestaurantID == uuid.Nil {
		return fmt.Errorf("restaurant ID is required")
	}
	if len(order.Items) == 0 {
		return fmt.Errorf("order must have at least one item")
	}
	if order.DeliveryAddressID == uuid.Nil {
		return fmt.Errorf("delivery address ID is required")
	}
	return nil
}

func (os *OrderService) calculateOrderTotals(order *Order) error {
	order.Subtotal = 0
	for i := range order.Items {
		item := &order.Items[i]
		item.Subtotal = item.UnitPrice * float64(item.Quantity)
		order.Subtotal += item.Subtotal
	}

	order.TaxAmount = order.Subtotal * 0.05 // 5% tax
	order.TotalAmount = order.Subtotal + order.DeliveryFee + order.TaxAmount - order.DiscountAmount

	return nil
}

func (os *OrderService) calculateEstimatedDeliveryTime(order *Order) time.Time {
	// Calculate based on restaurant preparation time + delivery time
	prepTime := 30 * time.Minute // Default preparation time
	deliveryTime := 20 * time.Minute // Default delivery time
	return time.Now().Add(prepTime + deliveryTime)
}

func (os *OrderService) generateOrderNumber() string {
	return fmt.Sprintf("ORD-%d", time.Now().Unix())
}

func (os *OrderService) validateStatusTransition(currentStatus, newStatus OrderStatus) error {
	validTransitions := map[OrderStatus][]OrderStatus{
		OrderStatusPending:   {OrderStatusConfirmed, OrderStatusCancelled},
		OrderStatusConfirmed: {OrderStatusPreparing, OrderStatusCancelled},
		OrderStatusPreparing: {OrderStatusReady, OrderStatusCancelled},
		OrderStatusReady:     {OrderStatusPickedUp, OrderStatusCancelled},
		OrderStatusPickedUp:  {OrderStatusOnTheWay},
		OrderStatusOnTheWay:  {OrderStatusDelivered},
		OrderStatusDelivered: {},
		OrderStatusCancelled: {OrderStatusRefunded},
		OrderStatusRefunded:  {},
	}

	allowedStatuses, exists := validTransitions[currentStatus]
	if !exists {
		return fmt.Errorf("invalid current status: %s", currentStatus)
	}

	for _, status := range allowedStatuses {
		if status == newStatus {
			return nil
		}
	}

	return fmt.Errorf("cannot transition from %s to %s", currentStatus, newStatus)
}

func (os *OrderService) canCancelOrder(order *Order) bool {
	cancelableStatuses := []OrderStatus{
		OrderStatusPending,
		OrderStatusConfirmed,
		OrderStatusPreparing,
	}

	for _, status := range cancelableStatuses {
		if order.Status == status {
			return true
		}
	}

	return false
}

func (os *OrderService) saveOrderToDB(ctx context.Context, order *Order) error {
	// Save to database
	return nil
}

func (os *OrderService) fetchOrderFromDB(ctx context.Context, id uuid.UUID) (*Order, error) {
	// Fetch from database
	return &Order{}, nil
}

func (os *OrderService) updateOrderInDB(ctx context.Context, order *Order) error {
	// Update in database
	return nil
}

func (os *OrderService) fetchUserOrdersFromDB(ctx context.Context, userID uuid.UUID, status *OrderStatus, page, pageSize int) ([]Order, int64, error) {
	// Fetch from database
	return []Order{}, 0, nil
}
