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

type OrderStatus string

const (
    StatusPlaced    OrderStatus = "PLACED"
    StatusAccepted  OrderStatus = "ACCEPTED"
    StatusPreparing OrderStatus = "PREPARING"
    StatusReady     OrderStatus = "READY"
    StatusPickedUp  OrderStatus = "PICKED_UP"
    StatusDelivered OrderStatus = "DELIVERED"
    StatusCancelled OrderStatus = "CANCELLED"
)

type Order struct {
    gorm.Model
    ID           string      `json:"id" gorm:"primaryKey"`
    CustomerID   string      `json:"customerId"`
    RestaurantID string      `json:"restaurantId"`
    RiderID      string      `json:"riderId"`
    Status       OrderStatus `json:"status"`
    TotalAmount  float64     `json:"totalAmount"`
    DeliveryFee  float64     `json:"deliveryFee"`
    Tax          float64     `json:"tax"`
    Address      string      `json:"address"`
    Items        []OrderItem `json:"items" gorm:"foreignKey:OrderID"`
}

type OrderItem struct {
    gorm.Model
    OrderID        string  `json:"orderId"`
    MenuItemID     string  `json:"menuItemId"`
    Name           string  `json:"name"`
    Price          float64 `json:"price"`
    Quantity       int     `json:"quantity"`
    Customizations string  `json:"customizations"` // JSON or text representation
}

type CreateOrderRequest struct {
    CustomerID   string            `json:"customerId" binding:"required"`
    RestaurantID string            `json:"restaurantId" binding:"required"`
    Items        []CreateOrderItem `json:"items" binding:"required"`
    TotalAmount  float64           `json:"totalAmount" binding:"required"`
    Address      string            `json:"address" binding:"required"`
}

type CreateOrderItem struct {
    MenuItemID     string  `json:"menuItemId" binding:"required"`
    Name           string  `json:"name" binding:"required"`
    Price          float64 `json:"price" binding:"required"`
    Quantity       int     `json:"quantity" binding:"required"`
    Customizations string  `json:"customizations"`
}

type UpdateStatusRequest struct {
    Status  OrderStatus `json:"status" binding:"required"`
    RiderID string      `json:"riderId"`
}

func main() {
    dsn := os.Getenv("POSTGRES_DSN")
    if dsn == "" {
        dsn = "host=localhost user=postgres password=postgres dbname=order port=5432 sslmode=disable"
    }

    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
    if err != nil {
        log.Fatalf("failed to connect database: %v", err)
    }

    if err := db.AutoMigrate(&Order{}, &OrderItem{}); err != nil {
        log.Fatalf("auto migration failed: %v", err)
    }

    r := gin.Default()
    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "UP"})
    })

    // Create order
    r.POST("/orders", func(c *gin.Context) {
        var req CreateOrderRequest
        if err := c.ShouldBindJSON(&req); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }

        orderID := "ord_" + time.Now().Format("20060102150405")
        var orderItems []OrderItem
        for _, item := range req.Items {
            orderItems = append(orderItems, OrderItem{
                OrderID:        orderID,
                MenuItemID:     item.MenuItemID,
                Name:           item.Name,
                Price:          item.Price,
                Quantity:       item.Quantity,
                Customizations: item.Customizations,
            })
        }

        order := Order{
            ID:           orderID,
            CustomerID:   req.CustomerID,
            RestaurantID: req.RestaurantID,
            Status:       StatusPlaced,
            TotalAmount:  req.TotalAmount,
            DeliveryFee:  40.0, // default dummy delivery fee
            Tax:          req.TotalAmount * 0.05, // 5% tax
            Address:      req.Address,
            Items:        orderItems,
        }

        if err := db.Create(&order).Error; err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }

        c.JSON(http.StatusCreated, order)
    })

    // Get single order
    r.GET("/orders/:id", func(c *gin.Context) {
        id := c.Param("id")
        var order Order
        if err := db.Preload("Items").First(&order, "id = ?", id).Error; err != nil {
            c.JSON(http.StatusNotFound, gin.H{"error": "order not found"})
            return
        }
        c.JSON(http.StatusOK, order)
    })

    // List orders for customer / restaurant / rider
    r.GET("/orders", func(c *gin.Context) {
        customerID := c.Query("customerId")
        restaurantID := c.Query("restaurantId")
        riderID := c.Query("riderId")

        var orders []Order
        query := db.Preload("Items")

        if customerID != "" {
            query = query.Where("customer_id = ?", customerID)
        }
        if restaurantID != "" {
            query = query.Where("restaurant_id = ?", restaurantID)
        }
        if riderID != "" {
            query = query.Where("rider_id = ?", riderID)
        }

        if err := query.Order("created_at desc").Find(&orders).Error; err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }
        c.JSON(http.StatusOK, orders)
    })

    // Update order status/rider assignment
    r.PATCH("/orders/:id/status", func(c *gin.Context) {
        id := c.Param("id")
        var req UpdateStatusRequest
        if err := c.ShouldBindJSON(&req); err != nil {
            c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
            return
        }

        var order Order
        if err := db.First(&order, "id = ?", id).Error; err != nil {
            c.JSON(http.StatusNotFound, gin.H{"error": "order not found"})
            return
        }

        order.Status = req.Status
        if req.RiderID != "" {
            order.RiderID = req.RiderID
        }

        if err := db.Save(&order).Error; err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }

        c.JSON(http.StatusOK, order)
    })

    r.Run(":8082")
}
