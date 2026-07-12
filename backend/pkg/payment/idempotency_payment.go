package payment

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// IdempotencyKey represents a unique key for idempotent operations
type IdempotencyKey struct {
	Key       string    `json:"key"`
	UserID    uuid.UUID `json:"user_id"`
	OrderID   uuid.UUID `json:"order_id"`
	Status    string    `json:"status"`   // "pending", "completed", "failed"
	Response  string    `json:"response"` // Cached response
	CreatedAt time.Time `json:"created_at"`
	ExpiresAt time.Time `json:"expires_at"`
}

// PaymentAttempt represents a payment attempt with retry logic
type PaymentAttempt struct {
	ID             uuid.UUID `json:"id"`
	IdempotencyKey string    `json:"idempotency_key"`
	OrderID        uuid.UUID `json:"order_id"`
	Amount         float64   `json:"amount"`
	Gateway        string    `json:"gateway"`
	Status         string    `json:"status"` // "pending", "processing", "completed", "failed"
	TransactionID  string    `json:"transaction_id"`
	AttemptNumber  int       `json:"attempt_number"`
	MaxRetries     int       `json:"max_retries"`
	LastError      string    `json:"last_error"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

// IdempotencyRepository handles idempotency key storage
type IdempotencyRepository interface {
	SaveKey(ctx context.Context, key *IdempotencyKey) error
	GetKey(ctx context.Context, key string) (*IdempotencyKey, error)
	UpdateKeyStatus(ctx context.Context, key string, status string, response string) error
	DeleteExpiredKeys(ctx context.Context) error
}

// PaymentAttemptRepository handles payment attempt storage
type PaymentAttemptRepository interface {
	SaveAttempt(ctx context.Context, attempt *PaymentAttempt) error
	GetAttempt(ctx context.Context, id uuid.UUID) (*PaymentAttempt, error)
	GetAttemptsByKey(ctx context.Context, idempotencyKey string) ([]*PaymentAttempt, error)
	UpdateAttempt(ctx context.Context, attempt *PaymentAttempt) error
}

// IdempotentPaymentService handles payments with idempotency
type IdempotentPaymentService struct {
	idempotencyRepo IdempotencyRepository
	attemptRepo     PaymentAttemptRepository
	paymentGateway  PaymentGatewayInterface
	maxRetries      int
	retryDelay      time.Duration
	keyExpiration   time.Duration
}

type PaymentGatewayInterface interface {
	ProcessPayment(ctx context.Context, amount float64, metadata map[string]interface{}) (string, error)
}

func NewIdempotentPaymentService(
	idempotencyRepo IdempotencyRepository,
	attemptRepo PaymentAttemptRepository,
	paymentGateway PaymentGatewayInterface,
	maxRetries int,
	retryDelay time.Duration,
	keyExpiration time.Duration,
) *IdempotentPaymentService {
	return &IdempotentPaymentService{
		idempotencyRepo: idempotencyRepo,
		attemptRepo:     attemptRepo,
		paymentGateway:  paymentGateway,
		maxRetries:      maxRetries,
		retryDelay:      retryDelay,
		keyExpiration:   keyExpiration,
	}
}

// ProcessPaymentWithIdempotency processes a payment with idempotency guarantee
func (ips *IdempotentPaymentService) ProcessPaymentWithIdempotency(ctx context.Context, idempotencyKey string, userID, orderID uuid.UUID, amount float64, metadata map[string]interface{}) (*PaymentAttempt, error) {
	// Check if this key has been used before
	existingKey, err := ips.idempotencyRepo.GetKey(ctx, idempotencyKey)
	if err == nil && existingKey != nil {
		// Key exists, check status
		if existingKey.Status == "completed" {
			// Return cached response
			attempts, err := ips.attemptRepo.GetAttemptsByKey(ctx, idempotencyKey)
			if err != nil {
				return nil, fmt.Errorf("failed to get existing attempts: %w", err)
			}
			if len(attempts) > 0 {
				return attempts[len(attempts)-1], nil
			}
		} else if existingKey.Status == "pending" {
			// Payment is still in progress
			return nil, fmt.Errorf("payment with this idempotency key is already in progress")
		}
	}

	// Save new idempotency key
	newKey := &IdempotencyKey{
		Key:       idempotencyKey,
		UserID:    userID,
		OrderID:   orderID,
		Status:    "pending",
		CreatedAt: time.Now(),
		ExpiresAt: time.Now().Add(ips.keyExpiration),
	}

	if err := ips.idempotencyRepo.SaveKey(ctx, newKey); err != nil {
		return nil, fmt.Errorf("failed to save idempotency key: %w", err)
	}

	// Create payment attempt
	attempt := &PaymentAttempt{
		ID:             uuid.New(),
		IdempotencyKey: idempotencyKey,
		OrderID:        orderID,
		Amount:         amount,
		Gateway:        "stripe", // or determine from metadata
		Status:         "pending",
		AttemptNumber:  1,
		MaxRetries:     ips.maxRetries,
		CreatedAt:      time.Now(),
		UpdatedAt:      time.Now(),
	}

	// Process payment with retry logic
	return ips.processPaymentWithRetry(ctx, attempt, metadata)
}

// processPaymentWithRetry processes payment with automatic retry
func (ips *IdempotentPaymentService) processPaymentWithRetry(ctx context.Context, attempt *PaymentAttempt, metadata map[string]interface{}) (*PaymentAttempt, error) {
	for attempt.AttemptNumber <= attempt.MaxRetries {
		// Update status to processing
		attempt.Status = "processing"
		attempt.UpdatedAt = time.Now()
		if err := ips.attemptRepo.UpdateAttempt(ctx, attempt); err != nil {
			return nil, fmt.Errorf("failed to update attempt status: %w", err)
		}

		// Process payment
		transactionID, err := ips.paymentGateway.ProcessPayment(ctx, attempt.Amount, metadata)
		if err == nil {
			// Payment successful
			attempt.Status = "completed"
			attempt.TransactionID = transactionID
			attempt.UpdatedAt = time.Now()

			if err := ips.attemptRepo.UpdateAttempt(ctx, attempt); err != nil {
				return nil, fmt.Errorf("failed to update successful attempt: %w", err)
			}

			// Update idempotency key status
			if err := ips.idempotencyRepo.UpdateKeyStatus(ctx, attempt.IdempotencyKey, "completed", transactionID); err != nil {
				// Log error but don't fail the payment
				fmt.Printf("Failed to update idempotency key status: %v\n", err)
			}

			return attempt, nil
		}

		// Payment failed
		attempt.Status = "failed"
		attempt.LastError = err.Error()
		attempt.UpdatedAt = time.Now()

		if err := ips.attemptRepo.UpdateAttempt(ctx, attempt); err != nil {
			return nil, fmt.Errorf("failed to update failed attempt: %w", err)
		}

		// Check if we should retry
		if attempt.AttemptNumber >= attempt.MaxRetries {
			// Max retries reached
			if err := ips.idempotencyRepo.UpdateKeyStatus(ctx, attempt.IdempotencyKey, "failed", err.Error()); err != nil {
				fmt.Printf("Failed to update idempotency key status: %v\n", err)
			}
			return attempt, fmt.Errorf("payment failed after %d attempts: %w", attempt.AttemptNumber, err)
		}

		// Increment attempt number and retry
		attempt.AttemptNumber++
		time.Sleep(ips.retryDelay)
	}

	return attempt, fmt.Errorf("payment failed after max retries")
}

// RetryFailedPayment retries a failed payment attempt
func (ips *IdempotentPaymentService) RetryFailedPayment(ctx context.Context, attemptID uuid.UUID) (*PaymentAttempt, error) {
	attempt, err := ips.attemptRepo.GetAttempt(ctx, attemptID)
	if err != nil {
		return nil, fmt.Errorf("failed to get payment attempt: %w", err)
	}

	if attempt.Status != "failed" {
		return nil, fmt.Errorf("payment attempt is not in failed state")
	}

	// Reset attempt for retry
	attempt.Status = "pending"
	attempt.AttemptNumber = 1
	attempt.LastError = ""
	attempt.UpdatedAt = time.Now()

	// Reset idempotency key status
	if err := ips.idempotencyRepo.UpdateKeyStatus(ctx, attempt.IdempotencyKey, "pending", ""); err != nil {
		return nil, fmt.Errorf("failed to reset idempotency key: %w", err)
	}

	// Process payment with retry
	return ips.processPaymentWithRetry(ctx, attempt, nil)
}

// GetPaymentStatus retrieves the status of a payment by idempotency key
func (ips *IdempotentPaymentService) GetPaymentStatus(ctx context.Context, idempotencyKey string) (*PaymentAttempt, error) {
	key, err := ips.idempotencyRepo.GetKey(ctx, idempotencyKey)
	if err != nil {
		return nil, fmt.Errorf("failed to get idempotency key: %w", err)
	}

	if key == nil {
		return nil, fmt.Errorf("idempotency key not found")
	}

	attempts, err := ips.attemptRepo.GetAttemptsByKey(ctx, idempotencyKey)
	if err != nil {
		return nil, fmt.Errorf("failed to get payment attempts: %w", err)
	}

	if len(attempts) == 0 {
		return nil, fmt.Errorf("no payment attempts found")
	}

	return attempts[len(attempts)-1], nil
}

// CleanupExpiredKeys cleans up expired idempotency keys
func (ips *IdempotentPaymentService) CleanupExpiredKeys(ctx context.Context) error {
	return ips.idempotencyRepo.DeleteExpiredKeys(ctx)
}
