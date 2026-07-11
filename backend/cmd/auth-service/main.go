package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/zomato-clone/auth-service/internal/config"
	"github.com/zomato-clone/auth-service/internal/handlers"
	"github.com/zomato-clone/auth-service/internal/middleware"
	"github.com/zomato-clone/auth-service/internal/repository"
	"github.com/zomato-clone/auth-service/internal/services"
)

func main() {
	// Load configuration
	cfg := config.Load()

	// Initialize database
	db, err := repository.InitDB(cfg.DatabaseURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// Initialize repositories
	userRepo := repository.NewUserRepository(db)
	refreshTokenRepo := repository.NewRefreshTokenRepository(db)

	// Initialize services
	authService := services.NewAuthService(userRepo, refreshTokenRepo, cfg.JWTSecret)
	otpService := services.NewOTPService(cfg.OTPSecret)

	// Initialize handlers
	authHandler := handlers.NewAuthHandler(authService, otpService)

	// Initialize middleware
	authMiddleware := middleware.NewAuthMiddleware(authService)

	// Setup Gin router
	router := gin.Default()

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "healthy", "service": "auth-service"})
	})

	// Public routes
	public := router.Group("/api/v1/auth")
	{
		public.POST("/register", authHandler.Register)
		public.POST("/login", authHandler.Login)
		public.POST("/logout", authHandler.Logout)
		public.POST("/refresh", authHandler.RefreshToken)
		public.POST("/verify-otp", authHandler.VerifyOTP)
		public.POST("/send-otp", authHandler.SendOTP)
		public.POST("/forgot-password", authHandler.ForgotPassword)
		public.POST("/reset-password", authHandler.ResetPassword)
		public.POST("/social-login", authHandler.SocialLogin)
	}

	// Protected routes
	protected := router.Group("/api/v1/auth")
	protected.Use(authMiddleware.Authenticate())
	{
		protected.GET("/me", authHandler.GetCurrentUser)
		protected.PUT("/me", authHandler.UpdateProfile)
		protected.POST("/change-password", authHandler.ChangePassword)
		protected.DELETE("/me", authHandler.DeleteAccount)
	}

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8001"
	}

	log.Printf("Starting auth-service on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
