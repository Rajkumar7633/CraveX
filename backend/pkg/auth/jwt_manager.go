package auth

import (
	"errors"
	"fmt"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

type TokenType string

const (
	AccessToken  TokenType = "access"
	RefreshToken TokenType = "refresh"
)

type TokenClaims struct {
	UserID      string   `json:"user_id"`
	UserType    string   `json:"user_type"`
	TokenType   TokenType `json:"token_type"`
	Permissions []string `json:"permissions"`
	jwt.RegisteredClaims
}

type JWTManager struct {
	secretKey           []byte
	accessTokenDuration  time.Duration
	refreshTokenDuration time.Duration
	issuer              string
}

type TokenPair struct {
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token"`
	ExpiresAt    time.Time `json:"expires_at"`
	TokenType    TokenType `json:"token_type"`
}

func NewJWTManager(secretKey string, accessTokenDuration, refreshTokenDuration time.Duration, issuer string) *JWTManager {
	return &JWTManager{
		secretKey:           []byte(secretKey),
		accessTokenDuration:  accessTokenDuration,
		refreshTokenDuration: refreshTokenDuration,
		issuer:              issuer,
	}
}

func (j *JWTManager) GenerateTokenPair(userID, userType string, permissions []string) (*TokenPair, error) {
	accessToken, accessExpiresAt, err := j.generateToken(userID, userType, AccessToken, permissions)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	refreshToken, refreshExpiresAt, err := j.generateToken(userID, userType, RefreshToken, permissions)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	return &TokenPair{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresAt:    accessExpiresAt,
		TokenType:    AccessToken,
	}, nil
}

func (j *JWTManager) generateToken(userID, userType string, tokenType TokenType, permissions []string) (string, time.Time, error) {
	now := time.Now()
	var expiresAt time.Time

	switch tokenType {
	case AccessToken:
		expiresAt = now.Add(j.accessTokenDuration)
	case RefreshToken:
		expiresAt = now.Add(j.refreshTokenDuration)
	default:
		return "", time.Time{}, errors.New("invalid token type")
	}

	claims := TokenClaims{
		UserID:      userID,
		UserType:    userType,
		TokenType:   tokenType,
		Permissions: permissions,
		RegisteredClaims: jwt.RegisteredClaims{
			ID:        uuid.New().String(),
			IssuedAt: jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(expiresAt),
			NotBefore: jwt.NewNumericDate(now),
			Issuer:    j.issuer,
			Subject:   userID,
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString(j.secretKey)
	if err != nil {
		return "", time.Time{}, fmt.Errorf("failed to sign token: %w", err)
	}

	return tokenString, expiresAt, nil
}

func (j *JWTManager) ValidateToken(tokenString string) (*TokenClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &TokenClaims{}, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return j.secretKey, nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to parse token: %w", err)
	}

	claims, ok := token.Claims.(*TokenClaims)
	if !ok || !token.Valid {
		return nil, errors.New("invalid token")
	}

	if claims.ExpiresAt.Time.Before(time.Now()) {
		return nil, errors.New("token has expired")
	}

	return claims, nil
}

func (j *JWTManager) RefreshAccessToken(refreshToken string) (*TokenPair, error) {
	claims, err := j.ValidateToken(refreshToken)
	if err != nil {
		return nil, fmt.Errorf("invalid refresh token: %w", err)
	}

	if claims.TokenType != RefreshToken {
		return nil, errors.New("token is not a refresh token")
	}

	return j.GenerateTokenPair(claims.UserID, claims.UserType, claims.Permissions)
}

func (j *JWTManager) ExtractUserID(tokenString string) (string, error) {
	claims, err := j.ValidateToken(tokenString)
	if err != nil {
		return "", err
	}
	return claims.UserID, nil
}

func (j *JWTManager) ExtractUserType(tokenString string) (string, error) {
	claims, err := j.ValidateToken(tokenString)
	if err != nil {
		return "", err
	}
	return claims.UserType, nil
}

func (j *JWTManager) HasPermission(tokenString string, permission string) (bool, error) {
	claims, err := j.ValidateToken(tokenString)
	if err != nil {
		return false, err
	}

	for _, p := range claims.Permissions {
		if p == permission {
			return true, nil
		}
	}

	return false, nil
}
