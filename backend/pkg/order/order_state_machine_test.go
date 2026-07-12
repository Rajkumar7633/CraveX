package order

import (
	"context"
	"testing"

	"github.com/google/uuid"
)

func TestOrderStateMachine_ValidTransitions(t *testing.T) {
	sm := NewOrderStateMachine()

	tests := []struct {
		name        string
		fromState   string
		toState     string
		shouldError bool
	}{
		{
			name:        "valid transition: PENDING -> CONFIRMED",
			fromState:   "PENDING",
			toState:     "CONFIRMED",
			shouldError: false,
		},
		{
			name:        "valid transition: CONFIRMED -> PREPARING",
			fromState:   "CONFIRMED",
			toState:     "PREPARING",
			shouldError: false,
		},
		{
			name:        "valid transition: PREPARING -> READY",
			fromState:   "PREPARING",
			toState:     "READY",
			shouldError: false,
		},
		{
			name:        "valid transition: READY -> PICKED_UP",
			fromState:   "READY",
			toState:     "PICKED_UP",
			shouldError: false,
		},
		{
			name:        "valid transition: PICKED_UP -> DELIVERED",
			fromState:   "PICKED_UP",
			toState:     "DELIVERED",
			shouldError: false,
		},
		{
			name:        "invalid transition: DELIVERED -> PREPARING",
			fromState:   "DELIVERED",
			toState:     "PREPARING",
			shouldError: true,
		},
		{
			name:        "invalid transition: CANCELLED -> CONFIRMED",
			fromState:   "CANCELLED",
			toState:     "CONFIRMED",
			shouldError: true,
		},
		{
			name:        "invalid transition: PENDING -> DELIVERED",
			fromState:   "PENDING",
			toState:     "DELIVERED",
			shouldError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			orderID := uuid.New()
			err := sm.TransitionOrder(context.Background(), orderID, tt.fromState, tt.toState, "test_event")
			
			if tt.shouldError {
				if err == nil {
					t.Error("Expected error for invalid transition but got none")
				}
			} else {
				if err != nil {
					t.Errorf("Unexpected error for valid transition: %v", err)
				}
			}
		})
	}
}

func TestOrderStateMachine_CancelOrder(t *testing.T) {
	sm := NewOrderStateMachine()

	tests := []struct {
		name        string
		currentState string
		shouldError bool
	}{
		{
			name:        "cancel from PENDING",
			currentState: "PENDING",
			shouldError: false,
		},
		{
			name:        "cancel from CONFIRMED",
			currentState: "CONFIRMED",
			shouldError: false,
		},
		{
			name:        "cancel from PREPARING",
			currentState: "PREPARING",
			shouldError: false,
		},
		{
			name:        "cannot cancel from DELIVERED",
			currentState: "DELIVERED",
			shouldError: true,
		},
		{
			name:        "cannot cancel from CANCELLED",
			currentState: "CANCELLED",
			shouldError: true,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			orderID := uuid.New()
			err := sm.CancelOrder(context.Background(), orderID, tt.currentState, "customer_request")
			
			if tt.shouldError {
				if err == nil {
					t.Error("Expected error for invalid cancellation but got none")
				}
			} else {
				if err != nil {
					t.Errorf("Unexpected error for valid cancellation: %v", err)
				}
			}
		})
	}
}

func TestOrderStateMachine_StateHistory(t *testing.T) {
	sm := NewOrderStateMachine()
	orderID := uuid.New()

	// Simulate order lifecycle
	states := []string{"PENDING", "CONFIRMED", "PREPARING", "READY", "PICKED_UP", "DELIVERED"}
	
	for i := 0; i < len(states)-1; i++ {
		err := sm.TransitionOrder(context.Background(), orderID, states[i], states[i+1], "test_event")
		if err != nil {
			t.Fatalf("Failed to transition from %s to %s: %v", states[i], states[i+1], err)
		}
	}

	// Verify state history
	history := sm.GetStateHistory(context.Background(), orderID)
	if len(history) != len(states) {
		t.Errorf("Expected %d state transitions, got %d", len(states), len(history))
	}

	// Verify final state
	currentState := sm.GetCurrentState(context.Background(), orderID)
	if currentState != "DELIVERED" {
		t.Errorf("Expected final state DELIVERED, got %s", currentState)
	}
}

func TestOrderStateMachine_ConcurrentTransitions(t *testing.T) {
	sm := NewOrderStateMachine()
	orderID := uuid.New()

	// Simulate concurrent state changes
	done := make(chan bool, 2)
	
	go func() {
		sm.TransitionOrder(context.Background(), orderID, "PENDING", "CONFIRMED", "event1")
		done <- true
	}()
	
	go func() {
		sm.TransitionOrder(context.Background(), orderID, "PENDING", "CANCELLED", "event2")
		done <- true
	}()

	<-done
	<-done

	// Verify only one transition succeeded
	currentState := sm.GetCurrentState(context.Background(), orderID)
	if currentState != "CONFIRMED" && currentState != "CANCELLED" {
		t.Errorf("Expected either CONFIRMED or CANCELLED, got %s", currentState)
	}
}

func TestOrderStateMachine_EventIdempotency(t *testing.T) {
	sm := NewOrderStateMachine()
	orderID := uuid.New()
	eventID := "test_event_123"

	// First transition should succeed
	err := sm.TransitionOrder(context.Background(), orderID, "PENDING", "CONFIRMED", eventID)
	if err != nil {
		t.Fatalf("First transition failed: %v", err)
	}

	// Same event should be idempotent (no error, no state change)
	err = sm.TransitionOrder(context.Background(), orderID, "PENDING", "CONFIRMED", eventID)
	if err != nil {
		t.Errorf("Idempotent transition should not error: %v", err)
	}

	// Verify state didn't change
	currentState := sm.GetCurrentState(context.Background(), orderID)
	if currentState != "CONFIRMED" {
		t.Errorf("State should remain CONFIRMED, got %s", currentState)
	}
}
