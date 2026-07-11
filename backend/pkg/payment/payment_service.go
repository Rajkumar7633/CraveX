package payment

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

type PaymentMethod string

const (
	PaymentMethodUPI        PaymentMethod = "upi"
	PaymentMethodCreditCard PaymentMethod = "credit_card"
	PaymentMethodDebitCard  PaymentMethod = "debit_card"
	PaymentMethodNetBanking PaymentMethod = "net_banking"
	PaymentMethodWallet     PaymentMethod = "wallet"
	PaymentMethodCOD        PaymentMethod = "cod"
)

type PaymentStatus string

const (
	PaymentStatusPending    PaymentStatus = "pending"
	PaymentStatusProcessing PaymentStatus = "processing"
	PaymentStatusCompleted  PaymentStatus = "completed"
	PaymentStatusFailed     PaymentStatus = "failed"
	PaymentStatusRefunded   PaymentStatus = "refunded"
	PaymentStatusCancelled  PaymentStatus = "cancelled"
)

type PaymentGateway string

const (
	PaymentGatewayStripe   PaymentGateway = "stripe"
	PaymentGatewayRazorpay PaymentGateway = "razorpay"
	PaymentGatewayPaytm    PaymentGateway = "paytm"
	PaymentGatewayPhonePe  PaymentGateway = "phonepe"
)

type Payment struct {
	ID              uuid.UUID      `json:"id"`
	OrderID         uuid.UUID      `json:"order_id"`
	UserID          uuid.UUID      `json:"user_id"`
	Amount          float64        `json:"amount"`
	Currency        string         `json:"currency"`
	Method          PaymentMethod  `json:"method"`
	Gateway         PaymentGateway `json:"gateway"`
	Status          PaymentStatus  `json:"status"`
	TransactionID   string         `json:"transaction_id"`
	GatewayResponse string         `json:"gateway_response"`
	RefundAmount    float64        `json:"refund_amount"`
	RefundID        string         `json:"refund_id"`
	RefundReason    string         `json:"refund_reason"`
	CreatedAt       time.Time      `json:"created_at"`
	UpdatedAt       time.Time      `json:"updated_at"`
	CompletedAt     *time.Time     `json:"completed_at,omitempty"`
	FailedAt        *time.Time     `json:"failed_at,omitempty"`
	RefundedAt      *time.Time     `json:"refunded_at,omitempty"`
}

type PaymentRequest struct {
	OrderID  uuid.UUID              `json:"order_id"`
	UserID   uuid.UUID              `json:"user_id"`
	Amount   float64                `json:"amount"`
	Currency string                 `json:"currency"`
	Method   PaymentMethod          `json:"method"`
	Gateway  PaymentGateway         `json:"gateway"`
	Metadata map[string]interface{} `json:"metadata"`
}

type RefundRequest struct {
	PaymentID  uuid.UUID `json:"payment_id"`
	Amount     float64   `json:"amount"`
	Reason     string    `json:"reason"`
	RefundType string    `json:"refund_type"` // "full", "partial"
}

type Wallet struct {
	ID            uuid.UUID `json:"id"`
	UserID        uuid.UUID `json:"user_id"`
	Balance       float64   `json:"balance"`
	Currency      string    `json:"currency"`
	IsBlocked     bool      `json:"is_blocked"`
	BlockedReason string    `json:"blocked_reason,omitempty"`
	CreatedAt     time.Time `json:"created_at"`
	UpdatedAt     time.Time `json:"updated_at"`
}

type WalletTransaction struct {
	ID          uuid.UUID `json:"id"`
	WalletID    uuid.UUID `json:"wallet_id"`
	UserID      uuid.UUID `json:"user_id"`
	Type        string    `json:"type"` // "credit", "debit"
	Amount      float64   `json:"amount"`
	Description string    `json:"description"`
	ReferenceID string    `json:"reference_id"`
	CreatedAt   time.Time `json:"created_at"`
}

type PaymentService struct {
	cacheService     CacheService
	messagingService MessagingService
}

type CacheService interface {
	Get(ctx context.Context, key string) (string, error)
	Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error
	Delete(ctx context.Context, keys ...string) error
}

type MessagingService interface {
	PublishMessage(ctx context.Context, topic string, key string, message interface{}) error
}

func NewPaymentService(cacheService CacheService, messagingService MessagingService) *PaymentService {
	return &PaymentService{
		cacheService:     cacheService,
		messagingService: messagingService,
	}
}

func (ps *PaymentService) CreatePayment(ctx context.Context, req *PaymentRequest) (*Payment, error) {
	// Validate payment request
	if err := ps.validatePaymentRequest(req); err != nil {
		return nil, fmt.Errorf("payment validation failed: %w", err)
	}

	// Create payment record
	payment := &Payment{
		ID:        uuid.New(),
		OrderID:   req.OrderID,
		UserID:    req.UserID,
		Amount:    req.Amount,
		Currency:  req.Currency,
		Method:    req.Method,
		Gateway:   req.Gateway,
		Status:    PaymentStatusPending,
		CreatedAt: time.Now(),
		UpdatedAt: time.Now(),
	}

	// Save to database
	if err := ps.savePaymentToDB(ctx, payment); err != nil {
		return nil, fmt.Errorf("failed to save payment: %w", err)
	}

	// Initiate payment based on gateway
	var gatewayResponse string
	var err error

	switch req.Gateway {
	case PaymentGatewayStripe:
		gatewayResponse, err = ps.processStripePayment(ctx, payment)
	case PaymentGatewayRazorpay:
		gatewayResponse, err = ps.processRazorpayPayment(ctx, payment)
	case PaymentGatewayPaytm:
		gatewayResponse, err = ps.processPaytmPayment(ctx, payment)
	case PaymentGatewayPhonePe:
		gatewayResponse, err = ps.processPhonePePayment(ctx, payment)
	default:
		return nil, fmt.Errorf("unsupported payment gateway: %s", req.Gateway)
	}

	if err != nil {
		payment.Status = PaymentStatusFailed
		now := time.Now()
		payment.FailedAt = &now
		payment.UpdatedAt = now
		ps.updatePaymentInDB(ctx, payment)
		return nil, fmt.Errorf("payment processing failed: %w", err)
	}

	payment.GatewayResponse = gatewayResponse
	payment.Status = PaymentStatusProcessing
	payment.UpdatedAt = time.Now()

	if err := ps.updatePaymentInDB(ctx, payment); err != nil {
		return nil, fmt.Errorf("failed to update payment: %w", err)
	}

	// Publish payment initiated event
	event := map[string]interface{}{
		"payment_id": payment.ID.String(),
		"order_id":   payment.OrderID.String(),
		"user_id":    payment.UserID.String(),
		"amount":     payment.Amount,
		"status":     payment.Status,
		"gateway":    payment.Gateway,
	}

	if err := ps.messagingService.PublishMessage(ctx, "payment.initiated", payment.ID.String(), event); err != nil {
		return nil, fmt.Errorf("failed to publish payment initiated event: %w", err)
	}

	return payment, nil
}

func (ps *PaymentService) ConfirmPayment(ctx context.Context, paymentID uuid.UUID, transactionID string) error {
	payment, err := ps.GetPaymentByID(ctx, paymentID)
	if err != nil {
		return fmt.Errorf("failed to get payment: %w", err)
	}

	if payment.Status != PaymentStatusProcessing {
		return fmt.Errorf("payment is not in processing state")
	}

	// Verify payment with gateway
	isValid, err := ps.verifyPaymentWithGateway(ctx, payment, transactionID)
	if err != nil {
		return fmt.Errorf("failed to verify payment: %w", err)
	}

	if !isValid {
		payment.Status = PaymentStatusFailed
		now := time.Now()
		payment.FailedAt = &now
		payment.UpdatedAt = now
		ps.updatePaymentInDB(ctx, payment)
		return fmt.Errorf("payment verification failed")
	}

	// Update payment status
	payment.Status = PaymentStatusCompleted
	payment.TransactionID = transactionID
	now := time.Now()
	payment.CompletedAt = &now
	payment.UpdatedAt = now

	if err := ps.updatePaymentInDB(ctx, payment); err != nil {
		return fmt.Errorf("failed to update payment: %w", err)
	}

	// Add to wallet if applicable
	if payment.Method == PaymentMethodWallet {
		if err := ps.creditWallet(ctx, payment.UserID, payment.Amount); err != nil {
			return fmt.Errorf("failed to credit wallet: %w", err)
		}
	}

	// Publish payment completed event
	event := map[string]interface{}{
		"payment_id":     payment.ID.String(),
		"order_id":       payment.OrderID.String(),
		"user_id":        payment.UserID.String(),
		"transaction_id": transactionID,
		"amount":         payment.Amount,
		"completed_at":   payment.CompletedAt,
	}

	if err := ps.messagingService.PublishMessage(ctx, "payment.completed", paymentID.String(), event); err != nil {
		return fmt.Errorf("failed to publish payment completed event: %w", err)
	}

	// Invalidate cache
	ps.cacheService.Delete(ctx, fmt.Sprintf("payment:%s", paymentID.String()))

	return nil
}

func (ps *PaymentService) ProcessRefund(ctx context.Context, req *RefundRequest) (*Payment, error) {
	payment, err := ps.GetPaymentByID(ctx, req.PaymentID)
	if err != nil {
		return nil, fmt.Errorf("failed to get payment: %w", err)
	}

	if payment.Status != PaymentStatusCompleted {
		return nil, fmt.Errorf("payment is not completed")
	}

	if payment.Status == PaymentStatusRefunded {
		return nil, fmt.Errorf("payment already refunded")
	}

	// Validate refund amount
	if req.RefundType == "partial" && req.Amount > payment.Amount {
		return nil, fmt.Errorf("refund amount cannot exceed payment amount")
	}

	if req.RefundType == "full" {
		req.Amount = payment.Amount
	}

	// Process refund based on gateway
	var refundID string

	switch payment.Gateway {
	case PaymentGatewayStripe:
		refundID, err = ps.processStripeRefund(ctx, payment, req.Amount, req.Reason)
	case PaymentGatewayRazorpay:
		refundID, err = ps.processRazorpayRefund(ctx, payment, req.Amount, req.Reason)
	case PaymentGatewayPaytm:
		refundID, err = ps.processPaytmRefund(ctx, payment, req.Amount, req.Reason)
	case PaymentGatewayPhonePe:
		refundID, err = ps.processPhonePeRefund(ctx, payment, req.Amount, req.Reason)
	default:
		return nil, fmt.Errorf("unsupported payment gateway for refund: %s", payment.Gateway)
	}

	if err != nil {
		return nil, fmt.Errorf("refund processing failed: %w", err)
	}

	// Update payment
	payment.RefundAmount = req.Amount
	payment.RefundID = refundID
	payment.RefundReason = req.Reason
	payment.Status = PaymentStatusRefunded
	now := time.Now()
	payment.RefundedAt = &now
	payment.UpdatedAt = now

	if err := ps.updatePaymentInDB(ctx, payment); err != nil {
		return nil, fmt.Errorf("failed to update payment: %w", err)
	}

	// Refund to wallet if applicable
	if payment.Method == PaymentMethodWallet {
		if err := ps.creditWallet(ctx, payment.UserID, req.Amount); err != nil {
			return nil, fmt.Errorf("failed to refund to wallet: %w", err)
		}
	}

	// Publish refund event
	event := map[string]interface{}{
		"payment_id":    payment.ID.String(),
		"order_id":      payment.OrderID.String(),
		"user_id":       payment.UserID.String(),
		"refund_id":     refundID,
		"refund_amount": req.Amount,
		"refund_reason": req.Reason,
		"refunded_at":   payment.RefundedAt,
	}

	if err := ps.messagingService.PublishMessage(ctx, "payment.refunded", payment.ID.String(), event); err != nil {
		return nil, fmt.Errorf("failed to publish refund event: %w", err)
	}

	// Invalidate cache
	ps.cacheService.Delete(ctx, fmt.Sprintf("payment:%s", req.PaymentID.String()))

	return payment, nil
}

func (ps *PaymentService) GetPaymentByID(ctx context.Context, id uuid.UUID) (*Payment, error) {
	cacheKey := fmt.Sprintf("payment:%s", id.String())

	// Try cache first
	var cachedPayment Payment
	if _, err := ps.cacheService.Get(ctx, cacheKey); err == nil {
		return &cachedPayment, nil
	}

	// Fetch from database
	payment, err := ps.fetchPaymentFromDB(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch payment: %w", err)
	}

	// Cache for 15 minutes
	ps.cacheService.Set(ctx, cacheKey, payment, 15*time.Minute)

	return payment, nil
}

func (ps *PaymentService) GetUserWallet(ctx context.Context, userID uuid.UUID) (*Wallet, error) {
	cacheKey := fmt.Sprintf("wallet:%s", userID.String())

	// Try cache first
	var cachedWallet Wallet
	if _, err := ps.cacheService.Get(ctx, cacheKey); err == nil {
		return &cachedWallet, nil
	}

	// Fetch from database
	wallet, err := ps.fetchWalletFromDB(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch wallet: %w", err)
	}

	// Cache for 10 minutes
	ps.cacheService.Set(ctx, cacheKey, wallet, 10*time.Minute)

	return wallet, nil
}

func (ps *PaymentService) creditWallet(ctx context.Context, userID uuid.UUID, amount float64) error {
	wallet, err := ps.GetUserWallet(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to get wallet: %w", err)
	}

	if wallet.IsBlocked {
		return fmt.Errorf("wallet is blocked: %s", wallet.BlockedReason)
	}

	// Update wallet balance
	wallet.Balance += amount
	wallet.UpdatedAt = time.Now()

	if err := ps.updateWalletInDB(ctx, wallet); err != nil {
		return fmt.Errorf("failed to update wallet: %w", err)
	}

	// Create wallet transaction
	transaction := &WalletTransaction{
		ID:          uuid.New(),
		WalletID:    wallet.ID,
		UserID:      userID,
		Type:        "credit",
		Amount:      amount,
		Description: "Payment refund",
		CreatedAt:   time.Now(),
	}

	if err := ps.createWalletTransaction(ctx, transaction); err != nil {
		return fmt.Errorf("failed to create wallet transaction: %w", err)
	}

	// Invalidate cache
	ps.cacheService.Delete(ctx, fmt.Sprintf("wallet:%s", userID.String()))

	return nil
}

func (ps *PaymentService) debitWallet(ctx context.Context, userID uuid.UUID, amount float64, referenceID string) error {
	wallet, err := ps.GetUserWallet(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to get wallet: %w", err)
	}

	if wallet.IsBlocked {
		return fmt.Errorf("wallet is blocked: %s", wallet.BlockedReason)
	}

	if wallet.Balance < amount {
		return fmt.Errorf("insufficient wallet balance")
	}

	// Update wallet balance
	wallet.Balance -= amount
	wallet.UpdatedAt = time.Now()

	if err := ps.updateWalletInDB(ctx, wallet); err != nil {
		return fmt.Errorf("failed to update wallet: %w", err)
	}

	// Create wallet transaction
	transaction := &WalletTransaction{
		ID:          uuid.New(),
		WalletID:    wallet.ID,
		UserID:      userID,
		Type:        "debit",
		Amount:      amount,
		Description: "Order payment",
		ReferenceID: referenceID,
		CreatedAt:   time.Now(),
	}

	if err := ps.createWalletTransaction(ctx, transaction); err != nil {
		return fmt.Errorf("failed to create wallet transaction: %w", err)
	}

	// Invalidate cache
	ps.cacheService.Delete(ctx, fmt.Sprintf("wallet:%s", userID.String()))

	return nil
}

func (ps *PaymentService) validatePaymentRequest(req *PaymentRequest) error {
	if req.OrderID == uuid.Nil {
		return fmt.Errorf("order ID is required")
	}
	if req.UserID == uuid.Nil {
		return fmt.Errorf("user ID is required")
	}
	if req.Amount <= 0 {
		return fmt.Errorf("amount must be greater than zero")
	}
	if req.Currency == "" {
		return fmt.Errorf("currency is required")
	}
	if req.Method == "" {
		return fmt.Errorf("payment method is required")
	}
	if req.Gateway == "" {
		return fmt.Errorf("payment gateway is required")
	}
	return nil
}

func (ps *PaymentService) processStripePayment(ctx context.Context, payment *Payment) (string, error) {
	// Stripe payment processing logic
	// This would integrate with Stripe API
	return "stripe_payment_intent_id", nil
}

func (ps *PaymentService) processRazorpayPayment(ctx context.Context, payment *Payment) (string, error) {
	// Razorpay payment processing logic
	// This would integrate with Razorpay API
	return "razorpay_order_id", nil
}

func (ps *PaymentService) processPaytmPayment(ctx context.Context, payment *Payment) (string, error) {
	// Paytm payment processing logic
	// This would integrate with Paytm API
	return "paytm_transaction_id", nil
}

func (ps *PaymentService) processPhonePePayment(ctx context.Context, payment *Payment) (string, error) {
	// PhonePe payment processing logic
	// This would integrate with PhonePe API
	return "phonepe_transaction_id", nil
}

func (ps *PaymentService) verifyPaymentWithGateway(ctx context.Context, payment *Payment, transactionID string) (bool, error) {
	// Verify payment with respective gateway
	switch payment.Gateway {
	case PaymentGatewayStripe:
		return ps.verifyStripePayment(ctx, payment, transactionID)
	case PaymentGatewayRazorpay:
		return ps.verifyRazorpayPayment(ctx, payment, transactionID)
	case PaymentGatewayPaytm:
		return ps.verifyPaytmPayment(ctx, payment, transactionID)
	case PaymentGatewayPhonePe:
		return ps.verifyPhonePePayment(ctx, payment, transactionID)
	default:
		return false, fmt.Errorf("unsupported payment gateway: %s", payment.Gateway)
	}
}

func (ps *PaymentService) verifyStripePayment(ctx context.Context, payment *Payment, transactionID string) (bool, error) {
	// Stripe verification logic
	return true, nil
}

func (ps *PaymentService) verifyRazorpayPayment(ctx context.Context, payment *Payment, transactionID string) (bool, error) {
	// Razorpay verification logic
	return true, nil
}

func (ps *PaymentService) verifyPaytmPayment(ctx context.Context, payment *Payment, transactionID string) (bool, error) {
	// Paytm verification logic
	return true, nil
}

func (ps *PaymentService) verifyPhonePePayment(ctx context.Context, payment *Payment, transactionID string) (bool, error) {
	// PhonePe verification logic
	return true, nil
}

func (ps *PaymentService) processStripeRefund(ctx context.Context, payment *Payment, amount float64, reason string) (string, error) {
	// Stripe refund logic
	return "stripe_refund_id", nil
}

func (ps *PaymentService) processRazorpayRefund(ctx context.Context, payment *Payment, amount float64, reason string) (string, error) {
	// Razorpay refund logic
	return "razorpay_refund_id", nil
}

func (ps *PaymentService) processPaytmRefund(ctx context.Context, payment *Payment, amount float64, reason string) (string, error) {
	// Paytm refund logic
	return "paytm_refund_id", nil
}

func (ps *PaymentService) processPhonePeRefund(ctx context.Context, payment *Payment, amount float64, reason string) (string, error) {
	// PhonePe refund logic
	return "phonepe_refund_id", nil
}

func (ps *PaymentService) savePaymentToDB(ctx context.Context, payment *Payment) error {
	// Save to database
	return nil
}

func (ps *PaymentService) updatePaymentInDB(ctx context.Context, payment *Payment) error {
	// Update in database
	return nil
}

func (ps *PaymentService) fetchPaymentFromDB(ctx context.Context, id uuid.UUID) (*Payment, error) {
	// Fetch from database
	return &Payment{}, nil
}

func (ps *PaymentService) fetchWalletFromDB(ctx context.Context, userID uuid.UUID) (*Wallet, error) {
	// Fetch from database
	return &Wallet{}, nil
}

func (ps *PaymentService) updateWalletInDB(ctx context.Context, wallet *Wallet) error {
	// Update in database
	return nil
}

func (ps *PaymentService) createWalletTransaction(ctx context.Context, transaction *WalletTransaction) error {
	// Create transaction in database
	return nil
}
