package rider

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
)

// H3Hex represents an H3 hex grid cell
type H3Hex struct {
	ID        string  `json:"id"`
	CenterLat float64 `json:"center_lat"`
	CenterLng float64 `json:"center_lng"`
	Level     int     `json:"level"`
}

// RiderScore represents the scoring factors for rider assignment
type RiderScore struct {
	RiderID              uuid.UUID
	DistanceToRestaurant float64
	RiderRating          float64
	ActiveOrders         int
	BatchingScore        float64
	IdleTimePenalty      float64
	TotalScore           float64
	RejectionRate        float64
}

// ActiveOrder represents a rider's current active order
type ActiveOrder struct {
	OrderID       uuid.UUID
	RestaurantLat float64
	RestaurantLng float64
	CustomerLat   float64
	CustomerLng   float64
	Status        string
}

// AdvancedRiderAssignment implements the deep logic from the spec
type AdvancedRiderAssignment struct {
	riderRepo      RiderRepository
	h3Service      H3Service
	cacheService   RiderCacheService
	scoringWeights ScoringWeights
}

type RiderRepository interface {
	GetAvailableRiders(ctx context.Context, h3Hex string) ([]*RiderInfo, error)
	GetRiderActiveOrders(ctx context.Context, riderID uuid.UUID) ([]*ActiveOrder, error)
	GetRiderRejectionRate(ctx context.Context, riderID uuid.UUID) (float64, error)
	BlacklistRiderForOrder(ctx context.Context, riderID, orderID uuid.UUID) error
	IsRiderBlacklistedForOrder(ctx context.Context, riderID, orderID uuid.UUID) (bool, error)
}

type H3Service interface {
	LatLngToH3(lat, lng float64, level int) (string, error)
	H3ToLatLng(h3 string) (float64, float64, error)
	GetHexNeighbors(h3 string) ([]string, error)
}

type RiderCacheService interface {
	Get(ctx context.Context, key string) (string, error)
	Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error
}

type ScoringWeights struct {
	DistanceWeight     float64 // w1
	RatingWeight       float64 // w2
	ActiveOrdersWeight float64 // w3
	BatchingWeight     float64 // w4
	IdlePenaltyWeight  float64 // w5
}

type RiderInfo struct {
	ID             uuid.UUID
	Name           string
	Latitude       float64
	Longitude      float64
	Rating         float64
	ActiveOrders   int
	VehicleType    string
	LastActiveTime time.Time
}

type AssignmentRequest struct {
	OrderID          uuid.UUID
	RestaurantLat    float64
	RestaurantLng    float64
	CustomerLat      float64
	CustomerLng      float64
	Priority         int
	ExcludedRiderIDs []uuid.UUID
}

type AssignmentResult struct {
	RiderID       uuid.UUID
	Score         float64
	EstimatedTime time.Duration
	BatchingInfo  *BatchingInfo
}

type BatchingInfo struct {
	CompatibleOrderID uuid.UUID
	RouteOverlap      float64
	TimeSavings       time.Duration
}

func NewAdvancedRiderAssignment(
	riderRepo RiderRepository,
	h3Service H3Service,
	cacheService RiderCacheService,
	weights ScoringWeights,
) *AdvancedRiderAssignment {
	return &AdvancedRiderAssignment{
		riderRepo:      riderRepo,
		h3Service:      h3Service,
		cacheService:   cacheService,
		scoringWeights: weights,
	}
}

// AssignBestRider implements the advanced scoring algorithm from the spec:
// score = w1*(1/distance_to_restaurant) + w2*(rider_rating)
//   - w3*(1/current_active_orders) + w4*(batching_compatibility)
//   - w5*(rider_idle_time_penalty_if_ignored_before)
func (ara *AdvancedRiderAssignment) AssignBestRider(ctx context.Context, req *AssignmentRequest) (*AssignmentResult, error) {
	// Convert restaurant location to H3 hex
	h3Hex, err := ara.h3Service.LatLngToH3(req.RestaurantLat, req.RestaurantLng, 9) // Level 9 for city-level
	if err != nil {
		return nil, fmt.Errorf("failed to convert to H3: %w", err)
	}

	// Get available riders in the hex and neighboring hexes
	riders, err := ara.getRidersInHexArea(ctx, h3Hex)
	if err != nil {
		return nil, fmt.Errorf("failed to get riders: %w", err)
	}

	// Filter out excluded riders
	var eligibleRiders []*RiderInfo
	for _, rider := range riders {
		excluded := false
		for _, excludedID := range req.ExcludedRiderIDs {
			if rider.ID == excludedID {
				excluded = true
				break
			}
		}
		if !excluded {
			eligibleRiders = append(eligibleRiders, rider)
		}
	}

	if len(eligibleRiders) == 0 {
		return nil, fmt.Errorf("no eligible riders available")
	}

	// Score each rider
	var scoredRiders []*RiderScore
	for _, rider := range eligibleRiders {
		score, err := ara.scoreRider(ctx, rider, req)
		if err != nil {
			continue
		}
		scoredRiders = append(scoredRiders, score)
	}

	if len(scoredRiders) == 0 {
		return nil, fmt.Errorf("failed to score any riders")
	}

	// Select best rider
	bestRider := ara.selectBestRider(scoredRiders)

	// Calculate estimated time
	estimatedTime := ara.calculateEstimatedTime(bestRider, req)

	return &AssignmentResult{
		RiderID:       bestRider.RiderID,
		Score:         bestRider.TotalScore,
		EstimatedTime: estimatedTime,
	}, nil
}

// scoreRider calculates the comprehensive score for a rider
func (ara *AdvancedRiderAssignment) scoreRider(ctx context.Context, rider *RiderInfo, req *AssignmentRequest) (*RiderScore, error) {
	// Calculate distance to restaurant
	distanceToRestaurant := ara.calculateDistance(
		rider.Latitude, rider.Longitude,
		req.RestaurantLat, req.RestaurantLng,
	)

	// Get rider's active orders
	activeOrders, err := ara.riderRepo.GetRiderActiveOrders(ctx, rider.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to get active orders: %w", err)
	}

	// Calculate batching compatibility
	batchingScore := ara.calculateBatchingCompatibility(ctx, rider, req, activeOrders)

	// Get rejection rate
	rejectionRate, err := ara.riderRepo.GetRiderRejectionRate(ctx, rider.ID)
	if err != nil {
		rejectionRate = 0.0
	}

	// Calculate idle time penalty
	idleTimePenalty := ara.calculateIdleTimePenalty(rider.LastActiveTime)

	// Calculate score using the formula from the spec
	distanceScore := ara.scoringWeights.DistanceWeight * (1.0 / (distanceToRestaurant + 1.0))
	ratingScore := ara.scoringWeights.RatingWeight * rider.Rating
	activeOrdersScore := ara.scoringWeights.ActiveOrdersWeight * (1.0 / (float64(len(activeOrders)) + 1.0))
	batchingScoreWeighted := ara.scoringWeights.BatchingWeight * batchingScore
	idlePenaltyScore := ara.scoringWeights.IdlePenaltyWeight * idleTimePenalty

	totalScore := distanceScore + ratingScore + activeOrdersScore + batchingScoreWeighted - idlePenaltyScore

	return &RiderScore{
		RiderID:              rider.ID,
		DistanceToRestaurant: distanceToRestaurant,
		RiderRating:          rider.Rating,
		ActiveOrders:         len(activeOrders),
		BatchingScore:        batchingScore,
		IdleTimePenalty:      idleTimePenalty,
		TotalScore:           totalScore,
		RejectionRate:        rejectionRate,
	}, nil
}

// calculateBatchingCompatibility checks if rider's current orders are compatible with new order
func (ara *AdvancedRiderAssignment) calculateBatchingCompatibility(ctx context.Context, rider *RiderInfo, req *AssignmentRequest, activeOrders []*ActiveOrder) float64 {
	if len(activeOrders) == 0 {
		return 0.0 // No batching bonus if no active orders
	}

	maxCompatibility := 0.0

	for _, activeOrder := range activeOrders {
		// Check if new order's restaurant/customer is within 1.5km of active order's route
		restaurantDistance := ara.calculateDistance(
			req.RestaurantLat, req.RestaurantLng,
			activeOrder.RestaurantLat, activeOrder.RestaurantLng,
		)

		customerDistance := ara.calculateDistance(
			req.CustomerLat, req.CustomerLng,
			activeOrder.CustomerLat, activeOrder.CustomerLng,
		)

		// If both restaurant and customer are within 1.5km, high batching compatibility
		if restaurantDistance <= 1.5 && customerDistance <= 1.5 {
			compatibility := 1.0 - (restaurantDistance+customerDistance)/3.0
			if compatibility > maxCompatibility {
				maxCompatibility = compatibility
			}
		}
	}

	return maxCompatibility
}

// calculateIdleTimePenalty calculates penalty for riders who have ignored orders
func (ara *AdvancedRiderAssignment) calculateIdleTimePenalty(lastActiveTime time.Time) float64 {
	idleTime := time.Since(lastActiveTime).Minutes()

	// If rider has been idle for more than 30 minutes, apply penalty
	if idleTime > 30 {
		return (idleTime - 30) / 60.0 // Penalty increases with idle time
	}

	return 0.0
}

// selectBestRider selects the rider with the highest score
func (ara *AdvancedRiderAssignment) selectBestRider(scores []*RiderScore) *RiderScore {
	bestRider := scores[0]
	for _, score := range scores {
		if score.TotalScore > bestRider.TotalScore {
			bestRider = score
		}
	}
	return bestRider
}

// calculateEstimatedTime estimates time for rider to reach restaurant
func (ara *AdvancedRiderAssignment) calculateEstimatedTime(score *RiderScore, req *AssignmentRequest) time.Duration {
	// Assume average speed of 20 km/h
	avgSpeed := 20.0
	timeHours := score.DistanceToRestaurant / avgSpeed
	return time.Duration(timeHours * float64(time.Hour))
}

// getRidersInHexArea gets riders in the hex and neighboring hexes
func (ara *AdvancedRiderAssignment) getRidersInHexArea(ctx context.Context, h3Hex string) ([]*RiderInfo, error) {
	// Get riders in current hex
	riders, err := ara.riderRepo.GetAvailableRiders(ctx, h3Hex)
	if err != nil {
		return nil, err
	}

	// Get neighboring hexes
	neighbors, err := ara.h3Service.GetHexNeighbors(h3Hex)
	if err != nil {
		return riders, err // Return current hex riders if neighbor lookup fails
	}

	// Get riders from neighboring hexes
	for _, neighbor := range neighbors {
		neighborRiders, err := ara.riderRepo.GetAvailableRiders(ctx, neighbor)
		if err != nil {
			continue
		}
		riders = append(riders, neighborRiders...)
	}

	return riders, nil
}

// calculateDistance calculates distance between two points using Haversine formula
func (ara *AdvancedRiderAssignment) calculateDistance(lat1, lng1, lat2, lng2 float64) float64 {
	const earthRadius = 6371.0 // km

	lat1Rad := lat1 * math.Pi / 180.0
	lat2Rad := lat2 * math.Pi / 180.0
	deltaLat := (lat2 - lat1) * math.Pi / 180.0
	deltaLng := (lng2 - lng1) * math.Pi / 180.0

	a := math.Sin(deltaLat/2)*math.Sin(deltaLat/2) +
		math.Cos(lat1Rad)*math.Cos(lat2Rad)*
			math.Sin(deltaLng/2)*math.Sin(deltaLng/2)

	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return earthRadius * c
}

// HandleRiderRejection handles rider rejection and triggers reassignment
func (ara *AdvancedRiderAssignment) HandleRiderRejection(ctx context.Context, riderID, orderID uuid.UUID) error {
	// Blacklist rider for this specific order
	if err := ara.riderRepo.BlacklistRiderForOrder(ctx, riderID, orderID); err != nil {
		return fmt.Errorf("failed to blacklist rider: %w", err)
	}

	// Increment rider's rejection rate (this would be stored separately)
	// In production, this would update a rejection counter

	return nil
}

// IsRiderBlacklisted checks if rider is blacklisted for an order
func (ara *AdvancedRiderAssignment) IsRiderBlacklisted(ctx context.Context, riderID, orderID uuid.UUID) (bool, error) {
	return ara.riderRepo.IsRiderBlacklistedForOrder(ctx, riderID, orderID)
}
