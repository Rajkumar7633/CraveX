package restaurant

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
)

type Restaurant struct {
	ID                    uuid.UUID `json:"id"`
	Name                  string    `json:"name"`
	Description           string    `json:"description"`
	CuisineType           string    `json:"cuisine_type"`
	Address               string    `json:"address"`
	City                  string    `json:"city"`
	State                 string    `json:"state"`
	ZipCode               string    `json:"zip_code"`
	Latitude              float64   `json:"latitude"`
	Longitude             float64   `json:"longitude"`
	Phone                 string    `json:"phone"`
	Email                 string    `json:"email"`
	Website               string    `json:"website"`
	OpeningHours          string    `json:"opening_hours"`
	PriceRange            int       `json:"price_range"` // 1-4
	Rating                float64   `json:"rating"`
	ReviewCount           int       `json:"review_count"`
	IsVerified            bool      `json:"is_verified"`
	IsActive              bool      `json:"is_active"`
	IsFeatured            bool      `json:"is_featured"`
	AverageDeliveryTime   int       `json:"average_delivery_time"`
	MinimumOrderAmount    float64   `json:"minimum_order_amount"`
	DeliveryFee           float64   `json:"delivery_fee"`
	FreeDeliveryThreshold float64   `json:"free_delivery_threshold"`
	OwnerID               uuid.UUID `json:"owner_id"`
	LogoURL               string    `json:"logo_url"`
	CoverImageURL         string    `json:"cover_image_url"`
	CreatedAt             time.Time `json:"created_at"`
	UpdatedAt             time.Time `json:"updated_at"`
}

type SearchFilters struct {
	CuisineType     []string `json:"cuisine_type"`
	City            string   `json:"city"`
	PriceRange      []int    `json:"price_range"`
	Rating          float64  `json:"rating"`
	IsVerified      *bool    `json:"is_verified"`
	IsFeatured      *bool    `json:"is_featured"`
	MaxDeliveryTime *int     `json:"max_delivery_time"`
	MinRating       float64  `json:"min_rating"`
	OpenNow         *bool    `json:"open_now"`
	SearchQuery     string   `json:"search_query"`
}

type LocationSearch struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
	RadiusKm  float64 `json:"radius_km"`
}

type PaginationParams struct {
	Page      int    `json:"page"`
	PageSize  int    `json:"page_size"`
	SortBy    string `json:"sort_by"`    // "rating", "distance", "delivery_time", "popularity"
	SortOrder string `json:"sort_order"` // "asc", "desc"
}

type PaginatedResult struct {
	Data       []Restaurant `json:"data"`
	Total      int64        `json:"total"`
	Page       int          `json:"page"`
	PageSize   int          `json:"page_size"`
	TotalPages int          `json:"total_pages"`
	HasNext    bool         `json:"has_next"`
	HasPrev    bool         `json:"has_prev"`
}

type RestaurantService struct {
	cacheService CacheService
}

type CacheService interface {
	GetRestaurantMenu(ctx context.Context, restaurantID string, dest interface{}) error
	SetRestaurantMenu(ctx context.Context, restaurantID string, menu interface{}, expiration time.Duration) error
	InvalidateRestaurantCache(ctx context.Context, restaurantID string) error
	Get(ctx context.Context, key string) (string, error)
	Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error
}

func NewRestaurantService(cacheService CacheService) *RestaurantService {
	return &RestaurantService{
		cacheService: cacheService,
	}
}

func (rs *RestaurantService) SearchRestaurants(ctx context.Context, filters *SearchFilters, location *LocationSearch, pagination *PaginationParams) (*PaginatedResult, error) {
	// Generate cache key
	cacheKey := rs.generateSearchCacheKey(filters, location, pagination)

	// Try cache first
	var cachedResult PaginatedResult
	if _, err := rs.cacheService.Get(ctx, cacheKey); err == nil {
		return &cachedResult, nil
	}

	// Build query
	query := rs.buildSearchQuery(filters, location, pagination)

	// Execute query
	restaurants, total, err := rs.executeSearchQuery(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to execute search query: %w", err)
	}

	// Calculate pagination
	totalPages := int(math.Ceil(float64(total) / float64(pagination.PageSize)))
	result := &PaginatedResult{
		Data:       restaurants,
		Total:      total,
		Page:       pagination.Page,
		PageSize:   pagination.PageSize,
		TotalPages: totalPages,
		HasNext:    pagination.Page < totalPages,
		HasPrev:    pagination.Page > 1,
	}

	// Cache result for 5 minutes
	rs.cacheService.Set(ctx, cacheKey, result, 5*time.Minute)

	return result, nil
}

func (rs *RestaurantService) GetRestaurantByID(ctx context.Context, id uuid.UUID) (*Restaurant, error) {
	cacheKey := fmt.Sprintf("restaurant:%s", id.String())

	// Try cache first
	var cachedRestaurant Restaurant
	if _, err := rs.cacheService.Get(ctx, cacheKey); err == nil {
		return &cachedRestaurant, nil
	}

	// Fetch from database
	restaurant, err := rs.fetchRestaurantFromDB(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch restaurant: %w", err)
	}

	// Cache for 1 hour
	rs.cacheService.Set(ctx, cacheKey, restaurant, 1*time.Hour)

	return restaurant, nil
}

func (rs *RestaurantService) GetNearbyRestaurants(ctx context.Context, latitude, longitude, radiusKm float64, pagination *PaginationParams) (*PaginatedResult, error) {
	// Calculate bounding box
	_, _, _, _ = rs.calculateBoundingBox(latitude, longitude, radiusKm)

	filters := &SearchFilters{
		// Add location-based filters
	}

	location := &LocationSearch{
		Latitude:  latitude,
		Longitude: longitude,
		RadiusKm:  radiusKm,
	}

	return rs.SearchRestaurants(ctx, filters, location, pagination)
}

func (rs *RestaurantService) GetPopularRestaurants(ctx context.Context, city string, pagination *PaginationParams) (*PaginatedResult, error) {
	filters := &SearchFilters{
		City:       city,
		IsFeatured: boolPtr(true),
		Rating:     4.0,
	}

	pagination.SortBy = "popularity"
	pagination.SortOrder = "desc"

	return rs.SearchRestaurants(ctx, filters, nil, pagination)
}

func (rs *RestaurantService) GetTopRatedRestaurants(ctx context.Context, city string, pagination *PaginationParams) (*PaginatedResult, error) {
	filters := &SearchFilters{
		City:      city,
		MinRating: 4.5,
	}

	pagination.SortBy = "rating"
	pagination.SortOrder = "desc"

	return rs.SearchRestaurants(ctx, filters, nil, pagination)
}

func (rs *RestaurantService) CreateRestaurant(ctx context.Context, restaurant *Restaurant) (*Restaurant, error) {
	// Validate restaurant data
	if err := rs.validateRestaurant(restaurant); err != nil {
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	// Set default values
	restaurant.ID = uuid.New()
	restaurant.CreatedAt = time.Now()
	restaurant.UpdatedAt = time.Now()
	restaurant.IsActive = true
	restaurant.IsVerified = false

	// Save to database
	if err := rs.saveRestaurantToDB(ctx, restaurant); err != nil {
		return nil, fmt.Errorf("failed to save restaurant: %w", err)
	}

	// Invalidate cache
	rs.cacheService.InvalidateRestaurantCache(ctx, restaurant.ID.String())

	return restaurant, nil
}

func (rs *RestaurantService) UpdateRestaurant(ctx context.Context, id uuid.UUID, updates *Restaurant) (*Restaurant, error) {
	// Get existing restaurant
	existing, err := rs.GetRestaurantByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to get existing restaurant: %w", err)
	}

	// Apply updates
	rs.applyUpdates(existing, updates)
	existing.UpdatedAt = time.Now()

	// Save to database
	if err := rs.updateRestaurantInDB(ctx, existing); err != nil {
		return nil, fmt.Errorf("failed to update restaurant: %w", err)
	}

	// Invalidate cache
	rs.cacheService.InvalidateRestaurantCache(ctx, id.String())

	return existing, nil
}

func (rs *RestaurantService) DeleteRestaurant(ctx context.Context, id uuid.UUID) error {
	// Soft delete
	if err := rs.softDeleteRestaurant(ctx, id); err != nil {
		return fmt.Errorf("failed to delete restaurant: %w", err)
	}

	// Invalidate cache
	rs.cacheService.InvalidateRestaurantCache(ctx, id.String())

	return nil
}

func (rs *RestaurantService) UpdateRating(ctx context.Context, id uuid.UUID, newRating float64) error {
	restaurant, err := rs.GetRestaurantByID(ctx, id)
	if err != nil {
		return fmt.Errorf("failed to get restaurant: %w", err)
	}

	// Calculate new average rating
	restaurant.Rating = (restaurant.Rating*float64(restaurant.ReviewCount) + newRating) / float64(restaurant.ReviewCount+1)
	restaurant.ReviewCount++
	restaurant.UpdatedAt = time.Now()

	// Update in database
	if err := rs.updateRestaurantInDB(ctx, restaurant); err != nil {
		return fmt.Errorf("failed to update rating: %w", err)
	}

	// Invalidate cache
	rs.cacheService.InvalidateRestaurantCache(ctx, id.String())

	return nil
}

func (rs *RestaurantService) generateSearchCacheKey(filters *SearchFilters, location *LocationSearch, pagination *PaginationParams) string {
	return fmt.Sprintf("search:%v:%v:%v", filters, location, pagination)
}

func (rs *RestaurantService) buildSearchQuery(filters *SearchFilters, location *LocationSearch, pagination *PaginationParams) string {
	// Build complex SQL query with filters, location search, and sorting
	// This would be implemented with an ORM or raw SQL
	return "SELECT * FROM restaurants WHERE ..."
}

func (rs *RestaurantService) executeSearchQuery(ctx context.Context, query string) ([]Restaurant, int64, error) {
	// Execute query and return results
	return []Restaurant{}, 0, nil
}

func (rs *RestaurantService) fetchRestaurantFromDB(ctx context.Context, id uuid.UUID) (*Restaurant, error) {
	// Fetch from database
	return &Restaurant{}, nil
}

func (rs *RestaurantService) saveRestaurantToDB(ctx context.Context, restaurant *Restaurant) error {
	// Save to database
	return nil
}

func (rs *RestaurantService) updateRestaurantInDB(ctx context.Context, restaurant *Restaurant) error {
	// Update in database
	return nil
}

func (rs *RestaurantService) softDeleteRestaurant(ctx context.Context, id uuid.UUID) error {
	// Soft delete in database
	return nil
}

func (rs *RestaurantService) validateRestaurant(restaurant *Restaurant) error {
	// Validate restaurant data
	if restaurant.Name == "" {
		return fmt.Errorf("restaurant name is required")
	}
	if restaurant.Address == "" {
		return fmt.Errorf("address is required")
	}
	if restaurant.Phone == "" {
		return fmt.Errorf("phone is required")
	}
	if restaurant.PriceRange < 1 || restaurant.PriceRange > 4 {
		return fmt.Errorf("price range must be between 1 and 4")
	}
	return nil
}

func (rs *RestaurantService) applyUpdates(existing, updates *Restaurant) {
	if updates.Name != "" {
		existing.Name = updates.Name
	}
	if updates.Description != "" {
		existing.Description = updates.Description
	}
	if updates.CuisineType != "" {
		existing.CuisineType = updates.CuisineType
	}
	if updates.Address != "" {
		existing.Address = updates.Address
	}
	if updates.Phone != "" {
		existing.Phone = updates.Phone
	}
	if updates.Email != "" {
		existing.Email = updates.Email
	}
	if updates.Website != "" {
		existing.Website = updates.Website
	}
	if updates.OpeningHours != "" {
		existing.OpeningHours = updates.OpeningHours
	}
	if updates.PriceRange > 0 {
		existing.PriceRange = updates.PriceRange
	}
	if updates.LogoURL != "" {
		existing.LogoURL = updates.LogoURL
	}
	if updates.CoverImageURL != "" {
		existing.CoverImageURL = updates.CoverImageURL
	}
}

func (rs *RestaurantService) calculateBoundingBox(latitude, longitude, radiusKm float64) (minLat, maxLat, minLon, maxLon float64) {
	// Calculate bounding box for location-based search
	// Using Haversine formula approximation
	latDelta := radiusKm / 111.0 // 1 degree latitude ≈ 111 km
	lonDelta := radiusKm / (111.0 * math.Cos(degreesToRadians(latitude)))

	minLat = latitude - latDelta
	maxLat = latitude + latDelta
	minLon = longitude - lonDelta
	maxLon = longitude + lonDelta

	return minLat, maxLat, minLon, maxLon
}

func degreesToRadians(degrees float64) float64 {
	return degrees * (math.Pi / 180)
}

func (rs *RestaurantService) calculateDistance(lat1, lon1, lat2, lon2 float64) float64 {
	// Calculate distance between two points using Haversine formula
	const earthRadius = 6371.0 // km

	lat1Rad := degreesToRadians(lat1)
	lat2Rad := degreesToRadians(lat2)
	deltaLat := degreesToRadians(lat2 - lat1)
	deltaLon := degreesToRadians(lon2 - lon1)

	a := math.Sin(deltaLat/2)*math.Sin(deltaLat/2) +
		math.Cos(lat1Rad)*math.Cos(lat2Rad)*
			math.Sin(deltaLon/2)*math.Sin(deltaLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	return earthRadius * c
}

func boolPtr(b bool) *bool {
	return &b
}
