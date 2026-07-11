package messaging

import "time"

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

type RiderLocationEvent struct {
	RiderID  string  `json:"rider_id"`
	Latitude float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	Timestamp time.Time `json:"timestamp"`
}

type RiderAssignedEvent struct {
	RiderID  string    `json:"rider_id"`
	OrderID  string    `json:"order_id"`
	Timestamp time.Time `json:"timestamp"`
}

type NotificationEvent struct {
	UserID  string                 `json:"user_id"`
	Type    string                 `json:"type"`
	Title   string                 `json:"title"`
	Message string                 `json:"message"`
	Data    map[string]interface{} `json:"data"`
}

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

type Item struct {
	ID       string  `json:"id"`
	Name     string  `json:"name"`
	Quantity int     `json:"quantity"`
	Price    float64 `json:"price"`
}
