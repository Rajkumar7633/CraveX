package rider

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
)

// RouteDeviationAlert implements the route deviation alert from the spec:
// if rider's live location deviates >500m from expected route to customer for >3 min,
// auto-flag to support (safety + fraud check)
type RouteDeviationAlert struct {
	locationRepo   RouteLocationRepository
	routingService RoutingService
	alertService   DeviationAlertService
}

type RouteLocationRepository interface {
	GetRiderLocation(ctx context.Context, riderID uuid.UUID) (*RiderLocation, error)
	GetRiderLocationHistory(ctx context.Context, riderID uuid.UUID, since time.Time) ([]*RiderLocation, error)
}

type RoutingService interface {
	GetExpectedRoute(ctx context.Context, fromLat, fromLng, toLat, toLng float64) ([]*RoutePoint, error)
	CalculateDistanceFromRoute(ctx context.Context, lat, lng float64, route []*RoutePoint) (float64, error)
}

type DeviationAlertService interface {
	CreateDeviationAlert(ctx context.Context, alert *RouteDeviationAlertInfo) error
}

type RoutePoint struct {
	Latitude  float64
	Longitude float64
}

type RouteDeviationAlertInfo struct {
	ID              uuid.UUID
	RiderID         uuid.UUID
	OrderID         uuid.UUID
	DeviationMeters float64
	Duration        time.Duration
	ExpectedRoute   []*RoutePoint
	ActualLocation  *RiderLocation
	Severity        string
	FlaggedAt       time.Time
}

type DeviationCheckRequest struct {
	RiderID    uuid.UUID
	OrderID    uuid.UUID
	CurrentLat float64
	CurrentLng float64
	FromLat    float64
	FromLng    float64
	ToLat      float64
	ToLng      float64
}

type DeviationCheckResult struct {
	IsDeviating     bool
	DeviationMeters float64
	ShouldAlert     bool
	Severity        string
}

func NewRouteDeviationAlert(
	locationRepo RouteLocationRepository,
	routingService RoutingService,
	alertService DeviationAlertService,
) *RouteDeviationAlert {
	return &RouteDeviationAlert{
		locationRepo:   locationRepo,
		routingService: routingService,
		alertService:   alertService,
	}
}

// CheckRouteDeviation checks if rider is deviating from expected route
func (rda *RouteDeviationAlert) CheckRouteDeviation(ctx context.Context, req *DeviationCheckRequest) (*DeviationCheckResult, error) {
	// Get expected route
	expectedRoute, err := rda.routingService.GetExpectedRoute(ctx, req.FromLat, req.FromLng, req.ToLat, req.ToLng)
	if err != nil {
		return nil, fmt.Errorf("failed to get expected route: %w", err)
	}

	// Calculate distance from expected route
	deviationMeters, err := rda.routingService.CalculateDistanceFromRoute(ctx, req.CurrentLat, req.CurrentLng, expectedRoute)
	if err != nil {
		return nil, fmt.Errorf("failed to calculate deviation: %w", err)
	}

	// Check if deviation exceeds threshold (500m)
	isDeviating := deviationMeters > 500

	// Check if deviation has persisted for >3 minutes
	shouldAlert := false
	severity := "low"

	if isDeviating {
		// Get location history to check duration
		since := time.Now().Add(-3 * time.Minute)
		history, err := rda.locationRepo.GetRiderLocationHistory(ctx, req.RiderID, since)
		if err == nil {
			// Check if deviation has persisted
			persistentDeviations := 0
			for _, location := range history {
				deviation, _ := rda.routingService.CalculateDistanceFromRoute(ctx, location.Latitude, location.Longitude, expectedRoute)
				if deviation > 500 {
					persistentDeviations++
				}
			}

			// If more than 50% of locations in last 3 minutes are deviating, alert
			if persistentDeviations > len(history)/2 {
				shouldAlert = true

				// Determine severity based on deviation distance
				if deviationMeters > 1000 {
					severity = "high"
				} else if deviationMeters > 750 {
					severity = "medium"
				}
			}
		}
	}

	return &DeviationCheckResult{
		IsDeviating:     isDeviating,
		DeviationMeters: deviationMeters,
		ShouldAlert:     shouldAlert,
		Severity:        severity,
	}, nil
}

// CreateAlert creates a deviation alert
func (rda *RouteDeviationAlert) CreateAlert(ctx context.Context, req *DeviationCheckRequest, deviationMeters float64, duration time.Duration) error {
	// Get expected route
	expectedRoute, err := rda.routingService.GetExpectedRoute(ctx, req.FromLat, req.FromLng, req.ToLat, req.ToLng)
	if err != nil {
		return fmt.Errorf("failed to get expected route: %w", err)
	}

	// Get current location
	currentLocation, err := rda.locationRepo.GetRiderLocation(ctx, req.RiderID)
	if err != nil {
		return fmt.Errorf("failed to get current location: %w", err)
	}

	// Determine severity
	severity := "low"
	if deviationMeters > 1000 {
		severity = "high"
	} else if deviationMeters > 750 {
		severity = "medium"
	}

	alert := &RouteDeviationAlertInfo{
		ID:              uuid.New(),
		RiderID:         req.RiderID,
		OrderID:         req.OrderID,
		DeviationMeters: deviationMeters,
		Duration:        duration,
		ExpectedRoute:   expectedRoute,
		ActualLocation:  currentLocation,
		Severity:        severity,
		FlaggedAt:       time.Now(),
	}

	return rda.alertService.CreateDeviationAlert(ctx, alert)
}

// MonitorRiderRoute continuously monitors rider's route deviation
func (rda *RouteDeviationAlert) MonitorRiderRoute(ctx context.Context, riderID, orderID uuid.UUID, fromLat, fromLng, toLat, toLng float64) error {
	ticker := time.NewTicker(30 * time.Second) // Check every 30 seconds
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return nil
		case <-ticker.C:
			// Get current location
			currentLocation, err := rda.locationRepo.GetRiderLocation(ctx, riderID)
			if err != nil {
				continue
			}

			req := &DeviationCheckRequest{
				RiderID:    riderID,
				OrderID:    orderID,
				CurrentLat: currentLocation.Latitude,
				CurrentLng: currentLocation.Longitude,
				FromLat:    fromLat,
				FromLng:    fromLng,
				ToLat:      toLat,
				ToLng:      toLng,
			}

			result, err := rda.CheckRouteDeviation(ctx, req)
			if err != nil {
				continue
			}

			if result.ShouldAlert {
				// Create alert
				duration := 3 * time.Minute // Default duration
				err := rda.CreateAlert(ctx, req, result.DeviationMeters, duration)
				if err != nil {
					fmt.Printf("Failed to create deviation alert: %v\n", err)
				}
			}
		}
	}
}

// SimpleRoutingService implements basic routing calculations
type SimpleRoutingService struct{}

func NewSimpleRoutingService() *SimpleRoutingService {
	return &SimpleRoutingService{}
}

func (srs *SimpleRoutingService) GetExpectedRoute(ctx context.Context, fromLat, fromLng, toLat, toLng float64) ([]*RoutePoint, error) {
	// Simple straight-line route for demonstration
	// In production, use Google Maps API or OSRM
	return []*RoutePoint{
		{Latitude: fromLat, Longitude: fromLng},
		{Latitude: toLat, Longitude: toLng},
	}, nil
}

func (srs *SimpleRoutingService) CalculateDistanceFromRoute(ctx context.Context, lat, lng float64, route []*RoutePoint) (float64, error) {
	// Calculate minimum distance to any point on the route
	minDistance := math.MaxFloat64

	for _, point := range route {
		distance := srs.calculateDistance(lat, lng, point.Latitude, point.Longitude)
		if distance < minDistance {
			minDistance = distance
		}
	}

	return minDistance * 1000, nil // Convert km to meters
}

func (srs *SimpleRoutingService) calculateDistance(lat1, lng1, lat2, lng2 float64) float64 {
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

// SimpleDeviationAlertService implements basic alert service
type SimpleDeviationAlertService struct {
	alerts []*RouteDeviationAlertInfo
}

func NewSimpleDeviationAlertService() *SimpleDeviationAlertService {
	return &SimpleDeviationAlertService{
		alerts: make([]*RouteDeviationAlertInfo, 0),
	}
}

func (sdas *SimpleDeviationAlertService) CreateDeviationAlert(ctx context.Context, alert *RouteDeviationAlertInfo) error {
	sdas.alerts = append(sdas.alerts, alert)
	fmt.Printf("Route deviation alert created for rider %s: %.2f meters deviation\n", alert.RiderID, alert.DeviationMeters)
	return nil
}

func (sdas *SimpleDeviationAlertService) GetAlerts() []*RouteDeviationAlertInfo {
	return sdas.alerts
}
