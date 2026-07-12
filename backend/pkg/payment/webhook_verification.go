package payment

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
)

// WebhookVerifier handles webhook signature verification for payment gateways
type WebhookVerifier struct {
	secretKeys map[string]string // gateway -> secret key
}

func NewWebhookVerifier() *WebhookVerifier {
	return &WebhookVerifier{
		secretKeys: make(map[string]string),
	}
}

// AddSecretKey adds a secret key for a payment gateway
func (wv *WebhookVerifier) AddSecretKey(gateway, secretKey string) {
	wv.secretKeys[gateway] = secretKey
}

// VerifyStripeWebhook verifies Stripe webhook signature
func (wv *WebhookVerifier) VerifyStripeWebhook(payload []byte, signature string) error {
	secretKey, exists := wv.secretKeys["stripe"]
	if !exists {
		return fmt.Errorf("stripe secret key not configured")
	}

	// Stripe signature format: t=timestamp,v1=signature
	// For simplicity, we'll implement basic HMAC verification
	expectedSignature := wv.computeHMACSHA256(secretKey, payload)
	
	// In production, you'd parse the signature header and compare timestamps
	// This is a simplified version
	if !wv.compareSignatures(expectedSignature, signature) {
		return fmt.Errorf("invalid stripe webhook signature")
	}

	return nil
}

// VerifyRazorpayWebhook verifies Razorpay webhook signature
func (wv *WebhookVerifier) VerifyRazorpayWebhook(payload []byte, signature string) error {
	secretKey, exists := wv.secretKeys["razorpay"]
	if !exists {
		return fmt.Errorf("razorpay secret key not configured")
	}

	expectedSignature := wv.computeHMACSHA256(secretKey, payload)
	
	if !wv.compareSignatures(expectedSignature, signature) {
		return fmt.Errorf("invalid razorpay webhook signature")
	}

	return nil
}

// VerifyPaytmWebhook verifies Paytm webhook signature
func (wv *WebhookVerifier) VerifyPaytmWebhook(payload []byte, signature string) error {
	secretKey, exists := wv.secretKeys["paytm"]
	if !exists {
		return fmt.Errorf("paytm secret key not configured")
	}

	// Paytm uses SHA256 hash of payload + merchant key
	expectedSignature := wv.computeSHA256WithKey(secretKey, payload)
	
	if !wv.compareSignatures(expectedSignature, signature) {
		return fmt.Errorf("invalid paytm webhook signature")
	}

	return nil
}

// VerifyPhonePeWebhook verifies PhonePe webhook signature
func (wv *WebhookVerifier) VerifyPhonePeWebhook(payload []byte, signature string) error {
	secretKey, exists := wv.secretKeys["phonepe"]
	if !exists {
		return fmt.Errorf("phonepe secret key not configured")
	}

	expectedSignature := wv.computeHMACSHA256(secretKey, payload)
	
	if !wv.compareSignatures(expectedSignature, signature) {
		return fmt.Errorf("invalid phonepe webhook signature")
	}

	return nil
}

// VerifyWebhook verifies webhook signature based on gateway
func (wv *WebhookVerifier) VerifyWebhook(gateway string, payload []byte, signature string) error {
	switch gateway {
	case "stripe":
		return wv.VerifyStripeWebhook(payload, signature)
	case "razorpay":
		return wv.VerifyRazorpayWebhook(payload, signature)
	case "paytm":
		return wv.VerifyPaytmWebhook(payload, signature)
	case "phonepe":
		return wv.VerifyPhonePeWebhook(payload, signature)
	default:
		return fmt.Errorf("unsupported payment gateway: %s", gateway)
	}
}

// computeHMACSHA256 computes HMAC-SHA256 signature
func (wv *WebhookVerifier) computeHMACSHA256(secret string, payload []byte) string {
	h := hmac.New(sha256.New, []byte(secret))
	h.Write(payload)
	return hex.EncodeToString(h.Sum(nil))
}

// computeSHA256WithKey computes SHA256 hash with key (for Paytm)
func (wv *WebhookVerifier) computeSHA256WithKey(key string, payload []byte) string {
	// Paytm uses SHA256 of (payload + key)
	combined := append(payload, []byte(key)...)
	h := sha256.Sum256(combined)
	return hex.EncodeToString(h[:])
}

// compareSignatures compares two signatures safely
func (wv *WebhookVerifier) compareSignatures(sig1, sig2 string) bool {
	// Use constant-time comparison to prevent timing attacks
	return hmac.Equal([]byte(sig1), []byte(sig2))
}

// WebhookSecurityConfig holds security configuration for webhooks
type WebhookSecurityConfig struct {
	AllowedIPs      []string // IP whitelist for webhook sources
	RequireTLS      bool     // Require HTTPS for webhooks
	MaxPayloadSize  int64    // Maximum webhook payload size
	SignatureTTL    int64    // Signature validity time in seconds
}

// WebhookSecurityMiddleware provides security checks for webhooks
type WebhookSecurityMiddleware struct {
	config *WebhookSecurityConfig
}

func NewWebhookSecurityMiddleware(config *WebhookSecurityConfig) *WebhookSecurityMiddleware {
	return &WebhookSecurityMiddleware{
		config: config,
	}
}

// ValidateIP validates if the request IP is allowed
func (wsm *WebhookSecurityMiddleware) ValidateIP(ip string) bool {
	if len(wsm.config.AllowedIPs) == 0 {
		return true // No IP restriction
	}

	for _, allowedIP := range wsm.config.AllowedIPs {
		if ip == allowedIP {
			return true
		}
	}

	return false
}

// ValidatePayloadSize validates payload size
func (wsm *WebhookSecurityMiddleware) ValidatePayloadSize(size int64) bool {
	return size <= wsm.config.MaxPayloadSize
}

// ValidateTLS validates if the request is over HTTPS
func (wsm *WebhookSecurityMiddleware) ValidateTLS(isHTTPS bool) bool {
	if !wsm.config.RequireTLS {
		return true
	}
	return isHTTPS
}
