package saga

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// SagaState represents the state of a saga
type SagaState string

const (
	SagaStateStarted      SagaState = "started"
	SagaStateOrderCreated SagaState = "order_created"
	SagaStatePaymentInit  SagaState = "payment_initiated"
	SagaStatePaymentSucc  SagaState = "payment_succeeded"
	SagaStatePaymentFail  SagaState = "payment_failed"
	SagaStateCompleted    SagaState = "completed"
	SagaStateCompensating SagaState = "compensating"
	SagaStateCompensated  SagaState = "compensated"
	SagaStateFailed       SagaState = "failed"
)

// SagaStep represents a step in the saga
type SagaStep struct {
	Name         string
	Execute      func(ctx context.Context) error
	Compensate   func(ctx context.Context) error
	Completed    bool
	Compensated  bool
}

// OrderPaymentSaga implements the saga pattern for order+payment consistency
type OrderPaymentSaga struct {
	ID              uuid.UUID
	OrderID         uuid.UUID
	PaymentID       uuid.UUID
	State           SagaState
	Steps           []*SagaStep
	CurrentStep     int
	StartedAt       time.Time
	CompletedAt     *time.Time
	FailedAt        *time.Time
	FailureReason   string
}

// SagaRepository handles saga persistence
type SagaRepository interface {
	SaveSaga(ctx context.Context, saga *OrderPaymentSaga) error
	GetSaga(ctx context.Context, id uuid.UUID) (*OrderPaymentSaga, error)
	UpdateSagaState(ctx context.Context, id uuid.UUID, state SagaState) error
}

// OrderService handles order operations
type OrderService interface {
	CreateOrder(ctx context.Context, orderID uuid.UUID) error
	CancelOrder(ctx context.Context, orderID uuid.UUID, reason string) error
}

// PaymentService handles payment operations
type PaymentService interface {
	InitiatePayment(ctx context.Context, paymentID uuid.UUID, amount float64) error
	ConfirmPayment(ctx context.Context, paymentID uuid.UUID) error
	RefundPayment(ctx context.Context, paymentID uuid.UUID, amount float64) error
	CancelPayment(ctx context.Context, paymentID uuid.UUID) error
}

// SagaOrchestrator manages saga execution
type SagaOrchestrator struct {
	sagaRepo      SagaRepository
	orderService  OrderService
	paymentService PaymentService
}

func NewSagaOrchestrator(sagaRepo SagaRepository, orderService OrderService, paymentService PaymentService) *SagaOrchestrator {
	return &SagaOrchestrator{
		sagaRepo:       sagaRepo,
		orderService:   orderService,
		paymentService: paymentService,
	}
}

// StartOrderPaymentSaga starts a new saga for order+payment
func (so *SagaOrchestrator) StartOrderPaymentSaga(ctx context.Context, orderID uuid.UUID, amount float64) (*OrderPaymentSaga, error) {
	sagaID := uuid.New()
	paymentID := uuid.New()

	saga := &OrderPaymentSaga{
		ID:        sagaID,
		OrderID:   orderID,
		PaymentID: paymentID,
		State:     SagaStateStarted,
		StartedAt: time.Now(),
		Steps: []*SagaStep{
			{
				Name: "create_order",
				Execute: func(ctx context.Context) error {
					return so.orderService.CreateOrder(ctx, orderID)
				},
				Compensate: func(ctx context.Context) error {
					return so.orderService.CancelOrder(ctx, orderID, "payment_failed")
				},
			},
			{
				Name: "initiate_payment",
				Execute: func(ctx context.Context) error {
					return so.paymentService.InitiatePayment(ctx, paymentID, amount)
				},
				Compensate: func(ctx context.Context) error {
					return so.paymentService.CancelPayment(ctx, paymentID)
				},
			},
			{
				Name: "confirm_payment",
				Execute: func(ctx context.Context) error {
					return so.paymentService.ConfirmPayment(ctx, paymentID)
				},
				Compensate: func(ctx context.Context) error {
					return so.paymentService.RefundPayment(ctx, paymentID, amount)
				},
			},
		},
		CurrentStep: 0,
	}

	if err := so.sagaRepo.SaveSaga(ctx, saga); err != nil {
		return nil, fmt.Errorf("failed to save saga: %w", err)
	}

	// Execute saga asynchronously
	go so.executeSaga(context.Background(), saga)

	return saga, nil
}

// executeSaga executes the saga steps
func (so *SagaOrchestrator) executeSaga(ctx context.Context, saga *OrderPaymentSaga) error {
	for i, step := range saga.Steps {
		saga.CurrentStep = i
		saga.State = SagaStateOrderCreated
		
		if err := so.sagaRepo.SaveSaga(ctx, saga); err != nil {
			return fmt.Errorf("failed to save saga state: %w", err)
		}

		// Execute step
		if err := step.Execute(ctx); err != nil {
			// Step failed, start compensation
			saga.State = SagaStateCompensating
			saga.FailedAt = &[]time.Time{time.Now()}[0]
			saga.FailureReason = fmt.Sprintf("step %s failed: %v", step.Name, err)
			
			if err := so.sagaRepo.SaveSaga(ctx, saga); err != nil {
				return fmt.Errorf("failed to save saga state: %w", err)
			}

			// Compensate all completed steps in reverse order
			return so.compensateSaga(ctx, saga, i)
		}

		step.Completed = true
	}

	// All steps completed successfully
	saga.State = SagaStateCompleted
	now := time.Now()
	saga.CompletedAt = &now
	
	if err := so.sagaRepo.SaveSaga(ctx, saga); err != nil {
		return fmt.Errorf("failed to save completed saga: %w", err)
	}

	return nil
}

// compensateSaga compensates failed saga by executing compensation actions
func (so *SagaOrchestrator) compensateSaga(ctx context.Context, saga *OrderPaymentSaga, failedStep int) error {
	// Compensate in reverse order
	for i := failedStep - 1; i >= 0; i-- {
		step := saga.Steps[i]
		
		if !step.Completed {
			continue
		}

		if err := step.Compensate(ctx); err != nil {
			// Compensation failed - log and continue
			fmt.Printf("Compensation failed for step %s: %v\n", step.Name, err)
		}

		step.Compensated = true
	}

	saga.State = SagaStateCompensated
	if err := so.sagaRepo.SaveSaga(ctx, saga); err != nil {
		return fmt.Errorf("failed to save compensated saga: %w", err)
	}

	return nil
}

// HandlePaymentFailure handles payment failure and triggers compensation
func (so *SagaOrchestrator) HandlePaymentFailure(ctx context.Context, sagaID uuid.UUID, reason string) error {
	saga, err := so.sagaRepo.GetSaga(ctx, sagaID)
	if err != nil {
		return fmt.Errorf("failed to get saga: %w", err)
	}

	saga.State = SagaStatePaymentFail
	saga.FailureReason = reason
	now := time.Now()
	saga.FailedAt = &now

	if err := so.sagaRepo.SaveSaga(ctx, saga); err != nil {
		return fmt.Errorf("failed to save saga state: %w", err)
	}

	// Trigger compensation
	return so.compensateSaga(ctx, saga, saga.CurrentStep)
}

// RetryFailedSaga retries a failed saga
func (so *SagaOrchestrator) RetryFailedSaga(ctx context.Context, sagaID uuid.UUID) error {
	saga, err := so.sagaRepo.GetSaga(ctx, sagaID)
	if err != nil {
		return fmt.Errorf("failed to get saga: %w", err)
	}

	if saga.State != SagaStateCompensated && saga.State != SagaStateFailed {
		return fmt.Errorf("saga is not in a retryable state: %s", saga.State)
	}

	// Reset saga state
	saga.State = SagaStateStarted
	saga.CurrentStep = 0
	saga.FailedAt = nil
	saga.FailureReason = ""
	
	// Reset step states
	for _, step := range saga.Steps {
		step.Completed = false
		step.Compensated = false
	}

	if err := so.sagaRepo.SaveSaga(ctx, saga); err != nil {
		return fmt.Errorf("failed to reset saga: %w", err)
	}

	// Re-execute saga
	return so.executeSaga(ctx, saga)
}

// GetSagaStatus returns the current status of a saga
func (so *SagaOrchestrator) GetSagaStatus(ctx context.Context, sagaID uuid.UUID) (*OrderPaymentSaga, error) {
	return so.sagaRepo.GetSaga(ctx, sagaID)
}
