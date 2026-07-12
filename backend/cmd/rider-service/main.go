package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/zomato-clone/rider-service/internal/handlers"
	"github.com/zomato-clone/rider-service/internal/repository"
	"github.com/zomato-clone/rider-service/internal/services"
)

func main() {
	// Load database URL from environment or fallback
	dbURL := os.Getenv("DATABASE_URL")
	if dbURL == "" {
		dbURL = "postgres://postgres:Raj@76330Raj@localhost:5432/cravex?sslmode=disable"
	}

	// Initialize database
	db, err := repository.InitDB(dbURL)
	if err != nil {
		log.Fatalf("Failed to connect to database: %v", err)
	}

	// Initialize repositories
	riderRepo := repository.NewRiderRepository(db)
	earningRepo := repository.NewRiderEarningRepository(db)

	// Initialize services
	riderService := services.NewRiderService(riderRepo)
	earningService := services.NewRiderEarningService(earningRepo, riderRepo)

	// Initialize handlers
	riderHandler := handlers.NewRiderHandler(riderService, earningService)

	// Setup Gin router
	router := gin.Default()

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "healthy", "service": "rider-service"})
	})

	// Public routes
	public := router.Group("/api/v1/riders")
	{
		public.GET("/:id", riderHandler.GetRider)
		public.GET("/nearby", riderHandler.FindAvailableNearby)
		public.GET("/:id/track", riderHandler.TrackRiderLocation)
	}

	// Protected routes
	protected := router.Group("/api/v1/riders")
	// protected.Use(authMiddleware.Authenticate())
	{
		protected.POST("/", riderHandler.CreateRider)
		protected.GET("/profile", riderHandler.GetMyProfile)
		protected.PUT("/", riderHandler.UpdateRider)
		protected.PUT("/location", riderHandler.UpdateLocation)
		protected.PUT("/online", riderHandler.ToggleOnlineStatus)
		protected.PUT("/availability", riderHandler.UpdateAvailability)
		protected.GET("/:id/earnings", riderHandler.GetEarnings)
		protected.GET("/:id/earnings/total", riderHandler.GetTotalEarnings)
	}

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8004"
	}

	log.Printf("Starting rider-service on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
