package order

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// Mock implementations for testing
type MockCacheService struct {
	mock.Mock
}

func (m *MockCacheService) Get(ctx context.Context, key string) (string, error) {
	args := m.Called(ctx, key)
	return args.String(0), args.Error(1)
}

func (m *MockCacheService) Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error {
	args := m.Called(ctx, key, value, expiration)
	return args.Error(0)
}

func (m *MockCacheService) Delete(ctx context.Context, keys ...string) error {
	args := m.Called(ctx, keys)
	return args.Error(0)
}

type MockMessagingService struct {
	mock.Mock
}

func (m *MockMessagingService) PublishMessage(ctx context.Context, topic string, key string, message interface{}) error {
	args := m.Called(ctx, topic, key, message)
	return args.Error(0)
}

func TestNewOrderService(t *testing.T) {
	mockCache := new(MockCacheService)
	mockMessaging := new(MockMessagingService)
	orderService := NewOrderService(mockCache, mockMessaging)

	assert.NotNil(t, orderService)
	assert.NotNil(t, orderService.cacheService)
	assert.NotNil(t, orderService.messagingService)
}

func TestCalculateOrderTotals(t *testing.T) {
	mockCache := new(MockCacheService)
	mockMessaging := new(MockMessagingService)
	orderService := NewOrderService(mockCache, mockMessaging)

	order := &Order{
		Items: []OrderItem{
			{
				Quantity:  2,
				UnitPrice: 100.0,
			},
			{
				Quantity:  1,
				UnitPrice: 50.0,
			},
		},
		DeliveryFee:    20.0,
		DiscountAmount: 10.0,
	}

	err := orderService.calculateOrderTotals(order)

	assert.NoError(t, err)
	assert.Equal(t, 250.0, order.Subtotal) // (2*100) + (1*50)
	assert.Equal(t, 12.5, order.TaxAmount) // 5% of 250
	assert.Equal(t, 272.5, order.TotalAmount) // 250 + 20 + 12.5 - 10
}

func TestValidateOrder(t *testing.T) {
	mockCache := new(MockCacheService)
	mockMessaging := new(MockMessagingService)
	orderService := NewOrderService(mockCache, mockMessaging)

	validOrder := &Order{
		UserID:            uuid.New(),
		RestaurantID:      uuid.New(),
		DeliveryAddressID: uuid.New(),
		Items:             []OrderItem{{MenuItemID: uuid.New(), Quantity: 1}},
	}

	err := orderService.validateOrder(validOrder)
	assert.NoError(t, err)

	invalidOrder := &Order{
		UserID: uuid.Nil,
		Items:  []OrderItem{},
	}

	err = orderService.validateOrder(invalidOrder)
	assert.Error(t, err)
}

func TestGenerateOrderNumber(t *testing.T) {
	mockCache := new(MockCacheService)
	mockMessaging := new(MockMessagingService)
	orderService := NewOrderService(mockCache, mockMessaging)

	orderNumber1 := orderService.generateOrderNumber()
	orderNumber2 := orderService.generateOrderNumber()

	assert.NotEmpty(t, orderNumber1)
	assert.NotEmpty(t, orderNumber2)
	assert.NotEqual(t, orderNumber1, orderNumber2)
	assert.Contains(t, orderNumber1, "ORD-")
}

func TestValidateStatusTransition(t *testing.T) {
	mockCache := new(MockCacheService)
	mockMessaging := new(MockMessagingService)
	orderService := NewOrderService(mockCache, mockMessaging)

	testCases := []struct {
		currentStatus OrderStatus
		newStatus     OrderStatus
		shouldSucceed bool
	}{
		{OrderStatusPending, OrderStatusConfirmed, true},
		{OrderStatusPending, OrderStatusCancelled, true},
		{OrderStatusConfirmed, OrderStatusPreparing, true},
		{OrderStatusPreparing, OrderStatusReady, true},
		{OrderStatusReady, OrderStatusPickedUp, true},
		{OrderStatusPickedUp, OrderStatusOnTheWay, true},
		{OrderStatusOnTheWay, OrderStatusDelivered, true},
		{OrderStatusDelivered, OrderStatusPending, false},
		{OrderStatusCancelled, OrderStatusConfirmed, false},
	}

	for _, tc := range testCases {
		err := orderService.validateStatusTransition(tc.currentStatus, tc.newStatus)
		if tc.shouldSucceed {
			assert.NoError(t, err, "Transition from %s to %s should succeed", tc.currentStatus, tc.newStatus)
		} else {
			assert.Error(t, err, "Transition from %s to %s should fail", tc.currentStatus, tc.newStatus)
		}
	}
}

func TestCanCancelOrder(t *testing.T) {
	mockCache := new(MockCacheService)
	mockMessaging := new(MockMessagingService)
	orderService := NewOrderService(mockCache, mockMessaging)

	cancelableStatuses := []OrderStatus{
		OrderStatusPending,
		OrderStatusConfirmed,
		OrderStatusPreparing,
	}

	for _, status := range cancelableStatuses {
		order := &Order{Status: status}
		assert.True(t, orderService.canCancelOrder(order), "Order with status %s should be cancelable", status)
	}

	nonCancelableStatuses := []OrderStatus{
		OrderStatusReady,
		OrderStatusPickedUp,
		OrderStatusOnTheWay,
		OrderStatusDelivered,
		OrderStatusCancelled,
	}

	for _, status := range nonCancelableStatuses {
		order := &Order{Status: status}
		assert.False(t, orderService.canCancelOrder(order), "Order with status %s should not be cancelable", status)
	}
}

func TestCalculateEstimatedDeliveryTime(t *testing.T) {
	mockCache := new(MockCacheService)
	mockMessaging := new(MockMessagingService)
	orderService := NewOrderService(mockCache, mockMessaging)

	order := &Order{}
	estimatedTime := orderService.calculateEstimatedDeliveryTime(order)

	assert.True(t, estimatedTime.After(time.Now()))
	assert.True(t, estimatedTime.Before(time.Now().Add(2*time.Hour)))
}
