package repository

import (
	"github.com/google/uuid"
	"github.com/zomato-clone/payment-service/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type PaymentRepository interface {
	Create(payment *models.Payment) error
	FindByID(id uuid.UUID) (*models.Payment, error)
	FindByOrderID(orderID uuid.UUID) (*models.Payment, error)
	FindByUserID(userID uuid.UUID) ([]*models.Payment, error)
	Update(payment *models.Payment) error
	UpdateStatus(id uuid.UUID, status string) error
}

type paymentRepository struct {
	db *gorm.DB
}

func NewPaymentRepository(db *gorm.DB) PaymentRepository {
	return &paymentRepository{db: db}
}

func (r *paymentRepository) Create(payment *models.Payment) error {
	return r.db.Create(payment).Error
}

func (r *paymentRepository) FindByID(id uuid.UUID) (*models.Payment, error) {
	var payment models.Payment
	err := r.db.Where("id = ?", id).First(&payment).Error
	if err != nil {
		return nil, err
	}
	return &payment, nil
}

func (r *paymentRepository) FindByOrderID(orderID uuid.UUID) (*models.Payment, error) {
	var payment models.Payment
	err := r.db.Where("order_id = ?", orderID).First(&payment).Error
	if err != nil {
		return nil, err
	}
	return &payment, nil
}

func (r *paymentRepository) FindByUserID(userID uuid.UUID) ([]*models.Payment, error) {
	var payments []*models.Payment
	err := r.db.Where("user_id = ?", userID).Order("created_at DESC").Find(&payments).Error
	if err != nil {
		return nil, err
	}
	return payments, nil
}

func (r *paymentRepository) Update(payment *models.Payment) error {
	return r.db.Save(payment).Error
}

func (r *paymentRepository) UpdateStatus(id uuid.UUID, status string) error {
	return r.db.Model(&models.Payment{}).Where("id = ?", id).Update("status", status).Error
}

type WalletRepository interface {
	Create(wallet *models.Wallet) error
	FindByUserID(userID uuid.UUID) (*models.Wallet, error)
	Update(wallet *models.Wallet) error
	UpdateBalance(walletID uuid.UUID, newBalance float64) error
}

type walletRepository struct {
	db *gorm.DB
}

func NewWalletRepository(db *gorm.DB) WalletRepository {
	return &walletRepository{db: db}
}

func (r *walletRepository) Create(wallet *models.Wallet) error {
	return r.db.Create(wallet).Error
}

func (r *walletRepository) FindByUserID(userID uuid.UUID) (*models.Wallet, error) {
	var wallet models.Wallet
	err := r.db.Where("user_id = ?", userID).First(&wallet).Error
	if err != nil {
		return nil, err
	}
	return &wallet, nil
}

func (r *walletRepository) Update(wallet *models.Wallet) error {
	return r.db.Save(wallet).Error
}

func (r *walletRepository) UpdateBalance(walletID uuid.UUID, newBalance float64) error {
	return r.db.Model(&models.Wallet{}).Where("id = ?", walletID).Update("balance", newBalance).Error
}

type WalletTransactionRepository interface {
	Create(transaction *models.WalletTransaction) error
	FindByWalletID(walletID uuid.UUID) ([]*models.WalletTransaction, error)
}

type walletTransactionRepository struct {
	db *gorm.DB
}

func NewWalletTransactionRepository(db *gorm.DB) WalletTransactionRepository {
	return &walletTransactionRepository{db: db}
}

func (r *walletTransactionRepository) Create(transaction *models.WalletTransaction) error {
	return r.db.Create(transaction).Error
}

func (r *walletTransactionRepository) FindByWalletID(walletID uuid.UUID) ([]*models.WalletTransaction, error) {
	var transactions []*models.WalletTransaction
	err := r.db.Where("wallet_id = ?", walletID).Order("created_at DESC").Find(&transactions).Error
	if err != nil {
		return nil, err
	}
	return transactions, nil
}

func InitDB(databaseURL string) (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(databaseURL), &gorm.Config{})
	if err != nil {
		return nil, err
	}

	// Auto migrate tables
	err = db.AutoMigrate(
		&models.Payment{},
		&models.Wallet{},
		&models.WalletTransaction{},
	)
	if err != nil {
		return nil, err
	}

	return db, nil
}
