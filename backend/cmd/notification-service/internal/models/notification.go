package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Notification struct {
	ID          uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	UserID      uuid.UUID  `json:"user_id" gorm:"not null;index"`
	Title       string     `json:"title" gorm:"not null"`
	Body        string     `json:"body" gorm:"not null"`
	Type        string     `json:"type" gorm:"not null"` // order, payment, promotion, system
	Data        string     `json:"data" gorm:"type:jsonb"`
	IsRead      bool       `json:"is_read" gorm:"default:false"`
	ReadAt      *time.Time `json:"read_at"`
	CreatedAt   time.Time  `json:"created_at" gorm:"autoCreateTime"`
}

type NotificationPreference struct {
	ID              uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	UserID          uuid.UUID `json:"user_id" gorm:"uniqueIndex;not null"`
	PushEnabled     bool      `json:"push_enabled" gorm:"default:true"`
	EmailEnabled    bool      `json:"email_enabled" gorm:"default:true"`
	SMSEnabled      bool      `json:"sms_enabled" gorm:"default:false"`
	OrderUpdates    bool      `json:"order_updates" gorm:"default:true"`
	Promotions      bool      `json:"promotions" gorm:"default:true"`
	Offers          bool      `json:"offers" gorm:"default:true"`
	CreatedAt       time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt       time.Time `json:"updated_at" gorm:"autoUpdateTime"`
}

type SendNotificationRequest struct {
	UserID  uuid.UUID `json:"user_id" binding:"required"`
	Title   string    `json:"title" binding:"required"`
	Body    string    `json:"body" binding:"required"`
	Type    string    `json:"type" binding:"required"`
	Data    string    `json:"data"`
}

type SendBulkNotificationRequest struct {
	UserIDs []uuid.UUID `json:"user_ids" binding:"required"`
	Title   string      `json:"title" binding:"required"`
	Body    string      `json:"body" binding:"required"`
	Type    string      `json:"type" binding:"required"`
	Data    string      `json:"data"`
}

type UpdatePreferencesRequest struct {
	PushEnabled  *bool `json:"push_enabled"`
	EmailEnabled *bool `json:"email_enabled"`
	SMSEnabled   *bool `json:"sms_enabled"`
	OrderUpdates *bool `json:"order_updates"`
	Promotions   *bool `json:"promotions"`
	Offers       *bool `json:"offers"`
}

// BeforeCreate hook for Notification
func (n *Notification) BeforeCreate(tx *gorm.DB) error {
	if n.ID == uuid.Nil {
		n.ID = uuid.New()
	}
	return nil
}

// BeforeCreate hook for NotificationPreference
func (np *NotificationPreference) BeforeCreate(tx *gorm.DB) error {
	if np.ID == uuid.Nil {
		np.ID = uuid.New()
	}
	return nil
}
