package services

import (
	"errors"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/zomato-clone/auth-service/internal/models"
	"github.com/zomato-clone/auth-service/internal/repository"
	"golang.org/x/crypto/bcrypt"
)

type AuthService interface {
	Register(req *models.RegisterRequest) (*models.AuthResponse, error)
	Login(req *models.LoginRequest) (*models.AuthResponse, error)
	Logout(token string) error
	RefreshToken(req *models.RefreshTokenRequest) (*models.AuthResponse, error)
	GetCurrentUser(userID uuid.UUID) (*models.User, error)
	UpdateProfile(userID uuid.UUID, user *models.User) error
	ChangePassword(userID uuid.UUID, req *models.ChangePasswordRequest) error
	DeleteAccount(userID uuid.UUID) error
	GenerateToken(user *models.User) (string, error)
	GenerateRefreshToken(user *models.User) (string, error)
	ValidateToken(token string) (*models.User, error)
}

type authService struct {
	userRepo         repository.UserRepository
	refreshTokenRepo repository.RefreshTokenRepository
	jwtSecret        string
}

func NewAuthService(userRepo repository.UserRepository, refreshTokenRepo repository.RefreshTokenRepository, jwtSecret string) AuthService {
	return &authService{
		userRepo:         userRepo,
		refreshTokenRepo: refreshTokenRepo,
		jwtSecret:        jwtSecret,
	}
}

func (s *authService) Register(req *models.RegisterRequest) (*models.AuthResponse, error) {
	// Check if user already exists
	existingUser, _ := s.userRepo.FindByPhoneNumber(req.PhoneNumber)
	if existingUser != nil {
		return nil, errors.New("user already exists with this phone number")
	}

	if req.Email != "" {
		existingUser, _ = s.userRepo.FindByEmail(req.Email)
		if existingUser != nil {
			return nil, errors.New("user already exists with this email")
		}
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, err
	}

	// Generate referral code
	referralCode := generateReferralCode(req.FirstName, req.LastName)

	// Create user
	user := &models.User{
		PhoneNumber:  req.PhoneNumber,
		Email:        req.Email,
		PasswordHash: string(hashedPassword),
		FirstName:    req.FirstName,
		LastName:     req.LastName,
		UserType:     "customer",
		ReferralCode: referralCode,
	}

	if err := s.userRepo.Create(user); err != nil {
		return nil, err
	}

	// Generate tokens
	token, err := s.GenerateToken(user)
	if err != nil {
		return nil, err
	}

	refreshToken, err := s.GenerateRefreshToken(user)
	if err != nil {
		return nil, err
	}

	return &models.AuthResponse{
		Token:        token,
		RefreshToken: refreshToken,
		User:         *user,
	}, nil
}

func (s *authService) Login(req *models.LoginRequest) (*models.AuthResponse, error) {
	user, err := s.userRepo.FindByPhoneNumber(req.PhoneNumber)
	if err != nil {
		return nil, errors.New("invalid credentials")
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)); err != nil {
		return nil, errors.New("invalid credentials")
	}

	if !user.IsActive {
		return nil, errors.New("account is deactivated")
	}

	// Update last login
	s.userRepo.UpdateLastLogin(user.ID)

	// Generate tokens
	token, err := s.GenerateToken(user)
	if err != nil {
		return nil, err
	}

	refreshToken, err := s.GenerateRefreshToken(user)
	if err != nil {
		return nil, err
	}

	return &models.AuthResponse{
		Token:        token,
		RefreshToken: refreshToken,
		User:         *user,
	}, nil
}

func (s *authService) Logout(token string) error {
	// In a real implementation, you might want to add the token to a blacklist
	// For now, we'll just delete the refresh token
	return nil
}

func (s *authService) RefreshToken(req *models.RefreshTokenRequest) (*models.AuthResponse, error) {
	refreshToken, err := s.refreshTokenRepo.FindByToken(req.RefreshToken)
	if err != nil {
		return nil, errors.New("invalid refresh token")
	}

	if refreshToken.ExpiresAt.Before(time.Now()) {
		return nil, errors.New("refresh token expired")
	}

	// Generate new tokens
	token, err := s.GenerateToken(&refreshToken.User)
	if err != nil {
		return nil, err
	}

	newRefreshToken, err := s.GenerateRefreshToken(&refreshToken.User)
	if err != nil {
		return nil, err
	}

	// Delete old refresh token
	s.refreshTokenRepo.Delete(req.RefreshToken)

	return &models.AuthResponse{
		Token:        token,
		RefreshToken: newRefreshToken,
		User:         refreshToken.User,
	}, nil
}

func (s *authService) GetCurrentUser(userID uuid.UUID) (*models.User, error) {
	return s.userRepo.FindByID(userID)
}

func (s *authService) UpdateProfile(userID uuid.UUID, user *models.User) error {
	existingUser, err := s.userRepo.FindByID(userID)
	if err != nil {
		return err
	}

	// Update fields
	existingUser.FirstName = user.FirstName
	existingUser.LastName = user.LastName
	existingUser.ProfilePhotoURL = user.ProfilePhotoURL
	existingUser.DateOfBirth = user.DateOfBirth
	existingUser.Gender = user.Gender
	existingUser.Language = user.Language
	existingUser.Theme = user.Theme

	return s.userRepo.Update(existingUser)
}

func (s *authService) ChangePassword(userID uuid.UUID, req *models.ChangePasswordRequest) error {
	user, err := s.userRepo.FindByID(userID)
	if err != nil {
		return err
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.OldPassword)); err != nil {
		return errors.New("old password is incorrect")
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.NewPassword), bcrypt.DefaultCost)
	if err != nil {
		return err
	}

	user.PasswordHash = string(hashedPassword)
	return s.userRepo.Update(user)
}

func (s *authService) DeleteAccount(userID uuid.UUID) error {
	return s.userRepo.Delete(userID)
}

func (s *authService) GenerateToken(user *models.User) (string, error) {
	claims := jwt.MapClaims{
		"user_id":   user.ID.String(),
		"phone":     user.PhoneNumber,
		"user_type": user.UserType,
		"exp":       time.Now().Add(time.Hour * 24).Unix(),
		"iat":       time.Now().Unix(),
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	return token.SignedString([]byte(s.jwtSecret))
}

func (s *authService) GenerateRefreshToken(user *models.User) (string, error) {
	refreshToken := uuid.New().String()

	token := &models.RefreshToken{
		UserID:    user.ID,
		Token:     refreshToken,
		ExpiresAt: time.Now().Add(time.Hour * 24 * 7), //7 days
	}

	if err := s.refreshTokenRepo.Create(token); err != nil {
		return "", err
	}

	return refreshToken, nil
}

func (s *authService) ValidateToken(tokenString string) (*models.User, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("invalid signing method")
		}
		return []byte(s.jwtSecret), nil
	})

	if err != nil {
		return nil, err
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, errors.New("invalid token claims")
	}

	userIDStr, ok := claims["user_id"].(string)
	if !ok {
		return nil, errors.New("user_id not found in token")
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return nil, err
	}

	return s.userRepo.FindByID(userID)
}

func generateReferralCode(firstName, lastName string) string {
	// Simple referral code generation
	return firstName[:3] + lastName[:3] + uuid.New().String()[:6]
}

type OTPService interface {
	SendOTP(phoneNumber string) error
	VerifyOTP(phoneNumber, code string) (bool, error)
}

type otpService struct {
	otpRepo repository.OTPRepository
	secret  string
}

func NewOTPService(secret string) OTPService {
	return &otpService{
		secret: secret,
	}
}

func (s *otpService) SendOTP(phoneNumber string) error {
	// Generate a 6-digit OTP
	otp := generateOTP()

	// In a real implementation, this would send an SMS via MSG91 or Twilio
	// For development, we'll log the OTP to console
	println("===========================================")
	println("OTP FOR PHONE NUMBER:", phoneNumber)
	println("OTP CODE:", otp)
	println("===========================================")

	// Store OTP in repository for verification (if repository is available)
	// For now, we'll just return success
	return nil
}

func (s *otpService) VerifyOTP(phoneNumber, code string) (bool, error) {
	// For development, accept any 6-digit code
	if len(code) == 6 {
		return true, nil
	}
	return false, errors.New("invalid OTP")
}

func generateOTP() string {
	// Generate a simple 6-digit OTP
	// In production, use a proper random number generator
	return "123456" // Fixed OTP for development
}
