package auth

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// JWTRefreshTokenManager implements JWT best practices with refresh tokens
// - Short-lived access token (15 minutes)
// - Long-lived refresh token (7-30 days)
// - Refresh token rotation on use
// - Secure storage and validation
type JWTRefreshTokenManager struct {
	accessTokenManager *JWTManager
	refreshTokenRepo   RefreshTokenRepository
	accessTokenExpiry  time.Duration
	refreshTokenExpiry time.Duration
}

type RefreshTokenRepository interface {
	SaveRefreshToken(ctx context.Context, token *RefreshTokenData) error
	GetRefreshToken(ctx context.Context, tokenID string) (*RefreshTokenData, error)
	RevokeRefreshToken(ctx context.Context, tokenID string) error
	RevokeAllUserTokens(ctx context.Context, userID uuid.UUID) error
	IsTokenRevoked(ctx context.Context, tokenID string) (bool, error)
}

type RefreshTokenData struct {
	ID          uuid.UUID
	UserID      uuid.UUID
	TokenString string
	DeviceID    string
	IPAddress   string
	UserAgent   string
	ExpiresAt   time.Time
	CreatedAt   time.Time
	LastUsedAt  *time.Time
	IsRevoked   bool
}

type TokenPairResult struct {
	AccessToken  string
	RefreshToken string
	ExpiresIn    time.Duration
	TokenType    string
}

type RefreshTokenRequest struct {
	RefreshToken string
	DeviceID     string
	IPAddress    string
	UserAgent    string
}

func NewJWTRefreshTokenManager(
	accessTokenManager *JWTManager,
	refreshTokenRepo RefreshTokenRepository,
	accessTokenExpiry time.Duration,
	refreshTokenExpiry time.Duration,
) *JWTRefreshTokenManager {
	return &JWTRefreshTokenManager{
		accessTokenManager: accessTokenManager,
		refreshTokenRepo:   refreshTokenRepo,
		accessTokenExpiry:  accessTokenExpiry,
		refreshTokenExpiry: refreshTokenExpiry,
	}
}

// GenerateTokenPair generates both access and refresh tokens
func (jrtm *JWTRefreshTokenManager) GenerateTokenPair(ctx context.Context, userID uuid.UUID, deviceID, ipAddress, userAgent string) (*TokenPairResult, error) {
	// Generate access token (short-lived)
	accessToken, _, err := jrtm.accessTokenManager.generateToken(userID.String(), "access", "access", []string{})
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	// Generate refresh token (long-lived)
	refreshTokenString, err := jrtm.generateSecureToken()
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	// Store refresh token in database
	refreshToken := &RefreshTokenData{
		ID:          uuid.New(),
		UserID:      userID,
		TokenString: refreshTokenString,
		DeviceID:    deviceID,
		IPAddress:   ipAddress,
		UserAgent:   userAgent,
		ExpiresAt:   time.Now().Add(jrtm.refreshTokenExpiry),
		CreatedAt:   time.Now(),
		IsRevoked:   false,
	}

	if err := jrtm.refreshTokenRepo.SaveRefreshToken(ctx, refreshToken); err != nil {
		return nil, fmt.Errorf("failed to save refresh token: %w", err)
	}

	return &TokenPairResult{
		AccessToken:  accessToken,
		RefreshToken: refreshTokenString,
		ExpiresIn:    jrtm.accessTokenExpiry,
		TokenType:    "Bearer",
	}, nil
}

// RefreshAccessToken generates a new access token using a refresh token
// Implements refresh token rotation: old token is revoked, new token is issued
func (jrtm *JWTRefreshTokenManager) RefreshAccessToken(ctx context.Context, req *RefreshTokenRequest) (*TokenPairResult, error) {
	// Validate refresh token
	refreshToken, err := jrtm.refreshTokenRepo.GetRefreshToken(ctx, req.RefreshToken)
	if err != nil {
		return nil, fmt.Errorf("invalid refresh token: %w", err)
	}

	// Check if token is revoked
	if refreshToken.IsRevoked {
		return nil, fmt.Errorf("refresh token has been revoked")
	}

	// Check if token is expired
	if time.Now().After(refreshToken.ExpiresAt) {
		return nil, fmt.Errorf("refresh token has expired")
	}

	// Verify device matches (optional security measure)
	if req.DeviceID != "" && refreshToken.DeviceID != req.DeviceID {
		return nil, fmt.Errorf("device mismatch for security")
	}

	// Revoke old refresh token (rotation)
	if err := jrtm.refreshTokenRepo.RevokeRefreshToken(ctx, req.RefreshToken); err != nil {
		return nil, fmt.Errorf("failed to revoke old refresh token: %w", err)
	}

	// Generate new token pair
	return jrtm.GenerateTokenPair(ctx, refreshToken.UserID, req.DeviceID, req.IPAddress, req.UserAgent)
}

// RevokeRefreshToken revokes a specific refresh token
func (jrtm *JWTRefreshTokenManager) RevokeRefreshToken(ctx context.Context, tokenID string) error {
	return jrtm.refreshTokenRepo.RevokeRefreshToken(ctx, tokenID)
}

// RevokeAllUserTokens revokes all refresh tokens for a user (e.g., on password change)
func (jrtm *JWTRefreshTokenManager) RevokeAllUserTokens(ctx context.Context, userID uuid.UUID) error {
	return jrtm.refreshTokenRepo.RevokeAllUserTokens(ctx, userID)
}

// ValidateRefreshToken validates a refresh token without consuming it
func (jrtm *JWTRefreshTokenManager) ValidateRefreshToken(ctx context.Context, tokenID string) (bool, error) {
	token, err := jrtm.refreshTokenRepo.GetRefreshToken(ctx, tokenID)
	if err != nil {
		return false, nil
	}

	// Check if revoked
	if token.IsRevoked {
		return false, nil
	}

	// Check if expired
	if time.Now().After(token.ExpiresAt) {
		return false, nil
	}

	return true, nil
}

// generateSecureToken generates a cryptographically secure random token
func (jrtm *JWTRefreshTokenManager) generateSecureToken() (string, error) {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return base64.URLEncoding.EncodeToString(bytes), nil
}

// CleanupExpiredTokens removes expired refresh tokens from the database
func (jrtm *JWTRefreshTokenManager) CleanupExpiredTokens(ctx context.Context) error {
	// In production, this would be a scheduled job
	// For now, this is a placeholder
	return nil
}

// GetActiveTokensCount returns the number of active refresh tokens for a user
func (jrtm *JWTRefreshTokenManager) GetActiveTokensCount(ctx context.Context, userID uuid.UUID) (int, error) {
	// In production, this would query the repository
	return 0, nil
}
