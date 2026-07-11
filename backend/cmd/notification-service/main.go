package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/zomato-clone/notification-service/internal/config"
	"github.com/zomato-clone/notification-service/internal/handlers"
	"github.com/zomato-clone/notification-service/internal/repository"
	"github.com/zomato-clone/notification-service/internal/services"
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
	notificationRepo := repository.NewNotificationRepository(db)
	preferenceRepo := repository.NewNotificationPreferenceRepository(db)

	// Initialize services
	notificationService := services.NewNotificationService(notificationRepo)
	preferenceService := services.NewNotificationPreferenceService(preferenceRepo)

	// Initialize handlers
	notificationHandler := handlers.NewNotificationHandler(notificationService, preferenceService)

	// Setup Gin router
	router := gin.Default()

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "healthy", "service": "notification-service"})
	})

	// Public routes
	public := router.Group("/api/v1/notifications")
	{
		public.GET("/:id", notificationHandler.GetNotification)
	}

	// Protected routes
	protected := router.Group("/api/v1")
	// protected.Use(authMiddleware.Authenticate())
	{
		// Notification routes
		protected.POST("/notifications", notificationHandler.SendNotification)
		protected.POST("/notifications/bulk", notificationHandler.SendBulkNotification)
		protected.GET("/notifications/my", notificationHandler.GetUserNotifications)
		protected.PUT("/notifications/:id/read", notificationHandler.MarkAsRead)
		protected.PUT("/notifications/read-all", notificationHandler.MarkAllAsRead)
		protected.DELETE("/notifications/:id", notificationHandler.DeleteNotification)
		
		// Preference routes
		protected.GET("/notifications/preferences", notificationHandler.GetPreferences)
		protected.PUT("/notifications/preferences", notificationHandler.UpdatePreferences)
	}

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8006"
	}

	log.Printf("Starting notification-service on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
