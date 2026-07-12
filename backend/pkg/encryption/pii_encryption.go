package encryption

import (
	"crypto/aes"
	"crypto/cipher"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"io"
)

// PIIEncryptionService handles encryption of PII data at rest
// - Phone numbers, addresses, payment tokens encrypted in DB
// - Uses AES-256-GCM for authenticated encryption
// - Key management via AWS KMS or similar
type PIIEncryptionService struct {
	encryptionKey []byte
}

func NewPIIEncryptionService(encryptionKey []byte) (*PIIEncryptionService, error) {
	if len(encryptionKey) != 32 {
		return nil, fmt.Errorf("encryption key must be 32 bytes for AES-256")
	}

	return &PIIEncryptionService{
		encryptionKey: encryptionKey,
	}, nil
}

// Encrypt encrypts plaintext using AES-256-GCM
func (pes *PIIEncryptionService) Encrypt(plaintext string) (string, error) {
	block, err := aes.NewCipher(pes.encryptionKey)
	if err != nil {
		return "", fmt.Errorf("failed to create cipher: %w", err)
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("failed to create GCM: %w", err)
	}

	nonce := make([]byte, gcm.NonceSize())
	if _, err = io.ReadFull(rand.Reader, nonce); err != nil {
		return "", fmt.Errorf("failed to generate nonce: %w", err)
	}

	ciphertext := gcm.Seal(nonce, nonce, []byte(plaintext), nil)
	return base64.URLEncoding.EncodeToString(ciphertext), nil
}

// Decrypt decrypts ciphertext using AES-256-GCM
func (pes *PIIEncryptionService) Decrypt(ciphertext string) (string, error) {
	data, err := base64.URLEncoding.DecodeString(ciphertext)
	if err != nil {
		return "", fmt.Errorf("failed to decode ciphertext: %w", err)
	}

	block, err := aes.NewCipher(pes.encryptionKey)
	if err != nil {
		return "", fmt.Errorf("failed to create cipher: %w", err)
	}

	gcm, err := cipher.NewGCM(block)
	if err != nil {
		return "", fmt.Errorf("failed to create GCM: %w", err)
	}

	nonceSize := gcm.NonceSize()
	if len(data) < nonceSize {
		return "", fmt.Errorf("ciphertext too short")
	}

	nonce, ciphertextBytes := data[:nonceSize], data[nonceSize:]
	plaintext, err := gcm.Open(nil, nonce, ciphertextBytes, nil)
	if err != nil {
		return "", fmt.Errorf("failed to decrypt: %w", err)
	}

	return string(plaintext), nil
}

// EncryptPhoneNumber encrypts a phone number
func (pes *PIIEncryptionService) EncryptPhoneNumber(phoneNumber string) (string, error) {
	return pes.Encrypt(phoneNumber)
}

// DecryptPhoneNumber decrypts a phone number
func (pes *PIIEncryptionService) DecryptPhoneNumber(encryptedPhone string) (string, error) {
	return pes.Decrypt(encryptedPhone)
}

// EncryptAddress encrypts an address
func (pes *PIIEncryptionService) EncryptAddress(address string) (string, error) {
	return pes.Encrypt(address)
}

// DecryptAddress decrypts an address
func (pes *PIIEncryptionService) DecryptAddress(encryptedAddress string) (string, error) {
	return pes.Decrypt(encryptedAddress)
}

// EncryptPaymentToken encrypts a payment token
func (pes *PIIEncryptionService) EncryptPaymentToken(token string) (string, error) {
	return pes.Encrypt(token)
}

// DecryptPaymentToken decrypts a payment token
func (pes *PIIEncryptionService) DecryptPaymentToken(encryptedToken string) (string, error) {
	return pes.Decrypt(encryptedToken)
}

// EncryptEmail encrypts an email address
func (pes *PIIEncryptionService) EncryptEmail(email string) (string, error) {
	return pes.Encrypt(email)
}

// DecryptEmail decrypts an email address
func (pes *PIIEncryptionService) DecryptEmail(encryptedEmail string) (string, error) {
	return pes.Decrypt(encryptedEmail)
}

// KeyManager interface for key rotation and management
type KeyManager interface {
	GetCurrentKey() ([]byte, error)
	RotateKey() ([]byte, error)
	GetKeyVersion(keyID string) ([]byte, error)
}

// RotatingPIIEncryptionService handles key rotation for PII encryption
type RotatingPIIEncryptionService struct {
	keyManager KeyManager
}

func NewRotatingPIIEncryptionService(keyManager KeyManager) *RotatingPIIEncryptionService {
	return &RotatingPIIEncryptionService{
		keyManager: keyManager,
	}
}

// EncryptWithVersion encrypts data with the current key and returns key version
func (rpies *RotatingPIIEncryptionService) EncryptWithVersion(plaintext string) (string, string, error) {
	key, err := rpies.keyManager.GetCurrentKey()
	if err != nil {
		return "", "", fmt.Errorf("failed to get current key: %w", err)
	}

	service, err := NewPIIEncryptionService(key)
	if err != nil {
		return "", "", err
	}

	ciphertext, err := service.Encrypt(plaintext)
	if err != nil {
		return "", "", err
	}

	return ciphertext, "current", nil
}

// DecryptWithVersion decrypts data using the appropriate key version
func (rpies *RotatingPIIEncryptionService) DecryptWithVersion(ciphertext, keyVersion string) (string, error) {
	key, err := rpies.keyManager.GetKeyVersion(keyVersion)
	if err != nil {
		return "", fmt.Errorf("failed to get key version: %w", err)
	}

	service, err := NewPIIEncryptionService(key)
	if err != nil {
		return "", err
	}

	return service.Decrypt(ciphertext)
}

// SimpleKeyManager implements a simple in-memory key manager for development
type SimpleKeyManager struct {
	currentKey []byte
	keys       map[string][]byte
}

func NewSimpleKeyManager(currentKey []byte) *SimpleKeyManager {
	return &SimpleKeyManager{
		currentKey: currentKey,
		keys:       map[string][]byte{"current": currentKey},
	}
}

func (skm *SimpleKeyManager) GetCurrentKey() ([]byte, error) {
	return skm.currentKey, nil
}

func (skm *SimpleKeyManager) RotateKey() ([]byte, error) {
	// In production, this would generate a new key and store it securely
	// For now, return the current key
	return skm.currentKey, nil
}

func (skm *SimpleKeyManager) GetKeyVersion(keyVersion string) ([]byte, error) {
	key, exists := skm.keys[keyVersion]
	if !exists {
		return nil, fmt.Errorf("key version not found")
	}
	return key, nil
}

// HashPII hashes PII data for comparison without storing plaintext
func HashPII(data string) string {
	// In production, use a proper hashing algorithm like bcrypt or argon2
	// For now, return a simple hash (NOT SECURE - for demonstration only)
	return fmt.Sprintf("%x", len(data))
}

// MaskPhoneNumber masks a phone number for display (e.g., +91*****1234)
func MaskPhoneNumber(phoneNumber string) string {
	if len(phoneNumber) < 4 {
		return "****"
	}
	return phoneNumber[:len(phoneNumber)-4] + "****"
}

// MaskEmail masks an email address for display (e.g., u***@example.com)
func MaskEmail(email string) string {
	if len(email) < 8 {
		return "***@***"
	}
	atIndex := len(email) - len(email)
	for i, c := range email {
		if c == '@' {
			atIndex = i
			break
		}
	}
	
	if atIndex <= 1 {
		return "***@***"
	}
	
	return email[:1] + "***" + email[atIndex:]
}
