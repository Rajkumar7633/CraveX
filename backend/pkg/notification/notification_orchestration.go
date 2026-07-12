package notification

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// NotificationOrchestrator implements the notification orchestration layer from the spec:
// single service decides channel (push/SMS/email/in-app) based on:
// user's notification preference, delivery criticality (order status = push+SMS fallback if push fails, marketing = push only),
// and rate-limiting (don't spam)
type NotificationOrchestrator struct {
	preferenceRepo NotificationPreferenceRepository
	pushService    PushNotificationService
	smsService     OrchestratorSMSService
	emailService   OrchestratorEmailService
	inAppService   InAppNotificationService
	rateLimiter    NotificationRateLimiter
}

type NotificationPreferenceRepository interface {
	GetUserPreferences(ctx context.Context, userID uuid.UUID) (*NotificationPreferences, error)
}

type PushNotificationService interface {
	SendPush(ctx context.Context, userID uuid.UUID, title, body string, data map[string]interface{}) error
}

type OrchestratorSMSService interface {
	SendSMS(ctx context.Context, phone string, message string) error
}

type OrchestratorEmailService interface {
	SendEmail(ctx context.Context, email string, subject, body string) error
}

type InAppNotificationService interface {
	CreateInAppNotification(ctx context.Context, userID uuid.UUID, notification *InAppNotification) error
}

type NotificationRateLimiter interface {
	IsRateLimited(ctx context.Context, userID uuid.UUID, notificationType string) (bool, error)
}

type NotificationPreferences struct {
	UserID           uuid.UUID
	PushEnabled      bool
	SMSEnabled       bool
	EmailEnabled     bool
	InAppEnabled     bool
	QuietHoursStart  string
	QuietHoursEnd    string
	MarketingEnabled bool
}

type InAppNotification struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	Title     string
	Body      string
	Type      string
	Read      bool
	CreatedAt time.Time
}

type NotificationRequest struct {
	UserID      uuid.UUID
	Title       string
	Body        string
	Type        string // "order_status", "marketing", "promo", "alert"
	Criticality string // "high", "medium", "low"
	Data        map[string]interface{}
	UserPhone   string
	UserEmail   string
}

type NotificationResult struct {
	ChannelsSent   []string
	ChannelsFailed []string
	SilentPushSent bool
	InAppCreated   bool
}

func NewNotificationOrchestrator(
	preferenceRepo NotificationPreferenceRepository,
	pushService PushNotificationService,
	smsService OrchestratorSMSService,
	emailService OrchestratorEmailService,
	inAppService InAppNotificationService,
	rateLimiter NotificationRateLimiter,
) *NotificationOrchestrator {
	return &NotificationOrchestrator{
		preferenceRepo: preferenceRepo,
		pushService:    pushService,
		smsService:     smsService,
		emailService:   emailService,
		inAppService:   inAppService,
		rateLimiter:    rateLimiter,
	}
}

// SendNotification orchestrates notification delivery based on preferences and criticality
func (no *NotificationOrchestrator) SendNotification(ctx context.Context, req *NotificationRequest) (*NotificationResult, error) {
	// Get user preferences
	preferences, err := no.preferenceRepo.GetUserPreferences(ctx, req.UserID)
	if err != nil {
		// Use default preferences if not found
		preferences = &NotificationPreferences{
			PushEnabled:      true,
			SMSEnabled:       true,
			EmailEnabled:     true,
			InAppEnabled:     true,
			MarketingEnabled: true,
		}
	}

	// Check rate limiting
	isRateLimited, err := no.rateLimiter.IsRateLimited(ctx, req.UserID, req.Type)
	if err == nil && isRateLimited {
		return &NotificationResult{
			ChannelsSent: []string{},
		}, fmt.Errorf("notification rate limited")
	}

	result := &NotificationResult{
		ChannelsSent:   []string{},
		ChannelsFailed: []string{},
	}

	// Determine channels based on criticality and type
	channels := no.determineChannels(req, preferences)

	// Send notifications through selected channels
	for _, channel := range channels {
		switch channel {
		case "push":
			if err := no.pushService.SendPush(ctx, req.UserID, req.Title, req.Body, req.Data); err == nil {
				result.ChannelsSent = append(result.ChannelsSent, "push")
			} else {
				result.ChannelsFailed = append(result.ChannelsFailed, "push")
			}
		case "sms":
			if req.UserPhone != "" {
				if err := no.smsService.SendSMS(ctx, req.UserPhone, req.Body); err == nil {
					result.ChannelsSent = append(result.ChannelsSent, "sms")
				} else {
					result.ChannelsFailed = append(result.ChannelsFailed, "sms")
				}
			}
		case "email":
			if req.UserEmail != "" {
				if err := no.emailService.SendEmail(ctx, req.UserEmail, req.Title, req.Body); err == nil {
					result.ChannelsSent = append(result.ChannelsSent, "email")
				} else {
					result.ChannelsFailed = append(result.ChannelsFailed, "email")
				}
			}
		case "in_app":
			inAppNotif := &InAppNotification{
				ID:        uuid.New(),
				UserID:    req.UserID,
				Title:     req.Title,
				Body:      req.Body,
				Type:      req.Type,
				Read:      false,
				CreatedAt: time.Now(),
			}
			if err := no.inAppService.CreateInAppNotification(ctx, req.UserID, inAppNotif); err == nil {
				result.ChannelsSent = append(result.ChannelsSent, "in_app")
				result.InAppCreated = true
			} else {
				result.ChannelsFailed = append(result.ChannelsFailed, "in_app")
			}
		}
	}

	return result, nil
}

// determineChannels decides which channels to use based on notification type and criticality
func (no *NotificationOrchestrator) determineChannels(req *NotificationRequest, preferences *NotificationPreferences) []string {
	var channels []string

	switch req.Type {
	case "order_status":
		// Order status: push + SMS fallback if push fails, in-app
		if preferences.PushEnabled {
			channels = append(channels, "push")
		}
		if preferences.SMSEnabled && req.Criticality == "high" {
			channels = append(channels, "sms")
		}
		if preferences.InAppEnabled {
			channels = append(channels, "in_app")
		}
	case "marketing":
		// Marketing: push only if enabled
		if preferences.MarketingEnabled && preferences.PushEnabled {
			channels = append(channels, "push")
		}
		if preferences.MarketingEnabled && preferences.EmailEnabled {
			channels = append(channels, "email")
		}
	case "promo":
		// Promo: push + email
		if preferences.PushEnabled {
			channels = append(channels, "push")
		}
		if preferences.EmailEnabled {
			channels = append(channels, "email")
		}
	case "alert":
		// Alert: all channels
		if preferences.PushEnabled {
			channels = append(channels, "push")
		}
		if preferences.SMSEnabled {
			channels = append(channels, "sms")
		}
		if preferences.EmailEnabled {
			channels = append(channels, "email")
		}
		if preferences.InAppEnabled {
			channels = append(channels, "in_app")
		}
	default:
		// Default: push + in-app
		if preferences.PushEnabled {
			channels = append(channels, "push")
		}
		if preferences.InAppEnabled {
			channels = append(channels, "in_app")
		}
	}

	return channels
}

// SendSilentPush sends a silent push for state sync without showing notification
func (no *NotificationOrchestrator) SendSilentPush(ctx context.Context, userID uuid.UUID, data map[string]interface{}) error {
	if err := no.pushService.SendPush(ctx, userID, "", "", data); err != nil {
		return fmt.Errorf("failed to send silent push: %w", err)
	}
	return nil
}

// SendOrderNotification sends order-specific notifications with proper orchestration
func (no *NotificationOrchestrator) SendOrderNotification(ctx context.Context, userID uuid.UUID, orderID uuid.UUID, status string, userPhone, userEmail string) error {
	var title, body string
	var criticality string

	switch status {
	case "confirmed":
		title = "Order Confirmed"
		body = "Your order has been confirmed"
		criticality = "medium"
	case "preparing":
		title = "Preparing Your Order"
		body = "Your order is being prepared"
		criticality = "medium"
	case "ready_for_pickup":
		title = "Order Ready"
		body = "Your order is ready for pickup"
		criticality = "high"
	case "picked_up":
		title = "Order Picked Up"
		body = "Your order has been picked up"
		criticality = "high"
	case "delivered":
		title = "Order Delivered"
		body = "Your order has been delivered"
		criticality = "high"
	case "cancelled":
		title = "Order Cancelled"
		body = "Your order has been cancelled"
		criticality = "high"
	default:
		title = "Order Update"
		body = fmt.Sprintf("Your order status is now: %s", status)
		criticality = "medium"
	}

	req := &NotificationRequest{
		UserID:      userID,
		Title:       title,
		Body:        body,
		Type:        "order_status",
		Criticality: criticality,
		Data: map[string]interface{}{
			"order_id": orderID.String(),
			"status":   status,
		},
		UserPhone: userPhone,
		UserEmail: userEmail,
	}

	_, err := no.SendNotification(ctx, req)
	return err
}

// CheckQuietHours checks if current time is within quiet hours
func (no *NotificationOrchestrator) CheckQuietHours(preferences *NotificationPreferences) bool {
	if preferences.QuietHoursStart == "" || preferences.QuietHoursEnd == "" {
		return false
	}

	now := time.Now()
	currentHour := now.Hour()

	// Parse quiet hours (simplified - in production use proper time parsing)
	startHour := 22 // Default 10 PM
	endHour := 8    // Default 8 AM

	if startHour < endHour {
		// Same day range (e.g., 2 AM to 6 AM)
		return currentHour >= startHour && currentHour < endHour
	} else {
		// Overnight range (e.g., 10 PM to 8 AM)
		return currentHour >= startHour || currentHour < endHour
	}
}

// SimpleNotificationRateLimiter implements basic rate limiting
type SimpleNotificationRateLimiter struct {
	notificationCounts map[string]int
}

func NewSimpleNotificationRateLimiter() *SimpleNotificationRateLimiter {
	return &SimpleNotificationRateLimiter{
		notificationCounts: make(map[string]int),
	}
}

func (snrl *SimpleNotificationRateLimiter) IsRateLimited(ctx context.Context, userID uuid.UUID, notificationType string) (bool, error) {
	key := fmt.Sprintf("%s:%s", userID.String(), notificationType)

	// Reset counts periodically (simplified - in production use Redis with TTL)
	count := snrl.notificationCounts[key]

	// Rate limit: max 10 notifications per hour per type
	if count >= 10 {
		return true, nil
	}

	snrl.notificationCounts[key] = count + 1
	return false, nil
}
