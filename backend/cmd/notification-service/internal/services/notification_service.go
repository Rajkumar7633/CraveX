package services

import (
	"github.com/google/uuid"
	"github.com/zomato-clone/notification-service/internal/models"
	"github.com/zomato-clone/notification-service/internal/repository"
)

type NotificationService interface {
	SendNotification(userID uuid.UUID, title, body, notificationType, data string) (*models.Notification, error)
	SendBulkNotification(userIDs []uuid.UUID, title, body, notificationType, data string) ([]*models.Notification, error)
	GetNotification(id uuid.UUID) (*models.Notification, error)
	GetUserNotifications(userID uuid.UUID) ([]*models.Notification, error)
	MarkAsRead(id uuid.UUID) error
	MarkAllAsRead(userID uuid.UUID) error
	DeleteNotification(id uuid.UUID) error
}

type notificationService struct {
	notificationRepo repository.NotificationRepository
}

func NewNotificationService(notificationRepo repository.NotificationRepository) NotificationService {
	return &notificationService{
		notificationRepo: notificationRepo,
	}
}

func (s *notificationService) SendNotification(userID uuid.UUID, title, body, notificationType, data string) (*models.Notification, error) {
	notification := &models.Notification{
		UserID: userID,
		Title:  title,
		Body:   body,
		Type:   notificationType,
		Data:   data,
		IsRead: false,
	}

	if err := s.notificationRepo.Create(notification); err != nil {
		return nil, err
	}

	// In a real implementation, this would send push notification via FCM
	// and/or send SMS/email based on user preferences

	return notification, nil
}

func (s *notificationService) SendBulkNotification(userIDs []uuid.UUID, title, body, notificationType, data string) ([]*models.Notification, error) {
	var notifications []*models.Notification

	for _, userID := range userIDs {
		notification := &models.Notification{
			UserID: userID,
			Title:  title,
			Body:   body,
			Type:   notificationType,
			Data:   data,
			IsRead: false,
		}

		if err := s.notificationRepo.Create(notification); err != nil {
			return nil, err
		}

		notifications = append(notifications, notification)
	}

	return notifications, nil
}

func (s *notificationService) GetNotification(id uuid.UUID) (*models.Notification, error) {
	return s.notificationRepo.FindByID(id)
}

func (s *notificationService) GetUserNotifications(userID uuid.UUID) ([]*models.Notification, error) {
	return s.notificationRepo.FindByUserID(userID)
}

func (s *notificationService) MarkAsRead(id uuid.UUID) error {
	return s.notificationRepo.MarkAsRead(id)
}

func (s *notificationService) MarkAllAsRead(userID uuid.UUID) error {
	return s.notificationRepo.MarkAllAsRead(userID)
}

func (s *notificationService) DeleteNotification(id uuid.UUID) error {
	return s.notificationRepo.Delete(id)
}

type NotificationPreferenceService interface {
	GetPreferences(userID uuid.UUID) (*models.NotificationPreference, error)
	UpdatePreferences(userID uuid.UUID, req *models.UpdatePreferencesRequest) (*models.NotificationPreference, error)
}

type notificationPreferenceService struct {
	preferenceRepo repository.NotificationPreferenceRepository
}

func NewNotificationPreferenceService(preferenceRepo repository.NotificationPreferenceRepository) NotificationPreferenceService {
	return &notificationPreferenceService{
		preferenceRepo: preferenceRepo,
	}
}

func (s *notificationPreferenceService) GetPreferences(userID uuid.UUID) (*models.NotificationPreference, error) {
	preference, err := s.preferenceRepo.FindByUserID(userID)
	if err != nil {
		// If preferences don't exist, create default ones
		return s.CreateDefaultPreferences(userID)
	}
	return preference, nil
}

func (s *notificationPreferenceService) CreateDefaultPreferences(userID uuid.UUID) (*models.NotificationPreference, error) {
	preference := &models.NotificationPreference{
		UserID:       userID,
		PushEnabled:  true,
		EmailEnabled: true,
		SMSEnabled:   false,
		OrderUpdates: true,
		Promotions:   true,
		Offers:       true,
	}

	if err := s.preferenceRepo.Create(preference); err != nil {
		return nil, err
	}

	return preference, nil
}

func (s *notificationPreferenceService) UpdatePreferences(userID uuid.UUID, req *models.UpdatePreferencesRequest) (*models.NotificationPreference, error) {
	preference, err := s.GetPreferences(userID)
	if err != nil {
		return nil, err
	}

	if req.PushEnabled != nil {
		preference.PushEnabled = *req.PushEnabled
	}
	if req.EmailEnabled != nil {
		preference.EmailEnabled = *req.EmailEnabled
	}
	if req.SMSEnabled != nil {
		preference.SMSEnabled = *req.SMSEnabled
	}
	if req.OrderUpdates != nil {
		preference.OrderUpdates = *req.OrderUpdates
	}
	if req.Promotions != nil {
		preference.Promotions = *req.Promotions
	}
	if req.Offers != nil {
		preference.Offers = *req.Offers
	}

	if err := s.preferenceRepo.Update(preference); err != nil {
		return nil, err
	}

	return preference, nil
}
