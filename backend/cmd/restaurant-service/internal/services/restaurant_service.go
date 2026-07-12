package services

import (
	"context"
	"errors"
	"fmt"
	"log"
	"strings"
	"time"

	"github.com/google/uuid"
	"github.com/zomato-clone/restaurant-service/internal/cache"
	"github.com/zomato-clone/restaurant-service/internal/models"
	"github.com/zomato-clone/restaurant-service/internal/repository"
)

type RestaurantService interface {
	CreateRestaurant(userID uuid.UUID, req *models.CreateRestaurantRequest) (*models.Restaurant, error)
	GetRestaurant(id uuid.UUID) (*models.Restaurant, error)
	GetRestaurantByUserID(userID uuid.UUID) (*models.Restaurant, error)
	UpdateRestaurant(id uuid.UUID, req *models.UpdateRestaurantRequest) error
	DeleteRestaurant(id uuid.UUID) error
	SearchRestaurants(query string, cuisine string, lat, lng float64, radiusKm float64) ([]*models.Restaurant, error)
}

type restaurantService struct {
	restaurantRepo repository.RestaurantRepository
	cacheService   cache.CacheService
}

func NewRestaurantService(restaurantRepo repository.RestaurantRepository, cacheService cache.CacheService) RestaurantService {
	return &restaurantService{
		restaurantRepo: restaurantRepo,
		cacheService:   cacheService,
	}
}

func (s *restaurantService) CreateRestaurant(userID uuid.UUID, req *models.CreateRestaurantRequest) (*models.Restaurant, error) {
	// Check if user already has a restaurant
	existingRestaurant, _ := s.restaurantRepo.FindByUserID(userID)
	if existingRestaurant != nil {
		return nil, errors.New("user already has a restaurant")
	}

	// Generate slug from name
	slug := generateSlug(req.Name)

	// Create restaurant
	restaurant := &models.Restaurant{
		UserID:         userID,
		Name:           req.Name,
		Slug:           slug,
		Description:    req.Description,
		CuisineTypes:   req.CuisineTypes,
		AddressLine1:   req.AddressLine1,
		AddressLine2:   req.AddressLine2,
		Landmark:       req.Landmark,
		City:           req.City,
		State:          req.State,
		PostalCode:     req.PostalCode,
		Latitude:       req.Latitude,
		Longitude:      req.Longitude,
		CostForTwo:     req.CostForTwo,
		IsPureVeg:      req.IsPureVeg,
		FSSAILicense:   req.FSSAILicense,
		GSTNumber:      req.GSTNumber,
		PANNumber:      req.PANNumber,
		OperatingHours: req.OperatingHours,
		IsAvailable:    true,
		IsActive:       true,
		IsVerified:     false,
		CommissionRate: 15.00,
	}

	if err := s.restaurantRepo.Create(restaurant); err != nil {
		return nil, err
	}

	return restaurant, nil
}

func (s *restaurantService) GetRestaurant(id uuid.UUID) (*models.Restaurant, error) {
	return s.restaurantRepo.FindByID(id)
}

func (s *restaurantService) GetRestaurantByUserID(userID uuid.UUID) (*models.Restaurant, error) {
	return s.restaurantRepo.FindByUserID(userID)
}

func (s *restaurantService) UpdateRestaurant(id uuid.UUID, req *models.UpdateRestaurantRequest) error {
	restaurant, err := s.restaurantRepo.FindByID(id)
	if err != nil {
		return err
	}

	// Update fields if provided
	if req.Name != nil {
		restaurant.Name = *req.Name
		restaurant.Slug = generateSlug(*req.Name)
	}
	if req.Description != nil {
		restaurant.Description = *req.Description
	}
	if req.CuisineTypes != nil {
		restaurant.CuisineTypes = *req.CuisineTypes
	}
	if req.CoverImageURL != nil {
		restaurant.CoverImageURL = *req.CoverImageURL
	}
	if req.LogoURL != nil {
		restaurant.LogoURL = *req.LogoURL
	}
	if req.IsAvailable != nil {
		restaurant.IsAvailable = *req.IsAvailable
	}
	if req.CostForTwo != nil {
		restaurant.CostForTwo = req.CostForTwo
	}
	if req.OperatingHours != nil {
		restaurant.OperatingHours = *req.OperatingHours
	}

	return s.restaurantRepo.Update(restaurant)
}

func (s *restaurantService) DeleteRestaurant(id uuid.UUID) error {
	return s.restaurantRepo.Delete(id)
}

func (s *restaurantService) SearchRestaurants(query string, cuisine string, lat, lng float64, radiusKm float64) ([]*models.Restaurant, error) {
	var restaurants []*models.Restaurant
	var err error

	// Cache read path: check Redis if searching nearby
	var cacheKey string
	if lat != 0 && lng != 0 && query == "" && cuisine == "" {
		cacheKey = fmt.Sprintf("restaurants:nearby:%.2f:%.2f:%.1f", lat, lng, radiusKm)
		err = s.cacheService.Get(context.Background(), cacheKey, &restaurants)
		if err == nil {
			log.Printf("[Cache Hit] Found nearby restaurants in spatial grid bucket")
			return restaurants, nil
		}
	}

	if cuisine != "" {
		restaurants, err = s.restaurantRepo.FindByCuisine(cuisine)
	} else if query != "" {
		restaurants, err = s.restaurantRepo.Search(query)
	} else if lat != 0 && lng != 0 {
		restaurants, err = s.restaurantRepo.FindNearby(lat, lng, radiusKm)
	} else {
		return nil, errors.New("please provide search criteria")
	}

	if err != nil {
		return nil, err
	}

	// Cache write path: store nearby lists for 2 mins (TTL per spec)
	if cacheKey != "" {
		_ = s.cacheService.Set(context.Background(), cacheKey, restaurants, 2*time.Minute)
	}

	return restaurants, nil
}

func generateSlug(name string) string {
	slug := strings.ToLower(name)
	slug = strings.ReplaceAll(slug, " ", "-")
	slug = strings.ReplaceAll(slug, "&", "and")
	slug = strings.ReplaceAll(slug, "/", "-")
	return slug
}

type MenuService interface {
	CreateCategory(restaurantID uuid.UUID, req *models.CreateMenuCategoryRequest) (*models.MenuCategory, error)
	GetCategories(restaurantID uuid.UUID) ([]*models.MenuCategory, error)
	UpdateCategory(id uuid.UUID, req *models.CreateMenuCategoryRequest) error
	DeleteCategory(id uuid.UUID) error
	CreateMenuItem(restaurantID uuid.UUID, req *models.CreateMenuItemRequest) (*models.MenuItem, error)
	GetMenuItems(restaurantID uuid.UUID) ([]*models.MenuItem, error)
	GetMenuItem(id uuid.UUID) (*models.MenuItem, error)
	UpdateMenuItem(id uuid.UUID, req *models.UpdateMenuItemRequest) error
	DeleteMenuItem(id uuid.UUID) error
	SearchMenuItems(query string, restaurantID uuid.UUID) ([]*models.MenuItem, error)
}

type menuService struct {
	categoryRepo repository.MenuCategoryRepository
	itemRepo     repository.MenuItemRepository
	cacheService cache.CacheService
}

func NewMenuService(categoryRepo repository.MenuCategoryRepository, itemRepo repository.MenuItemRepository, cacheService cache.CacheService) MenuService {
	return &menuService{
		categoryRepo: categoryRepo,
		itemRepo:     itemRepo,
		cacheService: cacheService,
	}
}

func (s *menuService) CreateCategory(restaurantID uuid.UUID, req *models.CreateMenuCategoryRequest) (*models.MenuCategory, error) {
	category := &models.MenuCategory{
		RestaurantID: restaurantID,
		Name:         req.Name,
		Description:  req.Description,
		DisplayOrder: req.DisplayOrder,
		IsActive:     true,
	}

	if err := s.categoryRepo.Create(category); err != nil {
		return nil, err
	}

	return category, nil
}

func (s *menuService) GetCategories(restaurantID uuid.UUID) ([]*models.MenuCategory, error) {
	return s.categoryRepo.FindByRestaurantID(restaurantID)
}

func (s *menuService) UpdateCategory(id uuid.UUID, req *models.CreateMenuCategoryRequest) error {
	category, err := s.categoryRepo.FindByID(id)
	if err != nil {
		return err
	}

	category.Name = req.Name
	category.Description = req.Description
	category.DisplayOrder = req.DisplayOrder

	return s.categoryRepo.Update(category)
}

func (s *menuService) DeleteCategory(id uuid.UUID) error {
	return s.categoryRepo.Delete(id)
}

func (s *menuService) CreateMenuItem(restaurantID uuid.UUID, req *models.CreateMenuItemRequest) (*models.MenuItem, error) {
	item := &models.MenuItem{
		RestaurantID:    restaurantID,
		CategoryID:      req.CategoryID,
		Name:            req.Name,
		Description:     req.Description,
		ImageURL:        req.ImageURL,
		Price:           req.Price,
		OriginalPrice:   req.OriginalPrice,
		IsVegetarian:    req.IsVegetarian,
		IsAvailable:     req.IsAvailable,
		IsFeatured:      req.IsFeatured,
		PreparationTime: req.PreparationTime,
		SpiceLevel:      req.SpiceLevel,
		ServingSize:     req.ServingSize,
		Calories:        req.Calories,
		Allergens:       req.Allergens,
		Customizations:  req.Customizations,
		Rating:          0.00,
		TotalOrders:     0,
	}

	if err := s.itemRepo.Create(item); err != nil {
		return nil, err
	}

	// Write-through: invalidate cached menu for this restaurant
	key := fmt.Sprintf("menu:restaurant:%s", restaurantID.String())
	_ = s.cacheService.Delete(context.Background(), key)

	return item, nil
}

func (s *menuService) GetMenuItems(restaurantID uuid.UUID) ([]*models.MenuItem, error) {
	key := fmt.Sprintf("menu:restaurant:%s", restaurantID.String())
	var items []*models.MenuItem
	err := s.cacheService.Get(context.Background(), key, &items)
	if err == nil {
		log.Printf("[Cache Hit] Fetched menu for restaurant %s from Redis", restaurantID)
		return items, nil
	}

	log.Printf("[Cache Miss] Fetching menu from DB for restaurant %s", restaurantID)
	items, err = s.itemRepo.FindByRestaurantID(restaurantID)
	if err != nil {
		return nil, err
	}

	// Cache menu for 5 minutes (TTL per spec)
	_ = s.cacheService.Set(context.Background(), key, items, 5*time.Minute)

	return items, nil
}

func (s *menuService) GetMenuItem(id uuid.UUID) (*models.MenuItem, error) {
	return s.itemRepo.FindByID(id)
}

func (s *menuService) UpdateMenuItem(id uuid.UUID, req *models.UpdateMenuItemRequest) error {
	item, err := s.itemRepo.FindByID(id)
	if err != nil {
		return err
	}

	if req.CategoryID != nil {
		item.CategoryID = req.CategoryID
	}
	if req.Name != nil {
		item.Name = *req.Name
	}
	if req.Description != nil {
		item.Description = *req.Description
	}
	if req.ImageURL != nil {
		item.ImageURL = *req.ImageURL
	}
	if req.Price != nil {
		item.Price = *req.Price
	}
	if req.OriginalPrice != nil {
		item.OriginalPrice = req.OriginalPrice
	}
	if req.IsVegetarian != nil {
		item.IsVegetarian = *req.IsVegetarian
	}
	if req.IsAvailable != nil {
		item.IsAvailable = *req.IsAvailable
	}
	if req.IsFeatured != nil {
		item.IsFeatured = *req.IsFeatured
	}
	if req.PreparationTime != nil {
		item.PreparationTime = req.PreparationTime
	}
	if req.SpiceLevel != nil {
		item.SpiceLevel = *req.SpiceLevel
	}
	if req.ServingSize != nil {
		item.ServingSize = *req.ServingSize
	}
	if req.Calories != nil {
		item.Calories = req.Calories
	}
	if len(req.Allergens) > 0 {
		item.Allergens = req.Allergens
	}
	if req.Customizations != nil {
		item.Customizations = *req.Customizations
	}

	if err := s.itemRepo.Update(item); err != nil {
		return err
	}

	// Write-through: invalidate cached menu
	key := fmt.Sprintf("menu:restaurant:%s", item.RestaurantID.String())
	_ = s.cacheService.Delete(context.Background(), key)

	return nil
}

func (s *menuService) DeleteMenuItem(id uuid.UUID) error {
	item, err := s.itemRepo.FindByID(id)
	if err != nil {
		return err
	}

	if err := s.itemRepo.Delete(id); err != nil {
		return err
	}

	// Write-through: invalidate cached menu
	key := fmt.Sprintf("menu:restaurant:%s", item.RestaurantID.String())
	_ = s.cacheService.Delete(context.Background(), key)

	return nil
}

func (s *menuService) SearchMenuItems(query string, restaurantID uuid.UUID) ([]*models.MenuItem, error) {
	return s.itemRepo.Search(query, restaurantID)
}
