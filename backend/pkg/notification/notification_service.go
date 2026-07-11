package notification

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

type NotificationChannel string

const (
	ChannelEmail    NotificationChannel = "email"
	ChannelSMS      NotificationChannel = "sms"
	ChannelPush     NotificationChannel = "push"
	ChannelInApp    NotificationChannel = "in_app"
	ChannelWhatsApp NotificationChannel = "whatsapp"
)

type NotificationType string

const (
	TypeOrderCreated   NotificationType = "order_created"
	TypeOrderConfirmed NotificationType = "order_confirmed"
	TypeOrderPreparing NotificationType = "order_preparing"
	TypeOrderReady     NotificationType = "order_ready"
	TypeOrderPickedUp  NotificationType = "order_picked_up"
	TypeOrderOnTheWay  NotificationType = "order_on_the_way"
	TypeOrderDelivered NotificationType = "order_delivered"
	TypeOrderCancelled NotificationType = "order_cancelled"
	TypePaymentSuccess NotificationType = "payment_success"
	TypePaymentFailed  NotificationType = "payment_failed"
	TypeRiderAssigned  NotificationType = "rider_assigned"
	TypeRiderArrived   NotificationType = "rider_arrived"
	TypePromoOffer     NotificationType = "promo_offer"
	TypeReviewRequest  NotificationType = "review_request"
)

type NotificationPriority string

const (
	PriorityLow    NotificationPriority = "low"
	PriorityMedium NotificationPriority = "medium"
	PriorityHigh   NotificationPriority = "high"
	PriorityUrgent NotificationPriority = "urgent"
)

type Notification struct {
	ID          uuid.UUID              `json:"id"`
	UserID      uuid.UUID              `json:"user_id"`
	Type        NotificationType       `json:"type"`
	Title       string                 `json:"title"`
	Body        string                 `json:"body"`
	Data        map[string]interface{} `json:"data"`
	Channels    []NotificationChannel  `json:"channels"`
	Priority    NotificationPriority   `json:"priority"`
	Read        bool                   `json:"read"`
	ReadAt      *time.Time             `json:"read_at,omitempty"`
	CreatedAt   time.Time              `json:"created_at"`
	SentAt      *time.Time             `json:"sent_at,omitempty"`
	DeliveredAt *time.Time             `json:"delivered_at,omitempty"`
	ExpiresAt   *time.Time             `json:"expires_at,omitempty"`
}

type NotificationTemplate struct {
	ID        uuid.UUID           `json:"id"`
	Type      NotificationType    `json:"type"`
	Channel   NotificationChannel `json:"channel"`
	Subject   string              `json:"subject"`
	Body      string              `json:"body"`
	Variables []string            `json:"variables"`
	IsActive  bool                `json:"is_active"`
	CreatedAt time.Time           `json:"created_at"`
	UpdatedAt time.Time           `json:"updated_at"`
}

type NotificationPreference struct {
	UserID          uuid.UUID `json:"user_id"`
	EmailEnabled    bool      `json:"email_enabled"`
	SMSEnabled      bool      `json:"sms_enabled"`
	PushEnabled     bool      `json:"push_enabled"`
	InAppEnabled    bool      `json:"in_app_enabled"`
	WhatsAppEnabled bool      `json:"whatsapp_enabled"`
	QuietHoursStart string    `json:"quiet_hours_start"`
	QuietHoursEnd   string    `json:"quiet_hours_end"`
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

type NotificationService struct {
	emailService    EmailService
	smsService      SMSService
	pushService     PushService
	templateService TemplateService
	cacheService    CacheService
}

type EmailService interface {
	SendEmail(ctx context.Context, to, subject, body string) error
	SendTemplateEmail(ctx context.Context, to, templateID string, data map[string]interface{}) error
}

type SMSService interface {
	SendSMS(ctx context.Context, to, message string) error
}

type PushService interface {
	SendPushNotification(ctx context.Context, userID uuid.UUID, title, body string, data map[string]interface{}) error
}

type TemplateService interface {
	GetTemplate(ctx context.Context, notificationType NotificationType, channel NotificationChannel) (*NotificationTemplate, error)
	RenderTemplate(template string, data map[string]interface{}) (string, error)
}

type CacheService interface {
	Get(ctx context.Context, key string) (string, error)
	Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error
	Delete(ctx context.Context, keys ...string) error
}

func NewNotificationService(emailService EmailService, smsService SMSService, pushService PushService, templateService TemplateService, cacheService CacheService) *NotificationService {
	return &NotificationService{
		emailService:    emailService,
		smsService:      smsService,
		pushService:     pushService,
		templateService: templateService,
		cacheService:    cacheService,
	}
}

func (ns *NotificationService) SendNotification(ctx context.Context, notification *Notification) error {
	// Get user notification preferences
	preferences, err := ns.getUserPreferences(ctx, notification.UserID)
	if err != nil {
		return fmt.Errorf("failed to get user preferences: %w", err)
	}

	// Check quiet hours
	if ns.isQuietHours(preferences) {
		notification.Channels = []NotificationChannel{ChannelInApp}
	}

	// Filter channels based on preferences
	enabledChannels := ns.filterEnabledChannels(notification.Channels, preferences)
	if len(enabledChannels) == 0 {
		return fmt.Errorf("no enabled channels for notification")
	}

	// Save notification to database
	if err := ns.saveNotificationToDB(ctx, notification); err != nil {
		return fmt.Errorf("failed to save notification: %w", err)
	}

	// Send notification through each enabled channel
	var sendErrors []error
	for _, channel := range enabledChannels {
		if err := ns.sendThroughChannel(ctx, notification, channel); err != nil {
			sendErrors = append(sendErrors, fmt.Errorf("channel %s failed: %w", channel, err))
		}
	}

	// Update notification status
	now := time.Now()
	notification.SentAt = &now
	if len(sendErrors) == 0 {
		notification.DeliveredAt = &now
	}
	if err := ns.updateNotificationInDB(ctx, notification); err != nil {
		return fmt.Errorf("failed to update notification: %w", err)
	}

	// Invalidate cache
	ns.cacheService.Delete(ctx, fmt.Sprintf("notifications:%s", notification.UserID.String()))

	if len(sendErrors) > 0 {
		return fmt.Errorf("notification sent with %d errors: %v", len(sendErrors), sendErrors)
	}

	return nil
}

func (ns *NotificationService) SendOrderNotification(ctx context.Context, userID, orderID uuid.UUID, notificationType NotificationType, orderData map[string]interface{}) error {
	// Get template for notification type and channel
	template, err := ns.templateService.GetTemplate(ctx, notificationType, ChannelPush)
	if err != nil {
		return fmt.Errorf("failed to get template: %w", err)
	}

	// Render template with order data
	body, err := ns.templateService.RenderTemplate(template.Body, orderData)
	if err != nil {
		return fmt.Errorf("failed to render template: %w", err)
	}

	// Create notification
	notification := &Notification{
		ID:        uuid.New(),
		UserID:    userID,
		Type:      notificationType,
		Title:     template.Subject,
		Body:      body,
		Data:      orderData,
		Channels:  []NotificationChannel{ChannelPush, ChannelInApp, ChannelEmail},
		Priority:  PriorityMedium,
		Read:      false,
		CreatedAt: time.Now(),
	}

	return ns.SendNotification(ctx, notification)
}

func (ns *NotificationService) SendPromoNotification(ctx context.Context, userID uuid.UUID, promoData map[string]interface{}) error {
	template, err := ns.templateService.GetTemplate(ctx, TypePromoOffer, ChannelPush)
	if err != nil {
		return fmt.Errorf("failed to get template: %w", err)
	}

	body, err := ns.templateService.RenderTemplate(template.Body, promoData)
	if err != nil {
		return fmt.Errorf("failed to render template: %w", err)
	}

	notification := &Notification{
		ID:        uuid.New(),
		UserID:    userID,
		Type:      TypePromoOffer,
		Title:     template.Subject,
		Body:      body,
		Data:      promoData,
		Channels:  []NotificationChannel{ChannelPush, ChannelInApp, ChannelEmail, ChannelSMS},
		Priority:  PriorityMedium,
		Read:      false,
		CreatedAt: time.Now(),
	}

	return ns.SendNotification(ctx, notification)
}

func (ns *NotificationService) GetUserNotifications(ctx context.Context, userID uuid.UUID, limit, offset int) ([]Notification, error) {
	cacheKey := fmt.Sprintf("notifications:%s:%d:%d", userID.String(), limit, offset)

	// Try cache first
	var cachedNotifications []Notification
	if _, err := ns.cacheService.Get(ctx, cacheKey); err == nil {
		return cachedNotifications, nil
	}

	// Fetch from database
	notifications, err := ns.fetchUserNotificationsFromDB(ctx, userID, limit, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch notifications: %w", err)
	}

	// Cache for 5 minutes
	ns.cacheService.Set(ctx, cacheKey, notifications, 5*time.Minute)

	return notifications, nil
}

func (ns *NotificationService) MarkAsRead(ctx context.Context, notificationID uuid.UUID) error {
	notification, err := ns.getNotificationByID(ctx, notificationID)
	if err != nil {
		return fmt.Errorf("failed to get notification: %w", err)
	}

	if notification.Read {
		return nil
	}

	now := time.Now()
	notification.Read = true
	notification.ReadAt = &now

	if err := ns.updateNotificationInDB(ctx, notification); err != nil {
		return fmt.Errorf("failed to update notification: %w", err)
	}

	// Invalidate cache
	ns.cacheService.Delete(ctx, fmt.Sprintf("notifications:%s", notification.UserID.String()))

	return nil
}

func (ns *NotificationService) MarkAllAsRead(ctx context.Context, userID uuid.UUID) error {
	if err := ns.markAllUserNotificationsAsRead(ctx, userID); err != nil {
		return fmt.Errorf("failed to mark all as read: %w", err)
	}

	// Invalidate cache
	ns.cacheService.Delete(ctx, fmt.Sprintf("notifications:%s:*", userID.String()))

	return nil
}

func (ns *NotificationService) UpdateNotificationPreferences(ctx context.Context, userID uuid.UUID, preferences *NotificationPreference) error {
	preferences.UserID = userID
	preferences.UpdatedAt = time.Now()

	if err := ns.saveNotificationPreferences(ctx, preferences); err != nil {
		return fmt.Errorf("failed to save preferences: %w", err)
	}

	// Invalidate cache
	ns.cacheService.Delete(ctx, fmt.Sprintf("preferences:%s", userID.String()))

	return nil
}

func (ns *NotificationService) sendThroughChannel(ctx context.Context, notification *Notification, channel NotificationChannel) error {
	switch channel {
	case ChannelEmail:
		return ns.sendEmailNotification(ctx, notification)
	case ChannelSMS:
		return ns.sendSMSNotification(ctx, notification)
	case ChannelPush:
		return ns.sendPushNotification(ctx, notification)
	case ChannelInApp:
		return ns.sendInAppNotification(ctx, notification)
	case ChannelWhatsApp:
		return ns.sendWhatsAppNotification(ctx, notification)
	default:
		return fmt.Errorf("unsupported channel: %s", channel)
	}
}

func (ns *NotificationService) sendEmailNotification(ctx context.Context, notification *Notification) error {
	// Get user email
	email, err := ns.getUserEmail(ctx, notification.UserID)
	if err != nil {
		return fmt.Errorf("failed to get user email: %w", err)
	}

	// Try to use template
	template, err := ns.templateService.GetTemplate(ctx, notification.Type, ChannelEmail)
	if err == nil {
		_, err := ns.templateService.RenderTemplate(template.Body, notification.Data)
		if err != nil {
			return fmt.Errorf("failed to render template: %w", err)
		}
		return ns.emailService.SendTemplateEmail(ctx, email, template.ID.String(), notification.Data)
	}

	// Fallback to direct email
	return ns.emailService.SendEmail(ctx, email, notification.Title, notification.Body)
}

func (ns *NotificationService) sendSMSNotification(ctx context.Context, notification *Notification) error {
	// Get user phone
	phone, err := ns.getUserPhone(ctx, notification.UserID)
	if err != nil {
		return fmt.Errorf("failed to get user phone: %w", err)
	}

	return ns.smsService.SendSMS(ctx, phone, notification.Body)
}

func (ns *NotificationService) sendPushNotification(ctx context.Context, notification *Notification) error {
	return ns.pushService.SendPushNotification(ctx, notification.UserID, notification.Title, notification.Body, notification.Data)
}

func (ns *NotificationService) sendInAppNotification(ctx context.Context, notification *Notification) error {
	// In-app notifications are stored in database and retrieved by the client
	// This is handled by the saveNotificationToDB method
	return nil
}

func (ns *NotificationService) sendWhatsAppNotification(ctx context.Context, notification *Notification) error {
	// WhatsApp notification logic
	// This would integrate with WhatsApp Business API
	return nil
}

func (ns *NotificationService) getUserPreferences(ctx context.Context, userID uuid.UUID) (*NotificationPreference, error) {
	cacheKey := fmt.Sprintf("preferences:%s", userID.String())

	// Try cache first
	var cachedPreferences NotificationPreference
	if _, err := ns.cacheService.Get(ctx, cacheKey); err == nil {
		return &cachedPreferences, nil
	}

	// Fetch from database
	preferences, err := ns.fetchUserPreferencesFromDB(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch preferences: %w", err)
	}

	// Cache for 1 hour
	ns.cacheService.Set(ctx, cacheKey, preferences, 1*time.Hour)

	return preferences, nil
}

func (ns *NotificationService) filterEnabledChannels(channels []NotificationChannel, preferences *NotificationPreference) []NotificationChannel {
	var enabledChannels []NotificationChannel

	for _, channel := range channels {
		switch channel {
		case ChannelEmail:
			if preferences.EmailEnabled {
				enabledChannels = append(enabledChannels, channel)
			}
		case ChannelSMS:
			if preferences.SMSEnabled {
				enabledChannels = append(enabledChannels, channel)
			}
		case ChannelPush:
			if preferences.PushEnabled {
				enabledChannels = append(enabledChannels, channel)
			}
		case ChannelInApp:
			if preferences.InAppEnabled {
				enabledChannels = append(enabledChannels, channel)
			}
		case ChannelWhatsApp:
			if preferences.WhatsAppEnabled {
				enabledChannels = append(enabledChannels, channel)
			}
		}
	}

	return enabledChannels
}

func (ns *NotificationService) isQuietHours(preferences *NotificationPreference) bool {
	if preferences.QuietHoursStart == "" || preferences.QuietHoursEnd == "" {
		return false
	}

	now := time.Now()
	currentTime := now.Format("15:04")

	if preferences.QuietHoursStart < preferences.QuietHoursEnd {
		return currentTime >= preferences.QuietHoursStart && currentTime <= preferences.QuietHoursEnd
	}

	// Handle overnight quiet hours (e.g., 22:00 to 06:00)
	return currentTime >= preferences.QuietHoursStart || currentTime <= preferences.QuietHoursEnd
}

func (ns *NotificationService) saveNotificationToDB(ctx context.Context, notification *Notification) error {
	// Save to database
	return nil
}

func (ns *NotificationService) updateNotificationInDB(ctx context.Context, notification *Notification) error {
	// Update in database
	return nil
}

func (ns *NotificationService) getNotificationByID(ctx context.Context, id uuid.UUID) (*Notification, error) {
	// Fetch from database
	return &Notification{}, nil
}

func (ns *NotificationService) fetchUserNotificationsFromDB(ctx context.Context, userID uuid.UUID, limit, offset int) ([]Notification, error) {
	// Fetch from database
	return []Notification{}, nil
}

func (ns *NotificationService) markAllUserNotificationsAsRead(ctx context.Context, userID uuid.UUID) error {
	// Update in database
	return nil
}

func (ns *NotificationService) saveNotificationPreferences(ctx context.Context, preferences *NotificationPreference) error {
	// Save to database
	return nil
}

func (ns *NotificationService) fetchUserPreferencesFromDB(ctx context.Context, userID uuid.UUID) (*NotificationPreference, error) {
	// Fetch from database
	return &NotificationPreference{}, nil
}

func (ns *NotificationService) getUserEmail(ctx context.Context, userID uuid.UUID) (string, error) {
	// Fetch user email from database
	return "", nil
}

func (ns *NotificationService) getUserPhone(ctx context.Context, userID uuid.UUID) (string, error) {
	// Fetch user phone from database
	return "", nil
}
