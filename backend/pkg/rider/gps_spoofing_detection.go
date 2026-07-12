package rider

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
)

// GPSSpoofingDetector implements GPS spoofing detection from the spec:
// compare rider's reported GPS speed/acceleration against physically plausible bounds
// (e.g., no rider "teleporting" 5km in 10 sec); flag for review
type GPSSpoofingDetector struct {
	locationRepo LocationRepository
	alertService  AlertService
}

type LocationRepository interface {
	GetRiderLocationHistory(ctx context.Context, riderID uuid.UUID, since time.Time) ([]*RiderLocation, error)
	GetLastLocation(ctx context.Context, riderID uuid.UUID) (*RiderLocation, error)
}

type AlertService interface {
	CreateAlert(ctx context.Context, alert *SpoofingAlert) error
}

type RiderLocation struct {
	RiderID   uuid.UUID
	Latitude  float64
	Longitude float64
	Bearing   float64
	Speed     float64 // km/h
	Timestamp time.Time
}

type SpoofingAlert struct {
	ID          uuid.UUID
	RiderID     uuid.UUID
	AlertType   string
	Description string
	Severity    string
	Location1   *RiderLocation
	Location2   *RiderLocation
	DetectedAt  time.Time
}

type SpoofingDetectionResult struct {
	IsSpoofing      bool
	AlertType       string
	Confidence      float64
	Reason          string
	ShouldFlag      bool
}

func NewGPSSpoofingDetector(locationRepo LocationRepository, alertService AlertService) *GPSSpoofingDetector {
	return &GPSSpoofingDetector{
		locationRepo: locationRepo,
		alertService:  alertService,
	}
}

// DetectSpoofing detects GPS spoofing based on location updates
func (gsd *GPSSpoofingDetector) DetectSpoofing(ctx context.Context, riderID uuid.UUID, newLocation *RiderLocation) (*SpoofingDetectionResult, error) {
	// Get last location
	lastLocation, err := gsd.locationRepo.GetLastLocation(ctx, riderID)
	if err != nil {
		// First location, no spoofing detection possible
		return &SpoofingDetectionResult{IsSpoofing: false}, nil
	}

	// Calculate time difference
	timeDiff := newLocation.Timestamp.Sub(lastLocation.Timestamp).Seconds()
	if timeDiff <= 0 {
		return &SpoofingDetectionResult{
			IsSpoofing: true,
			AlertType:  "invalid_timestamp",
			Confidence: 1.0,
			Reason:     "Timestamp is not newer than last location",
			ShouldFlag: true,
		}, nil
	}

	// Calculate distance
	distance := gsd.calculateDistance(
		lastLocation.Latitude, lastLocation.Longitude,
		newLocation.Latitude, newLocation.Longitude,
	)

	// Calculate speed from distance and time
	calculatedSpeed := (distance / timeDiff) * 3600 // km/h

	// Check for teleportation (impossible speed)
	if calculatedSpeed > 150 { // 150 km/h is physically impossible for a rider
		return &SpoofingDetectionResult{
			IsSpoofing: true,
			AlertType:  "teleportation",
			Confidence: 0.95,
			Reason:     fmt.Sprintf("Impossible speed: %.2f km/h over %.2f seconds", calculatedSpeed, timeDiff),
			ShouldFlag: true,
		}, nil
	}

	// Check for sudden speed changes (acceleration/deceleration)
	speedDiff := math.Abs(newLocation.Speed - lastLocation.Speed)
	if speedDiff > 50 { // Sudden speed change of 50 km/h
		return &SpoofingDetectionResult{
			IsSpoofing: true,
			AlertType:  "sudden_speed_change",
			Confidence: 0.7,
			Reason:     fmt.Sprintf("Sudden speed change: %.2f km/h", speedDiff),
			ShouldFlag: true,
		}, nil
	}

	// Check for location jumps (distance too large for time)
	if distance > 5.0 && timeDiff < 60 { // 5km in less than 60 seconds
		return &SpoofingDetectionResult{
			IsSpoofing: true,
			AlertType:  "location_jump",
			Confidence: 0.85,
			Reason:     fmt.Sprintf("Location jump: %.2f km in %.2f seconds", distance, timeDiff),
			ShouldFlag: true,
		}, nil
	}

	// Check for inconsistent bearing
	if gsd.isInconsistentBearing(lastLocation, newLocation) {
		return &SpoofingDetectionResult{
			IsSpoofing: true,
			AlertType:  "inconsistent_bearing",
			Confidence: 0.6,
			Reason:     "Bearing inconsistent with movement direction",
			ShouldFlag: false, // Lower confidence, don't auto-flag
		}, nil
	}

	return &SpoofingDetectionResult{
		IsSpoofing: false,
		AlertType:  "none",
		Confidence: 0.0,
		Reason:     "No spoofing detected",
		ShouldFlag: false,
	}, nil
}

// AnalyzeLocationHistory analyzes rider's location history for patterns
func (gsd *GPSSpoofingDetector) AnalyzeLocationHistory(ctx context.Context, riderID uuid.UUID, since time.Time) ([]*SpoofingDetectionResult, error) {
	history, err := gsd.locationRepo.GetRiderLocationHistory(ctx, riderID, since)
	if err != nil {
		return nil, fmt.Errorf("failed to get location history: %w", err)
	}

	var results []*SpoofingDetectionResult

	for i := 1; i < len(history); i++ {
		result, err := gsd.DetectSpoofing(ctx, riderID, history[i])
		if err != nil {
			continue
		}
		results = append(results, result)
	}

	return results, nil
}

// CreateSpoofingAlert creates an alert for detected spoofing
func (gsd *GPSSpoofingDetector) CreateSpoofingAlert(ctx context.Context, riderID uuid.UUID, result *SpoofingDetectionResult, location1, location2 *RiderLocation) error {
	if !result.ShouldFlag {
		return nil
	}

	alert := &SpoofingAlert{
		ID:          uuid.New(),
		RiderID:     riderID,
		AlertType:   result.AlertType,
		Description: result.Reason,
		Severity:    "high",
		Location1:   location1,
		Location2:   location2,
		DetectedAt:  time.Now(),
	}

	return gsd.alertService.CreateAlert(ctx, alert)
}

// calculateDistance calculates distance between two points using Haversine formula
func (gsd *GPSSpoofingDetector) calculateDistance(lat1, lng1, lat2, lng2 float64) float64 {
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

// isInconsistentBearing checks if the bearing is consistent with movement direction
func (gsd *GPSSpoofingDetector) isInconsistentBearing(loc1, loc2 *RiderLocation) bool {
	// Calculate expected bearing from movement
	expectedBearing := gsd.calculateBearing(
		loc1.Latitude, loc1.Longitude,
		loc2.Latitude, loc2.Longitude,
	)

	// Compare with reported bearing
	bearingDiff := math.Abs(expectedBearing - loc2.Bearing)
	
	// Allow 45 degree tolerance
	return bearingDiff > 45
}

// calculateBearing calculates the bearing between two points
func (gsd *GPSSpoofingDetector) calculateBearing(lat1, lng1, lat2, lng2 float64) float64 {
	lat1Rad := lat1 * math.Pi / 180.0
	lat2Rad := lat2 * math.Pi / 180.0
	deltaLng := (lng2 - lng1) * math.Pi / 180.0

	x := math.Sin(deltaLng) * math.Cos(lat2Rad)
	y := math.Cos(lat1Rad)*math.Sin(lat2Rad) -
		math.Sin(lat1Rad)*math.Cos(lat2Rad)*math.Cos(deltaLng)

	bearing := math.Atan2(x, y) * 180.0 / math.Pi
	
	// Normalize to 0-360
	if bearing < 0 {
		bearing += 360
	}

	return bearing
}

// GetSpoofingScore calculates an overall spoofing score for a rider
func (gsd *GPSSpoofingDetector) GetSpoofingScore(ctx context.Context, riderID uuid.UUID, hours int) (float64, error) {
	since := time.Now().Add(-time.Duration(hours) * time.Hour)
	results, err := gsd.AnalyzeLocationHistory(ctx, riderID, since)
	if err != nil {
		return 0.0, err
	}

	if len(results) == 0 {
		return 0.0, nil
	}

	spoofingCount := 0
	totalConfidence := 0.0

	for _, result := range results {
		if result.IsSpoofing {
			spoofingCount++
			totalConfidence += result.Confidence
		}
	}

	// Calculate overall score (0-1)
	spoofingRatio := float64(spoofingCount) / float64(len(results))
	avgConfidence := totalConfidence / float64(spoofingCount)

	return spoofingRatio * avgConfidence, nil
}
