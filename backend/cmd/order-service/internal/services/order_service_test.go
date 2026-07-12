package services

import (
	"errors"
	"math"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/zomato-clone/order-service/internal/models"
)

// Mock OrderRepository
type mockOrderRepo struct {
	orders map[uuid.UUID]*models.Order
}

func (m *mockOrderRepo) Create(order *models.Order) error {
	m.orders[order.ID] = order
	return nil
}

func (m *mockOrderRepo) FindByID(id uuid.UUID) (*models.Order, error) {
	o, exists := m.orders[id]
	if !exists {
		return nil, errors.New("not found")
	}
	return o, nil
}

func (m *mockOrderRepo) FindByOrderNumber(num string) (*models.Order, error) {
	for _, o := range m.orders {
		if o.OrderNumber == num {
			return o, nil
		}
	}
	return nil, errors.New("not found")
}

func (m *mockOrderRepo) FindByUserID(userID uuid.UUID) ([]*models.Order, error) {
	var result []*models.Order
	for _, o := range m.orders {
		if o.UserID == userID {
			result = append(result, o)
		}
	}
	return result, nil
}

func (m *mockOrderRepo) FindByRestaurantID(restaurantID uuid.UUID) ([]*models.Order, error) {
	var result []*models.Order
	for _, o := range m.orders {
		if o.RestaurantID == restaurantID {
			result = append(result, o)
		}
	}
	return result, nil
}

func (m *mockOrderRepo) FindByRiderID(riderID uuid.UUID) ([]*models.Order, error) {
	var result []*models.Order
	for _, o := range m.orders {
		if o.RiderID != nil && *o.RiderID == riderID {
			result = append(result, o)
		}
	}
	return result, nil
}

func (m *mockOrderRepo) FindActive() ([]*models.Order, error) {
	var result []*models.Order
	for _, o := range m.orders {
		if o.Status != "delivered" && o.Status != "cancelled" {
			result = append(result, o)
		}
	}
	return result, nil
}

func (m *mockOrderRepo) Update(order *models.Order) error {
	m.orders[order.ID] = order
	return nil
}

func (m *mockOrderRepo) UpdateStatus(id uuid.UUID, status string) error {
	if o, exists := m.orders[id]; exists {
		o.Status = status
		return nil
	}
	return errors.New("not found")
}

func (m *mockOrderRepo) Delete(id uuid.UUID) error {
	delete(m.orders, id)
	return nil
}

// Mock OrderItemRepository
type mockOrderItemRepo struct{}

func (m *mockOrderItemRepo) Create(item *models.OrderItem) error {
	return nil
}

func (m *mockOrderItemRepo) FindByOrderID(orderID uuid.UUID) ([]*models.OrderItem, error) {
	return nil, nil
}

func (m *mockOrderItemRepo) FindByID(id uuid.UUID) (*models.OrderItem, error) {
	return nil, nil
}

func (m *mockOrderItemRepo) Update(item *models.OrderItem) error {
	return nil
}

func (m *mockOrderItemRepo) Delete(id uuid.UUID) error {
	return nil
}

// Mock OrderStatusHistoryRepository
type mockStatusHistoryRepo struct {
	histories []models.OrderStatusHistory
}

func (m *mockStatusHistoryRepo) Create(history *models.OrderStatusHistory) error {
	// Enforce unique eventID check (idempotency key validation)
	for _, h := range m.histories {
		if h.EventID == history.EventID {
			return errors.New("duplicate event key constraint")
		}
	}
	m.histories = append(m.histories, *history)
	return nil
}

func (m *mockStatusHistoryRepo) FindByOrderID(orderID uuid.UUID) ([]*models.OrderStatusHistory, error) {
	var result []*models.OrderStatusHistory
	for i := range m.histories {
		if m.histories[i].OrderID == orderID {
			result = append(result, &m.histories[i])
		}
	}
	return result, nil
}

func (m *mockStatusHistoryRepo) FindByEventID(eventID string) (*models.OrderStatusHistory, error) {
	for i := range m.histories {
		if m.histories[i].EventID == eventID {
			return &m.histories[i], nil
		}
	}
	return nil, errors.New("not found")
}

// Test Pricing splits and surge multipliers
func TestCreateOrderPricing(t *testing.T) {
	orderRepo := &mockOrderRepo{orders: make(map[uuid.UUID]*models.Order)}
	itemRepo := &mockOrderItemRepo{}
	historyRepo := &mockStatusHistoryRepo{}

	service := NewOrderService(orderRepo, itemRepo, historyRepo, nil)

	userID := uuid.New()
	restaurantID := uuid.New()
	addressID := uuid.New()

	req := &models.CreateOrderRequest{
		RestaurantID:      restaurantID,
		DeliveryAddressID: addressID,
		PaymentMethod:     "card",
		TipAmount:         2.0,
		Items: []models.OrderItemRequest{
			{
				MenuItemID: uuid.New(),
				Quantity:   2,
				UnitPrice:  10.0, // Subtotal = 20.0
			},
		},
	}

	order, err := service.CreateOrder(userID, req)
	if err != nil {
		t.Fatalf("Failed to create order: %v", err)
	}

	// Verify Pricing Totals (rounding float precision differences)
	roundedTotal := math.Round(order.TotalAmount*100) / 100
	expectedTotal := 28.16
	if roundedTotal != expectedTotal {
		t.Errorf("Expected total amount to be %.2f, got %.2f", expectedTotal, roundedTotal)
	}
}

// Test coupon application
func TestCreateOrderWithCoupon(t *testing.T) {
	orderRepo := &mockOrderRepo{orders: make(map[uuid.UUID]*models.Order)}
	itemRepo := &mockOrderItemRepo{}
	historyRepo := &mockStatusHistoryRepo{}

	service := NewOrderService(orderRepo, itemRepo, historyRepo, nil)

	userID := uuid.New()
	restaurantID := uuid.New()
	addressID := uuid.New()

	req := &models.CreateOrderRequest{
		RestaurantID:      restaurantID,
		DeliveryAddressID: addressID,
		PaymentMethod:     "card",
		CouponCode:        "CRAVEX50",
		Items: []models.OrderItemRequest{
			{
				MenuItemID: uuid.New(),
				Quantity:   1,
				UnitPrice:  20.0, // Subtotal = 20.0, Discount = 50% max cap = 5.0
			},
		},
	}

	order, err := service.CreateOrder(userID, req)
	if err != nil {
		t.Fatalf("Failed to create order: %v", err)
	}

	if order.Discount != 5.0 {
		t.Errorf("Expected coupon discount of 5.0, got %.2f", order.Discount)
	}
}

// Test Order status state transitions and checks
func TestUpdateOrderStatusTransitions(t *testing.T) {
	orderRepo := &mockOrderRepo{orders: make(map[uuid.UUID]*models.Order)}
	itemRepo := &mockOrderItemRepo{}
	historyRepo := &mockStatusHistoryRepo{}

	service := NewOrderService(orderRepo, itemRepo, historyRepo, nil)

	orderID := uuid.New()
	order := &models.Order{
		ID:           orderID,
		OrderNumber:  "CRX12345",
		Status:       "placed",
		TotalAmount:  15.0,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}
	_ = orderRepo.Create(order)

	// Valid Transition: placed -> restaurant_accepted
	err := service.UpdateOrderStatus(orderID, "restaurant_accepted", "Restaurant approved", "event-001", uuid.New())
	if err != nil {
		t.Errorf("Expected status update to succeed, got error: %v", err)
	}

	// Invalid Transition: restaurant_accepted -> delivered (skipping prep / rider steps)
	err = service.UpdateOrderStatus(orderID, "delivered", "Direct delivery", "event-002", uuid.New())
	if err == nil {
		t.Error("Expected status update from restaurant_accepted to delivered to fail")
	}

	// Test Idempotency: re-submit identical event ID (must return nil to bypass)
	err = service.UpdateOrderStatus(orderID, "preparing", "Commence prep", "event-001", uuid.New())
	if err != nil {
		t.Errorf("Expected duplicate event_id update to be skipped with nil error, got: %v", err)
	}
}
