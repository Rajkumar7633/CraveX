package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/zomato-clone/order-service/internal/config"
	"github.com/zomato-clone/order-service/internal/handlers"
	"github.com/zomato-clone/order-service/internal/messaging"
	"github.com/zomato-clone/order-service/internal/repository"
	"github.com/zomato-clone/order-service/internal/services"
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
	orderRepo := repository.NewOrderRepository(db)
	orderItemRepo := repository.NewOrderItemRepository(db)
	statusHistoryRepo := repository.NewOrderStatusHistoryRepository(db)

	// Initialize Kafka producer
	var kafkaProducer *messaging.KafkaProducer
	if cfg.KafkaURL != "" {
		var err error
		kafkaProducer, err = messaging.NewKafkaProducer([]string{cfg.KafkaURL})
		if err != nil {
			log.Printf("Warning: Failed to initialize Kafka producer: %v. Continuing without Kafka.", err)
		} else {
			defer kafkaProducer.Close()
		}
	}

	// Initialize services
	orderService := services.NewOrderService(orderRepo, orderItemRepo, statusHistoryRepo, kafkaProducer)

	// Initialize handlers
	orderHandler := handlers.NewOrderHandler(orderService)

	// Setup Gin router
	router := gin.Default()

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "healthy", "service": "order-service"})
	})

	// Public routes
	public := router.Group("/api/v1/orders")
	{
		public.GET("/:id", orderHandler.GetOrder)
		public.GET("/number/:order_number", orderHandler.GetOrderByNumber)
	}

	// Protected routes
	protected := router.Group("/api/v1/orders")
	// protected.Use(authMiddleware.Authenticate())
	{
		protected.POST("/", orderHandler.CreateOrder)
		protected.GET("/my", orderHandler.GetUserOrders)
		protected.GET("/restaurant/:restaurant_id", orderHandler.GetRestaurantOrders)
		protected.GET("/rider/my", orderHandler.GetRiderOrders)
		protected.PUT("/:id/status", orderHandler.UpdateOrderStatus)
		protected.POST("/:id/cancel", orderHandler.CancelOrder)
		protected.PUT("/:id/assign-rider", orderHandler.AssignRider)
	}

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8003"
	}

	log.Printf("Starting order-service on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
