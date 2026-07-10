package repository

import (
    "gorm.io/gorm"
)

// Restaurant model
type Restaurant struct {
    gorm.Model
    ID         string   `json:"id" gorm:"primaryKey"`
    Name       string   `json:"name"`
    Rating     float64  `json:"rating"`
    CostForTwo int      `json:"costForTwo"`
    DistanceKM float64  `json:"distanceKm"`
    ImageURL   string   `json:"imageUrl"`
    Cuisine    []string `json:"cuisine" gorm:"type:text[]"`
    IsOpen     bool     `json:"isOpen"`
}

// MenuCategory model
type MenuCategory struct {
    gorm.Model
    ID           string `json:"id" gorm:"primaryKey"`
    Name         string `json:"name"`
    RestaurantID string `json:"restaurantId"`
}

// MenuItem model
type MenuItem struct {
    gorm.Model
    ID          string   `json:"id" gorm:"primaryKey"`
    CategoryID  string   `json:"categoryId"`
    Name        string   `json:"name"`
    Description string   `json:"description"`
    Price       float64  `json:"price"`
    ImageURL    string   `json:"imageUrl"`
    Veg         bool     `json:"veg"`
    AddOns      []string `json:"addOns" gorm:"type:text[]"`
}

// Repository wraps the DB connection
type Repository struct {
    db *gorm.DB
}

// NewRepository creates a new repository instance
func NewRepository(db *gorm.DB) *Repository {
    return &Repository{db: db}
}

// GetAllRestaurants returns all restaurants
func (r *Repository) GetAllRestaurants() ([]Restaurant, error) {
    var restaurants []Restaurant
    if err := r.db.Find(&restaurants).Error; err != nil {
        return nil, err
    }
    return restaurants, nil
}

// GetMenuByRestaurant returns categories and items for a restaurant
func (r *Repository) GetMenuByRestaurant(restaurantID string) ([]MenuCategory, []MenuItem, error) {
    var categories []MenuCategory
    var items []MenuItem
    if err := r.db.Where("restaurant_id = ?", restaurantID).Find(&categories).Error; err != nil {
        return nil, nil, err
    }
    if err := r.db.Where("category_id IN (SELECT id FROM menu_categories WHERE restaurant_id = ?)", restaurantID).Find(&items).Error; err != nil {
        return nil, nil, err
    }
    return categories, items, nil
}
