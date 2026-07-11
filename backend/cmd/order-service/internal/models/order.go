package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Order struct {
	ID                    uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	OrderNumber           string     `json:"order_number" gorm:"uniqueIndex;not null"`
	UserID                uuid.UUID  `json:"user_id" gorm:"not null;index"`
	RestaurantID          uuid.UUID  `json:"restaurant_id" gorm:"not null;index"`
	RiderID               *uuid.UUID `json:"rider_id" gorm:"index"`
	DeliveryAddressID     uuid.UUID  `json:"delivery_address_id" gorm:"not null"`
	Status                string     `json:"status" gorm:"default:'pending'"`
	Subtotal              float64    `json:"subtotal" gorm:"not null"`
	DeliveryFee           float64    `json:"delivery_fee" gorm:"not null"`
	Tax                   float64    `json:"tax" gorm:"not null"`
	Discount              float64    `json:"discount" gorm:"default:0.00"`
	PlatformFee           float64    `json:"platform_fee" gorm:"default:0.00"`
	PackagingFee          float64    `json:"packaging_fee" gorm:"default:0.00"`
	TipAmount             float64    `json:"tip_amount" gorm:"default:0.00"`
	TotalAmount           float64    `json:"total_amount" gorm:"not null"`
	PaymentMethod         string     `json:"payment_method"`
	PaymentStatus         string     `json:"payment_status" gorm:"default:'pending'"`
	PaymentID             string     `json:"payment_id"`
	CouponCode            string     `json:"coupon_code"`
	SpecialInstructions   string     `json:"special_instructions"`
	ScheduledFor          *time.Time `json:"scheduled_for"`
	EstimatedDeliveryTime *time.Time `json:"estimated_delivery_time"`
	ActualDeliveryTime    *time.Time `json:"actual_delivery_time"`
	CancellationReason    string     `json:"cancellation_reason"`
	CancelledBy           *uuid.UUID `json:"cancelled_by"`
	CancelledAt           *time.Time `json:"cancelled_at"`
	CreatedAt             time.Time  `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt             time.Time  `json:"updated_at" gorm:"autoUpdateTime"`
}

type OrderItem struct {
	ID                  uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	OrderID             uuid.UUID `json:"order_id" gorm:"not null;index"`
	MenuItemID          uuid.UUID `json:"menu_item_id" gorm:"not null;index"`
	Quantity            int       `json:"quantity" gorm:"not null"`
	UnitPrice           float64   `json:"unit_price" gorm:"not null"`
	Customizations      string    `json:"customizations" gorm:"type:jsonb"`
	SpecialInstructions string    `json:"special_instructions"`
	CreatedAt           time.Time `json:"created_at" gorm:"autoCreateTime"`
}

type OrderStatusHistory struct {
	ID        uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	OrderID   uuid.UUID  `json:"order_id" gorm:"not null;index"`
	Status    string     `json:"status" gorm:"not null"`
	Notes     string     `json:"notes"`
	UpdatedBy *uuid.UUID `json:"updated_by"`
	CreatedAt time.Time  `json:"created_at" gorm:"autoCreateTime"`
}

type CreateOrderRequest struct {
	RestaurantID        uuid.UUID          `json:"restaurant_id" binding:"required"`
	DeliveryAddressID   uuid.UUID          `json:"delivery_address_id" binding:"required"`
	Items               []OrderItemRequest `json:"items" binding:"required"`
	PaymentMethod       string             `json:"payment_method" binding:"required"`
	CouponCode          string             `json:"coupon_code"`
	SpecialInstructions string             `json:"special_instructions"`
	TipAmount           float64            `json:"tip_amount"`
	ScheduledFor        *time.Time         `json:"scheduled_for"`
}

type OrderItemRequest struct {
	MenuItemID          uuid.UUID `json:"menu_item_id" binding:"required"`
	Quantity            int       `json:"quantity" binding:"required,min=1"`
	UnitPrice           float64   `json:"unit_price" binding:"required"`
	Customizations      string    `json:"customizations"`
	SpecialInstructions string    `json:"special_instructions"`
}

type UpdateOrderStatusRequest struct {
	Status string `json:"status" binding:"required"`
	Notes  string `json:"notes"`
}

type CancelOrderRequest struct {
	Reason string `json:"reason" binding:"required"`
}

// BeforeCreate hook for Order
func (o *Order) BeforeCreate(tx *gorm.DB) error {
	if o.ID == uuid.Nil {
		o.ID = uuid.New()
	}
	return nil
}

// BeforeCreate hook for OrderItem
func (oi *OrderItem) BeforeCreate(tx *gorm.DB) error {
	if oi.ID == uuid.Nil {
		oi.ID = uuid.New()
	}
	return nil
}

// BeforeCreate hook for OrderStatusHistory
func (osh *OrderStatusHistory) BeforeCreate(tx *gorm.DB) error {
	if osh.ID == uuid.Nil {
		osh.ID = uuid.New()
	}
	return nil
}
