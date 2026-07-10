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

type Notification struct {
    gorm.Model
    ID        string    `json:"id" gorm:"primaryKey"`
    UserID    string    `json:"userId"`
    Title     string    `json:"title"`
    Body      string    `json:"body"`
    SentAt    time.Time `json:"sentAt"`
    IsRead    bool      `json:"isRead"`
}

type SendNotificationRequest struct {
    UserID string `json:"userId" binding:"required"`
    Title  string `json:"title" binding:"required"`
    Body   string `json:"body" binding:"required"`
}

func main() {
    dsn := os.Getenv("POSTGRES_DSN")
    if dsn == "" {
        dsn = "host=localhost user=postgres password=postgres dbname=notification port=5432 sslmode=disable"
    }

    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
    if err != nil {
        log.Fatalf("failed to connect database: %v", err)
    }

    if err := db.AutoMigrate(&Notification{}); err != nil {
        log.Fatalf("auto migration failed: %v", err)
    }

    r := gin.Default()
    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "UP"})
    })

    // Send push notification
    r.POST("/notifications/send", func(c *gin.Context) {
        var req SendNotificationRequest
        if err := c.ShouldBindJSON(&req); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }

        notifID := "notif_" + time.Now().Format("20060102150405")
        notification := Notification{
            ID:     notifID,
            UserID: req.UserID,
            Title:  req.Title,
            Body:   req.Body,
            SentAt: time.Now(),
            IsRead: false,
        }

        if err := db.Create(&notification).Error; err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }

        // In a real system, we'd also fire an FCM call here.
        log.Printf("FCM Notification sent to user %s: [%s] %s", req.UserID, req.Title, req.Body)

        c.JSON(http.StatusOK, notification)
    })

    // List notifications for a user
    r.GET("/notifications", func(c *gin.Context) {
        userID := c.Query("userId")
        if userID == "" {
            c.JSON(http.StatusBadRequest, gin.H{"error": "userId query param is required"})
            return
        }

        var notifications []Notification
        if err := db.Where("user_id = ?", userID).Order("sent_at desc").Find(&notifications).Error; err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }
        c.JSON(http.StatusOK, notifications)
    })

    r.Run(":8085")
}
