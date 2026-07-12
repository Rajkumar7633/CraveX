package event_sourcing

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// OrderEventSourcing implements event sourcing for order history from the spec:
// instead of just storing final order state, store every event (append-only log) —
// enables replay/debugging and accurate "time spent in each stage" analytics
type OrderEventSourcing struct {
	eventStore    EventStore
	snapshotStore SnapshotStore
}

type EventStore interface {
	SaveEvent(ctx context.Context, event *OrderEvent) error
	GetEvents(ctx context.Context, aggregateID uuid.UUID, fromVersion int) ([]*OrderEvent, error)
	GetLatestVersion(ctx context.Context, aggregateID uuid.UUID) (int, error)
}

type SnapshotStore interface {
	SaveSnapshot(ctx context.Context, snapshot *OrderSnapshot) error
	GetLatestSnapshot(ctx context.Context, aggregateID uuid.UUID) (*OrderSnapshot, error)
}

type OrderEvent struct {
	ID          uuid.UUID
	AggregateID uuid.UUID
	EventType   string
	Version     int
	Timestamp   time.Time
	Data        []byte
	Metadata    map[string]interface{}
}

type OrderSnapshot struct {
	AggregateID uuid.UUID
	Version     int
	State       *OrderState
	Timestamp   time.Time
}

type OrderState struct {
	ID            uuid.UUID
	OrderNumber   string
	UserID        uuid.UUID
	RestaurantID  uuid.UUID
	Status        string
	Items         []OrderItem
	TotalAmount   float64
	PaymentStatus string
	CreatedAt     time.Time
	UpdatedAt     time.Time
}

type OrderItem struct {
	ID         uuid.UUID
	MenuItemID uuid.UUID
	Quantity   int
	UnitPrice  float64
}

type OrderCreatedEvent struct {
	OrderID      uuid.UUID
	OrderNumber  string
	UserID       uuid.UUID
	RestaurantID uuid.UUID
	Items        []OrderItem
	TotalAmount  float64
}

type OrderStatusChangedEvent struct {
	OrderID   uuid.UUID
	OldStatus string
	NewStatus string
	ChangedBy string
	Reason    string
}

type PaymentCompletedEvent struct {
	OrderID       uuid.UUID
	PaymentID     uuid.UUID
	PaymentMethod string
	Amount        float64
}

type RiderAssignedEvent struct {
	OrderID uuid.UUID
	RiderID uuid.UUID
}

func NewOrderEventSourcing(eventStore EventStore, snapshotStore SnapshotStore) *OrderEventSourcing {
	return &OrderEventSourcing{
		eventStore:    eventStore,
		snapshotStore: snapshotStore,
	}
}

// SaveEvent saves an event to the event store
func (oes *OrderEventSourcing) SaveEvent(ctx context.Context, event *OrderEvent) error {
	return oes.eventStore.SaveEvent(ctx, event)
}

// GetOrderState reconstructs the current state by replaying events
func (oes *OrderEventSourcing) GetOrderState(ctx context.Context, aggregateID uuid.UUID) (*OrderState, error) {
	// Check for latest snapshot
	snapshot, err := oes.snapshotStore.GetLatestSnapshot(ctx, aggregateID)
	if err == nil && snapshot != nil {
		// Get events from snapshot version onwards
		events, err := oes.eventStore.GetEvents(ctx, aggregateID, snapshot.Version)
		if err != nil {
			return nil, fmt.Errorf("failed to get events: %w", err)
		}

		// Apply events to snapshot state
		state := snapshot.State
		for _, event := range events {
			state = oes.applyEvent(state, event)
		}

		return state, nil
	}

	// No snapshot, replay all events
	events, err := oes.eventStore.GetEvents(ctx, aggregateID, 0)
	if err != nil {
		return nil, fmt.Errorf("failed to get events: %w", err)
	}

	// Reconstruct state from events
	var state *OrderState
	for _, event := range events {
		state = oes.applyEvent(state, event)
	}

	return state, nil
}

// applyEvent applies a single event to the state
func (oes *OrderEventSourcing) applyEvent(state *OrderState, event *OrderEvent) *OrderState {
	switch event.EventType {
	case "order_created":
		var data OrderCreatedEvent
		json.Unmarshal(event.Data, &data)
		return &OrderState{
			ID:           data.OrderID,
			OrderNumber:  data.OrderNumber,
			UserID:       data.UserID,
			RestaurantID: data.RestaurantID,
			Status:       "placed",
			Items:        data.Items,
			TotalAmount:  data.TotalAmount,
			CreatedAt:    event.Timestamp,
			UpdatedAt:    event.Timestamp,
		}
	case "status_changed":
		if state == nil {
			return state
		}
		var data OrderStatusChangedEvent
		json.Unmarshal(event.Data, &data)
		state.Status = data.NewStatus
		state.UpdatedAt = event.Timestamp
		return state
	case "payment_completed":
		if state == nil {
			return state
		}
		var data PaymentCompletedEvent
		json.Unmarshal(event.Data, &data)
		state.PaymentStatus = "completed"
		state.UpdatedAt = event.Timestamp
		return state
	case "rider_assigned":
		if state == nil {
			return state
		}
		var data RiderAssignedEvent
		json.Unmarshal(event.Data, &data)
		state.UpdatedAt = event.Timestamp
		return state
	default:
		return state
	}
}

// CreateSnapshot creates a snapshot of the current state
func (oes *OrderEventSourcing) CreateSnapshot(ctx context.Context, aggregateID uuid.UUID) error {
	state, err := oes.GetOrderState(ctx, aggregateID)
	if err != nil {
		return fmt.Errorf("failed to get order state: %w", err)
	}

	latestVersion, err := oes.eventStore.GetLatestVersion(ctx, aggregateID)
	if err != nil {
		return fmt.Errorf("failed to get latest version: %w", err)
	}

	snapshot := &OrderSnapshot{
		AggregateID: aggregateID,
		Version:     latestVersion,
		State:       state,
		Timestamp:   time.Now(),
	}

	return oes.snapshotStore.SaveSnapshot(ctx, snapshot)
}

// GetOrderHistory returns the complete event history for an order
func (oes *OrderEventSourcing) GetOrderHistory(ctx context.Context, aggregateID uuid.UUID) ([]*OrderEvent, error) {
	return oes.eventStore.GetEvents(ctx, aggregateID, 0)
}

// GetTimeInStage calculates time spent in each stage for analytics
func (oes *OrderEventSourcing) GetTimeInStage(ctx context.Context, aggregateID uuid.UUID) (map[string]time.Duration, error) {
	events, err := oes.eventStore.GetEvents(ctx, aggregateID, 0)
	if err != nil {
		return nil, fmt.Errorf("failed to get events: %w", err)
	}

	stageTimes := make(map[string]time.Duration)
	var lastStatus string
	var lastTimestamp time.Time

	for _, event := range events {
		if event.EventType == "status_changed" {
			var data OrderStatusChangedEvent
			json.Unmarshal(event.Data, &data)

			if lastStatus != "" {
				duration := event.Timestamp.Sub(lastTimestamp)
				stageTimes[lastStatus] += duration
			}

			lastStatus = data.NewStatus
			lastTimestamp = event.Timestamp
		}
	}

	// Add time in current stage if order is still active
	if lastStatus != "" {
		duration := time.Since(lastTimestamp)
		stageTimes[lastStatus] += duration
	}

	return stageTimes, nil
}

// ReplayEvents replays events from a specific version for debugging
func (oes *OrderEventSourcing) ReplayEvents(ctx context.Context, aggregateID uuid.UUID, fromVersion int) (*OrderState, error) {
	events, err := oes.eventStore.GetEvents(ctx, aggregateID, fromVersion)
	if err != nil {
		return nil, fmt.Errorf("failed to get events: %w", err)
	}

	var state *OrderState
	for _, event := range events {
		state = oes.applyEvent(state, event)
	}

	return state, nil
}

// PublishOrderCreatedEvent publishes an order created event
func (oes *OrderEventSourcing) PublishOrderCreatedEvent(ctx context.Context, orderID uuid.UUID, orderNumber string, userID, restaurantID uuid.UUID, items []OrderItem, totalAmount float64) error {
	data := OrderCreatedEvent{
		OrderID:      orderID,
		OrderNumber:  orderNumber,
		UserID:       userID,
		RestaurantID: restaurantID,
		Items:        items,
		TotalAmount:  totalAmount,
	}

	dataBytes, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("failed to marshal event data: %w", err)
	}

	event := &OrderEvent{
		ID:          uuid.New(),
		AggregateID: orderID,
		EventType:   "order_created",
		Version:     1,
		Timestamp:   time.Now(),
		Data:        dataBytes,
		Metadata:    make(map[string]interface{}),
	}

	return oes.SaveEvent(ctx, event)
}

// PublishStatusChangedEvent publishes a status changed event
func (oes *OrderEventSourcing) PublishStatusChangedEvent(ctx context.Context, orderID uuid.UUID, oldStatus, newStatus, changedBy, reason string) error {
	latestVersion, err := oes.eventStore.GetLatestVersion(ctx, orderID)
	if err != nil {
		return fmt.Errorf("failed to get latest version: %w", err)
	}

	data := OrderStatusChangedEvent{
		OrderID:   orderID,
		OldStatus: oldStatus,
		NewStatus: newStatus,
		ChangedBy: changedBy,
		Reason:    reason,
	}

	dataBytes, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("failed to marshal event data: %w", err)
	}

	event := &OrderEvent{
		ID:          uuid.New(),
		AggregateID: orderID,
		EventType:   "status_changed",
		Version:     latestVersion + 1,
		Timestamp:   time.Now(),
		Data:        dataBytes,
		Metadata: map[string]interface{}{
			"changed_by": changedBy,
			"reason":     reason,
		},
	}

	return oes.SaveEvent(ctx, event)
}

// PublishPaymentCompletedEvent publishes a payment completed event
func (oes *OrderEventSourcing) PublishPaymentCompletedEvent(ctx context.Context, orderID, paymentID uuid.UUID, paymentMethod string, amount float64) error {
	latestVersion, err := oes.eventStore.GetLatestVersion(ctx, orderID)
	if err != nil {
		return fmt.Errorf("failed to get latest version: %w", err)
	}

	data := PaymentCompletedEvent{
		OrderID:       orderID,
		PaymentID:     paymentID,
		PaymentMethod: paymentMethod,
		Amount:        amount,
	}

	dataBytes, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("failed to marshal event data: %w", err)
	}

	event := &OrderEvent{
		ID:          uuid.New(),
		AggregateID: orderID,
		EventType:   "payment_completed",
		Version:     latestVersion + 1,
		Timestamp:   time.Now(),
		Data:        dataBytes,
		Metadata:    make(map[string]interface{}),
	}

	return oes.SaveEvent(ctx, event)
}

// PublishRiderAssignedEvent publishes a rider assigned event
func (oes *OrderEventSourcing) PublishRiderAssignedEvent(ctx context.Context, orderID, riderID uuid.UUID) error {
	latestVersion, err := oes.eventStore.GetLatestVersion(ctx, orderID)
	if err != nil {
		return fmt.Errorf("failed to get latest version: %w", err)
	}

	data := RiderAssignedEvent{
		OrderID: orderID,
		RiderID: riderID,
	}

	dataBytes, err := json.Marshal(data)
	if err != nil {
		return fmt.Errorf("failed to marshal event data: %w", err)
	}

	event := &OrderEvent{
		ID:          uuid.New(),
		AggregateID: orderID,
		EventType:   "rider_assigned",
		Version:     latestVersion + 1,
		Timestamp:   time.Now(),
		Data:        dataBytes,
		Metadata:    make(map[string]interface{}),
	}

	return oes.SaveEvent(ctx, event)
}
