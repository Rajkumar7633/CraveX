package messaging

import (
	"context"
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
