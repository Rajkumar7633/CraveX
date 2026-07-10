package main

import (
    "log"
    "net/http"
    "os"
    "time"

    "github.com/gin-gonic/gin"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
)

type PaymentStatus string

const (
    StatusPending   PaymentStatus = "PENDING"
    StatusCompleted PaymentStatus = "COMPLETED"
    StatusFailed    PaymentStatus = "FAILED"
    StatusRefunded  PaymentStatus = "REFUNDED"
)

type Payment struct {
    gorm.Model
    ID            string        `json:"id" gorm:"primaryKey"`
    OrderID       string        `json:"orderId"`
    CustomerID    string        `json:"customerId"`
    Amount        float64       `json:"amount"`
    Currency      string        `json:"currency"`
    PaymentMethod string        `json:"paymentMethod"` // card, upi, cod, wallet
    Status        PaymentStatus `json:"status"`
    TransactionID string        `json:"transactionId"`
}

type ChargeRequest struct {
    OrderID       string  `json:"orderId" binding:"required"`
    CustomerID    string  `json:"customerId" binding:"required"`
    Amount        float64 `json:"amount" binding:"required"`
    Currency      string  `json:"currency" binding:"required"`
    PaymentMethod string  `json:"paymentMethod" binding:"required"`
}

type RefundRequest struct {
    PaymentID string `json:"paymentId" binding:"required"`
}

func main() {
    dsn := os.Getenv("POSTGRES_DSN")
    if dsn == "" {
        dsn = "host=localhost user=postgres password=postgres dbname=payment port=5432 sslmode=disable"
    }

    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
    if err != nil {
        log.Fatalf("failed to connect database: %v", err)
    }

    if err := db.AutoMigrate(&Payment{}); err != nil {
        log.Fatalf("auto migration failed: %v", err)
    }

    r := gin.Default()
    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "UP"})
    })

    // Charge / Initialize payment
    r.POST("/payments/charge", func(c *gin.Context) {
        var req ChargeRequest
        if err := c.ShouldBindJSON(&req); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }

        paymentID := "pay_" + time.Now().Format("20060102150405")
        status := StatusCompleted // Simulating instant success for convenience, except COD
        if req.PaymentMethod == "cod" {
            status = StatusPending
        }

        payment := Payment{
            ID:            paymentID,
            OrderID:       req.OrderID,
            CustomerID:    req.CustomerID,
            Amount:        req.Amount,
            Currency:      req.Currency,
            PaymentMethod: req.PaymentMethod,
            Status:        status,
            TransactionID: "txn_" + time.Now().Format("150405.000000"),
        }

        if err := db.Create(&payment).Error; err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }

        c.JSON(http.StatusOK, payment)
    })

    // Get payment status
    r.GET("/payments/:id", func(c *gin.Context) {
        id := c.Param("id")
        var payment Payment
        if err := db.First(&payment, "id = ?", id).Error; err != nil {
            c.JSON(http.StatusNotFound, gin.H{"error": "payment record not found"})
            return
        }
        c.JSON(http.StatusOK, payment)
    })

    // Refund endpoint
    r.POST("/payments/refund", func(c *gin.Context) {
        var req RefundRequest
        if err := c.ShouldBindJSON(&req); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }

        var payment Payment
        if err := db.First(&payment, "id = ?", req.PaymentID).Error; err != nil {
            c.JSON(http.StatusNotFound, gin.H{"error": "payment record not found"})
            return
        }

        payment.Status = StatusRefunded
        if err := db.Save(&payment).Error; err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }

        c.JSON(http.StatusOK, payment)
    })

    r.Run(":8083")
}
