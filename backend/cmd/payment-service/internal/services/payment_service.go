package services

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/zomato-clone/payment-service/internal/models"
	"github.com/zomato-clone/payment-service/internal/repository"
)

type PaymentService interface {
	CreatePayment(userID uuid.UUID, req *models.CreatePaymentRequest) (*models.Payment, error)
	GetPayment(id uuid.UUID) (*models.Payment, error)
	GetPaymentByOrderID(orderID uuid.UUID) (*models.Payment, error)
	GetUserPayments(userID uuid.UUID) ([]*models.Payment, error)
	ProcessPayment(id uuid.UUID) error
	RefundPayment(id uuid.UUID, amount float64, reason string) error
}

type paymentService struct {
	paymentRepo repository.PaymentRepository
}

func NewPaymentService(paymentRepo repository.PaymentRepository) PaymentService {
	return &paymentService{
		paymentRepo: paymentRepo,
	}
}

func (s *paymentService) CreatePayment(userID uuid.UUID, req *models.CreatePaymentRequest) (*models.Payment, error) {
	// Check if payment already exists for this order
	existingPayment, _ := s.paymentRepo.FindByOrderID(req.OrderID)
	if existingPayment != nil {
		return nil, errors.New("payment already exists for this order")
	}

	payment := &models.Payment{
		OrderID:       req.OrderID,
		UserID:        userID,
		Amount:        req.Amount,
		PaymentMethod: req.PaymentMethod,
		Status:        "pending",
		Currency:      "INR",
	}

	if err := s.paymentRepo.Create(payment); err != nil {
		return nil, err
	}

	return payment, nil
}

func (s *paymentService) GetPayment(id uuid.UUID) (*models.Payment, error) {
	return s.paymentRepo.FindByID(id)
}

func (s *paymentService) GetPaymentByOrderID(orderID uuid.UUID) (*models.Payment, error) {
	return s.paymentRepo.FindByOrderID(orderID)
}

func (s *paymentService) GetUserPayments(userID uuid.UUID) ([]*models.Payment, error) {
	return s.paymentRepo.FindByUserID(userID)
}

func (s *paymentService) ProcessPayment(id uuid.UUID) error {
	payment, err := s.paymentRepo.FindByID(id)
	if err != nil {
		return err
	}

	// In a real implementation, this would integrate with Razorpay/Stripe
	// For now, we'll simulate successful payment
	now := time.Now()
	payment.Status = "completed"
	payment.TransactionID = generateTransactionID()
	payment.PaidAt = &now

	return s.paymentRepo.Update(payment)
}

func (s *paymentService) RefundPayment(id uuid.UUID, amount float64, reason string) error {
	payment, err := s.paymentRepo.FindByID(id)
	if err != nil {
		return err
	}

	if payment.Status != "completed" {
		return errors.New("can only refund completed payments")
	}

	if amount > payment.Amount {
		return errors.New("refund amount cannot exceed payment amount")
	}

	now := time.Now()
	payment.RefundAmount = &amount
	payment.RefundedAt = &now

	return s.paymentRepo.Update(payment)
}

func generateTransactionID() string {
	return "TXN-" + uuid.New().String()
}

type WalletService interface {
	GetWallet(userID uuid.UUID) (*models.Wallet, error)
	CreateWallet(userID uuid.UUID) (*models.Wallet, error)
	AddFunds(userID uuid.UUID, amount float64, description string) error
	WithdrawFunds(userID uuid.UUID, amount float64, description string) error
	GetTransactions(userID uuid.UUID) ([]*models.WalletTransaction, error)
}

type walletService struct {
	walletRepo       repository.WalletRepository
	transactionRepo  repository.WalletTransactionRepository
}

func NewWalletService(walletRepo repository.WalletRepository, transactionRepo repository.WalletTransactionRepository) WalletService {
	return &walletService{
		walletRepo:      walletRepo,
		transactionRepo: transactionRepo,
	}
}

func (s *walletService) GetWallet(userID uuid.UUID) (*models.Wallet, error) {
	wallet, err := s.walletRepo.FindByUserID(userID)
	if err != nil {
		// If wallet doesn't exist, create one
		return s.CreateWallet(userID)
	}
	return wallet, nil
}

func (s *walletService) CreateWallet(userID uuid.UUID) (*models.Wallet, error) {
	wallet := &models.Wallet{
		UserID:   userID,
		Balance:  0.00,
		Currency: "INR",
		IsActive: true,
	}

	if err := s.walletRepo.Create(wallet); err != nil {
		return nil, err
	}

	return wallet, nil
}

func (s *walletService) AddFunds(userID uuid.UUID, amount float64, description string) error {
	wallet, err := s.GetWallet(userID)
	if err != nil {
		return err
	}

	newBalance := wallet.Balance + amount
	if err := s.walletRepo.UpdateBalance(wallet.ID, newBalance); err != nil {
		return err
	}

	// Create transaction
	transaction := &models.WalletTransaction{
		WalletID:    wallet.ID,
		Type:        "credit",
		Amount:      amount,
		Balance:     newBalance,
		Description: description,
		ReferenceID: uuid.New().String(),
	}

	return s.transactionRepo.Create(transaction)
}

func (s *walletService) WithdrawFunds(userID uuid.UUID, amount float64, description string) error {
	wallet, err := s.GetWallet(userID)
	if err != nil {
		return err
	}

	if wallet.Balance < amount {
		return errors.New("insufficient balance")
	}

	newBalance := wallet.Balance - amount
	if err := s.walletRepo.UpdateBalance(wallet.ID, newBalance); err != nil {
		return err
	}

	// Create transaction
	transaction := &models.WalletTransaction{
		WalletID:    wallet.ID,
		Type:        "debit",
		Amount:      amount,
		Balance:     newBalance,
		Description: description,
		ReferenceID: uuid.New().String(),
	}

	return s.transactionRepo.Create(transaction)
}

func (s *walletService) GetTransactions(userID uuid.UUID) ([]*models.WalletTransaction, error) {
	wallet, err := s.GetWallet(userID)
	if err != nil {
		return nil, err
	}

	return s.transactionRepo.FindByWalletID(wallet.ID)
}
