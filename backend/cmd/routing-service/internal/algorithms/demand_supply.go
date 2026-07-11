package algorithms

import (
	"math"
	"time"
)

// DemandSupplyAnalyzer analyzes demand and supply patterns
type DemandSupplyAnalyzer struct {
	HistoricalData []DemandSnapshot
	CurrentData    []DemandSnapshot
}

type DemandSnapshot struct {
	ZoneID          string
	Timestamp       time.Time
	PendingOrders   int
	ActiveRiders    int
	DemandScore     float64
	SupplyScore     float64
	ImbalanceFactor float64
	SurgeMultiplier float64
}

type ZoneDemand struct {
	ZoneID          string
	CurrentDemand   float64
	PredictedDemand float64
	CurrentSupply   float64
	PredictedSupply float64
	ImbalanceFactor float64
	SurgeMultiplier float64
	Recommendation  string
}

// AnalyzeDemandSupply analyzes current demand-supply situation
func (d *DemandSupplyAnalyzer) AnalyzeDemandSupply() ([]ZoneDemand, error) {
	zones := make(map[string]*ZoneDemand)

	// Analyze current data
	for _, snapshot := range d.CurrentData {
		if _, exists := zones[snapshot.ZoneID]; !exists {
			zones[snapshot.ZoneID] = &ZoneDemand{
				ZoneID: snapshot.ZoneID,
			}
		}

		zone := zones[snapshot.ZoneID]
		zone.CurrentDemand = float64(snapshot.PendingOrders)
		zone.CurrentSupply = float64(snapshot.ActiveRiders)
		zone.ImbalanceFactor = snapshot.ImbalanceFactor
		zone.SurgeMultiplier = snapshot.SurgeMultiplier
	}

	// Predict future demand using historical patterns
	for zoneID, zone := range zones {
		zone.PredictedDemand = d.predictDemand(zoneID)
		zone.PredictedSupply = d.predictSupply(zoneID)
		zone.Recommendation = d.generateRecommendation(zone)
	}

	result := make([]ZoneDemand, 0, len(zones))
	for _, zone := range zones {
		result = append(result, *zone)
	}

	return result, nil
}

// predictDemand predicts future demand based on historical data
func (d *DemandSupplyAnalyzer) predictDemand(zoneID string) float64 {
	// Simple time-series prediction using weighted average
	relevantData := d.getHistoricalData(zoneID, 7*24*time.Hour) // Last 7 days

	if len(relevantData) == 0 {
		return 0
	}

	// Calculate weighted average (more recent data has higher weight)
	weights := calculateExponentialWeights(len(relevantData))
	predictedDemand := 0.0

	for i, data := range relevantData {
		predictedDemand += float64(data.PendingOrders) * weights[i]
	}

	// Apply time-of-day adjustment
	now := time.Now()
	timeOfDayFactor := d.getTimeOfDayFactor(now.Hour())
	predictedDemand *= timeOfDayFactor

	// Apply day-of-week adjustment
	dayOfWeekFactor := d.getDayOfWeekFactor(now.Weekday())
	predictedDemand *= dayOfWeekFactor

	return predictedDemand
}

// predictSupply predicts future supply based on historical data
func (d *DemandSupplyAnalyzer) predictSupply(zoneID string) float64 {
	relevantData := d.getHistoricalData(zoneID, 7*24*time.Hour)

	if len(relevantData) == 0 {
		return 0
	}

	weights := calculateExponentialWeights(len(relevantData))
	predictedSupply := 0.0

	for i, data := range relevantData {
		predictedSupply += float64(data.ActiveRiders) * weights[i]
	}

	// Apply time-of-day adjustment (riders typically work during peak hours)
	now := time.Now()
	timeOfDayFactor := d.getRiderTimeOfDayFactor(now.Hour())
	predictedSupply *= timeOfDayFactor

	return predictedSupply
}

// getHistoricalData retrieves historical data for a zone
func (d *DemandSupplyAnalyzer) getHistoricalData(zoneID string, duration time.Duration) []DemandSnapshot {
	result := make([]DemandSnapshot, 0)
	cutoff := time.Now().Add(-duration)

	for _, data := range d.HistoricalData {
		if data.ZoneID == zoneID && data.Timestamp.After(cutoff) {
			result = append(result, data)
		}
	}

	return result
}

// getTimeOfDayFactor returns demand multiplier based on time of day
func (d *DemandSupplyAnalyzer) getTimeOfDayFactor(hour int) float64 {
	// Peak meal times: 12-2 PM (lunch), 7-10 PM (dinner)
	if (hour >= 12 && hour < 14) || (hour >= 19 && hour < 22) {
		return 2.0 // High demand
	}
	if (hour >= 11 && hour < 15) || (hour >= 18 && hour < 23) {
		return 1.5 // Moderate demand
	}
	if hour >= 8 && hour < 11 {
		return 1.2 // Breakfast demand
	}
	return 0.8 // Low demand
}

// getRiderTimeOfDayFactor returns supply multiplier based on time of day
func (d *DemandSupplyAnalyzer) getRiderTimeOfDayFactor(hour int) float64 {
	// Riders typically work during peak hours
	if (hour >= 11 && hour < 15) || (hour >= 18 && hour < 23) {
		return 1.5 // High rider availability
	}
	if hour >= 10 && hour < 24 {
		return 1.2 // Moderate rider availability
	}
	return 0.5 // Low rider availability (night shift)
}

// getDayOfWeekFactor returns demand multiplier based on day of week
func (d *DemandSupplyAnalyzer) getDayOfWeekFactor(day time.Weekday) float64 {
	// Weekends have higher demand
	if day == time.Saturday || day == time.Sunday {
		return 1.5
	}
	// Friday evening is also high
	if day == time.Friday {
		return 1.3
	}
	return 1.0 // Normal weekday
}

// generateRecommendation generates recommendations based on demand-supply analysis
func (d *DemandSupplyAnalyzer) generateRecommendation(zone *ZoneDemand) string {
	demandSupplyRatio := zone.CurrentDemand / (zone.CurrentSupply + 0.001)

	if demandSupplyRatio > 3.0 {
		return "CRITICAL: High demand, low supply. Increase surge pricing and dispatch more riders."
	}
	if demandSupplyRatio > 2.0 {
		return "HIGH: Demand exceeds supply. Apply surge pricing and notify nearby riders."
	}
	if demandSupplyRatio > 1.5 {
		return "MODERATE: Slight demand-supply imbalance. Monitor closely."
	}
	if demandSupplyRatio < 0.5 {
		return "LOW: Excess supply. Consider reducing surge pricing or redirecting riders."
	}
	return "NORMAL: Balanced demand and supply."
}

// calculateExponentialWeights calculates exponential weights for time series
func calculateExponentialWeights(n int) []float64 {
	if n == 0 {
		return []float64{}
	}

	weights := make([]float64, n)
	alpha := 0.3 // Smoothing factor

	// Calculate weights (most recent has highest weight)
	for i := 0; i < n; i++ {
		weights[i] = math.Pow(1-alpha, float64(n-1-i))
	}

	// Normalize weights
	sum := 0.0
	for _, w := range weights {
		sum += w
	}

	for i := range weights {
		weights[i] /= sum
	}

	return weights
}

// RiderOptimizer optimizes rider allocation across zones
type RiderOptimizer struct {
	Zones          []ZoneDemand
	RiderLocations []RiderLocation
}

type RiderLocation struct {
	RiderID     string
	ZoneID      string
	Latitude    float64
	Longitude   float64
	IsAvailable bool
}

type RiderAllocation struct {
	RiderID      string
	FromZoneID   string
	ToZoneID     string
	Priority     int
	EstimatedETA time.Duration
}

// OptimizeRiderAllocation optimizes rider allocation across zones
func (r *RiderOptimizer) OptimizeRiderAllocation() ([]RiderAllocation, error) {
	allocations := make([]RiderAllocation, 0)

	// Find zones with high demand-supply imbalance
	highDemandZones := r.getHighDemandZones()

	// Match riders from low-demand zones to high-demand zones
	for _, rider := range r.RiderLocations {
		if !rider.IsAvailable {
			continue
		}

		riderZone := r.getZoneByID(rider.ZoneID)
		if riderZone == nil {
			continue
		}

		// If rider is in low-demand zone, consider moving to high-demand zone
		if r.isLowDemandZone(rider.ZoneID) {
			bestZone := r.findBestDestinationZone(rider, highDemandZones)
			if bestZone != nil {
				allocations = append(allocations, RiderAllocation{
					RiderID:      rider.RiderID,
					FromZoneID:   rider.ZoneID,
					ToZoneID:     bestZone.ZoneID,
					Priority:     r.calculatePriority(bestZone),
					EstimatedETA: r.calculateETA(rider, bestZone),
				})
			}
		}
	}

	// Sort by priority
	sortAllocationsByPriority(allocations)

	return allocations, nil
}

func (r *RiderOptimizer) getHighDemandZones() []ZoneDemand {
	result := make([]ZoneDemand, 0)
	for _, zone := range r.Zones {
		if zone.ImbalanceFactor > 2.0 {
			result = append(result, zone)
		}
	}
	return result
}

func (r *RiderOptimizer) getLowSupplyZones() []ZoneDemand {
	result := make([]ZoneDemand, 0)
	for _, zone := range r.Zones {
		if zone.ImbalanceFactor < 0.5 {
			result = append(result, zone)
		}
	}
	return result
}

func (r *RiderOptimizer) getZoneByID(zoneID string) *ZoneDemand {
	for _, zone := range r.Zones {
		if zone.ZoneID == zoneID {
			return &zone
		}
	}
	return nil
}

func (r *RiderOptimizer) isLowDemandZone(zoneID string) bool {
	zone := r.getZoneByID(zoneID)
	return zone != nil && zone.ImbalanceFactor < 0.8
}

func (r *RiderOptimizer) findBestDestinationZone(rider RiderLocation, highDemandZones []ZoneDemand) *ZoneDemand {
	bestZone := highDemandZones[0]
	minDistance := math.MaxFloat64

	for _, zone := range highDemandZones {
		distance := calculateDistance(
			rider.Latitude, rider.Longitude,
			0, 0, // Zone center (simplified)
		)
		if distance < minDistance {
			minDistance = distance
			bestZone = zone
		}
	}

	return &bestZone
}

func (r *RiderOptimizer) calculatePriority(zone *ZoneDemand) int {
	if zone.ImbalanceFactor > 3.0 {
		return 3 // Critical
	}
	if zone.ImbalanceFactor > 2.0 {
		return 2 // High
	}
	return 1 // Moderate
}

func (r *RiderOptimizer) calculateETA(rider RiderLocation, zone *ZoneDemand) time.Duration {
	// Simplified ETA calculation (in production, use actual routing)
	distance := 5.0  // km (simplified)
	avgSpeed := 20.0 // km/h
	return time.Duration(distance/avgSpeed) * time.Hour
}

func calculateDistance(lat1, lon1, lat2, lon2 float64) float64 {
	// Haversine formula
	const earthRadius = 6371.0
	lat1Rad := lat1 * math.Pi / 180
	lat2Rad := lat2 * math.Pi / 180
	deltaLat := (lat2 - lat1) * math.Pi / 180
	deltaLon := (lon2 - lon1) * math.Pi / 180
	a := math.Sin(deltaLat/2)*math.Sin(deltaLat/2) +
		math.Cos(lat1Rad)*math.Cos(lat2Rad)*
			math.Sin(deltaLon/2)*math.Sin(deltaLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return earthRadius * c
}

func sortAllocationsByPriority(allocations []RiderAllocation) {
	for i := 0; i < len(allocations); i++ {
		for j := i + 1; j < len(allocations); j++ {
			if allocations[i].Priority < allocations[j].Priority {
				allocations[i], allocations[j] = allocations[j], allocations[i]
			}
		}
	}
}
