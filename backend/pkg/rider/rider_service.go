package rider

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
)

type RiderStatus string

const (
	RiderStatusOffline    RiderStatus = "offline"
	RiderStatusAvailable  RiderStatus = "available"
	RiderStatusBusy       RiderStatus = "busy"
	RiderStatusOnDelivery RiderStatus = "on_delivery"
	RiderStatusBreak      RiderStatus = "break"
)

type VehicleType string

const (
	VehicleTypeBike    VehicleType = "bike"
	VehicleTypeScooter VehicleType = "scooter"
	VehicleTypeBicycle VehicleType = "bicycle"
	VehicleTypeWalk    VehicleType = "walk"
)

type Rider struct {
	ID              uuid.UUID   `json:"id"`
	UserID          uuid.UUID   `json:"user_id"`
	Name            string      `json:"name"`
	Phone           string      `json:"phone"`
	Email           string      `json:"email"`
	VehicleType     VehicleType `json:"vehicle_type"`
	VehicleNumber   string      `json:"vehicle_number"`
	VehicleModel    string      `json:"vehicle_model"`
	LicenseNumber   string      `json:"license_number"`
	LicenseExpiry   time.Time   `json:"license_expiry"`
	Status          RiderStatus `json:"status"`
	CurrentLocation Location    `json:"current_location"`
	CurrentOrderID  *uuid.UUID  `json:"current_order_id,omitempty"`
	IsVerified      bool        `json:"is_verified"`
	IsActive        bool        `json:"is_active"`
	Rating          float64     `json:"rating"`
	TotalDeliveries int         `json:"total_deliveries"`
	TotalEarnings   float64     `json:"total_earnings"`
	OnlineHours     float64     `json:"online_hours"`
	CreatedAt       time.Time   `json:"created_at"`
	UpdatedAt       time.Time   `json:"updated_at"`
	LastOnlineAt    time.Time   `json:"last_online_at"`
}

type Location struct {
	Latitude  float64   `json:"latitude"`
	Longitude float64   `json:"longitude"`
	Bearing   float64   `json:"bearing"`
	Speed     float64   `json:"speed"`
	UpdatedAt time.Time `json:"updated_at"`
}

type RiderEarnings struct {
	RiderID            uuid.UUID `json:"rider_id"`
	Period             string    `json:"period"` // "today", "week", "month"
	TotalDeliveries    int       `json:"total_deliveries"`
	TotalEarnings      float64   `json:"total_earnings"`
	BaseEarnings       float64   `json:"base_earnings"`
	TipEarnings        float64   `json:"tip_earnings"`
	BonusEarnings      float64   `json:"bonus_earnings"`
	DistanceKm         float64   `json:"distance_km"`
	OnlineHours        float64   `json:"online_hours"`
	AveragePerDelivery float64   `json:"average_per_delivery"`
}

type RiderService struct {
	cacheService     CacheService
	messagingService MessagingService
}

type CacheService interface {
	Get(ctx context.Context, key string) (string, error)
	Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error
	Delete(ctx context.Context, keys ...string) error
	SetJSON(ctx context.Context, key string, value interface{}, expiration time.Duration) error
}

type MessagingService interface {
	PublishMessage(ctx context.Context, topic string, key string, message interface{}) error
}

func NewRiderService(cacheService CacheService, messagingService MessagingService) *RiderService {
	return &RiderService{
		cacheService:     cacheService,
		messagingService: messagingService,
	}
}

func (rs *RiderService) UpdateLocation(ctx context.Context, riderID uuid.UUID, location Location) error {
	// Validate location
	if location.Latitude < -90 || location.Latitude > 90 {
		return fmt.Errorf("invalid latitude")
	}
	if location.Longitude < -180 || location.Longitude > 180 {
		return fmt.Errorf("invalid longitude")
	}

	location.UpdatedAt = time.Now()

	// Update rider location in database
	if err := rs.updateRiderLocationInDB(ctx, riderID, location); err != nil {
		return fmt.Errorf("failed to update rider location: %w", err)
	}

	// Publish location update event
	event := map[string]interface{}{
		"rider_id":   riderID.String(),
		"latitude":   location.Latitude,
		"longitude":  location.Longitude,
		"bearing":    location.Bearing,
		"speed":      location.Speed,
		"updated_at": location.UpdatedAt,
	}

	if err := rs.messagingService.PublishMessage(ctx, "rider.location", riderID.String(), event); err != nil {
		return fmt.Errorf("failed to publish location update: %w", err)
	}

	// Invalidate cache
	rs.cacheService.Delete(ctx, fmt.Sprintf("rider:%s", riderID.String()))

	return nil
}

func (rs *RiderService) GetNearbyRiders(ctx context.Context, latitude, longitude, radiusKm float64, vehicleType *VehicleType) ([]Rider, error) {
	cacheKey := fmt.Sprintf("nearby_riders:%f:%f:%f:%v", latitude, longitude, radiusKm, vehicleType)

	// Try cache first
	var cachedRiders []Rider
	if _, err := rs.cacheService.Get(ctx, cacheKey); err == nil {
		return cachedRiders, nil
	}

	// Calculate bounding box
	minLat, maxLat, minLon, maxLon := rs.calculateBoundingBox(latitude, longitude, radiusKm)

	// Fetch from database
	riders, err := rs.fetchNearbyRidersFromDB(ctx, minLat, maxLat, minLon, maxLon, vehicleType)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch nearby riders: %w", err)
	}

	// Filter by distance and calculate distances
	var nearbyRiders []Rider
	for _, rider := range riders {
		distance := rs.calculateDistance(latitude, longitude, rider.CurrentLocation.Latitude, rider.CurrentLocation.Longitude)
		if distance <= radiusKm {
			// Add distance to rider data
			nearbyRiders = append(nearbyRiders, rider)
		}
	}

	// Cache for 1 minute
	rs.cacheService.Set(ctx, cacheKey, nearbyRiders, 1*time.Minute)

	return nearbyRiders, nil
}

func (rs *RiderService) UpdateStatus(ctx context.Context, riderID uuid.UUID, status RiderStatus) error {
	// Get current rider
	rider, err := rs.GetRiderByID(ctx, riderID)
	if err != nil {
		return fmt.Errorf("failed to get rider: %w", err)
	}

	// Validate status transition
	if err := rs.validateStatusTransition(rider.Status, status); err != nil {
		return fmt.Errorf("invalid status transition: %w", err)
	}

	// Update status
	oldStatus := rider.Status
	rider.Status = status
	rider.UpdatedAt = time.Now()
	rider.LastOnlineAt = time.Now()

	// Track online time
	if status == RiderStatusAvailable || status == RiderStatusOnDelivery {
		// Start tracking online time
	} else if oldStatus == RiderStatusAvailable || oldStatus == RiderStatusOnDelivery {
		// Stop tracking online time
	}

	// Save to database
	if err := rs.updateRiderInDB(ctx, rider); err != nil {
		return fmt.Errorf("failed to update rider: %w", err)
	}

	// Publish status update event
	event := map[string]interface{}{
		"rider_id":   riderID.String(),
		"old_status": oldStatus,
		"new_status": status,
		"updated_at": rider.UpdatedAt,
	}

	if err := rs.messagingService.PublishMessage(ctx, "rider.status_update", riderID.String(), event); err != nil {
		return fmt.Errorf("failed to publish status update: %w", err)
	}

	// Invalidate cache
	rs.cacheService.Delete(ctx, fmt.Sprintf("rider:%s", riderID.String()))

	return nil
}

func (rs *RiderService) GetRiderByID(ctx context.Context, id uuid.UUID) (*Rider, error) {
	cacheKey := fmt.Sprintf("rider:%s", id.String())

	// Try cache first
	var cachedRider Rider
	if _, err := rs.cacheService.Get(ctx, cacheKey); err == nil {
		return &cachedRider, nil
	}

	// Fetch from database
	rider, err := rs.fetchRiderFromDB(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to fetch rider: %w", err)
	}

	// Cache for 5 minutes
	rs.cacheService.Set(ctx, cacheKey, rider, 5*time.Minute)

	return rider, nil
}

func (rs *RiderService) GetRiderEarnings(ctx context.Context, riderID uuid.UUID, period string) (*RiderEarnings, error) {
	cacheKey := fmt.Sprintf("rider_earnings:%s:%s", riderID.String(), period)

	// Try cache first
	var cachedEarnings RiderEarnings
	if _, err := rs.cacheService.Get(ctx, cacheKey); err == nil {
		return &cachedEarnings, nil
	}

	// Calculate time range
	startTime, endTime := rs.calculatePeriodRange(period)

	// Fetch from database
	earnings, err := rs.calculateEarningsFromDB(ctx, riderID, startTime, endTime)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate earnings: %w", err)
	}

	earnings.RiderID = riderID
	earnings.Period = period

	// Calculate averages
	if earnings.TotalDeliveries > 0 {
		earnings.AveragePerDelivery = earnings.TotalEarnings / float64(earnings.TotalDeliveries)
	}

	// Cache for 10 minutes
	rs.cacheService.Set(ctx, cacheKey, earnings, 10*time.Minute)

	return earnings, nil
}

func (rs *RiderService) CompleteDelivery(ctx context.Context, riderID, orderID uuid.UUID, distanceKm float64, tipAmount float64) error {
	// Get rider
	rider, err := rs.GetRiderByID(ctx, riderID)
	if err != nil {
		return fmt.Errorf("failed to get rider: %w", err)
	}

	// Calculate earnings
	baseEarning := rs.calculateBaseEarning(distanceKm)
	bonusEarning := rs.calculateBonus(rider, distanceKm)
	totalEarning := baseEarning + bonusEarning + tipAmount

	// Update rider stats
	rider.TotalDeliveries++
	rider.TotalEarnings += totalEarning
	rider.UpdatedAt = time.Now()

	// Update rider in database
	if err := rs.updateRiderInDB(ctx, rider); err != nil {
		return fmt.Errorf("failed to update rider: %w", err)
	}

	// Record delivery transaction
	transaction := map[string]interface{}{
		"rider_id":      riderID.String(),
		"order_id":      orderID.String(),
		"base_earning":  baseEarning,
		"tip_earning":   tipAmount,
		"bonus_earning": bonusEarning,
		"total_earning": totalEarning,
		"distance_km":   distanceKm,
		"completed_at":  time.Now(),
	}

	if err := rs.recordDeliveryTransaction(ctx, transaction); err != nil {
		return fmt.Errorf("failed to record delivery transaction: %w", err)
	}

	// Invalidate cache
	rs.cacheService.Delete(ctx, fmt.Sprintf("rider:%s", riderID.String()))
	rs.cacheService.Delete(ctx, fmt.Sprintf("rider_earnings:%s:*", riderID.String()))

	return nil
}

func (rs *RiderService) calculateBoundingBox(latitude, longitude, radiusKm float64) (minLat, maxLat, minLon, maxLon float64) {
	latDelta := radiusKm / 111.0
	lonDelta := radiusKm / (111.0 * math.Cos(degreesToRadians(latitude)))

	minLat = latitude - latDelta
	maxLat = latitude + latDelta
	minLon = longitude - lonDelta
	maxLon = longitude + lonDelta

	return minLat, maxLat, minLon, maxLon
}

func (rs *RiderService) calculateDistance(lat1, lon1, lat2, lon2 float64) float64 {
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

func (rs *RiderService) calculateBaseEarning(distanceKm float64) float64 {
	// Base earning calculation
	baseRate := 10.0    // Base rate per delivery
	distanceRate := 2.0 // Rate per km
	return baseRate + (distanceRate * distanceKm)
}

func (rs *RiderService) calculateBonus(rider *Rider, distanceKm float64) float64 {
	bonus := 0.0

	// Rating bonus
	if rider.Rating >= 4.8 {
		bonus += 5.0
	} else if rider.Rating >= 4.5 {
		bonus += 3.0
	}

	// Distance bonus for long deliveries
	if distanceKm > 10 {
		bonus += 10.0
	} else if distanceKm > 5 {
		bonus += 5.0
	}

	// Peak hours bonus (would check time)
	hour := time.Now().Hour()
	if (hour >= 12 && hour <= 14) || (hour >= 19 && hour <= 21) {
		bonus += 8.0
	}

	return bonus
}

func (rs *RiderService) calculatePeriodRange(period string) (startTime, endTime time.Time) {
	now := time.Now()

	switch period {
	case "today":
		startTime = time.Date(now.Year(), now.Month(), now.Day(), 0, 0, 0, 0, now.Location())
		endTime = startTime.Add(24 * time.Hour)
	case "week":
		weekday := now.Weekday()
		startTime = now.AddDate(0, 0, -int(weekday))
		startTime = time.Date(startTime.Year(), startTime.Month(), startTime.Day(), 0, 0, 0, 0, startTime.Location())
		endTime = startTime.AddDate(0, 0, 7)
	case "month":
		startTime = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
		endTime = startTime.AddDate(0, 1, 0)
	default:
		startTime = now.Add(-24 * time.Hour)
		endTime = now
	}

	return startTime, endTime
}

func (rs *RiderService) validateStatusTransition(currentStatus, newStatus RiderStatus) error {
	validTransitions := map[RiderStatus][]RiderStatus{
		RiderStatusOffline:    {RiderStatusAvailable, RiderStatusBreak},
		RiderStatusAvailable:  {RiderStatusBusy, RiderStatusOnDelivery, RiderStatusOffline, RiderStatusBreak},
		RiderStatusBusy:       {RiderStatusAvailable, RiderStatusOffline, RiderStatusBreak},
		RiderStatusOnDelivery: {RiderStatusAvailable, RiderStatusOffline, RiderStatusBreak},
		RiderStatusBreak:      {RiderStatusAvailable, RiderStatusOffline},
	}

	allowedStatuses, exists := validTransitions[currentStatus]
	if !exists {
		return fmt.Errorf("invalid current status: %s", currentStatus)
	}

	for _, status := range allowedStatuses {
		if status == newStatus {
			return nil
		}
	}

	return fmt.Errorf("cannot transition from %s to %s", currentStatus, newStatus)
}

func (rs *RiderService) updateRiderLocationInDB(ctx context.Context, riderID uuid.UUID, location Location) error {
	// Update in database
	return nil
}

func (rs *RiderService) fetchNearbyRidersFromDB(ctx context.Context, minLat, maxLat, minLon, maxLon float64, vehicleType *VehicleType) ([]Rider, error) {
	// Fetch from database
	return []Rider{}, nil
}

func (rs *RiderService) updateRiderInDB(ctx context.Context, rider *Rider) error {
	// Update in database
	return nil
}

func (rs *RiderService) fetchRiderFromDB(ctx context.Context, id uuid.UUID) (*Rider, error) {
	// Fetch from database
	return &Rider{}, nil
}

func (rs *RiderService) calculateEarningsFromDB(ctx context.Context, riderID uuid.UUID, startTime, endTime time.Time) (*RiderEarnings, error) {
	// Calculate from database
	return &RiderEarnings{}, nil
}

func (rs *RiderService) recordDeliveryTransaction(ctx context.Context, transaction map[string]interface{}) error {
	// Record transaction in database
	return nil
}

func degreesToRadians(degrees float64) float64 {
	return degrees * (math.Pi / 180)
}
