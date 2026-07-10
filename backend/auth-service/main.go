package main

import (
    "net/http"
    "github.com/gin-gonic/gin"
)

func main() {
    r := gin.Default()
    r.GET("/health", func(c *gin.Context) {
        c.JSON(http.StatusOK, gin.H{"status": "UP"})
    })
    // TODO: add service-specific routes
    r.Run(":8080") // listen and serve on 0.0.0.0:8080
}
