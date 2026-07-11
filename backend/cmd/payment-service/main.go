package main

import (
	"log"
	"os"

	"github.com/gin-gonic/gin"
	"github.com/zomato-clone/payment-service/internal/config"
	"github.com/zomato-clone/payment-service/internal/handlers"
	"github.com/zomato-clone/payment-service/internal/repository"
	"github.com/zomato-clone/payment-service/internal/services"
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
	paymentRepo := repository.NewPaymentRepository(db)
	walletRepo := repository.NewWalletRepository(db)
	transactionRepo := repository.NewWalletTransactionRepository(db)

	// Initialize services
	paymentService := services.NewPaymentService(paymentRepo)
	walletService := services.NewWalletService(walletRepo, transactionRepo)

	// Initialize handlers
	paymentHandler := handlers.NewPaymentHandler(paymentService, walletService)

	// Setup Gin router
	router := gin.Default()

	// Health check
	router.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{"status": "healthy", "service": "payment-service"})
	})

	// Public routes
	public := router.Group("/api/v1/payments")
	{
		public.GET("/:id", paymentHandler.GetPayment)
		public.GET("/order/:order_id", paymentHandler.GetPaymentByOrderID)
	}

	// Protected routes
	protected := router.Group("/api/v1")
	// protected.Use(authMiddleware.Authenticate())
	{
		// Payment routes
		protected.POST("/payments", paymentHandler.CreatePayment)
		protected.GET("/payments/my", paymentHandler.GetUserPayments)
		protected.POST("/payments/:id/process", paymentHandler.ProcessPayment)
		protected.POST("/payments/:id/refund", paymentHandler.RefundPayment)
		
		// Wallet routes
		protected.GET("/wallet", paymentHandler.GetWallet)
		protected.POST("/wallet/add", paymentHandler.AddFunds)
		protected.POST("/wallet/withdraw", paymentHandler.WithdrawFunds)
		protected.GET("/wallet/transactions", paymentHandler.GetTransactions)
	}

	// Start server
	port := os.Getenv("PORT")
	if port == "" {
		port = "8005"
	}

	log.Printf("Starting payment-service on port %s", port)
	if err := router.Run(":" + port); err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
