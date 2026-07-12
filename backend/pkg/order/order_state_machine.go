package order

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// OrderState represents the exact states from the spec
type OrderState string

const (
	StatePlaced                 OrderState = "placed"
	StateRestaurantAccepted     OrderState = "restaurant_accepted"
	StateRestaurantRejected     OrderState = "restaurant_rejected"
	StatePreparing              OrderState = "preparing"
	StateReadyForPickup         OrderState = "ready_for_pickup"
	StateRiderAssigned          OrderState = "rider_assigned"
	StateRiderArrivedRestaurant OrderState = "rider_arrived_restaurant"
	StatePickedUp               OrderState = "picked_up"
	StateRiderArrivedCustomer   OrderState = "rider_arrived_customer"
	StateDelivered              OrderState = "delivered"
	StateCustomerCancelled      OrderState = "customer_cancelled"
	StateRefundInitiated        OrderState = "refund_initiated"
	StateRefunded               OrderState = "refunded"
	StateDeliveryFailed         OrderState = "delivery_failed"
	StateRiderReassignment      OrderState = "rider_reassignment"
)

// OrderEvent represents events in the CQRS pattern
type OrderEvent struct {
	ID          uuid.UUID      `json:"id"`
	OrderID     uuid.UUID      `json:"order_id"`
	EventType   string         `json:"event_type"`
	FromState   OrderState     `json:"from_state"`
	ToState     OrderState     `json:"to_state"`
	EventID     string         `json:"event_id"` // For idempotency
	Timestamp   time.Time      `json:"timestamp"`
	TriggeredBy string         `json:"triggered_by"` // user_id or "system"
	Metadata    map[string]interface{} `json:"metadata"`
}

// StateTransition represents a valid state transition
type StateTransition struct {
	From OrderState
	To   OrderState
}

// ValidTransitions defines all valid state transitions
var ValidTransitions = map[OrderState][]OrderState{
	StatePlaced: {
		StateRestaurantAccepted,
		StateRestaurantRejected,
		StateCustomerCancelled,
	},
	StateRestaurantAccepted: {
		StatePreparing,
		StateCustomerCancelled,
		StateRiderReassignment, // If rider doesn't accept
	},
	StateRestaurantRejected: {
		StateRefundInitiated,
	},
	StatePreparing: {
		StateReadyForPickup,
		StateCustomerCancelled,
	},
	StateReadyForPickup: {
		StateRiderAssigned,
		StateCustomerCancelled,
	},
	StateRiderAssigned: {
		StateRiderArrivedRestaurant,
		StateRiderReassignment, // If rider goes offline
		StateCustomerCancelled,
	},
	StateRiderReassignment: {
		StateRiderAssigned, // To new rider
	},
	StateRiderArrivedRestaurant: {
		StatePickedUp,
		StateCustomerCancelled,
	},
	StatePickedUp: {
		StateRiderArrivedCustomer,
		StateDeliveryFailed,
	},
	StateRiderArrivedCustomer: {
		StateDelivered,
		StateDeliveryFailed,
	},
	StateDelivered: {}, // Terminal state
	StateCustomerCancelled: {
		StateRefundInitiated,
	},
	StateRefundInitiated: {
		StateRefunded,
	},
	StateRefunded: {}, // Terminal state
	StateDeliveryFailed: {
		StateDelivered, // If resolved
		StateRefundInitiated, // If cannot resolve
	},
}

// OrderStateMachine handles state transitions with CQRS pattern
type OrderStateMachine struct {
	eventStore EventStore
	notifier   Notifier
	auditLog   AuditLogger
}

type EventStore interface {
	SaveEvent(ctx context.Context, event OrderEvent) error
	GetOrderEvents(ctx context.Context, orderID uuid.UUID) ([]OrderEvent, error)
}

type Notifier interface {
	SendPushNotification(ctx context.Context, userID uuid.UUID, title, body string, data map[string]interface{}) error
	EmitWebSocketEvent(ctx context.Context, orderID uuid.UUID, eventType string, data map[string]interface{}) error
}

type AuditLogger interface {
	LogStateChange(ctx context.Context, orderID uuid.UUID, from, to OrderState, triggeredBy string, metadata map[string]interface{}) error
}

func NewOrderStateMachine(eventStore EventStore, notifier Notifier, auditLog AuditLogger) *OrderStateMachine {
	return &OrderStateMachine{
		eventStore: eventStore,
		notifier:   notifier,
		auditLog:   auditLog,
	}
}

// TransitionState performs a state transition with idempotency check
func (osm *OrderStateMachine) TransitionState(ctx context.Context, orderID uuid.UUID, toState OrderState, eventID string, triggeredBy string, metadata map[string]interface{}) error {
	// Get current state from event store
	events, err := osm.eventStore.GetOrderEvents(ctx, orderID)
	if err != nil {
		return fmt.Errorf("failed to get order events: %w", err)
	}

	if len(events) == 0 {
		return fmt.Errorf("order not found")
	}

	currentState := events[len(events)-1].ToState

	// Check idempotency - if this event already processed, return success
	for _, event := range events {
		if event.EventID == eventID {
			return nil // Already processed
		}
	}

	// Validate transition
	if !osm.isValidTransition(currentState, toState) {
		return fmt.Errorf("invalid state transition from %s to %s", currentState, toState)
	}

	// Create event
	event := OrderEvent{
		ID:          uuid.New(),
		OrderID:     orderID,
		EventType:   "state_transition",
		FromState:   currentState,
		ToState:     toState,
		EventID:     eventID,
		Timestamp:   time.Now(),
		TriggeredBy: triggeredBy,
		Metadata:    metadata,
	}

	// Save event
	if err := osm.eventStore.SaveEvent(ctx, event); err != nil {
		return fmt.Errorf("failed to save event: %w", err)
	}

	// Audit log
	if err := osm.auditLog.LogStateChange(ctx, orderID, currentState, toState, triggeredBy, metadata); err != nil {
		// Log error but don't fail the transition
		fmt.Printf("Failed to log audit: %v\n", err)
	}

	// Send notifications based on state
	if err := osm.sendStateNotifications(ctx, orderID, toState, triggeredBy, metadata); err != nil {
		// Log error but don't fail the transition
		fmt.Printf("Failed to send notifications: %v\n", err)
	}

	// Emit websocket event
	if err := osm.notifier.EmitWebSocketEvent(ctx, orderID, string(toState), metadata); err != nil {
		// Log error but don't fail the transition
		fmt.Printf("Failed to emit websocket event: %v\n", err)
	}

	return nil
}

func (osm *OrderStateMachine) isValidTransition(from, to OrderState) bool {
	validToStates, exists := ValidTransitions[from]
	if !exists {
		return false
	}

	for _, validState := range validToStates {
		if validState == to {
			return true
		}
	}

	return false
}

func (osm *OrderStateMachine) sendStateNotifications(ctx context.Context, orderID uuid.UUID, state OrderState, triggeredBy string, metadata map[string]interface{}) error {
	// Extract user ID from metadata
	userIDStr, ok := metadata["user_id"].(string)
	if !ok {
		return fmt.Errorf("user_id not found in metadata")
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return fmt.Errorf("invalid user_id: %w", err)
	}

	var title, body string

	switch state {
	case StateRestaurantAccepted:
		title = "Order Confirmed"
		body = "Your order has been accepted by the restaurant"
	case StatePreparing:
		title = "Preparing Your Order"
		body = "Your order is being prepared"
	case StateReadyForPickup:
		title = "Order Ready"
		body = "Your order is ready for pickup"
	case StateRiderAssigned:
		title = "Rider Assigned"
		body = "A rider has been assigned to your order"
	case StateRiderArrivedRestaurant:
		title = "Rider at Restaurant"
		body = "Your rider has arrived at the restaurant"
	case StatePickedUp:
		title = "Order Picked Up"
		body = "Your order has been picked up and is on the way"
	case StateRiderArrivedCustomer:
		title = "Rider Arrived"
		body = "Your rider has arrived at your location"
	case StateDelivered:
		title = "Order Delivered"
		body = "Your order has been delivered successfully"
	case StateCustomerCancelled:
		title = "Order Cancelled"
		body = "Your order has been cancelled"
	case StateRefundInitiated:
		title = "Refund Initiated"
		body = "Your refund is being processed"
	case StateRefunded:
		title = "Refund Processed"
		body = "Your refund has been processed successfully"
	case StateDeliveryFailed:
		title = "Delivery Issue"
		body = "There was an issue with your delivery. Please contact support"
	default:
		return nil
	}

	return osm.notifier.SendPushNotification(ctx, userID, title, body, metadata)
}

// GetCurrentState retrieves the current state from event store
func (osm *OrderStateMachine) GetCurrentState(ctx context.Context, orderID uuid.UUID) (OrderState, error) {
	events, err := osm.eventStore.GetOrderEvents(ctx, orderID)
	if err != nil {
		return "", fmt.Errorf("failed to get order events: %w", err)
	}

	if len(events) == 0 {
		return "", fmt.Errorf("order not found")
	}

	return events[len(events)-1].ToState, nil
}

// GetOrderHistory returns the complete event history for an order
func (osm *OrderStateMachine) GetOrderHistory(ctx context.Context, orderID uuid.UUID) ([]OrderEvent, error) {
	return osm.eventStore.GetOrderEvents(ctx, orderID)
}

// CanCancel checks if order can be cancelled based on current state
func (osm *OrderStateMachine) CanCancel(ctx context.Context, orderID uuid.UUID) (bool, error) {
	currentState, err := osm.GetCurrentState(ctx, orderID)
	if err != nil {
		return false, err
	}

	// Can cancel before pickup
	cancelableStates := map[OrderState]bool{
		StatePlaced:             true,
		StateRestaurantAccepted: true,
		StatePreparing:          true,
		StateReadyForPickup:     true,
		StateRiderAssigned:      true,
	}

	return cancelableStates[currentState], nil
}

// HandleRestaurantOffline handles the edge case when restaurant goes offline mid-order
func (osm *OrderStateMachine) HandleRestaurantOffline(ctx context.Context, orderID uuid.UUID, triggeredBy string) error {
	currentState, err := osm.GetCurrentState(ctx, orderID)
	if err != nil {
		return err
	}

	// Only handle if restaurant accepted but not yet ready
	if currentState == StateRestaurantAccepted || currentState == StatePreparing {
		metadata := map[string]interface{}{
			"reason":       "restaurant_offline",
			"auto_cancel": true,
		}
		return osm.TransitionState(ctx, orderID, StateCustomerCancelled, uuid.New().String(), "system", metadata)
	}

	return fmt.Errorf("cannot handle restaurant offline in state: %s", currentState)
}

// HandleRiderCancellation handles rider cancellation and triggers reassignment
func (osm *OrderStateMachine) HandleRiderCancellation(ctx context.Context, orderID uuid.UUID, riderID uuid.UUID, triggeredBy string) error {
	currentState, err := osm.GetCurrentState(ctx, orderID)
	if err != nil {
		return err
	}

	if currentState == StateRiderAssigned {
		metadata := map[string]interface{}{
			"cancelled_rider_id": riderID.String(),
			"reason":             "rider_cancelled",
		}
		return osm.TransitionState(ctx, orderID, StateRiderReassignment, uuid.New().String(), "system", metadata)
	}

	return fmt.Errorf("cannot handle rider cancellation in state: %s", currentState)
}

// HandleDeliveryFailure handles delivery failure scenarios
func (osm *OrderStateMachine) HandleDeliveryFailure(ctx context.Context, orderID uuid.UUID, reason string, triggeredBy string) error {
	metadata := map[string]interface{}{
		"failure_reason": reason,
	}
	return osm.TransitionState(ctx, orderID, StateDeliveryFailed, uuid.New().String(), triggeredBy, metadata)
}
