package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Rider struct {
	ID                uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	UserID            uuid.UUID  `json:"user_id" gorm:"not null;index"`
	VehicleType       string    `json:"vehicle_type" gorm:"not null"`
	VehicleNumber     string    `json:"vehicle_number" gorm:"not null"`
	VehicleModel      string    `json:"vehicle_model"`
	LicenseNumber     string    `json:"license_number"`
	CurrentLatitude   *float64  `json:"current_latitude"`
	CurrentLongitude  *float64  `json:"current_longitude"`
	LastLocationUpdate *time.Time `json:"last_location_update"`
	IsOnline          bool      `json:"is_online" gorm:"default:false"`
	IsAvailable       bool      `json:"is_available" gorm:"default:true"`
	Rating            float64   `json:"rating" gorm:"default:0.00"`
	TotalDeliveries   int       `json:"total_deliveries" gorm:"default:0"`
	TotalEarnings     float64   `json:"total_earnings" gorm:"default:0.00"`
	ZoneID            string    `json:"zone_id"`
	IsVerified        bool      `json:"is_verified" gorm:"default:false"`
	IsActive          bool      `json:"is_active" gorm:"default:true"`
	CreatedAt         time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt         time.Time `json:"updated_at" gorm:"autoUpdateTime"`
}

type RiderDocument struct {
	ID              uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	RiderID         uuid.UUID  `json:"rider_id" gorm:"not null;index"`
	DocumentType    string     `json:"document_type" gorm:"not null"`
	DocumentURL     string     `json:"document_url" gorm:"not null"`
	ExpiryDate      *time.Time `json:"expiry_date"`
	Status          string     `json:"status" gorm:"default:'pending'"`
	RejectionReason string     `json:"rejection_reason"`
	VerifiedAt      *time.Time `json:"verified_at"`
	VerifiedBy      *uuid.UUID `json:"verified_by"`
	CreatedAt       time.Time  `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt       time.Time  `json:"updated_at" gorm:"autoUpdateTime"`
}

type RiderEarning struct {
	ID           uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	RiderID      uuid.UUID  `json:"rider_id" gorm:"not null;index"`
	OrderID      uuid.UUID  `json:"order_id" gorm:"not null;index"`
	DeliveryFee  float64    `json:"delivery_fee" gorm:"not null"`
	TipAmount    float64    `json:"tip_amount" gorm:"default:0.00"`
	BonusAmount  float64    `json:"bonus_amount" gorm:"default:0.00"`
	TotalEarned  float64    `json:"total_earned" gorm:"not null"`
	EarnedAt     time.Time  `json:"earned_at" gorm:"autoCreateTime"`
}

type CreateRiderRequest struct {
	VehicleType   string `json:"vehicle_type" binding:"required"`
	VehicleNumber string `json:"vehicle_number" binding:"required"`
	VehicleModel  string `json:"vehicle_model"`
	LicenseNumber string `json:"license_number"`
	ZoneID        string `json:"zone_id"`
}

type UpdateRiderRequest struct {
	VehicleType       *string   `json:"vehicle_type"`
	VehicleNumber     *string   `json:"vehicle_number"`
	VehicleModel      *string   `json:"vehicle_model"`
	LicenseNumber     *string   `json:"license_number"`
	CurrentLatitude  *float64  `json:"current_latitude"`
	CurrentLongitude *float64  `json:"current_longitude"`
	IsOnline          *bool     `json:"is_online"`
	IsAvailable       *bool     `json:"is_available"`
	ZoneID            *string   `json:"zone_id"`
}

type UpdateLocationRequest struct {
	Latitude  float64 `json:"latitude" binding:"required"`
	Longitude float64 `json:"longitude" binding:"required"`
}

type ToggleOnlineRequest struct {
	IsOnline bool `json:"is_online" binding:"required"`
}

// BeforeCreate hook for Rider
func (r *Rider) BeforeCreate(tx *gorm.DB) error {
	if r.ID == uuid.Nil {
		r.ID = uuid.New()
	}
	return nil
}

// BeforeCreate hook for RiderDocument
func (rd *RiderDocument) BeforeCreate(tx *gorm.DB) error {
	if rd.ID == uuid.Nil {
		rd.ID = uuid.New()
	}
	return nil
}

// BeforeCreate hook for RiderEarning
func (re *RiderEarning) BeforeCreate(tx *gorm.DB) error {
	if re.ID == uuid.Nil {
		re.ID = uuid.New()
	}
	return nil
}
