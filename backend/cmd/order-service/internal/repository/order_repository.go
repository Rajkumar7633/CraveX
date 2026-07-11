package repository

import (
	"github.com/google/uuid"
	"github.com/zomato-clone/order-service/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type OrderRepository interface {
	Create(order *models.Order) error
	FindByID(id uuid.UUID) (*models.Order, error)
	FindByOrderNumber(orderNumber string) (*models.Order, error)
	FindByUserID(userID uuid.UUID) ([]*models.Order, error)
	FindByRestaurantID(restaurantID uuid.UUID) ([]*models.Order, error)
	FindByRiderID(riderID uuid.UUID) ([]*models.Order, error)
	Update(order *models.Order) error
	UpdateStatus(id uuid.UUID, status string) error
	Delete(id uuid.UUID) error
}

type orderRepository struct {
	db *gorm.DB
}

func NewOrderRepository(db *gorm.DB) OrderRepository {
	return &orderRepository{db: db}
}

func (r *orderRepository) Create(order *models.Order) error {
	return r.db.Create(order).Error
}

func (r *orderRepository) FindByID(id uuid.UUID) (*models.Order, error) {
	var order models.Order
	err := r.db.Preload("OrderItems").Where("id = ?", id).First(&order).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}

func (r *orderRepository) FindByOrderNumber(orderNumber string) (*models.Order, error) {
	var order models.Order
	err := r.db.Preload("OrderItems").Where("order_number = ?", orderNumber).First(&order).Error
	if err != nil {
		return nil, err
	}
	return &order, nil
}

func (r *orderRepository) FindByUserID(userID uuid.UUID) ([]*models.Order, error) {
	var orders []*models.Order
	err := r.db.Preload("OrderItems").Where("user_id = ?", userID).Order("created_at DESC").Find(&orders).Error
	if err != nil {
		return nil, err
	}
	return orders, nil
}

func (r *orderRepository) FindByRestaurantID(restaurantID uuid.UUID) ([]*models.Order, error) {
	var orders []*models.Order
	err := r.db.Preload("OrderItems").Where("restaurant_id = ?", restaurantID).Order("created_at DESC").Find(&orders).Error
	if err != nil {
		return nil, err
	}
	return orders, nil
}

func (r *orderRepository) FindByRiderID(riderID uuid.UUID) ([]*models.Order, error) {
	var orders []*models.Order
	err := r.db.Preload("OrderItems").Where("rider_id = ?", riderID).Order("created_at DESC").Find(&orders).Error
	if err != nil {
		return nil, err
	}
	return orders, nil
}

func (r *orderRepository) Update(order *models.Order) error {
	return r.db.Save(order).Error
}

func (r *orderRepository) UpdateStatus(id uuid.UUID, status string) error {
	return r.db.Model(&models.Order{}).Where("id = ?", id).Update("status", status).Error
}

func (r *orderRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.Order{}, "id = ?", id).Error
}

type OrderItemRepository interface {
	Create(item *models.OrderItem) error
	FindByOrderID(orderID uuid.UUID) ([]*models.OrderItem, error)
	FindByID(id uuid.UUID) (*models.OrderItem, error)
	Update(item *models.OrderItem) error
	Delete(id uuid.UUID) error
}

type orderItemRepository struct {
	db *gorm.DB
}

func NewOrderItemRepository(db *gorm.DB) OrderItemRepository {
	return &orderItemRepository{db: db}
}

func (r *orderItemRepository) Create(item *models.OrderItem) error {
	return r.db.Create(item).Error
}

func (r *orderItemRepository) FindByOrderID(orderID uuid.UUID) ([]*models.OrderItem, error) {
	var items []*models.OrderItem
	err := r.db.Where("order_id = ?", orderID).Find(&items).Error
	if err != nil {
		return nil, err
	}
	return items, nil
}

func (r *orderItemRepository) FindByID(id uuid.UUID) (*models.OrderItem, error) {
	var item models.OrderItem
	err := r.db.Where("id = ?", id).First(&item).Error
	if err != nil {
		return nil, err
	}
	return &item, nil
}

func (r *orderItemRepository) Update(item *models.OrderItem) error {
	return r.db.Save(item).Error
}

func (r *orderItemRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.OrderItem{}, "id = ?", id).Error
}

type OrderStatusHistoryRepository interface {
	Create(history *models.OrderStatusHistory) error
	FindByOrderID(orderID uuid.UUID) ([]*models.OrderStatusHistory, error)
}

type orderStatusHistoryRepository struct {
	db *gorm.DB
}

func NewOrderStatusHistoryRepository(db *gorm.DB) OrderStatusHistoryRepository {
	return &orderStatusHistoryRepository{db: db}
}

func (r *orderStatusHistoryRepository) Create(history *models.OrderStatusHistory) error {
	return r.db.Create(history).Error
}

func (r *orderStatusHistoryRepository) FindByOrderID(orderID uuid.UUID) ([]*models.OrderStatusHistory, error) {
	var history []*models.OrderStatusHistory
	err := r.db.Where("order_id = ?", orderID).Order("created_at ASC").Find(&history).Error
	if err != nil {
		return nil, err
	}
	return history, nil
}

func InitDB(databaseURL string) (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(databaseURL), &gorm.Config{})
	if err != nil {
		return nil, err
	}

	// Auto migrate tables
	err = db.AutoMigrate(
		&models.Order{},
		&models.OrderItem{},
		&models.OrderStatusHistory{},
	)
	if err != nil {
		return nil, err
	}

	return db, nil
}
