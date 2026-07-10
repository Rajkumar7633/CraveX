package main

import (
    "log"
    "net/http"
    "os"

    "github.com/gin-gonic/gin"
    "gorm.io/driver/postgres"
    "gorm.io/gorm"

    "restaurant-service/repository"
    "restaurant-service/handlers"
)

func main() {
    // Load DB config from environment
    dsn := os.Getenv("POSTGRES_DSN")
    if dsn == "" {
        // Default development DSN
        dsn = "host=localhost user=postgres password=postgres dbname=restaurant port=5432 sslmode=disable"
    }

    db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
    if err != nil {
        log.Fatalf("failed to connect database: %v", err)
    }

    // Auto-migrate models
    if err := db.AutoMigrate(&repository.Restaurant{}, &repository.MenuCategory{}, &repository.MenuItem{}); err != nil {
        log.Fatalf("auto migration failed: %v", err)
    }

    repo := repository.NewRepository(db)

    r := gin.Default()
    r.GET("/health", func(c *gin.Context) { c.JSON(http.StatusOK, gin.H{"status": "UP"}) })
    // Register handlers using the repository
    r.GET("/restaurants", handlers.GetRestaurants(repo))
    r.GET("/restaurants/:id/menu", handlers.GetMenu(repo))

    r.Run(":8081")
}
