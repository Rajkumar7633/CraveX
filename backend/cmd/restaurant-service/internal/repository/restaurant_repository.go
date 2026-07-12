package repository

import (
	"github.com/google/uuid"
	"github.com/zomato-clone/restaurant-service/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type RestaurantRepository interface {
	Create(restaurant *models.Restaurant) error
	FindByID(id uuid.UUID) (*models.Restaurant, error)
	FindByUserID(userID uuid.UUID) (*models.Restaurant, error)
	FindBySlug(slug string) (*models.Restaurant, error)
	Update(restaurant *models.Restaurant) error
	Delete(id uuid.UUID) error
	FindNearby(latitude, longitude float64, radiusKm float64) ([]*models.Restaurant, error)
	FindByCuisine(cuisine string) ([]*models.Restaurant, error)
	Search(query string) ([]*models.Restaurant, error)
}

type restaurantRepository struct {
	db *gorm.DB
}

func NewRestaurantRepository(db *gorm.DB) RestaurantRepository {
	return &restaurantRepository{db: db}
}

func (r *restaurantRepository) Create(restaurant *models.Restaurant) error {
	return r.db.Create(restaurant).Error
}

func (r *restaurantRepository) FindByID(id uuid.UUID) (*models.Restaurant, error) {
	var restaurant models.Restaurant
	err := r.db.Where("id = ?", id).First(&restaurant).Error
	if err != nil {
		return nil, err
	}
	return &restaurant, nil
}

func (r *restaurantRepository) FindByUserID(userID uuid.UUID) (*models.Restaurant, error) {
	var restaurant models.Restaurant
	err := r.db.Where("user_id = ?", userID).First(&restaurant).Error
	if err != nil {
		return nil, err
	}
	return &restaurant, nil
}

func (r *restaurantRepository) FindBySlug(slug string) (*models.Restaurant, error) {
	var restaurant models.Restaurant
	err := r.db.Where("slug = ?", slug).First(&restaurant).Error
	if err != nil {
		return nil, err
	}
	return &restaurant, nil
}

func (r *restaurantRepository) Update(restaurant *models.Restaurant) error {
	return r.db.Save(restaurant).Error
}

func (r *restaurantRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.Restaurant{}, "id = ?", id).Error
}

func (r *restaurantRepository) FindNearby(latitude, longitude float64, radiusKm float64) ([]*models.Restaurant, error) {
	var restaurants []*models.Restaurant
	radiusMeters := radiusKm * 1000.0
	err := r.db.Where("is_active = ? AND is_available = ?", true, true).
		Where("ST_DWithin(delivery_zone::geography, ST_SetSRID(ST_Point(?, ?), 4326)::geography, ?)", longitude, latitude, radiusMeters).
		Find(&restaurants).Error
	if err != nil {
		return nil, err
	}
	return restaurants, nil
}

func (r *restaurantRepository) FindByCuisine(cuisine string) ([]*models.Restaurant, error) {
	var restaurants []*models.Restaurant
	err := r.db.Where("? = ANY(cuisine_types)", cuisine).Find(&restaurants).Error
	if err != nil {
		return nil, err
	}
	return restaurants, nil
}

func (r *restaurantRepository) Search(query string) ([]*models.Restaurant, error) {
	var restaurants []*models.Restaurant
	err := r.db.Where("name ILIKE ? OR description ILIKE ?", "%"+query+"%", "%"+query+"%").Find(&restaurants).Error
	if err != nil {
		return nil, err
	}
	return restaurants, nil
}

type MenuCategoryRepository interface {
	Create(category *models.MenuCategory) error
	FindByID(id uuid.UUID) (*models.MenuCategory, error)
	FindByRestaurantID(restaurantID uuid.UUID) ([]*models.MenuCategory, error)
	Update(category *models.MenuCategory) error
	Delete(id uuid.UUID) error
}

type menuCategoryRepository struct {
	db *gorm.DB
}

func NewMenuCategoryRepository(db *gorm.DB) MenuCategoryRepository {
	return &menuCategoryRepository{db: db}
}

func (r *menuCategoryRepository) Create(category *models.MenuCategory) error {
	return r.db.Create(category).Error
}

func (r *menuCategoryRepository) FindByID(id uuid.UUID) (*models.MenuCategory, error) {
	var category models.MenuCategory
	err := r.db.Where("id = ?", id).First(&category).Error
	if err != nil {
		return nil, err
	}
	return &category, nil
}

func (r *menuCategoryRepository) FindByRestaurantID(restaurantID uuid.UUID) ([]*models.MenuCategory, error) {
	var categories []*models.MenuCategory
	err := r.db.Where("restaurant_id = ?", restaurantID).Order("display_order ASC").Find(&categories).Error
	if err != nil {
		return nil, err
	}
	return categories, nil
}

func (r *menuCategoryRepository) Update(category *models.MenuCategory) error {
	return r.db.Save(category).Error
}

func (r *menuCategoryRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.MenuCategory{}, "id = ?", id).Error
}

type MenuItemRepository interface {
	Create(item *models.MenuItem) error
	FindByID(id uuid.UUID) (*models.MenuItem, error)
	FindByRestaurantID(restaurantID uuid.UUID) ([]*models.MenuItem, error)
	FindByCategoryID(categoryID uuid.UUID) ([]*models.MenuItem, error)
	Update(item *models.MenuItem) error
	Delete(id uuid.UUID) error
	Search(query string, restaurantID uuid.UUID) ([]*models.MenuItem, error)
}

type menuItemRepository struct {
	db *gorm.DB
}

func NewMenuItemRepository(db *gorm.DB) MenuItemRepository {
	return &menuItemRepository{db: db}
}

func (r *menuItemRepository) Create(item *models.MenuItem) error {
	return r.db.Create(item).Error
}

func (r *menuItemRepository) FindByID(id uuid.UUID) (*models.MenuItem, error) {
	var item models.MenuItem
	err := r.db.Preload("Category").Where("id = ?", id).First(&item).Error
	if err != nil {
		return nil, err
	}
	return &item, nil
}

func (r *menuItemRepository) FindByRestaurantID(restaurantID uuid.UUID) ([]*models.MenuItem, error) {
	var items []*models.MenuItem
	err := r.db.Preload("Category").Where("restaurant_id = ?", restaurantID).Find(&items).Error
	if err != nil {
		return nil, err
	}
	return items, nil
}

func (r *menuItemRepository) FindByCategoryID(categoryID uuid.UUID) ([]*models.MenuItem, error) {
	var items []*models.MenuItem
	err := r.db.Preload("Category").Where("category_id = ?", categoryID).Find(&items).Error
	if err != nil {
		return nil, err
	}
	return items, nil
}

func (r *menuItemRepository) Update(item *models.MenuItem) error {
	return r.db.Save(item).Error
}

func (r *menuItemRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.MenuItem{}, "id = ?", id).Error
}

func (r *menuItemRepository) Search(query string, restaurantID uuid.UUID) ([]*models.MenuItem, error) {
	var items []*models.MenuItem
	err := r.db.Preload("Category").Where("restaurant_id = ? AND (name ILIKE ? OR description ILIKE ?)", restaurantID, "%"+query+"%", "%"+query+"%").Find(&items).Error
	if err != nil {
		return nil, err
	}
	return items, nil
}

func InitDB(databaseURL string) (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(databaseURL), &gorm.Config{})
	if err != nil {
		return nil, err
	}

	// Auto migrate tables
	err = db.AutoMigrate(
		&models.Restaurant{},
		&models.MenuCategory{},
		&models.MenuItem{},
		&models.RestaurantDocument{},
	)
	if err != nil {
		return nil, err
	}

	return db, nil
}
