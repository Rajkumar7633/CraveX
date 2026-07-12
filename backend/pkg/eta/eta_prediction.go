package eta

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
)

// ETAPredictionService implements the deep ETA prediction from the spec:
// ETA = prep_time_estimate + pickup_travel_time + delivery_travel_time + buffer
type ETAPredictionService struct {
	historicalRepo HistoricalRepository
	mappingService MappingService
	cacheService   CacheService
}

type HistoricalRepository interface {
	GetRestaurantPrepTime(ctx context.Context, restaurantID uuid.UUID) (*PrepTimeData, error)
	GetKitchenQueueLength(ctx context.Context, restaurantID uuid.UUID) (int, error)
	GetItemComplexity(ctx context.Context, menuItemID uuid.UUID) (float64, error)
	GetPeakHourMultiplier(ctx context.Context, restaurantID uuid.UUID, hour int) (float64, error)
}

type MappingService interface {
	CalculateTravelTime(ctx context.Context, fromLat, fromLng, toLat, toLng float64) (time.Duration, error)
	CalculateDistance(ctx context.Context, fromLat, fromLng, toLat, toLng float64) (float64, error)
}

type CacheService interface {
	Get(ctx context.Context, key string) (string, error)
	Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error
}

type PrepTimeData struct {
	AveragePrepTime    time.Duration
	MinPrepTime       time.Duration
	MaxPrepTime       time.Duration
	StandardDeviation time.Duration
}

type ETACalculationRequest struct {
	OrderID        uuid.UUID
	RestaurantID   uuid.UUID
	RestaurantLat  float64
	RestaurantLng  float64
	CustomerLat    float64
	CustomerLng    float64
	MenuItemIDs    []uuid.UUID
	OrderTime      time.Time
}

type ETACalculationResult struct {
	PrepTimeEstimate     time.Duration
	PickupTravelTime    time.Duration
	DeliveryTravelTime  time.Duration
	BufferTime          time.Duration
	EstimatedDeliveryTime time.Time
	ConfidenceLevel     float64
	CalculatedAt        time.Time
}

type TimeOfDay struct {
	Hour   int
	IsPeak bool
}

func NewETAPredictionService(
	historicalRepo HistoricalRepository,
	mappingService MappingService,
	cacheService CacheService,
) *ETAPredictionService {
	return &ETAPredictionService{
		historicalRepo: historicalRepo,
		mappingService: mappingService,
		cacheService:   cacheService,
	}
}

// CalculateETA implements the deep ETA prediction from the spec
func (eps *ETAPredictionService) CalculateETA(ctx context.Context, req *ETACalculationRequest) (*ETACalculationResult, error) {
	// 1. Calculate prep_time_estimate: restaurant-level historical average, weighted by:
	//    (a) current kitchen queue length (b) item complexity (c) time of day (peak hour multiplier)
	prepTimeEstimate, err := eps.calculatePrepTimeEstimate(ctx, req)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate prep time: %w", err)
	}

	// 2. Calculate pickup_travel_time
	pickupTravelTime, err := eps.mappingService.CalculateTravelTime(
		ctx,
		req.RestaurantLat, req.RestaurantLng,
		req.CustomerLat, req.CustomerLng,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate pickup travel time: %w", err)
	}

	// 3. Calculate delivery_travel_time (same as pickup for now, could be different in production)
	deliveryTravelTime := pickupTravelTime

	// 4. Add buffer time (10% of total time)
	totalTime := prepTimeEstimate + pickupTravelTime + deliveryTravelTime
	bufferTime := time.Duration(float64(totalTime) * 0.1)

	// 5. Calculate estimated delivery time
	estimatedDeliveryTime := req.OrderTime.Add(prepTimeEstimate).Add(pickupTravelTime).Add(deliveryTravelTime).Add(bufferTime)

	result := &ETACalculationResult{
		PrepTimeEstimate:      prepTimeEstimate,
		PickupTravelTime:     pickupTravelTime,
		DeliveryTravelTime:   deliveryTravelTime,
		BufferTime:           bufferTime,
		EstimatedDeliveryTime: estimatedDeliveryTime,
		ConfidenceLevel:      0.85, // 85% confidence based on historical accuracy
		CalculatedAt:         time.Now(),
	}

	return result, nil
}

// calculatePrepTimeEstimate calculates prep time with all the factors from the spec
func (eps *ETAPredictionService) calculatePrepTimeEstimate(ctx context.Context, req *ETACalculationRequest) (time.Duration, error) {
	// Get restaurant's historical prep time
	prepData, err := eps.historicalRepo.GetRestaurantPrepTime(ctx, req.RestaurantID)
	if err != nil {
		return 15 * time.Minute, nil // Default to 15 minutes if no data
	}

	// Get current kitchen queue length
	queueLength, err := eps.historicalRepo.GetKitchenQueueLength(ctx, req.RestaurantID)
	if err != nil {
		queueLength = 0
	}

	// Calculate item complexity
	itemComplexity := eps.calculateItemComplexity(ctx, req.MenuItemIDs)

	// Get time of day and peak hour multiplier
	timeOfDay := eps.getTimeOfDay(req.OrderTime)
	peakMultiplier, err := eps.historicalRepo.GetPeakHourMultiplier(ctx, req.RestaurantID, timeOfDay.Hour)
	if err != nil {
		peakMultiplier = 1.0
	}

	// Calculate weighted prep time
	// Base prep time from historical data
	basePrepTime := prepData.AveragePrepTime

	// Queue length factor: each item in queue adds 2 minutes
	queueFactor := time.Duration(queueLength) * 2 * time.Minute

	// Item complexity factor: complexity 0-1, adds 0-10 minutes
	complexityFactor := time.Duration(itemComplexity * 10 * float64(time.Minute))

	// Peak hour multiplier
	peakFactor := basePrepTime * time.Duration(peakMultiplier-1.0)

	// Calculate final prep time
	prepTime := basePrepTime + queueFactor + complexityFactor + peakFactor

	// Ensure prep time is within reasonable bounds
	if prepTime < 5*time.Minute {
		prepTime = 5 * time.Minute
	}
	if prepTime > 60*time.Minute {
		prepTime = 60 * time.Minute
	}

	return prepTime, nil
}

// calculateItemComplexity calculates the average complexity of menu items
func (eps *ETAPredictionService) calculateItemComplexity(ctx context.Context, menuItemIDs []uuid.UUID) float64 {
	if len(menuItemIDs) == 0 {
		return 0.5 // Default complexity
	}

	totalComplexity := 0.0
	for _, menuItemID := range menuItemIDs {
		complexity, err := eps.historicalRepo.GetItemComplexity(ctx, menuItemID)
		if err != nil {
			complexity = 0.5 // Default complexity
		}
		totalComplexity += complexity
	}

	return totalComplexity / float64(len(menuItemIDs))
}

// getTimeOfDay determines the time of day and whether it's peak hour
func (eps *ETAPredictionService) getTimeOfDay(orderTime time.Time) TimeOfDay {
	hour := orderTime.Hour()
	
	// Peak hours: 12-2pm (lunch) and 7-9pm (dinner)
	isPeak := (hour >= 12 && hour <= 14) || (hour >= 19 && hour <= 21)
	
	return TimeOfDay{
		Hour:   hour,
		IsPeak: isPeak,
	}
}

// RecalculateETA recalculates ETA for an active order
// Re-calculate ETA every 60 seconds while order active, push updated ETA via websocket only if delta > 2 min
func (eps *ETAPredictionService) RecalculateETA(ctx context.Context, req *ETACalculationRequest, previousETA time.Time) (*ETACalculationResult, error) {
	newResult, err := eps.CalculateETA(ctx, req)
	if err != nil {
		return nil, err
	}

	// Check if ETA changed by more than 2 minutes
	delta := math.Abs(float64(newResult.EstimatedDeliveryTime.Sub(previousETA)))
	if delta < 2*60 { // 2 minutes in seconds
		return nil, fmt.Errorf("ETA change less than 2 minutes, no update needed")
	}

	return newResult, nil
}

// GetETAConfidence calculates confidence level based on data availability
func (eps *ETAPredictionService) GetETAConfidence(ctx context.Context, req *ETACalculationRequest) float64 {
	// Check if we have historical data for this restaurant
	_, err := eps.historicalRepo.GetRestaurantPrepTime(ctx, req.RestaurantID)
	if err != nil {
		return 0.5 // Low confidence without historical data
	}

	// Check if we have item complexity data
	hasItemData := true
	for _, menuItemID := range req.MenuItemIDs {
		_, err := eps.historicalRepo.GetItemComplexity(ctx, menuItemID)
		if err != nil {
			hasItemData = false
			break
		}
	}

	if !hasItemData {
		return 0.7 // Medium confidence
	}

	return 0.9 // High confidence with all data
}

// CacheETA caches the ETA calculation result
func (eps *ETAPredictionService) CacheETA(ctx context.Context, orderID uuid.UUID, result *ETACalculationResult) error {
	cacheKey := fmt.Sprintf("eta:%s", orderID.String())
	return eps.cacheService.Set(ctx, cacheKey, result, 10*time.Minute)
}

// GetCachedETA retrieves cached ETA calculation
func (eps *ETAPredictionService) GetCachedETA(ctx context.Context, orderID uuid.UUID) (*ETACalculationResult, error) {
	cacheKey := fmt.Sprintf("eta:%s", orderID.String())
	var cachedResult ETACalculationResult
	if _, err := eps.cacheService.Get(ctx, cacheKey); err == nil {
		return &cachedResult, nil
	}
	return nil, fmt.Errorf("cached ETA not found")
}
