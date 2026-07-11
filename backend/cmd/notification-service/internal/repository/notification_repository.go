package repository

import (
	"github.com/google/uuid"
	"github.com/zomato-clone/notification-service/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type NotificationRepository interface {
	Create(notification *models.Notification) error
	FindByID(id uuid.UUID) (*models.Notification, error)
	FindByUserID(userID uuid.UUID) ([]*models.Notification, error)
	MarkAsRead(id uuid.UUID) error
	MarkAllAsRead(userID uuid.UUID) error
	Delete(id uuid.UUID) error
}

type notificationRepository struct {
	db *gorm.DB
}

func NewNotificationRepository(db *gorm.DB) NotificationRepository {
	return &notificationRepository{db: db}
}

func (r *notificationRepository) Create(notification *models.Notification) error {
	return r.db.Create(notification).Error
}

func (r *notificationRepository) FindByID(id uuid.UUID) (*models.Notification, error) {
	var notification models.Notification
	err := r.db.Where("id = ?", id).First(&notification).Error
	if err != nil {
		return nil, err
	}
	return &notification, nil
}

func (r *notificationRepository) FindByUserID(userID uuid.UUID) ([]*models.Notification, error) {
	var notifications []*models.Notification
	err := r.db.Where("user_id = ?", userID).Order("created_at DESC").Find(&notifications).Error
	if err != nil {
		return nil, err
	}
	return notifications, nil
}

func (r *notificationRepository) MarkAsRead(id uuid.UUID) error {
	return r.db.Model(&models.Notification{}).Where("id = ?", id).Update("is_read", true).Error
}

func (r *notificationRepository) MarkAllAsRead(userID uuid.UUID) error {
	return r.db.Model(&models.Notification{}).Where("user_id = ?", userID).Update("is_read", true).Error
}

func (r *notificationRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.Notification{}, "id = ?", id).Error
}

type NotificationPreferenceRepository interface {
	Create(preference *models.NotificationPreference) error
	FindByUserID(userID uuid.UUID) (*models.NotificationPreference, error)
	Update(preference *models.NotificationPreference) error
}

type notificationPreferenceRepository struct {
	db *gorm.DB
}

func NewNotificationPreferenceRepository(db *gorm.DB) NotificationPreferenceRepository {
	return &notificationPreferenceRepository{db: db}
}

func (r *notificationPreferenceRepository) Create(preference *models.NotificationPreference) error {
	return r.db.Create(preference).Error
}

func (r *notificationPreferenceRepository) FindByUserID(userID uuid.UUID) (*models.NotificationPreference, error) {
	var preference models.NotificationPreference
	err := r.db.Where("user_id = ?", userID).First(&preference).Error
	if err != nil {
		return nil, err
	}
	return &preference, nil
}

func (r *notificationPreferenceRepository) Update(preference *models.NotificationPreference) error {
	return r.db.Save(preference).Error
}

func InitDB(databaseURL string) (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(databaseURL), &gorm.Config{})
	if err != nil {
		return nil, err
	}

	// Auto migrate tables
	err = db.AutoMigrate(
		&models.Notification{},
		&models.NotificationPreference{},
	)
	if err != nil {
		return nil, err
	}

	return db, nil
}
