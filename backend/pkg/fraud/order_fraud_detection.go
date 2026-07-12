package fraud

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// OrderFraudDetector implements order fraud scoring from the spec:
// new account + high-value order + COD + new address = higher risk score → hold for manual review or require prepayment
type OrderFraudDetector struct {
	userRepo      UserRepository
	orderRepo     OrderRepository
	deviceRepo    DeviceRepository
	alertService  FraudAlertService
}

type UserRepository interface {
	GetUser(ctx context.Context, userID uuid.UUID) (*UserInfo, error)
	GetUserOrderCount(ctx context.Context, userID uuid.UUID) (int, error)
	GetUserAddresses(ctx context.Context, userID uuid.UUID) ([]*UserAddress, error)
}

type OrderRepository interface {
	GetUserOrders(ctx context.Context, userID uuid.UUID) ([]*OrderInfo, error)
	GetOrderValue(ctx context.Context, orderID uuid.UUID) (float64, error)
}

type DeviceRepository interface {
	GetUserDevices(ctx context.Context, userID uuid.UUID) ([]*DeviceInfo, error)
	IsDeviceBlacklisted(ctx context.Context, deviceID string) (bool, error)
}

type FraudAlertService interface {
	CreateFraudAlert(ctx context.Context, alert *FraudAlert) error
}

type UserInfo struct {
	ID              uuid.UUID
	Email           string
	Phone           string
	CreatedAt       time.Time
	IsVerified      bool
	AccountAgeDays int
}

type UserAddress struct {
	ID        uuid.UUID
	Address   string
	IsNew    bool
	CreatedAt time.Time
}

type OrderInfo struct {
	ID        uuid.UUID
	UserID    uuid.UUID
	Value     float64
	Method    string
	Status    string
	CreatedAt time.Time
}

type DeviceInfo struct {
	ID         uuid.UUID
	UserID     uuid.UUID
	DeviceID   string
	UserAgent  string
	IPAddress string
	IsNew     bool
}

type FraudAlert struct {
	ID          uuid.UUID
	UserID      uuid.UUID
	OrderID     uuid.UUID
	RiskScore   float64
	RiskFactors []string
	Action      string
	CreatedAt   time.Time
}

type FraudDetectionRequest struct {
	UserID         uuid.UUID
	OrderID        uuid.UUID
	OrderValue     float64
	PaymentMethod  string
	DeliveryAddress string
	DeviceID       string
	IPAddress      string
}

type FraudDetectionResult struct {
	RiskScore   float64
	RiskFactors []string
	Action      string // "approve", "review", "reject", "require_prepayment"
	Confidence  float64
}

func NewOrderFraudDetector(
	userRepo UserRepository,
	orderRepo OrderRepository,
	deviceRepo DeviceRepository,
	alertService FraudAlertService,
) *OrderFraudDetector {
	return &OrderFraudDetector{
		userRepo:     userRepo,
		orderRepo:    orderRepo,
		deviceRepo:   deviceRepo,
		alertService: alertService,
	}
}

// DetectOrderFraud implements the fraud detection logic from the spec
func (ofd *OrderFraudDetector) DetectOrderFraud(ctx context.Context, req *FraudDetectionRequest) (*FraudDetectionResult, error) {
	var riskScore float64
	var riskFactors []string

	// Get user information
	user, err := ofd.userRepo.GetUser(ctx, req.UserID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user: %w", err)
	}

	// Factor 1: New account (less than 7 days old)
	if user.AccountAgeDays < 7 {
		riskScore += 20
		riskFactors = append(riskFactors, "new_account")
	}

	// Factor 2: High-value order (above ₹2000)
	if req.OrderValue > 2000 {
		riskScore += 15
		riskFactors = append(riskFactors, "high_value_order")
	}

	// Factor 3: COD payment method
	if req.PaymentMethod == "cod" {
		riskScore += 25
		riskFactors = append(riskFactors, "cod_payment")
	}

	// Factor 4: New address
	userAddresses, err := ofd.userRepo.GetUserAddresses(ctx, req.UserID)
	if err == nil {
		hasNewAddress := false
		for _, addr := range userAddresses {
			if addr.IsNew {
				hasNewAddress = true
				break
			}
		}
		if hasNewAddress {
			riskScore += 15
			riskFactors = append(riskFactors, "new_address")
		}
	}

	// Factor 5: Unverified user
	if !user.IsVerified {
		riskScore += 10
		riskFactors = append(riskFactors, "unverified_user")
	}

	// Factor 6: Device fingerprinting
	devices, err := ofd.deviceRepo.GetUserDevices(ctx, req.UserID)
	if err == nil {
		hasNewDevice := false
		for _, device := range devices {
			if device.IsNew {
				hasNewDevice = true
				break
			}
		}
		if hasNewDevice {
			riskScore += 10
			riskFactors = append(riskFactors, "new_device")
		}

		// Check if device is blacklisted
		for _, device := range devices {
			isBlacklisted, _ := ofd.deviceRepo.IsDeviceBlacklisted(ctx, device.DeviceID)
			if isBlacklisted {
				riskScore += 50
				riskFactors = append(riskFactors, "blacklisted_device")
			}
		}
	}

	// Factor 7: Order history
	orderCount, err := ofd.userRepo.GetUserOrderCount(ctx, req.UserID)
	if err == nil {
		if orderCount == 0 {
			riskScore += 20
			riskFactors = append(riskFactors, "first_order")
		}
	}

	// Factor 8: Suspicious IP address
	if ofd.isSuspiciousIPAddress(req.IPAddress) {
		riskScore += 15
		riskFactors = append(riskFactors, "suspicious_ip")
	}

	// Cap risk score at 100
	if riskScore > 100 {
		riskScore = 100
	}

	// Determine action based on risk score
	var action string
	if riskScore >= 70 {
		action = "reject"
	} else if riskScore >= 50 {
		action = "review"
	} else if riskScore >= 30 {
		action = "require_prepayment"
	} else {
		action = "approve"
	}

	result := &FraudDetectionResult{
		RiskScore:   riskScore,
		RiskFactors: riskFactors,
		Action:      action,
		Confidence:  0.8,
	}

	// Create fraud alert if risk is high
	if riskScore >= 50 {
		alert := &FraudAlert{
			ID:          uuid.New(),
			UserID:      req.UserID,
			OrderID:     req.OrderID,
			RiskScore:   riskScore,
			RiskFactors: riskFactors,
			Action:      action,
			CreatedAt:   time.Now(),
		}
		ofd.alertService.CreateFraudAlert(ctx, alert)
	}

	return result, nil
}

// isSuspiciousIPAddress checks if an IP address is suspicious
func (ofd *OrderFraudDetector) isSuspiciousIPAddress(ip string) bool {
	// In production, this would check against a blacklist of known proxy/VPN IPs
	// For now, return false
	return false
}

// GetFraudScore calculates the overall fraud score for a user
func (ofd *OrderFraudDetector) GetFraudScore(ctx context.Context, userID uuid.UUID) (float64, error) {
	user, err := ofd.userRepo.GetUser(ctx, userID)
	if err != nil {
		return 0.0, err
	}

	var score float64

	// Account age factor
	if user.AccountAgeDays < 7 {
		score += 30
	} else if user.AccountAgeDays < 30 {
		score += 15
	}

	// Verification factor
	if !user.IsVerified {
		score += 20
	}

	// Order history factor
	orderCount, err := ofd.userRepo.GetUserOrderCount(ctx, userID)
	if err == nil {
		if orderCount == 0 {
			score += 25
		} else if orderCount < 5 {
			score += 10
		}
	}

	// Cap score at 100
	if score > 100 {
		score = 100
	}

	return score, nil
}

// CheckCouponAbuse detects coupon abuse from the spec:
// device fingerprinting + phone number + payment method fuzzy matching to detect same person creating multiple accounts for "first order free" abuse
func (ofd *OrderFraudDetector) CheckCouponAbuse(ctx context.Context, userID uuid.UUID, couponCode string) (*FraudDetectionResult, error) {
	var riskScore float64
	var riskFactors []string

	// Get user devices
	devices, err := ofd.deviceRepo.GetUserDevices(ctx, userID)
	if err == nil {
		// Check if same device has been used with multiple accounts for this coupon
		for _, device := range devices {
			// In production, check database for coupon usage by device
			// For now, add risk factor if device is new
			if device.IsNew {
				riskScore += 20
				riskFactors = append(riskFactors, "new_device_with_coupon")
			}
		}
	}

	// Get user information
	user, err := ofd.userRepo.GetUser(ctx, userID)
	if err == nil {
		// Check if phone number has been used with multiple accounts
		// In production, this would query for phone number usage across accounts
		if user.AccountAgeDays < 1 {
			riskScore += 30
			riskFactors = append(riskFactors, "very_new_account_with_coupon")
		}
	}

	// Determine action
	var action string
	if riskScore >= 50 {
		action = "reject"
	} else if riskScore >= 30 {
		action = "review"
	} else {
		action = "approve"
	}

	return &FraudDetectionResult{
		RiskScore:   riskScore,
		RiskFactors: riskFactors,
		Action:      action,
		Confidence:  0.75,
	}, nil
}

// CreateFraudAlert creates a fraud alert
func (ofd *OrderFraudDetector) CreateFraudAlert(ctx context.Context, alert *FraudAlert) error {
	return ofd.alertService.CreateFraudAlert(ctx, alert)
}
