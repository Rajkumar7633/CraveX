package auth

import (
	"context"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// Mock implementations for testing
type MockCacheService struct {
	mock.Mock
}

func (m *MockCacheService) SetUserSession(ctx context.Context, userID string, sessionData interface{}, expiration time.Duration) error {
	args := m.Called(ctx, userID, sessionData, expiration)
	return args.Error(0)
}

func (m *MockCacheService) GetUserSession(ctx context.Context, userID string, dest interface{}) error {
	args := m.Called(ctx, userID, dest)
	return args.Error(0)
}

func (m *MockCacheService) SetUserProfile(ctx context.Context, userID string, profile interface{}, expiration time.Duration) error {
	args := m.Called(ctx, userID, profile, expiration)
	return args.Error(0)
}

func (m *MockCacheService) GetUserProfile(ctx context.Context, userID string, dest interface{}) error {
	args := m.Called(ctx, userID, dest)
	return args.Error(0)
}

func (m *MockCacheService) CheckRateLimit(ctx context.Context, key string, limit int, window time.Duration) (bool, error) {
	args := m.Called(ctx, key, limit, window)
	return args.Bool(0), args.Error(1)
}

func (m *MockCacheService) InvalidateUserCache(ctx context.Context, userID string) error {
	args := m.Called(ctx, userID)
	return args.Error(0)
}

func (m *MockCacheService) InvalidateRestaurantCache(ctx context.Context, restaurantID string) error {
	args := m.Called(ctx, restaurantID)
	return args.Error(0)
}

func TestNewAuthService(t *testing.T) {
	jwtManager := NewJWTManager("test-secret", 15*time.Minute, 30*24*time.Hour, "cravex")
	authService := NewAuthService(jwtManager, 10)

	assert.NotNil(t, authService)
	assert.Equal(t, 10, authService.passwordCost)
}

func TestJWTManager_GenerateTokenPair(t *testing.T) {
	jwtManager := NewJWTManager("test-secret-key-for-testing", 15*time.Minute, 30*24*time.Hour, "cravex")
	userID := uuid.New().String()
	userType := "customer"
	permissions := []string{"order:create", "order:read"}

	tokenPair, err := jwtManager.GenerateTokenPair(userID, userType, permissions)

	assert.NoError(t, err)
	assert.NotNil(t, tokenPair)
	assert.NotEmpty(t, tokenPair.AccessToken)
	assert.NotEmpty(t, tokenPair.RefreshToken)
	assert.True(t, tokenPair.ExpiresAt.After(time.Now()))
}

func TestJWTManager_ValidateToken(t *testing.T) {
	jwtManager := NewJWTManager("test-secret-key-for-testing", 15*time.Minute, 30*24*time.Hour, "cravex")
	userID := uuid.New().String()
	userType := "customer"
	permissions := []string{"order:create", "order:read"}

	tokenPair, err := jwtManager.GenerateTokenPair(userID, userType, permissions)
	assert.NoError(t, err)

	claims, err := jwtManager.ValidateToken(tokenPair.AccessToken)

	assert.NoError(t, err)
	assert.NotNil(t, claims)
	assert.Equal(t, userID, claims.UserID)
	assert.Equal(t, userType, claims.UserType)
	assert.Equal(t, AccessToken, claims.TokenType)
}

func TestJWTManager_RefreshAccessToken(t *testing.T) {
	jwtManager := NewJWTManager("test-secret-key-for-testing", 15*time.Minute, 30*24*time.Hour, "cravex")
	userID := uuid.New().String()
	userType := "customer"
	permissions := []string{"order:create", "order:read"}

	tokenPair, err := jwtManager.GenerateTokenPair(userID, userType, permissions)
	assert.NoError(t, err)

	newTokenPair, err := jwtManager.RefreshAccessToken(tokenPair.RefreshToken)

	assert.NoError(t, err)
	assert.NotNil(t, newTokenPair)
	assert.NotEmpty(t, newTokenPair.AccessToken)
	assert.NotEqual(t, tokenPair.AccessToken, newTokenPair.AccessToken)
}

func TestJWTManager_ExtractUserID(t *testing.T) {
	jwtManager := NewJWTManager("test-secret-key-for-testing", 15*time.Minute, 30*24*time.Hour, "cravex")
	userID := uuid.New().String()
	userType := "customer"
	permissions := []string{"order:create", "order:read"}

	tokenPair, err := jwtManager.GenerateTokenPair(userID, userType, permissions)
	assert.NoError(t, err)

	extractedUserID, err := jwtManager.ExtractUserID(tokenPair.AccessToken)

	assert.NoError(t, err)
	assert.Equal(t, userID, extractedUserID)
}

func TestJWTManager_ExtractUserType(t *testing.T) {
	jwtManager := NewJWTManager("test-secret-key-for-testing", 15*time.Minute, 30*24*time.Hour, "cravex")
	userID := uuid.New().String()
	userType := "customer"
	permissions := []string{"order:create", "order:read"}

	tokenPair, err := jwtManager.GenerateTokenPair(userID, userType, permissions)
	assert.NoError(t, err)

	extractedUserType, err := jwtManager.ExtractUserType(tokenPair.AccessToken)

	assert.NoError(t, err)
	assert.Equal(t, userType, extractedUserType)
}

func TestJWTManager_HasPermission(t *testing.T) {
	jwtManager := NewJWTManager("test-secret-key-for-testing", 15*time.Minute, 30*24*time.Hour, "cravex")
	userID := uuid.New().String()
	userType := "customer"
	permissions := []string{"order:create", "order:read"}

	tokenPair, err := jwtManager.GenerateTokenPair(userID, userType, permissions)
	assert.NoError(t, err)

	hasPermission, err := jwtManager.HasPermission(tokenPair.AccessToken, "order:create")

	assert.NoError(t, err)
	assert.True(t, hasPermission)

	hasPermission, err = jwtManager.HasPermission(tokenPair.AccessToken, "admin:delete")

	assert.NoError(t, err)
	assert.False(t, hasPermission)
}

func TestAuthService_HashPassword(t *testing.T) {
	jwtManager := NewJWTManager("test-secret-key-for-testing", 15*time.Minute, 30*24*time.Hour, "cravex")
	authService := NewAuthService(jwtManager, 10)

	password := "testPassword123"
	hash, err := authService.hashPassword(password)

	assert.NoError(t, err)
	assert.NotEmpty(t, hash)
	assert.NotEqual(t, password, hash)
}

func TestAuthService_VerifyPassword(t *testing.T) {
	jwtManager := NewJWTManager("test-secret-key-for-testing", 15*time.Minute, 30*24*time.Hour, "cravex")
	authService := NewAuthService(jwtManager, 10)

	password := "testPassword123"
	hash, err := authService.hashPassword(password)
	assert.NoError(t, err)

	isValid := authService.verifyPassword(password, hash)
	assert.True(t, isValid)

	isValid = authService.verifyPassword("wrongPassword", hash)
	assert.False(t, isValid)
}

func TestAuthService_GenerateSecureToken(t *testing.T) {
	jwtManager := NewJWTManager("test-secret-key-for-testing", 15*time.Minute, 30*24*time.Hour, "cravex")
	authService := NewAuthService(jwtManager, 10)

	token, err := authService.generateSecureToken(32)

	assert.NoError(t, err)
	assert.NotEmpty(t, token)
	assert.Len(t, token, 44) // Base64 encoded 32 bytes
}

func TestAuthService_GetPermissionsForUserType(t *testing.T) {
	jwtManager := NewJWTManager("test-secret-key-for-testing", 15*time.Minute, 30*24*time.Hour, "cravex")
	authService := NewAuthService(jwtManager, 10)

	customerPermissions := authService.getPermissionsForUserType(UserTypeCustomer)
	assert.Contains(t, customerPermissions, "order:create")
	assert.Contains(t, customerPermissions, "restaurant:read")
	assert.NotContains(t, customerPermissions, "menu:create")

	restaurantPermissions := authService.getPermissionsForUserType(UserTypeRestaurant)
	assert.Contains(t, restaurantPermissions, "menu:create")
	assert.Contains(t, restaurantPermissions, "restaurant:update")

	riderPermissions := authService.getPermissionsForUserType(UserTypeRider)
	assert.Contains(t, riderPermissions, "location:update")
	assert.Contains(t, riderPermissions, "earnings:read")

	adminPermissions := authService.getPermissionsForUserType(UserTypeAdmin)
	assert.Contains(t, adminPermissions, "*")
}
