package main

import (
    "log"
    "net/http"
    "os"

    "github.com/gin-gonic/gin"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"
)

type Rider struct {
    gorm.Model
    ID           string  `json:"id" gorm:"primaryKey"`
    UserID       string  `json:"userId"`
    Name         string  `json:"name"`
    Phone        string  `json:"phone"`
    VehicleType  string  `json:"vehicleType"`  // bike, bicycle, car
    VehicleNo    string  `json:"vehicleNo"`
    IsOnline     bool    `json:"isOnline"`
    IsAvailable  bool    `json:"isAvailable"` // not busy with order
    Latitude     float64 `json:"latitude"`
    Longitude    float64 `json:"longitude"`
    Rating       float64 `json:"rating"`
    TotalOrders  int     `json:"totalOrders"`
    TotalEarnings float64 `json:"totalEarnings"`
}

type RegisterRequest struct {
    UserID      string `json:"userId" binding:"required"`
    Name        string `json:"name" binding:"required"`
    Phone       string `json:"phone" binding:"required"`
    VehicleType string `json:"vehicleType" binding:"required"`
    VehicleNo   string `json:"vehicleNo" binding:"required"`
}

type UpdateLocationRequest struct {
    Latitude  float64 `json:"latitude" binding:"required"`
    Longitude float64 `json:"longitude" binding:"required"`
}

type UpdateAvailabilityRequest struct {
    IsOnline bool `json:"isOnline"`
}

func main() {
    dsn := os.Getenv("POSTGRES_DSN")
    if dsn == "" {
        dsn = "host=localhost user=postgres password=postgres dbname=rider port=5432 sslmode=disable"
    }

    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
    if err != nil {
        log.Fatalf("failed to connect database: %v", err)
    }

    if err := db.AutoMigrate(&Rider{}); err != nil {
        log.Fatalf("auto migration failed: %v", err)
    }

    r := gin.Default()
    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "UP"})
    })

    // Register rider
    r.POST("/riders/register", func(c *gin.Context) {
        var req RegisterRequest
        if err := c.ShouldBindJSON(&req); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }

        rider := Rider{
            ID:           "rider_" + req.UserID,
            UserID:       req.UserID,
            Name:         req.Name,
            Phone:        req.Phone,
            VehicleType:  req.VehicleType,
            VehicleNo:    req.VehicleNo,
            IsOnline:     false,
            IsAvailable:  true,
            Latitude:     0.0,
            Longitude:    0.0,
            Rating:       5.0,
            TotalOrders:  0,
            TotalEarnings: 0.0,
        }

        if err := db.Create(&rider).Error; err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }

        c.JSON(http.StatusCreated, rider)
    })

    // Get rider info
    r.GET("/riders/:id", func(c *gin.Context) {
        id := c.Param("id")
        var rider Rider
        if err := db.First(&rider, "id = ? OR user_id = ?", id, id).Error; err != nil {
            c.JSON(http.StatusNotFound, gin.H{"error": "rider not found"})
            return
        }
        c.JSON(http.StatusOK, rider)
    })

    // Update location
    r.PATCH("/riders/:id/location", func(c *gin.Context) {
        id := c.Param("id")
        var req UpdateLocationRequest
        if err := c.ShouldBindJSON(&req); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }

        var rider Rider
        if err := db.First(&rider, "id = ? OR user_id = ?", id, id).Error; err != nil {
            c.JSON(http.StatusNotFound, gin.H{"error": "rider not found"})
            return
        }

        rider.Latitude = req.Latitude
        rider.Longitude = req.Longitude
        if err := db.Save(&rider).Error; err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }

        c.JSON(http.StatusOK, rider)
    })

    // Update availability
    r.PATCH("/riders/:id/availability", func(c *gin.Context) {
        id := c.Param("id")
        var req UpdateAvailabilityRequest
        if err := c.ShouldBindJSON(&req); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }

        var rider Rider
        if err := db.First(&rider, "id = ? OR user_id = ?", id, id).Error; err != nil {
            c.JSON(http.StatusNotFound, gin.H{"error": "rider not found"})
            return
        }

        rider.IsOnline = req.IsOnline
        if err := db.Save(&rider).Error; err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }

        c.JSON(http.StatusOK, rider)
    })

    // Get nearby active riders (dummy proximity calculation or just get all online)
    r.GET("/riders/near", func(c *gin.Context) {
        var riders []Rider
        if err := db.Where("is_online = ? AND is_available = ?", true, true).Find(&riders).Error; err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }
        c.JSON(http.StatusOK, riders)
    })

    r.Run(":8084")
}
