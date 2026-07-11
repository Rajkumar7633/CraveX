# Kafka Setup Guide for CraveX

This guide explains how to set up and configure Apache Kafka for event streaming in the CraveX food delivery platform.

## Overview

Kafka will be used for:
- **Event Streaming**: Real-time event communication between microservices
- **Order Processing**: Stream order events through the delivery pipeline
- **Notifications**: Push notifications to users and riders
- **Analytics**: Event sourcing for analytics and reporting
- **Audit Logging**: Track all system events for compliance

## Prerequisites

- Docker and Docker Compose installed
- Java Runtime Environment (for Kafka tools, optional)

## Installation

### Using Docker Compose (Recommended)

Add the following to your `docker-compose.yml`:

```yaml
version: '3.8'

services:
  zookeeper:
    image: confluentinc/cp-zookeeper:7.5.0
    container_name: cravex-zookeeper
    environment:
      ZOOKEEPER_CLIENT_PORT: 2181
      ZOOKEEPER_TICK_TIME: 2000
    ports:
      - "2181:2181"
    volumes:
      - zookeeper-data:/var/lib/zookeeper/data
      - zookeeper-logs:/var/lib/zookeeper/log
    networks:
      - cravex-network
    restart: unless-stopped

  kafka:
    image: confluentinc/cp-kafka:7.5.0
    container_name: cravex-kafka
    depends_on:
      - zookeeper
    ports:
      - "9092:9092"
      - "29092:29092"
    environment:
      KAFKA_BROKER_ID: 1
      KAFKA_ZOOKEEPER_CONNECT: zookeeper:2181
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_AUTO_CREATE_TOPICS_ENABLE: true
      KAFKA_LOG_RETENTION_HOURS: 168
      KAFKA_LOG_SEGMENT_BYTES: 1073741824
      KAFKA_LOG_RETENTION_CHECK_INTERVAL_MS: 300000
    volumes:
      - kafka-data:/var/lib/kafka/data
    networks:
      - cravex-network
    restart: unless-stopped

  kafka-ui:
    image: provectuslabs/kafka-ui:latest
    container_name: cravex-kafka-ui
    depends_on:
      - kafka
    ports:
      - "8080:8080"
    environment:
      KAFKA_CLUSTERS_0_NAME: cravex-cluster
      KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS: kafka:29092
      KAFKA_CLUSTERS_0_ZOOKEEPER: zookeeper:2181
    networks:
      - cravex-network
    restart: unless-stopped

volumes:
  zookeeper-data:
    driver: local
  zookeeper-logs:
    driver: local
  kafka-data:
    driver: local

networks:
  cravex-network:
    driver: bridge
```

Start Kafka:
```bash
docker-compose up -d zookeeper kafka kafka-ui
```

Access Kafka UI at `http://localhost:8080` to manage topics and monitor messages.

## Topics Configuration

### Required Topics

Create the following topics:

```bash
# Order Events
kafka-topics --create --topic order.created --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics --create --topic order.updated --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics --create --topic order.cancelled --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics --create --topic order.completed --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

# Rider Events
kafka-topics --create --topic rider.location --bootstrap-server localhost:9092 --partitions 5 --replication-factor 1
kafka-topics --create --topic rider.assigned --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics --create --topic rider.available --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

# Notification Events
kafka-topics --create --topic notification.push --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics --create --topic notification.email --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics --create --topic notification.sms --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

# Payment Events
kafka-topics --create --topic payment.initiated --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics --create --topic payment.completed --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics --create --topic payment.failed --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1

# Analytics Events
kafka-topics --create --topic analytics.order --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics --create --topic analytics.user --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
kafka-topics --create --topic analytics.restaurant --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
```

## Go Integration

### Install Kafka Client

```bash
go get github.com/IBM/sarama
```

### Kafka Producer Implementation

Create `backend/pkg/messaging/kafka_producer.go`:

```go
package messaging

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/IBM/sarama"
)

type KafkaProducer struct {
	producer sarama.SyncProducer
	config   *sarama.Config
}

func NewKafkaProducer(brokers []string) (*KafkaProducer, error) {
	config := sarama.NewConfig()
	config.Producer.RequiredAcks = sarama.WaitForAll
	config.Producer.Retry.Max = 5
	config.Producer.Return.Successes = true
	config.Producer.Return.Errors = true

	producer, err := sarama.NewSyncProducer(brokers, config)
	if err != nil {
		return nil, fmt.Errorf("failed to create Kafka producer: %w", err)
	}

	return &KafkaProducer{
		producer: producer,
		config:   config,
	}, nil
}

func (kp *KafkaProducer) PublishMessage(ctx context.Context, topic string, key string, message interface{}) error {
	value, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	msg := &sarama.ProducerMessage{
		Topic: topic,
		Key:   sarama.StringEncoder(key),
		Value: sarama.ByteEncoder(value),
	}

	partition, offset, err := kp.producer.SendMessage(msg)
	if err != nil {
		return fmt.Errorf("failed to send message: %w", err)
	}

	log.Printf("Message sent to topic %s, partition %d, offset %d", topic, partition, offset)
	return nil
}

func (kp *KafkaProducer) Close() error {
	return kp.producer.Close()
}
```

### Kafka Consumer Implementation

Create `backend/pkg/messaging/kafka_consumer.go`:

```go
package messaging

import (
	"context"
	"encoding/json"
	"fmt"
	"log"

	"github.com/IBM/sarama"
)

type KafkaConsumer struct {
	consumer sarama.ConsumerGroup
	handler  sarama.ConsumerGroupHandler
}

type ConsumerHandler struct {
	messageChan chan []byte
}

func NewKafkaConsumer(brokers []string, groupID string, topics []string) (*KafkaConsumer, error) {
	config := sarama.NewConfig()
	config.Consumer.Group.Rebalance.Strategy = sarama.BalanceStrategyRoundRobin
	config.Consumer.Offsets.Initial = sarama.OffsetNewest

	consumer, err := sarama.NewConsumerGroup(brokers, groupID, config)
	if err != nil {
		return nil, fmt.Errorf("failed to create consumer group: %w", err)
	}

	handler := &ConsumerHandler{
		messageChan: make(chan []byte, 100),
	}

	return &KafkaConsumer{
		consumer: consumer,
		handler:  handler,
	}, nil
}

func (kc *KafkaConsumer) Consume(ctx context.Context, topics []string) error {
	for {
		select {
		case <-ctx.Done():
			return ctx.Err()
		default:
			if err := kc.consumer.Consume(ctx, topics, kc.handler); err != nil {
				log.Printf("Error from consumer: %v", err)
			}
		}
	}
}

func (kc *KafkaConsumer) Messages() <-chan []byte {
	return kc.handler.(*ConsumerHandler).messageChan
}

func (kc *KafkaConsumer) Close() error {
	return kc.consumer.Close()
}

// Sarama ConsumerGroupHandler implementation
func (h *ConsumerHandler) Setup(sarama.ConsumerGroupSession) error {
	return nil
}

func (h *ConsumerHandler) Cleanup(sarama.ConsumerGroupSession) error {
	return nil
}

func (h *ConsumerHandler) ConsumeClaim(session sarama.ConsumerGroupSession, claim sarama.ConsumerGroupClaim) error {
	for message := range claim.Messages() {
		h.messageChan <- message.Value
		session.MarkMessage(message, "")
	}
	return nil
}
```

### Event Definitions

Create `backend/pkg/messaging/events.go`:

```go
package messaging

// Order Events
type OrderCreatedEvent struct {
	OrderID      string    `json:"order_id"`
	UserID       string    `json:"user_id"`
	RestaurantID string    `json:"restaurant_id"`
	Items        []Item    `json:"items"`
	TotalAmount  float64   `json:"total_amount"`
	Timestamp    time.Time `json:"timestamp"`
}

type OrderUpdatedEvent struct {
	OrderID   string    `json:"order_id"`
	Status    string    `json:"status"`
	Timestamp time.Time `json:"timestamp"`
}

type OrderCancelledEvent struct {
	OrderID   string    `json:"order_id"`
	Reason    string    `json:"reason"`
	Timestamp time.Time `json:"timestamp"`
}

// Rider Events
type RiderLocationEvent struct {
	RiderID  string  `json:"rider_id"`
	Latitude float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Timestamp time.Time `json:"timestamp"`
}

type RiderAssignedEvent struct {
	RiderID  string `json:"rider_id"`
	OrderID  string `json:"order_id"`
	Timestamp time.Time `json:"timestamp"`
}

// Notification Events
type NotificationEvent struct {
	UserID  string `json:"user_id"`
	Type    string `json:"type"`
	Title   string `json:"title"`
	Message string `json:"message"`
	Data    map[string]interface{} `json:"data"`
}

// Payment Events
type PaymentInitiatedEvent struct {
	PaymentID string  `json:"payment_id"`
	OrderID   string  `json:"order_id"`
	Amount    float64 `json:"amount"`
	Method    string  `json:"method"`
}

type PaymentCompletedEvent struct {
	PaymentID string    `json:"payment_id"`
	OrderID   string    `json:"order_id"`
	Amount    float64   `json:"amount"`
	Timestamp time.Time `json:"timestamp"`
}
```

## Service Integration

### Order Service Producer

```go
package main

import (
	"context"
	"log"
	"os"
	
	"github.com/zomato-clone/pkg/messaging"
)

func main() {
	// Initialize Kafka Producer
	brokers := []string{os.Getenv("KAFKA_BROKERS")}
	producer, err := messaging.NewKafkaProducer(brokers)
	if err != nil {
		log.Fatalf("Failed to create Kafka producer: %v", err)
	}
	defer producer.Close()

	// Publish order created event
	event := messaging.OrderCreatedEvent{
		OrderID:      "ORD12345",
		UserID:       "USER123",
		RestaurantID: "REST456",
		Items:        []Item{{ID: "ITEM1", Quantity: 2}},
		TotalAmount:  500.00,
		Timestamp:    time.Now(),
	}

	err = producer.PublishMessage(context.Background(), "order.created", event.OrderID, event)
	if err != nil {
		log.Printf("Failed to publish event: %v", err)
	}
}
```

### Notification Service Consumer

```go
package main

import (
	"context"
	"log"
	"os"
	
	"github.com/zomato-clone/pkg/messaging"
)

func main() {
	// Initialize Kafka Consumer
	brokers := []string{os.Getenv("KAFKA_BROKERS")}
	topics := []string{"notification.push", "notification.email", "notification.sms"}
	
	consumer, err := messaging.NewKafkaConsumer(brokers, "notification-service", topics)
	if err != nil {
		log.Fatalf("Failed to create Kafka consumer: %v", err)
	}
	defer consumer.Close()

	// Start consuming
	ctx := context.Background()
	go func() {
		if err := consumer.Consume(ctx, topics); err != nil {
			log.Printf("Consumer error: %v", err)
		}
	}()

	// Process messages
	for message := range consumer.Messages() {
		var notification messaging.NotificationEvent
		if err := json.Unmarshal(message, &notification); err != nil {
			log.Printf("Failed to unmarshal message: %v", err)
			continue
		}

		// Process notification
		processNotification(notification)
	}
}

func processNotification(event messaging.NotificationEvent) {
	// Send push notification, email, or SMS based on type
	log.Printf("Processing notification: %+v", event)
}
```

## Environment Variables

Add to `.env` files:

```bash
# Kafka Configuration
KAFKA_BROKERS=localhost:9092
KAFKA_GROUP_ID=cravex-group
KAFKA_AUTO_COMMIT=true
KAFKA_AUTO_COMMIT_INTERVAL_MS=1000
```

## Monitoring

### Kafka UI

Access Kafka UI at `http://localhost:8080` to:
- View all topics
- Monitor consumer groups
- Browse messages
- Create/delete topics
- View consumer lag

### CLI Monitoring

```bash
# List topics
kafka-topics --list --bootstrap-server localhost:9092

# Describe topic
kafka-topics --describe --topic order.created --bootstrap-server localhost:9092

# List consumer groups
kafka-consumer-groups --list --bootstrap-server localhost:9092

# Describe consumer group
kafka-consumer-groups --describe --group notification-service --bootstrap-server localhost:9092

# Consume messages
kafka-console-consumer --topic order.created --bootstrap-server localhost:9092 --from-beginning

# Produce messages
kafka-console-producer --topic order.created --bootstrap-server localhost:9092
```

## Best Practices

1. **Topic Naming**: Use descriptive names with dots for hierarchy
   - `order.created`
   - `rider.location`
   - `notification.push`

2. **Partitioning**: Choose appropriate partition count based on throughput
   - Order events: 3 partitions
   - Rider location: 5 partitions (high frequency)
   - Notifications: 3 partitions

3. **Message Keys**: Use consistent keys for ordering
   - Order ID for order events
   - Rider ID for rider events
   - User ID for notification events

4. **Consumer Groups**: Use unique group IDs for each service
   - `notification-service`
   - `analytics-service`
   - `audit-service`

5. **Retention**: Configure appropriate retention policies
   - Order events: 7 days
   - Rider location: 1 day
   - Analytics events: 30 days

## Troubleshooting

### Connection Issues

```bash
# Check if Kafka is running
docker ps | grep kafka

# Check Kafka logs
docker logs cravex-kafka

# Test connection
kafka-topics --list --bootstrap-server localhost:9092
```

### Consumer Lag

```bash
# Check consumer lag
kafka-consumer-groups --describe --group notification-service --bootstrap-server localhost:9092

# Reset consumer offsets (use with caution)
kafka-consumer-groups --reset-offsets --group notification-service --topic order.created --to-earliest --execute --bootstrap-server localhost:9092
```

### Topic Issues

```bash
# Delete topic
kafka-topics --delete --topic order.created --bootstrap-server localhost:9092

# Recreate topic
kafka-topics --create --topic order.created --bootstrap-server localhost:9092 --partitions 3 --replication-factor 1
```

## Production Considerations

1. **High Availability**: Use Kafka cluster with multiple brokers
2. **Replication**: Set replication factor to 3 for critical topics
3. **Monitoring**: Set up alerts for consumer lag and broker health
4. **Security**: Enable SSL/SASL authentication
5. **Backup**: Regular backups of Kafka data
6. **Schema Registry**: Use Confluent Schema Registry for message schemas
7. **Idempotence**: Enable idempotent producer for exactly-once semantics

## Next Steps

- [ ] Set up Kafka cluster for high availability
- [ ] Implement Schema Registry for message validation
- [ ] Add Kafka monitoring to observability stack
- [ ] Set up dead letter queues for failed messages
- [ ] Implement exactly-once semantics for critical operations
- [ ] Add integration tests for event flows
