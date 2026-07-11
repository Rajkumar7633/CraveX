package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/zomato-clone/auth-service/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type UserRepository interface {
	Create(user *models.User) error
	FindByID(id uuid.UUID) (*models.User, error)
	FindByPhoneNumber(phoneNumber string) (*models.User, error)
	FindByEmail(email string) (*models.User, error)
	Update(user *models.User) error
	Delete(id uuid.UUID) error
	UpdateLastLogin(id uuid.UUID) error
	FindByReferralCode(code string) (*models.User, error)
}

type userRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) UserRepository {
	return &userRepository{db: db}
}

func (r *userRepository) Create(user *models.User) error {
	return r.db.Create(user).Error
}

func (r *userRepository) FindByID(id uuid.UUID) (*models.User, error) {
	var user models.User
	err := r.db.Where("id = ?", id).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) FindByPhoneNumber(phoneNumber string) (*models.User, error) {
	var user models.User
	err := r.db.Where("phone_number = ?", phoneNumber).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) FindByEmail(email string) (*models.User, error) {
	var user models.User
	err := r.db.Where("email = ?", email).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

func (r *userRepository) Update(user *models.User) error {
	return r.db.Save(user).Error
}

func (r *userRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.User{}, "id = ?", id).Error
}

func (r *userRepository) UpdateLastLogin(id uuid.UUID) error {
	return r.db.Model(&models.User{}).Where("id = ?", id).Update("last_login_at", time.Now()).Error
}

func (r *userRepository) FindByReferralCode(code string) (*models.User, error) {
	var user models.User
	err := r.db.Where("referral_code = ?", code).First(&user).Error
	if err != nil {
		return nil, err
	}
	return &user, nil
}

type RefreshTokenRepository interface {
	Create(token *models.RefreshToken) error
	FindByToken(token string) (*models.RefreshToken, error)
	FindByUserID(userID uuid.UUID) ([]*models.RefreshToken, error)
	Delete(token string) error
	DeleteByUserID(userID uuid.UUID) error
	DeleteExpiredTokens() error
}

type refreshTokenRepository struct {
	db *gorm.DB
}

func NewRefreshTokenRepository(db *gorm.DB) RefreshTokenRepository {
	return &refreshTokenRepository{db: db}
}

func (r *refreshTokenRepository) Create(token *models.RefreshToken) error {
	return r.db.Create(token).Error
}

func (r *refreshTokenRepository) FindByToken(token string) (*models.RefreshToken, error) {
	var refreshToken models.RefreshToken
	err := r.db.Where("token = ?", token).Preload("User").First(&refreshToken).Error
	if err != nil {
		return nil, err
	}
	return &refreshToken, nil
}

func (r *refreshTokenRepository) FindByUserID(userID uuid.UUID) ([]*models.RefreshToken, error) {
	var tokens []*models.RefreshToken
	err := r.db.Where("user_id = ?", userID).Find(&tokens).Error
	if err != nil {
		return nil, err
	}
	return tokens, nil
}

func (r *refreshTokenRepository) Delete(token string) error {
	return r.db.Where("token = ?", token).Delete(&models.RefreshToken{}).Error
}

func (r *refreshTokenRepository) DeleteByUserID(userID uuid.UUID) error {
	return r.db.Where("user_id = ?", userID).Delete(&models.RefreshToken{}).Error
}

func (r *refreshTokenRepository) DeleteExpiredTokens() error {
	return r.db.Where("expires_at < ?", time.Now()).Delete(&models.RefreshToken{}).Error
}

type OTPRepository interface {
	Create(otp *models.OTP) error
	FindByPhoneNumber(phoneNumber string) (*models.OTP, error)
	MarkAsUsed(id uuid.UUID) error
	DeleteExpiredTokens() error
}

type otpRepository struct {
	db *gorm.DB
}

func NewOTPRepository(db *gorm.DB) OTPRepository {
	return &otpRepository{db: db}
}

func (r *otpRepository) Create(otp *models.OTP) error {
	return r.db.Create(otp).Error
}

func (r *otpRepository) FindByPhoneNumber(phoneNumber string) (*models.OTP, error) {
	var otp models.OTP
	err := r.db.Where("phone_number = ? AND is_used = false AND expires_at > ?", phoneNumber, time.Now()).Order("created_at DESC").First(&otp).Error
	if err != nil {
		return nil, err
	}
	return &otp, nil
}

func (r *otpRepository) MarkAsUsed(id uuid.UUID) error {
	return r.db.Model(&models.OTP{}).Where("id = ?", id).Update("is_used", true).Error
}

func (r *otpRepository) DeleteExpiredTokens() error {
	return r.db.Where("expires_at < ?", time.Now()).Delete(&models.OTP{}).Error
}

func InitDB(databaseURL string) (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(databaseURL), &gorm.Config{})
	if err != nil {
		return nil, err
	}

	// Auto migrate tables
	err = db.AutoMigrate(
		&models.User{},
		&models.RefreshToken{},
		&models.OTP{},
	)
	if err != nil {
		return nil, err
	}

	return db, nil
}
