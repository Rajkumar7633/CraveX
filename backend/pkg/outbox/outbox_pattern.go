package outbox

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// OutboxMessage represents a message in the outbox table
type OutboxMessage struct {
	ID          uuid.UUID      `json:"id"`
	AggregateID uuid.UUID     `json:"aggregate_id"` // e.g., order_id
	AggregateType string       `json:"aggregate_type"` // e.g., "order"
	EventType   string         `json:"event_type"` // e.g., "order_created"
	Payload     []byte         `json:"payload"`
	Topic       string         `json:"topic"` // Kafka topic
	Key         string         `json:"key"` // Kafka key
	Status      OutboxStatus   `json:"status"`
	CreatedAt   time.Time      `json:"created_at"`
	ProcessedAt *time.Time     `json:"processed_at,omitempty"`
	LastError   string         `json:"last_error,omitempty"`
	RetryCount  int            `json:"retry_count"`
}

type OutboxStatus string

const (
	OutboxStatusPending   OutboxStatus = "pending"
	OutboxStatusProcessed OutboxStatus = "processed"
	OutboxStatusFailed    OutboxStatus = "failed"
)

// OutboxRepository handles outbox persistence
type OutboxRepository interface {
	SaveMessage(ctx context.Context, message *OutboxMessage) error
	GetPendingMessages(ctx context.Context, limit int) ([]*OutboxMessage, error)
	MarkAsProcessed(ctx context.Context, messageID uuid.UUID) error
	MarkAsFailed(ctx context.Context, messageID uuid.UUID, error string) error
	DeleteProcessedMessages(ctx context.Context, olderThan time.Duration) error
}

// MessagePublisher handles publishing messages to Kafka
type MessagePublisher interface {
	PublishMessage(ctx context.Context, topic string, key string, payload []byte) error
}

// OutboxProcessor processes outbox messages and publishes them
type OutboxProcessor struct {
	outboxRepo   OutboxRepository
	publisher    MessagePublisher
	batchSize    int
	pollInterval time.Duration
	maxRetries   int
}

func NewOutboxProcessor(outboxRepo OutboxRepository, publisher MessagePublisher, batchSize int, pollInterval time.Duration, maxRetries int) *OutboxProcessor {
	return &OutboxProcessor{
		outboxRepo:   outboxRepo,
		publisher:    publisher,
		batchSize:    batchSize,
		pollInterval: pollInterval,
		maxRetries:   maxRetries,
	}
}

// ProcessOutbox processes pending outbox messages
func (op *OutboxProcessor) ProcessOutbox(ctx context.Context) error {
	messages, err := op.outboxRepo.GetPendingMessages(ctx, op.batchSize)
	if err != nil {
		return fmt.Errorf("failed to get pending messages: %w", err)
	}

	for _, message := range messages {
		if err := op.processMessage(ctx, message); err != nil {
			fmt.Printf("Failed to process message %s: %v\n", message.ID, err)
		}
	}

	return nil
}

// processMessage processes a single outbox message
func (op *OutboxProcessor) processMessage(ctx context.Context, message *OutboxMessage) error {
	// Publish message to Kafka
	if err := op.publisher.PublishMessage(ctx, message.Topic, message.Key, message.Payload); err != nil {
		// Mark as failed
		message.RetryCount++
		message.LastError = err.Error()
		
		if message.RetryCount >= op.maxRetries {
			if markErr := op.outboxRepo.MarkAsFailed(ctx, message.ID, err.Error()); markErr != nil {
				return fmt.Errorf("failed to mark as failed: %w", markErr)
			}
		} else {
			// Save updated retry count
			if saveErr := op.outboxRepo.SaveMessage(ctx, message); saveErr != nil {
				return fmt.Errorf("failed to save retry count: %w", saveErr)
			}
		}
		
		return fmt.Errorf("failed to publish message: %w", err)
	}

	// Mark as processed
	now := time.Now()
	message.ProcessedAt = &now
	message.Status = OutboxStatusProcessed
	
	if err := op.outboxRepo.MarkAsProcessed(ctx, message.ID); err != nil {
		return fmt.Errorf("failed to mark as processed: %w", err)
	}

	return nil
}

// StartOutboxProcessor starts the outbox processor as a background job
func (op *OutboxProcessor) StartOutboxProcessor(ctx context.Context) {
	ticker := time.NewTicker(op.pollInterval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			if err := op.ProcessOutbox(ctx); err != nil {
				fmt.Printf("Outbox processing error: %v\n", err)
			}
		}
	}
}

// OutboxService provides a high-level interface for using the outbox pattern
type OutboxService struct {
	outboxRepo OutboxRepository
}

func NewOutboxService(outboxRepo OutboxRepository) *OutboxService {
	return &OutboxService{
		outboxRepo: outboxRepo,
	}
}

// SaveEvent saves an event to the outbox table
func (os *OutboxService) SaveEvent(ctx context.Context, aggregateID uuid.UUID, aggregateType, eventType string, payload interface{}, topic, key string) error {
	payloadBytes, err := json.Marshal(payload)
	if err != nil {
		return fmt.Errorf("failed to marshal payload: %w", err)
	}

	message := &OutboxMessage{
		ID:            uuid.New(),
		AggregateID:   aggregateID,
		AggregateType: aggregateType,
		EventType:     eventType,
		Payload:       payloadBytes,
		Topic:         topic,
		Key:           key,
		Status:        OutboxStatusPending,
		CreatedAt:     time.Now(),
		RetryCount:    0,
	}

	return os.outboxRepo.SaveMessage(ctx, message)
}

// CleanupProcessedMessages cleans up old processed messages
func (os *OutboxService) CleanupProcessedMessages(ctx context.Context, olderThan time.Duration) error {
	return os.outboxRepo.DeleteProcessedMessages(ctx, olderThan)
}

// TransactionalOutbox provides transactional outbox operations
type TransactionalOutbox struct {
	outboxService *OutboxService
	dbTransaction DBTransaction
}

type DBTransaction interface {
	Commit() error
	Rollback() error
}

func NewTransactionalOutbox(outboxService *OutboxService, dbTransaction DBTransaction) *TransactionalOutbox {
	return &TransactionalOutbox{
		outboxService:  outboxService,
		dbTransaction: dbTransaction,
	}
}

// SaveEventWithTransaction saves an event within a database transaction
func (to *TransactionalOutbox) SaveEventWithTransaction(ctx context.Context, aggregateID uuid.UUID, aggregateType, eventType string, payload interface{}, topic, key string) error {
	// Save event to outbox table (part of the same transaction)
	if err := to.outboxService.SaveEvent(ctx, aggregateID, aggregateType, eventType, payload, topic, key); err != nil {
		to.dbTransaction.Rollback()
		return fmt.Errorf("failed to save outbox event: %w", err)
	}

	// Commit transaction
	if err := to.dbTransaction.Commit(); err != nil {
		return fmt.Errorf("failed to commit transaction: %w", err)
	}

	return nil
}
