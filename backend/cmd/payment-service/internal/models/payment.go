package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Payment struct {
	ID              uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	OrderID         uuid.UUID  `json:"order_id" gorm:"type:uuid;not null;index"`
	UserID          uuid.UUID  `json:"user_id" gorm:"type:uuid;not null;index"`
	Amount          float64    `json:"amount" gorm:"not null"`
	PaymentMethod   string     `json:"payment_method" gorm:"not null"`
	Status          string     `json:"status" gorm:"default:'pending'"`
	TransactionID   string     `json:"transaction_id"`
	GatewayResponse string     `json:"gateway_response" gorm:"type:jsonb"`
	Currency        string     `json:"currency" gorm:"default:'INR'"`
	PaidAt          *time.Time `json:"paid_at"`
	FailedAt        *time.Time `json:"failed_at"`
	RefundedAt      *time.Time `json:"refunded_at"`
	RefundAmount    *float64   `json:"refund_amount"`
	CreatedAt       time.Time  `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt       time.Time  `json:"updated_at" gorm:"autoUpdateTime"`
}

type Wallet struct {
	ID        uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	UserID    uuid.UUID `json:"user_id" gorm:"type:uuid;uniqueIndex;not null"`
	Balance   float64   `json:"balance" gorm:"default:0.00"`
	Currency  string    `json:"currency" gorm:"default:'INR'"`
	IsActive  bool      `json:"is_active" gorm:"default:true"`
	CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt time.Time `json:"updated_at" gorm:"autoUpdateTime"`
}

type WalletTransaction struct {
	ID          uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	WalletID    uuid.UUID  `json:"wallet_id" gorm:"type:uuid;not null;index"`
	Type        string     `json:"type" gorm:"not null"` // credit, debit
	Amount      float64    `json:"amount" gorm:"not null"`
	Balance     float64    `json:"balance" gorm:"not null"`
	Description string     `json:"description"`
	ReferenceID string     `json:"reference_id"`
	CreatedAt   time.Time  `json:"created_at" gorm:"autoCreateTime"`
}

type CreatePaymentRequest struct {
	OrderID       uuid.UUID `json:"order_id" binding:"required"`
	PaymentMethod string    `json:"payment_method" binding:"required"`
	Amount        float64   `json:"amount" binding:"required"`
}

type ProcessPaymentRequest struct {
	PaymentID     string  `json:"payment_id" binding:"required"`
	Amount        float64 `json:"amount" binding:"required"`
	PaymentMethod string  `json:"payment_method" binding:"required"`
}

type RefundRequest struct {
	PaymentID   uuid.UUID `json:"payment_id" binding:"required"`
	Amount      float64   `json:"amount" binding:"required"`
	Reason      string    `json:"reason" binding:"required"`
}

type AddToWalletRequest struct {
	Amount      float64 `json:"amount" binding:"required,gt=0"`
	Description string  `json:"description"`
}

type WalletWithdrawRequest struct {
	Amount      float64 `json:"amount" binding:"required,gt=0"`
	Description string  `json:"description"`
}

// BeforeCreate hook for Payment
func (p *Payment) BeforeCreate(tx *gorm.DB) error {
	if p.ID == uuid.Nil {
		p.ID = uuid.New()
	}
	return nil
}

// BeforeCreate hook for Wallet
func (w *Wallet) BeforeCreate(tx *gorm.DB) error {
	if w.ID == uuid.Nil {
		w.ID = uuid.New()
	}
	return nil
}

// BeforeCreate hook for WalletTransaction
func (wt *WalletTransaction) BeforeCreate(tx *gorm.DB) error {
	if wt.ID == uuid.Nil {
		wt.ID = uuid.New()
	}
	return nil
}
