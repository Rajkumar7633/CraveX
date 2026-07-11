package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type User struct {
	ID             uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	PhoneNumber    string    `json:"phone_number" gorm:"uniqueIndex;not null"`
	Email          string    `json:"email" gorm:"uniqueIndex"`
	PasswordHash   string    `json:"-"`
	FirstName      string    `json:"first_name" gorm:"not null"`
	LastName       string    `json:"last_name"`
	ProfilePhotoURL string   `json:"profile_photo_url"`
	DateOfBirth    time.Time `json:"date_of_birth"`
	Gender         string    `json:"gender"`
	UserType       string    `json:"user_type" gorm:"default:'customer'"`
	IsActive       bool      `json:"is_active" gorm:"default:true"`
	IsVerified     bool      `json:"is_verified" gorm:"default:false"`
	ReferralCode   string    `json:"referral_code" gorm:"uniqueIndex"`
	ReferredBy     string    `json:"referred_by"`
	CreatedAt      time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt      time.Time `json:"updated_at" gorm:"autoUpdateTime"`
	LastLoginAt    time.Time `json:"last_login_at"`
	FCMToken       string    `json:"fcm_token"`
	Language       string    `json:"language" gorm:"default:'en'"`
	Theme          string    `json:"theme" gorm:"default:'light'"`
}

type RefreshToken struct {
	ID        uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	UserID    uuid.UUID `json:"user_id" gorm:"not null;index"`
	Token     string    `json:"token" gorm:"not null;uniqueIndex"`
	ExpiresAt time.Time `json:"expires_at" gorm:"not null"`
	CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`
	User      User      `json:"user" gorm:"foreignKey:UserID"`
}

type OTP struct {
	ID        uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	PhoneNumber string  `json:"phone_number" gorm:"not null;index"`
	Code      string   `json:"code" gorm:"not null"`
	ExpiresAt time.Time `json:"expires_at" gorm:"not null"`
	IsUsed    bool     `json:"is_used" gorm:"default:false"`
	CreatedAt time.Time `json:"created_at" gorm:"autoCreateTime"`
}

type SocialLoginRequest struct {
	Provider   string `json:"provider" binding:"required"`
	ProviderID string `json:"provider_id" binding:"required"`
	Email      string `json:"email"`
	Name       string `json:"name"`
	PhotoURL   string `json:"photo_url"`
}

type RegisterRequest struct {
	PhoneNumber string `json:"phone_number" binding:"required"`
	Email       string `json:"email"`
	Password    string `json:"password" binding:"required,min=8"`
	FirstName   string `json:"first_name" binding:"required"`
	LastName    string `json:"last_name"`
	ReferralCode string `json:"referral_code"`
}

type LoginRequest struct {
	PhoneNumber string `json:"phone_number" binding:"required"`
	Password    string `json:"password" binding:"required"`
}

type OTPRequest struct {
	PhoneNumber string `json:"phone_number" binding:"required"`
}

type VerifyOTPRequest struct {
	PhoneNumber string `json:"phone_number" binding:"required"`
	Code        string `json:"code" binding:"required,len=6"`
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token" binding:"required"`
}

type ChangePasswordRequest struct {
	OldPassword string `json:"old_password" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=8"`
}

type ForgotPasswordRequest struct {
	Email string `json:"email" binding:"required,email"`
}

type ResetPasswordRequest struct {
	Token       string `json:"token" binding:"required"`
	NewPassword string `json:"new_password" binding:"required,min=8"`
}

type AuthResponse struct {
	Token        string `json:"token"`
	RefreshToken string `json:"refresh_token"`
	User         User   `json:"user"`
}

// BeforeCreate hook for User
func (u *User) BeforeCreate(tx *gorm.DB) error {
	if u.ID == uuid.Nil {
		u.ID = uuid.New()
	}
	return nil
}
