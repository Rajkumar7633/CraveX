package models

import (
	"time"

	"github.com/google/uuid"
	"github.com/lib/pq"
	"gorm.io/gorm"
)

type Restaurant struct {
	ID                uuid.UUID      `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	UserID            uuid.UUID      `json:"user_id" gorm:"type:uuid;not null;index"`
	Name              string         `json:"name" gorm:"not null"`
	Slug              string         `json:"slug" gorm:"uniqueIndex;not null"`
	Description       string         `json:"description"`
	CuisineTypes      pq.StringArray `json:"cuisine_types" gorm:"type:text[]"`
	CoverImageURL     string         `json:"cover_image_url"`
	LogoURL           string         `json:"logo_url"`
	AddressLine1      string         `json:"address_line1" gorm:"not null"`
	AddressLine2      string         `json:"address_line2"`
	Landmark          string     `json:"landmark"`
	City              string     `json:"city" gorm:"not null"`
	State             string     `json:"state" gorm:"not null"`
	PostalCode        string     `json:"postal_code" gorm:"not null"`
	Country           string     `json:"country" gorm:"default:'India'"`
	Latitude          *float64   `json:"latitude"`
	Longitude         *float64   `json:"longitude"`
	Rating            float64    `json:"rating" gorm:"default:0.00"`
	TotalReviews      int        `json:"total_reviews" gorm:"default:0"`
	CostForTwo        *float64   `json:"cost_for_two"`
	AverageDeliveryTime *int     `json:"average_delivery_time"`
	IsPureVeg         bool       `json:"is_pure_veg" gorm:"default:false"`
	IsAvailable       bool       `json:"is_available" gorm:"default:true"`
	IsVerified        bool       `json:"is_verified" gorm:"default:false"`
	IsActive          bool       `json:"is_active" gorm:"default:true"`
	FSSAILicense       string     `json:"fssai_license"`
	GSTNumber         string     `json:"gst_number"`
	PANNumber         string     `json:"pan_number"`
	CommissionRate    float64    `json:"commission_rate" gorm:"default:15.00"`
	OperatingHours    string     `json:"operating_hours" gorm:"type:jsonb"`
	CreatedAt         time.Time  `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt         time.Time  `json:"updated_at" gorm:"autoUpdateTime"`
}

type MenuCategory struct {
	ID           uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	RestaurantID uuid.UUID `json:"restaurant_id" gorm:"type:uuid;not null;index"`
	Name         string    `json:"name" gorm:"not null"`
	Description  string    `json:"description"`
	DisplayOrder int       `json:"display_order" gorm:"default:0"`
	IsActive     bool      `json:"is_active" gorm:"default:true"`
	CreatedAt    time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt    time.Time `json:"updated_at" gorm:"autoUpdateTime"`
	Restaurant   Restaurant `json:"restaurant" gorm:"foreignKey:RestaurantID"`
}

type MenuItem struct {
	ID               uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	RestaurantID     uuid.UUID  `json:"restaurant_id" gorm:"type:uuid;not null;index"`
	CategoryID       *uuid.UUID `json:"category_id" gorm:"type:uuid;index"`
	Name             string     `json:"name" gorm:"not null"`
	Description      string     `json:"description"`
	ImageURL         string     `json:"image_url"`
	Price            float64    `json:"price" gorm:"not null"`
	OriginalPrice    *float64   `json:"original_price"`
	IsVegetarian     bool       `json:"is_vegetarian" gorm:"default:true"`
	IsAvailable      bool       `json:"is_available" gorm:"default:true"`
	IsFeatured       bool       `json:"is_featured" gorm:"default:false"`
	PreparationTime  *int       `json:"preparation_time"`
	SpiceLevel       string     `json:"spice_level"`
	ServingSize      string     `json:"serving_size"`
	Calories         *int       `json:"calories"`
	Allergens        pq.StringArray `json:"allergens" gorm:"type:text[]"`
	Customizations   string     `json:"customizations" gorm:"type:jsonb"`
	Rating           float64    `json:"rating" gorm:"default:0.00"`
	TotalOrders      int        `json:"total_orders" gorm:"default:0"`
	CreatedAt        time.Time  `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt        time.Time  `json:"updated_at" gorm:"autoUpdateTime"`
	Restaurant       Restaurant    `json:"restaurant" gorm:"foreignKey:RestaurantID"`
	Category         *MenuCategory `json:"category" gorm:"foreignKey:CategoryID"`
}

type RestaurantDocument struct {
	ID              uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	RestaurantID    uuid.UUID  `json:"restaurant_id" gorm:"type:uuid;not null;index"`
	DocumentType    string     `json:"document_type" gorm:"not null"`
	DocumentURL     string     `json:"document_url" gorm:"not null"`
	Status          string     `json:"status" gorm:"default:'pending'"`
	RejectionReason string     `json:"rejection_reason"`
	VerifiedAt      *time.Time `json:"verified_at"`
	VerifiedBy      *uuid.UUID `json:"verified_by" gorm:"type:uuid"`
	CreatedAt       time.Time  `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt       time.Time  `json:"updated_at" gorm:"autoUpdateTime"`
}

type CreateRestaurantRequest struct {
	Name           string   `json:"name" binding:"required"`
	Description    string   `json:"description"`
	CuisineTypes   []string `json:"cuisine_types"`
	AddressLine1   string   `json:"address_line1" binding:"required"`
	AddressLine2   string   `json:"address_line2"`
	Landmark       string   `json:"landmark"`
	City           string   `json:"city" binding:"required"`
	State          string   `json:"state" binding:"required"`
	PostalCode     string   `json:"postal_code" binding:"required"`
	Latitude       *float64 `json:"latitude"`
	Longitude      *float64 `json:"longitude"`
	CostForTwo     *float64 `json:"cost_for_two"`
	IsPureVeg      bool     `json:"is_pure_veg"`
	FSSAILicense   string   `json:"fssai_license"`
	GSTNumber      string   `json:"gst_number"`
	PANNumber      string   `json:"pan_number"`
	OperatingHours string   `json:"operating_hours"`
}

type UpdateRestaurantRequest struct {
	Name           *string   `json:"name"`
	Description    *string   `json:"description"`
	CuisineTypes   *[]string `json:"cuisine_types"`
	CoverImageURL  *string   `json:"cover_image_url"`
	LogoURL        *string   `json:"logo_url"`
	IsAvailable    *bool     `json:"is_available"`
	CostForTwo     *float64  `json:"cost_for_two"`
	OperatingHours *string   `json:"operating_hours"`
}

type CreateMenuCategoryRequest struct {
	Name         string `json:"name" binding:"required"`
	Description  string `json:"description"`
	DisplayOrder int    `json:"display_order"`
}

type CreateMenuItemRequest struct {
	CategoryID      *uuid.UUID `json:"category_id"`
	Name            string     `json:"name" binding:"required"`
	Description     string     `json:"description"`
	ImageURL        string     `json:"image_url"`
	Price           float64    `json:"price" binding:"required"`
	OriginalPrice   *float64   `json:"original_price"`
	IsVegetarian    bool       `json:"is_vegetarian"`
	IsAvailable     bool       `json:"is_available"`
	IsFeatured      bool       `json:"is_featured"`
	PreparationTime *int       `json:"preparation_time"`
	SpiceLevel      string     `json:"spice_level"`
	ServingSize     string     `json:"serving_size"`
	Calories        *int       `json:"calories"`
	Allergens       []string   `json:"allergens"`
	Customizations  string     `json:"customizations"`
}

type UpdateMenuItemRequest struct {
	CategoryID      *uuid.UUID `json:"category_id"`
	Name            *string    `json:"name"`
	Description     *string    `json:"description"`
	ImageURL        *string    `json:"image_url"`
	Price           *float64   `json:"price"`
	OriginalPrice   *float64   `json:"original_price"`
	IsVegetarian    *bool      `json:"is_vegetarian"`
	IsAvailable     *bool      `json:"is_available"`
	IsFeatured      *bool      `json:"is_featured"`
	PreparationTime *int       `json:"preparation_time"`
	SpiceLevel      *string    `json:"spice_level"`
	ServingSize     *string    `json:"serving_size"`
	Calories        *int       `json:"calories"`
	Allergens       []string   `json:"allergens"`
	Customizations  *string    `json:"customizations"`
}

// BeforeCreate hook for Restaurant
func (r *Restaurant) BeforeCreate(tx *gorm.DB) error {
	if r.ID == uuid.Nil {
		r.ID = uuid.New()
	}
	return nil
}

// BeforeCreate hook for MenuCategory
func (c *MenuCategory) BeforeCreate(tx *gorm.DB) error {
	if c.ID == uuid.Nil {
		c.ID = uuid.New()
	}
	return nil
}

// BeforeCreate hook for MenuItem
func (i *MenuItem) BeforeCreate(tx *gorm.DB) error {
	if i.ID == uuid.Nil {
		i.ID = uuid.New()
	}
	return nil
}
