package auth

import (
	"context"
	"crypto/rand"
	"encoding/base64"
	"fmt"
	"time"

	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
)

type UserType string

const (
	UserTypeCustomer   UserType = "customer"
	UserTypeRestaurant UserType = "restaurant"
	UserTypeRider      UserType = "rider"
	UserTypeAdmin      UserType = "admin"
)

type User struct {
	ID           uuid.UUID  `json:"id"`
	Email        string     `json:"email"`
	Phone        string     `json:"phone"`
	PasswordHash string     `json:"-"`
	UserType     UserType   `json:"user_type"`
	FirstName    string     `json:"first_name"`
	LastName     string     `json:"last_name"`
	IsActive     bool       `json:"is_active"`
	IsVerified   bool       `json:"is_verified"`
	CreatedAt    time.Time  `json:"created_at"`
	UpdatedAt    time.Time  `json:"updated_at"`
	LastLoginAt  *time.Time `json:"last_login_at,omitempty"`
}

type Session struct {
	ID           uuid.UUID  `json:"id"`
	UserID       uuid.UUID  `json:"user_id"`
	RefreshToken string     `json:"refresh_token"`
	DeviceInfo   string     `json:"device_info"`
	IPAddress    string     `json:"ip_address"`
	UserAgent    string     `json:"user_agent"`
	ExpiresAt    time.Time  `json:"expires_at"`
	CreatedAt    time.Time  `json:"created_at"`
	RevokedAt    *time.Time `json:"revoked_at,omitempty"`
}

type LoginRequest struct {
	Email    string `json:"email" binding:"required,email"`
	Password string `json:"password" binding:"required,min=8"`
}

type RegisterRequest struct {
	Email     string   `json:"email" binding:"required,email"`
	Phone     string   `json:"phone" binding:"required,len=10"`
	Password  string   `json:"password" binding:"required,min=8"`
	FirstName string   `json:"first_name" binding:"required,min=2"`
	LastName  string   `json:"last_name" binding:"required,min=2"`
	UserType  UserType `json:"user_type" binding:"required"`
}

type AuthResponse struct {
	User         *User      `json:"user"`
	TokenPair    *TokenPair `json:"token_pair"`
	RefreshToken *Session   `json:"refresh_token,omitempty"`
}

type AuthService struct {
	jwtManager   *JWTManager
	passwordCost int
}

func NewAuthService(jwtManager *JWTManager, passwordCost int) *AuthService {
	return &AuthService{
		jwtManager:   jwtManager,
		passwordCost: passwordCost,
	}
}

func (as *AuthService) Register(ctx context.Context, req *RegisterRequest) (*AuthResponse, error) {
	// Check if user already exists
	// existingUser, err := as.userRepository.FindByEmail(ctx, req.Email)
	// if err != nil {
	// 	return nil, fmt.Errorf("failed to check existing user: %w", err)
	// }
	// if existingUser != nil {
	// 	return nil, errors.New("user already exists with this email")
	// }

	// Hash password
	passwordHash, err := as.hashPassword(req.Password)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	// Create user
	user := &User{
		ID:           uuid.New(),
		Email:        req.Email,
		Phone:        req.Phone,
		PasswordHash: passwordHash,
		UserType:     req.UserType,
		FirstName:    req.FirstName,
		LastName:     req.LastName,
		IsActive:     true,
		IsVerified:   false,
		CreatedAt:    time.Now(),
		UpdatedAt:    time.Now(),
	}

	// Save user to database
	// if err := as.userRepository.Create(ctx, user); err != nil {
	// 	return nil, fmt.Errorf("failed to create user: %w", err)
	// }

	// Generate tokens
	permissions := as.getPermissionsForUserType(req.UserType)
	tokenPair, err := as.jwtManager.GenerateTokenPair(user.ID.String(), string(req.UserType), permissions)
	if err != nil {
		return nil, fmt.Errorf("failed to generate tokens: %w", err)
	}

	// Create session
	session := &Session{
		ID:           uuid.New(),
		UserID:       user.ID,
		RefreshToken: tokenPair.RefreshToken,
		ExpiresAt:    time.Now().Add(30 * 24 * time.Hour), // 30 days
		CreatedAt:    time.Now(),
	}

	// Save session to database
	// if err := as.sessionRepository.Create(ctx, session); err != nil {
	// 	return nil, fmt.Errorf("failed to create session: %w", err)
	// }

	return &AuthResponse{
		User:         user,
		TokenPair:    tokenPair,
		RefreshToken: session,
	}, nil
}

func (as *AuthService) Login(ctx context.Context, req *LoginRequest, deviceInfo, ipAddress, userAgent string) (*AuthResponse, error) {
	// Find user by email
	// user, err := as.userRepository.FindByEmail(ctx, req.Email)
	// if err != nil {
	// 	return nil, fmt.Errorf("failed to find user: %w", err)
	// }
	// if user == nil {
	// 	return nil, errors.New("invalid credentials")
	// }

	// Verify password
	// if !as.verifyPassword(req.Password, user.PasswordHash) {
	// 	return nil, errors.New("invalid credentials")
	// }

	// Check if user is active
	// if !user.IsActive {
	// 	return nil, errors.New("user account is inactive")
	// }

	// Generate tokens
	permissions := as.getPermissionsForUserType(UserTypeCustomer) // Use actual user type
	tokenPair, err := as.jwtManager.GenerateTokenPair("user-id", string(UserTypeCustomer), permissions)
	if err != nil {
		return nil, fmt.Errorf("failed to generate tokens: %w", err)
	}

	// Update last login
	// now := time.Now()
	// user.LastLoginAt = &now
	// if err := as.userRepository.Update(ctx, user); err != nil {
	// 	return nil, fmt.Errorf("failed to update user: %w", err)
	// }

	// Create session
	session := &Session{
		ID:           uuid.New(),
		UserID:       uuid.New(), // Use actual user ID
		RefreshToken: tokenPair.RefreshToken,
		DeviceInfo:   deviceInfo,
		IPAddress:    ipAddress,
		UserAgent:    userAgent,
		ExpiresAt:    time.Now().Add(30 * 24 * time.Hour),
		CreatedAt:    time.Now(),
	}

	// Save session to database
	// if err := as.sessionRepository.Create(ctx, session); err != nil {
	// 	return nil, fmt.Errorf("failed to create session: %w", err)
	// }

	return &AuthResponse{
		TokenPair:    tokenPair,
		RefreshToken: session,
	}, nil
}

func (as *AuthService) RefreshToken(ctx context.Context, refreshToken string) (*AuthResponse, error) {
	// Validate refresh token
	tokenPair, err := as.jwtManager.RefreshAccessToken(refreshToken)
	if err != nil {
		return nil, fmt.Errorf("failed to refresh token: %w", err)
	}

	// Find session by refresh token
	// session, err := as.sessionRepository.FindByRefreshToken(ctx, refreshToken)
	// if err != nil {
	// 	return nil, fmt.Errorf("failed to find session: %w", err)
	// }
	// if session == nil || session.RevokedAt != nil {
	// 	return nil, errors.New("invalid or expired refresh token")
	// }

	// Update session with new refresh token
	// session.RefreshToken = tokenPair.RefreshToken
	// session.ExpiresAt = time.Now().Add(30 * 24 * time.Hour)
	// if err := as.sessionRepository.Update(ctx, session); err != nil {
	// 	return nil, fmt.Errorf("failed to update session: %w", err)
	// }

	return &AuthResponse{
		TokenPair:    tokenPair,
		RefreshToken: nil, // Session not needed in response
	}, nil
}

func (as *AuthService) Logout(ctx context.Context, userID uuid.UUID, refreshToken string) error {
	// Revoke session
	// if err := as.sessionRepository.RevokeByRefreshToken(ctx, refreshToken); err != nil {
	// 	return fmt.Errorf("failed to revoke session: %w", err)
	// }

	// Optionally revoke all sessions for user
	// if err := as.sessionRepository.RevokeAllByUserID(ctx, userID); err != nil {
	// 	return fmt.Errorf("failed to revoke all sessions: %w", err)
	// }

	return nil
}

func (as *AuthService) ChangePassword(ctx context.Context, userID uuid.UUID, oldPassword, newPassword string) error {
	// Get user
	// user, err := as.userRepository.FindByID(ctx, userID)
	// if err != nil {
	// 	return fmt.Errorf("failed to find user: %w", err)
	// }

	// Verify old password
	// if !as.verifyPassword(oldPassword, user.PasswordHash) {
	// 	return errors.New("invalid old password")
	// }

	// Hash new password
	_, err := as.hashPassword(newPassword)
	if err != nil {
		return fmt.Errorf("failed to hash password: %w", err)
	}

	// Update user
	// user.PasswordHash = newPasswordHash
	// user.UpdatedAt = time.Now()
	// if err := as.userRepository.Update(ctx, user); err != nil {
	// 	return fmt.Errorf("failed to update user: %w", err)
	// }

	return nil
}

func (as *AuthService) ResetPassword(ctx context.Context, email string) (string, error) {
	// Generate reset token
	resetToken, err := as.generateSecureToken(32)
	if err != nil {
		return "", fmt.Errorf("failed to generate reset token: %w", err)
	}

	// Find user by email
	// user, err := as.userRepository.FindByEmail(ctx, email)
	// if err != nil {
	// 	return "", fmt.Errorf("failed to find user: %w", err)
	// }
	// if user == nil {
	// 	return "", errors.New("user not found")
	// }

	// Store reset token in database with expiration
	// resetTokenRecord := &ResetToken{
	// 	ID:        uuid.New(),
	// 	UserID:    user.ID,
	// 	Token:     resetToken,
	// 	ExpiresAt: time.Now().Add(1 * time.Hour),
	// 	CreatedAt: time.Now(),
	// }
	// if err := as.resetTokenRepository.Create(ctx, resetTokenRecord); err != nil {
	// 	return "", fmt.Errorf("failed to store reset token: %w", err)
	// }

	return resetToken, nil
}

func (as *AuthService) ConfirmResetPassword(ctx context.Context, resetToken, newPassword string) error {
	// Validate reset token
	// resetTokenRecord, err := as.resetTokenRepository.FindByToken(ctx, resetToken)
	// if err != nil {
	// 	return fmt.Errorf("failed to find reset token: %w", err)
	// }
	// if resetTokenRecord == nil || resetTokenRecord.ExpiresAt.Before(time.Now()) {
	// 	return errors.New("invalid or expired reset token")
	// }

	// Hash new password
	_, err := as.hashPassword(newPassword)
	if err != nil {
		return fmt.Errorf("failed to hash password: %w", err)
	}

	// Update user password
	// user, err := as.userRepository.FindByID(ctx, resetTokenRecord.UserID)
	// if err != nil {
	// 	return fmt.Errorf("failed to find user: %w", err)
	// }
	// user.PasswordHash = newPasswordHash
	// user.UpdatedAt = time.Now()
	// if err := as.userRepository.Update(ctx, user); err != nil {
	// 	return fmt.Errorf("failed to update user: %w", err)
	// }

	// Delete used reset token
	// if err := as.resetTokenRepository.Delete(ctx, resetTokenRecord.ID); err != nil {
	// 	return fmt.Errorf("failed to delete reset token: %w", err)
	// }

	return nil
}

func (as *AuthService) hashPassword(password string) (string, error) {
	bytes, err := bcrypt.GenerateFromPassword([]byte(password), as.passwordCost)
	if err != nil {
		return "", err
	}
	return string(bytes), nil
}

func (as *AuthService) verifyPassword(password, hash string) bool {
	err := bcrypt.CompareHashAndPassword([]byte(hash), []byte(password))
	return err == nil
}

func (as *AuthService) generateSecureToken(length int) (string, error) {
	bytes := make([]byte, length)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return base64.URLEncoding.EncodeToString(bytes), nil
}

func (as *AuthService) getPermissionsForUserType(userType UserType) []string {
	switch userType {
	case UserTypeCustomer:
		return []string{
			"order:create",
			"order:read",
			"order:update",
			"order:delete",
			"restaurant:read",
			"menu:read",
			"profile:read",
			"profile:update",
		}
	case UserTypeRestaurant:
		return []string{
			"order:read",
			"order:update",
			"restaurant:read",
			"restaurant:update",
			"menu:read",
			"menu:create",
			"menu:update",
			"menu:delete",
			"profile:read",
			"profile:update",
		}
	case UserTypeRider:
		return []string{
			"order:read",
			"order:update",
			"rider:read",
			"rider:update",
			"location:update",
			"earnings:read",
			"profile:read",
			"profile:update",
		}
	case UserTypeAdmin:
		return []string{
			"*", // All permissions
		}
	default:
		return []string{}
	}
}
