package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/zomato-clone/restaurant-service/internal/cache"
	"github.com/zomato-clone/restaurant-service/internal/config"
	"github.com/zomato-clone/restaurant-service/internal/handlers"
	"github.com/zomato-clone/restaurant-service/internal/repository"
	"github.com/zomato-clone/restaurant-service/internal/services"
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
	restaurantRepo := repository.NewRestaurantRepository(db)
	categoryRepo := repository.NewMenuCategoryRepository(db)
	itemRepo := repository.NewMenuItemRepository(db)

	// Initialize Redis cache service
	cacheService, err := cache.NewCacheService(cfg.RedisURL)
	if err != nil {
		log.Fatalf("Failed to initialize Redis cache service: %v", err)
	}

	// Initialize services
	restaurantService := services.NewRestaurantService(restaurantRepo, cacheService)
	menuService := services.NewMenuService(categoryRepo, itemRepo, cacheService)

	// Initialize handlers
	restaurantHandler := handlers.NewRestaurantHandler(restaurantService, menuService)

	// Setup Gin router
	router := gin.Default()

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "healthy", "service": "restaurant-service"})
	})

	// Public routes
	public := router.Group("/api/v1/restaurants")
	{
		public.GET("/search", restaurantHandler.SearchRestaurants)
		public.GET("/:id", restaurantHandler.GetRestaurant)
		public.GET("/:id/menu", restaurantHandler.GetMenuItems)
		public.GET("/:id/menu/:id", restaurantHandler.GetMenuItem)
		public.GET("/:id/menu/search", restaurantHandler.SearchMenuItems)
	}

	// Protected routes (restaurant owner)
	protected := router.Group("/api/v1/restaurants")
	// protected.Use(authMiddleware.Authenticate())
	{
		protected.POST("/", restaurantHandler.CreateRestaurant)
		protected.GET("/my", restaurantHandler.GetMyRestaurant)
		protected.PUT("/:id", restaurantHandler.UpdateRestaurant)
		protected.DELETE("/:id", restaurantHandler.DeleteRestaurant)
		
		// Menu categories
		protected.POST("/:id/categories", restaurantHandler.CreateCategory)
		protected.GET("/:id/categories", restaurantHandler.GetCategories)
		protected.PUT("/categories/:id", restaurantHandler.UpdateCategory)
		protected.DELETE("/categories/:id", restaurantHandler.DeleteCategory)
		
		// Menu items
		protected.POST("/:id/menu", restaurantHandler.CreateMenuItem)
		protected.PUT("/menu/:id", restaurantHandler.UpdateMenuItem)
		protected.DELETE("/menu/:id", restaurantHandler.DeleteMenuItem)
	}

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8002"
	}

	log.Printf("Starting restaurant-service on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
