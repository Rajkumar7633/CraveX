package handlers

import (
    "net/http"

    "github.com/gin-gonic/gin"
    "restaurant-service/repository"
)

// GetRestaurants returns a handler that lists all restaurants.
func GetRestaurants(repo *repository.Repository) gin.HandlerFunc {
    return func(c *gin.Context) {
        restaurants, err := repo.GetAllRestaurants()
        if err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }
        c.JSON(http.StatusOK, restaurants)
    }
}

// menuResponse defines the JSON structure for a menu request.
type menuResponse struct {
    Categories []repository.MenuCategory `json:"categories"`
    Items      []repository.MenuItem      `json:"items"`
}

// GetMenu returns a handler that fetches menu categories and items for a restaurant.
func GetMenu(repo *repository.Repository) gin.HandlerFunc {
    return func(c *gin.Context) {
        restaurantID := c.Param("id")
        categories, items, err := repo.GetMenuByRestaurant(restaurantID)
        if err != nil {
            c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
            return
        }
        c.JSON(http.StatusOK, menuResponse{Categories: categories, Items: items})
    }
}
