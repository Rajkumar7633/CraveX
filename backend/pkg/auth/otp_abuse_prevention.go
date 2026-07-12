package auth

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/redis/go-redis/v9"
)

// OTPAbusePrevention implements OTP abuse prevention with cooldown and CAPTCHA
// - Max 3 OTP requests/hour per number
// - Exponential cooldown after failures
// - CAPTCHA after repeated failures
type OTPAbusePrevention struct {
	redisClient      *redis.Client
	maxRequests      int
	timeWindow       time.Duration
	baseCooldown     time.Duration
	maxCooldown      time.Duration
	captchaThreshold int // Failures before CAPTCHA required
}

type OTPRequest struct {
	PhoneNumber string
	IPAddress   string
	UserAgent   string
}

type OTPAbuseCheck struct {
	Allowed           bool
	Reason            string
	CooldownEnd       time.Time
	RequiresCaptcha   bool
	RemainingAttempts int
}

func NewOTPAbusePrevention(
	redisClient *redis.Client,
	maxRequests int,
	timeWindow time.Duration,
	baseCooldown time.Duration,
	maxCooldown time.Duration,
	captchaThreshold int,
) *OTPAbusePrevention {
	return &OTPAbusePrevention{
		redisClient:      redisClient,
		maxRequests:      maxRequests,
		timeWindow:       timeWindow,
		baseCooldown:     baseCooldown,
		maxCooldown:      maxCooldown,
		captchaThreshold: captchaThreshold,
	}
}

// CheckOTPRequest checks if an OTP request is allowed
func (oap *OTPAbusePrevention) CheckOTPRequest(ctx context.Context, req *OTPRequest) (*OTPAbuseCheck, error) {
	key := oap.generateKey(req.PhoneNumber)

	// Get current request count
	count, err := oap.redisClient.Get(ctx, key).Int()
	if err != nil && err != redis.Nil {
		return &OTPAbuseCheck{Allowed: false, Reason: "internal_error"}, nil
	}

	// Check if in cooldown
	cooldownKey := oap.generateCooldownKey(req.PhoneNumber)
	cooldownEnd, err := oap.redisClient.Get(ctx, cooldownKey).Int64()
	if err == nil {
		cooldownEndTime := time.Unix(cooldownEnd, 0)
		if time.Now().Before(cooldownEndTime) {
			return &OTPAbuseCheck{
				Allowed:     false,
				Reason:      "in_cooldown",
				CooldownEnd: cooldownEndTime,
			}, nil
		}
	}

	// Check if rate limit exceeded
	if count >= oap.maxRequests {
		// Apply cooldown
		cooldownDuration := oap.calculateCooldown(count)
		cooldownEndTime := time.Now().Add(cooldownDuration)

		oap.redisClient.Set(ctx, cooldownKey, cooldownEndTime.Unix(), cooldownDuration)

		return &OTPAbuseCheck{
			Allowed:     false,
			Reason:      "rate_limit_exceeded",
			CooldownEnd: cooldownEndTime,
		}, nil
	}

	// Check if CAPTCHA required
	failureKey := oap.generateFailureKey(req.PhoneNumber)
	failures, _ := oap.redisClient.Get(ctx, failureKey).Int()
	requiresCaptcha := failures >= oap.captchaThreshold

	return &OTPAbuseCheck{
		Allowed:           true,
		RequiresCaptcha:   requiresCaptcha,
		RemainingAttempts: oap.maxRequests - count,
	}, nil
}

// RecordOTPRequest records an OTP request
func (oap *OTPAbusePrevention) RecordOTPRequest(ctx context.Context, phoneNumber string) error {
	key := oap.generateKey(phoneNumber)

	// Increment request count
	count, err := oap.redisClient.Incr(ctx, key).Result()
	if err != nil {
		return fmt.Errorf("failed to increment request count: %w", err)
	}

	// Set expiration on first request
	if count == 1 {
		oap.redisClient.Expire(ctx, key, oap.timeWindow)
	}

	return nil
}

// RecordOTPFailure records an OTP verification failure
func (oap *OTPAbusePrevention) RecordOTPFailure(ctx context.Context, phoneNumber string) error {
	failureKey := oap.generateFailureKey(phoneNumber)

	// Increment failure count
	failures, err := oap.redisClient.Incr(ctx, failureKey).Result()
	if err != nil {
		return fmt.Errorf("failed to increment failure count: %w", err)
	}

	// Set expiration
	oap.redisClient.Expire(ctx, failureKey, 24*time.Hour)

	// Apply cooldown if threshold reached
	if failures >= int64(oap.captchaThreshold) {
		cooldownDuration := oap.calculateCooldown(int(failures))
		cooldownKey := oap.generateCooldownKey(phoneNumber)
		cooldownEndTime := time.Now().Add(cooldownDuration)

		oap.redisClient.Set(ctx, cooldownKey, cooldownEndTime.Unix(), cooldownDuration)
	}

	return nil
}

// RecordOTPSuccess records a successful OTP verification
func (oap *OTPAbusePrevention) RecordOTPSuccess(ctx context.Context, phoneNumber string) error {
	// Clear failure count on success
	failureKey := oap.generateFailureKey(phoneNumber)
	oap.redisClient.Del(ctx, failureKey)

	// Clear cooldown
	cooldownKey := oap.generateCooldownKey(phoneNumber)
	oap.redisClient.Del(ctx, cooldownKey)

	return nil
}

// calculateCooldown calculates exponential cooldown based on failure count
func (oap *OTPAbusePrevention) calculateCooldown(failures int) time.Duration {
	// Exponential backoff: base * 2^(failures-1)
	cooldown := oap.baseCooldown * time.Duration(math.Pow(2, float64(failures-1)))

	// Cap at max cooldown
	if cooldown > oap.maxCooldown {
		cooldown = oap.maxCooldown
	}

	return cooldown
}

// ResetOTPCounters resets all counters for a phone number (admin function)
func (oap *OTPAbusePrevention) ResetOTPCounters(ctx context.Context, phoneNumber string) error {
	keys := []string{
		oap.generateKey(phoneNumber),
		oap.generateCooldownKey(phoneNumber),
		oap.generateFailureKey(phoneNumber),
	}

	return oap.redisClient.Del(ctx, keys...).Err()
}

// GetOTPStats returns OTP statistics for a phone number
func (oap *OTPAbusePrevention) GetOTPStats(ctx context.Context, phoneNumber string) (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	requestKey := oap.generateKey(phoneNumber)
	count, _ := oap.redisClient.Get(ctx, requestKey).Int()
	stats["request_count"] = count

	failureKey := oap.generateFailureKey(phoneNumber)
	failures, _ := oap.redisClient.Get(ctx, failureKey).Int()
	stats["failure_count"] = failures

	cooldownKey := oap.generateCooldownKey(phoneNumber)
	cooldownEnd, _ := oap.redisClient.Get(ctx, cooldownKey).Int64()
	if cooldownEnd > 0 {
		stats["cooldown_end"] = time.Unix(cooldownEnd, 0)
		stats["in_cooldown"] = time.Now().Before(time.Unix(cooldownEnd, 0))
	} else {
		stats["in_cooldown"] = false
	}

	stats["requires_captcha"] = int(failures) >= oap.captchaThreshold

	return stats, nil
}

func (oap *OTPAbusePrevention) generateKey(phoneNumber string) string {
	return fmt.Sprintf("otp_requests:%s", phoneNumber)
}

func (oap *OTPAbusePrevention) generateCooldownKey(phoneNumber string) string {
	return fmt.Sprintf("otp_cooldown:%s", phoneNumber)
}

func (oap *OTPAbusePrevention) generateFailureKey(phoneNumber string) string {
	return fmt.Sprintf("otp_failures:%s", phoneNumber)
}

// CAPTCHAValidator interface for CAPTCHA validation
type CAPTCHAValidator interface {
	ValidateCAPTCHA(ctx context.Context, token string, ipAddress string) (bool, error)
}

// SimpleCAPTCHAValidator implements basic CAPTCHA validation
type SimpleCAPTCHAValidator struct{}

func NewSimpleCAPTCHAValidator() *SimpleCAPTCHAValidator {
	return &SimpleCAPTCHAValidator{}
}

func (scv *SimpleCAPTCHAValidator) ValidateCAPTCHA(ctx context.Context, token string, ipAddress string) (bool, error) {
	// In production, integrate with reCAPTCHA or hCaptcha
	// For now, return true if token is not empty
	return token != "", nil
}

// OTPServiceWithAbusePrevention wraps OTP service with abuse prevention
type OTPServiceWithAbusePrevention struct {
	otpService       OTPService
	abusePrevention  *OTPAbusePrevention
	captchaValidator CAPTCHAValidator
}

type OTPService interface {
	SendOTP(ctx context.Context, phoneNumber string) error
	VerifyOTP(ctx context.Context, phoneNumber, otp string) (bool, error)
}

func NewOTPServiceWithAbusePrevention(
	otpService OTPService,
	abusePrevention *OTPAbusePrevention,
	captchaValidator CAPTCHAValidator,
) *OTPServiceWithAbusePrevention {
	return &OTPServiceWithAbusePrevention{
		otpService:       otpService,
		abusePrevention:  abusePrevention,
		captchaValidator: captchaValidator,
	}
}

// SendOTPWithChecks sends OTP with abuse prevention checks
func (oswap *OTPServiceWithAbusePrevention) SendOTPWithChecks(ctx context.Context, req *OTPRequest, captchaToken string) error {
	// Check if request is allowed
	check, err := oswap.abusePrevention.CheckOTPRequest(ctx, req)
	if err != nil {
		return fmt.Errorf("failed to check OTP request: %w", err)
	}

	if !check.Allowed {
		return fmt.Errorf("OTP request not allowed: %s", check.Reason)
	}

	// Validate CAPTCHA if required
	if check.RequiresCaptcha {
		if captchaToken == "" {
			return fmt.Errorf("CAPTCHA required")
		}

		valid, err := oswap.captchaValidator.ValidateCAPTCHA(ctx, captchaToken, req.IPAddress)
		if err != nil || !valid {
			return fmt.Errorf("CAPTCHA validation failed")
		}
	}

	// Record the request
	if err := oswap.abusePrevention.RecordOTPRequest(ctx, req.PhoneNumber); err != nil {
		return fmt.Errorf("failed to record OTP request: %w", err)
	}

	// Send OTP
	return oswap.otpService.SendOTP(ctx, req.PhoneNumber)
}

// VerifyOTPWithChecks verifies OTP with failure tracking
func (oswap *OTPServiceWithAbusePrevention) VerifyOTPWithChecks(ctx context.Context, phoneNumber, otp string) (bool, error) {
	valid, err := oswap.otpService.VerifyOTP(ctx, phoneNumber, otp)
	if err != nil {
		return false, err
	}

	if valid {
		// Record success
		if err := oswap.abusePrevention.RecordOTPSuccess(ctx, phoneNumber); err != nil {
			// Log error but don't fail the verification
			fmt.Printf("Failed to record OTP success: %v\n", err)
		}
	} else {
		// Record failure
		if err := oswap.abusePrevention.RecordOTPFailure(ctx, phoneNumber); err != nil {
			fmt.Printf("Failed to record OTP failure: %v\n", err)
		}
	}

	return valid, nil
}
