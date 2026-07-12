package cqrs

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// OrderWriteModel represents the write model (source of truth in PostgreSQL)
type OrderWriteModel struct {
	ID              uuid.UUID
	OrderNumber     string
	UserID          uuid.UUID
	RestaurantID    uuid.UUID
	RiderID         *uuid.UUID
	Status          string
	Items           []OrderItemWrite
	Subtotal        float64
	DeliveryFee     float64
	TaxAmount       float64
	DiscountAmount  float64
	TotalAmount     float64
	PaymentMethod   string
	PaymentStatus   string
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type OrderItemWrite struct {
	ID         uuid.UUID
	MenuItemID uuid.UUID
	Quantity   int
	UnitPrice  float64
}

// OrderReadModel represents the read model (optimized for queries in Redis/Elasticsearch)
type OrderReadModel struct {
	ID              uuid.UUID
	OrderNumber     string
	UserID          uuid.UUID
	RestaurantID    uuid.UUID
	RestaurantName  string
	RiderID         *uuid.UUID
	RiderName       string
	Status          string
	StatusHistory   []StatusHistory
	Items           []OrderItemRead
	Subtotal        float64
	DeliveryFee     float64
	TaxAmount       float64
	DiscountAmount  float64
	TotalAmount     float64
	PaymentMethod   string
	PaymentStatus   string
	DeliveryAddress DeliveryAddressRead
	EstimatedDeliveryTime *time.Time
	ActualDeliveryTime    *time.Time
	CreatedAt       time.Time
	UpdatedAt       time.Time
}

type OrderItemRead struct {
	ID         uuid.UUID
	Name       string
	Quantity   int
	UnitPrice  float64
	ImageURL   string
}

type StatusHistory struct {
	Status    string
	Timestamp time.Time
	ChangedBy string
}

type DeliveryAddressRead struct {
	Address   string
	Latitude  float64
	Longitude float64
}

// OrderWriteRepository handles write operations (PostgreSQL)
type OrderWriteRepository interface {
	CreateOrder(ctx context.Context, order *OrderWriteModel) error
	UpdateOrder(ctx context.Context, order *OrderWriteModel) error
	DeleteOrder(ctx context.Context, orderID uuid.UUID) error
	GetOrder(ctx context.Context, orderID uuid.UUID) (*OrderWriteModel, error)
}

// OrderReadRepository handles read operations (Redis/Elasticsearch)
type OrderReadRepository interface {
	SaveOrderProjection(ctx context.Context, order *OrderReadModel) error
	GetOrderProjection(ctx context.Context, orderID uuid.UUID) (*OrderReadModel, error)
	GetUserOrders(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*OrderReadModel, error)
	GetRestaurantOrders(ctx context.Context, restaurantID uuid.UUID, limit, offset int) ([]*OrderReadModel, error)
	SearchOrders(ctx context.Context, query string, filters map[string]interface{}) ([]*OrderReadModel, error)
}

// OrderProjector converts write model to read model
type OrderProjector struct {
	writeRepo OrderWriteRepository
	readRepo  OrderReadRepository
	cache     CacheService
}

type CacheService interface {
	Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error
	Get(ctx context.Context, key string) (string, error)
	Delete(ctx context.Context, keys ...string) error
}

func NewOrderProjector(writeRepo OrderWriteRepository, readRepo OrderReadRepository, cache CacheService) *OrderProjector {
	return &OrderProjector{
		writeRepo: writeRepo,
		readRepo:  readRepo,
		cache:     cache,
	}
}

// ProjectOrder projects a write model change to the read model
func (op *OrderProjector) ProjectOrder(ctx context.Context, orderID uuid.UUID) error {
	// Get the write model (source of truth)
	writeModel, err := op.writeRepo.GetOrder(ctx, orderID)
	if err != nil {
		return fmt.Errorf("failed to get write model: %w", err)
	}

	// Convert to read model
	readModel := op.convertToReadModel(writeModel)

	// Save to read repository
	if err := op.readRepo.SaveOrderProjection(ctx, readModel); err != nil {
		return fmt.Errorf("failed to save read model: %w", err)
	}

	// Update cache
	cacheKey := fmt.Sprintf("order:%s", orderID.String())
	op.cache.Set(ctx, cacheKey, readModel, 15*time.Minute)

	return nil
}

// ProjectUserOrders projects all orders for a user
func (op *OrderProjector) ProjectUserOrders(ctx context.Context, userID uuid.UUID) error {
	// In production, this would query the write repository for all user orders
	// and project them to the read repository
	return nil
}

// convertToReadModel converts write model to read model with enriched data
func (op *OrderProjector) convertToReadModel(writeModel *OrderWriteModel) *OrderReadModel {
	readModel := &OrderReadModel{
		ID:              writeModel.ID,
		OrderNumber:     writeModel.OrderNumber,
		UserID:          writeModel.UserID,
		RestaurantID:    writeModel.RestaurantID,
		RiderID:         writeModel.RiderID,
		Status:          writeModel.Status,
		Subtotal:        writeModel.Subtotal,
		DeliveryFee:     writeModel.DeliveryFee,
		TaxAmount:       writeModel.TaxAmount,
		DiscountAmount:  writeModel.DiscountAmount,
		TotalAmount:     writeModel.TotalAmount,
		PaymentMethod:   writeModel.PaymentMethod,
		PaymentStatus:   writeModel.PaymentStatus,
		CreatedAt:       writeModel.CreatedAt,
		UpdatedAt:       writeModel.UpdatedAt,
	}

	// Convert items
	for _, item := range writeModel.Items {
		readModel.Items = append(readModel.Items, OrderItemRead{
			ID:         item.ID,
			Name:       "Item Name", // In production, fetch from menu service
			Quantity:   item.Quantity,
			UnitPrice:  item.UnitPrice,
			ImageURL:   "",
		})
	}

	return readModel
}

// OrderQueryService handles read queries using the read model
type OrderQueryService struct {
	readRepo OrderReadRepository
	cache    CacheService
}

func NewOrderQueryService(readRepo OrderReadRepository, cache CacheService) *OrderQueryService {
	return &OrderQueryService{
		readRepo: readRepo,
		cache:    cache,
	}
}

// GetOrder retrieves an order using the read model (fast query)
func (oqs *OrderQueryService) GetOrder(ctx context.Context, orderID uuid.UUID) (*OrderReadModel, error) {
	cacheKey := fmt.Sprintf("order:%s", orderID.String())

	// Try cache first
	var cachedOrder OrderReadModel
	if _, err := oqs.cache.Get(ctx, cacheKey); err == nil {
		return &cachedOrder, nil
	}

	// Fall back to read repository
	order, err := oqs.readRepo.GetOrderProjection(ctx, orderID)
	if err != nil {
		return nil, fmt.Errorf("failed to get order from read repo: %w", err)
	}

	// Cache the result
	oqs.cache.Set(ctx, cacheKey, order, 15*time.Minute)

	return order, nil
}

// GetUserOrders retrieves user orders using the read model
func (oqs *OrderQueryService) GetUserOrders(ctx context.Context, userID uuid.UUID, limit, offset int) ([]*OrderReadModel, error) {
	return oqs.readRepo.GetUserOrders(ctx, userID, limit, offset)
}

// GetRestaurantOrders retrieves restaurant orders using the read model
func (oqs *OrderQueryService) GetRestaurantOrders(ctx context.Context, restaurantID uuid.UUID, limit, offset int) ([]*OrderReadModel, error) {
	return oqs.readRepo.GetRestaurantOrders(ctx, restaurantID, limit, offset)
}

// SearchOrders performs advanced search using the read model
func (oqs *OrderQueryService) SearchOrders(ctx context.Context, query string, filters map[string]interface{}) ([]*OrderReadModel, error) {
	return oqs.readRepo.SearchOrders(ctx, query, filters)
}

// OrderCommandService handles write commands using the write model
type OrderCommandService struct {
	writeRepo OrderWriteRepository
	projector *OrderProjector
}

func NewOrderCommandService(writeRepo OrderWriteRepository, projector *OrderProjector) *OrderCommandService {
	return &OrderCommandService{
		writeRepo: writeRepo,
		projector: projector,
	}
}

// CreateOrder creates a new order (write operation)
func (ocs *OrderCommandService) CreateOrder(ctx context.Context, order *OrderWriteModel) error {
	// Save to write repository
	if err := ocs.writeRepo.CreateOrder(ctx, order); err != nil {
		return fmt.Errorf("failed to create order: %w", err)
	}

	// Project to read model asynchronously
	go func() {
		if err := ocs.projector.ProjectOrder(context.Background(), order.ID); err != nil {
			fmt.Printf("Failed to project order: %v\n", err)
		}
	}()

	return nil
}

// UpdateOrder updates an existing order (write operation)
func (ocs *OrderCommandService) UpdateOrder(ctx context.Context, order *OrderWriteModel) error {
	// Save to write repository
	if err := ocs.writeRepo.UpdateOrder(ctx, order); err != nil {
		return fmt.Errorf("failed to update order: %w", err)
	}

	// Project to read model asynchronously
	go func() {
		if err := ocs.projector.ProjectOrder(context.Background(), order.ID); err != nil {
			fmt.Printf("Failed to project order: %v\n", err)
		}
	}()

	return nil
}

// DeleteOrder deletes an order (write operation)
func (ocs *OrderCommandService) DeleteOrder(ctx context.Context, orderID uuid.UUID) error {
	// Delete from write repository
	if err := ocs.writeRepo.DeleteOrder(ctx, orderID); err != nil {
		return fmt.Errorf("failed to delete order: %w", err)
	}

	// Invalidate cache
	cacheKey := fmt.Sprintf("order:%s", orderID.String())
	ocs.projector.cache.Delete(ctx, cacheKey)

	return nil
}
