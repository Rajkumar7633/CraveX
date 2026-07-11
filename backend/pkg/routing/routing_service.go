package routing

import (
	"context"
	"fmt"
	"math"
	"math/rand"
	"sort"
	"time"

	"github.com/google/uuid"
)

type Location struct {
	Latitude  float64 `json:"latitude"`
	Longitude float64 `json:"longitude"`
}

type RoutePoint struct {
	Location Location `json:"location"`
	Address  string   `json:"address"`
	Type     string   `json:"type"` // "pickup", "delivery"
}

type Route struct {
	ID            uuid.UUID     `json:"id"`
	RiderID       uuid.UUID     `json:"rider_id"`
	OrderID       uuid.UUID     `json:"order_id"`
	Points        []RoutePoint  `json:"points"`
	TotalDistance float64       `json:"total_distance"`
	EstimatedTime time.Duration `json:"estimated_time"`
	OptimizedAt   time.Time     `json:"optimized_at"`
}

type RiderLocation struct {
	RiderID   uuid.UUID `json:"rider_id"`
	Location  Location  `json:"location"`
	Bearing   float64   `json:"bearing"`
	Speed     float64   `json:"speed"`
	UpdatedAt time.Time `json:"updated_at"`
}

type DeliveryRequest struct {
	OrderID            uuid.UUID  `json:"order_id"`
	RestaurantLocation Location   `json:"restaurant_location"`
	DeliveryLocation   Location   `json:"delivery_location"`
	Priority           int        `json:"priority"` // 1-10, higher is more urgent
	TimeWindow         TimeWindow `json:"time_window"`
}

type TimeWindow struct {
	StartTime time.Time `json:"start_time"`
	EndTime   time.Time `json:"end_time"`
}

type RoutingAlgorithm string

const (
	AlgorithmNearestNeighbor    RoutingAlgorithm = "nearest_neighbor"
	AlgorithmGenetic            RoutingAlgorithm = "genetic"
	AlgorithmSimulatedAnnealing RoutingAlgorithm = "simulated_annealing"
	AlgorithmAntColony          RoutingAlgorithm = "ant_colony"
)

type RoutingService struct {
	cacheService   CacheService
	mappingService MappingService
}

type CacheService interface {
	Get(ctx context.Context, key string) (string, error)
	Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error
	Delete(ctx context.Context, keys ...string) error
}

type MappingService interface {
	CalculateDistance(ctx context.Context, from, to Location) (float64, error)
	CalculateRoute(ctx context.Context, from, to Location) ([]RoutePoint, float64, time.Duration, error)
	GetTrafficData(ctx context.Context, location Location, radius float64) (float64, error)
}

func NewRoutingService(cacheService CacheService, mappingService MappingService) *RoutingService {
	return &RoutingService{
		cacheService:   cacheService,
		mappingService: mappingService,
	}
}

func (rs *RoutingService) OptimizeRoute(ctx context.Context, riderID uuid.UUID, requests []DeliveryRequest, algorithm RoutingAlgorithm) (*Route, error) {
	if len(requests) == 0 {
		return nil, fmt.Errorf("no delivery requests")
	}

	// Get rider location
	riderLocation, err := rs.getRiderLocation(ctx, riderID)
	if err != nil {
		return nil, fmt.Errorf("failed to get rider location: %w", err)
	}

	// Build initial route points
	points := []RoutePoint{
		{
			Location: riderLocation,
			Type:     "start",
		},
	}

	// Add pickup and delivery points
	for _, req := range requests {
		points = append(points, RoutePoint{
			Location: req.RestaurantLocation,
			Address:  "Restaurant",
			Type:     "pickup",
		})
		points = append(points, RoutePoint{
			Location: req.DeliveryLocation,
			Address:  "Delivery",
			Type:     "delivery",
		})
	}

	// Optimize route based on algorithm
	var optimizedPoints []RoutePoint
	var totalDistance float64
	var estimatedTime time.Duration

	switch algorithm {
	case AlgorithmNearestNeighbor:
		optimizedPoints, totalDistance, estimatedTime, err = rs.nearestNeighborAlgorithm(ctx, points)
	case AlgorithmGenetic:
		optimizedPoints, totalDistance, estimatedTime, err = rs.geneticAlgorithm(ctx, points)
	case AlgorithmSimulatedAnnealing:
		optimizedPoints, totalDistance, estimatedTime, err = rs.simulatedAnnealingAlgorithm(ctx, points)
	case AlgorithmAntColony:
		optimizedPoints, totalDistance, estimatedTime, err = rs.antColonyAlgorithm(ctx, points)
	default:
		optimizedPoints, totalDistance, estimatedTime, err = rs.nearestNeighborAlgorithm(ctx, points)
	}

	if err != nil {
		return nil, fmt.Errorf("route optimization failed: %w", err)
	}

	// Create route
	route := &Route{
		ID:            uuid.New(),
		RiderID:       riderID,
		OrderID:       requests[0].OrderID,
		Points:        optimizedPoints,
		TotalDistance: totalDistance,
		EstimatedTime: estimatedTime,
		OptimizedAt:   time.Now(),
	}

	// Cache route
	cacheKey := fmt.Sprintf("route:%s:%s", riderID.String(), route.ID.String())
	rs.cacheService.Set(ctx, cacheKey, route, 30*time.Minute)

	return route, nil
}

func (rs *RoutingService) AssignBestRider(ctx context.Context, request DeliveryRequest, availableRiders []RiderLocation) (*RiderLocation, float64, error) {
	if len(availableRiders) == 0 {
		return nil, 0, fmt.Errorf("no available riders")
	}

	// Calculate scores for each rider
	type RiderScore struct {
		Rider    RiderLocation
		Score    float64
		Distance float64
		Time     time.Duration
	}

	var riderScores []RiderScore

	for _, rider := range availableRiders {
		// Calculate distance to restaurant
		distance, err := rs.mappingService.CalculateDistance(ctx, rider.Location, request.RestaurantLocation)
		if err != nil {
			continue
		}

		// Calculate estimated time
		timeToRestaurant := rs.calculateEstimatedTime(distance, rider.Speed)

		// Get traffic factor
		trafficFactor := 1.0
		if traffic, err := rs.mappingService.GetTrafficData(ctx, rider.Location, 5.0); err == nil {
			trafficFactor = traffic
		}

		// Calculate score based on multiple factors
		score := rs.calculateRiderScore(rider, distance, timeToRestaurant, trafficFactor, request.Priority)

		riderScores = append(riderScores, RiderScore{
			Rider:    rider,
			Score:    score,
			Distance: distance,
			Time:     timeToRestaurant,
		})
	}

	// Sort by score (higher is better)
	sort.Slice(riderScores, func(i, j int) bool {
		return riderScores[i].Score > riderScores[j].Score
	})

	if len(riderScores) == 0 {
		return nil, 0, fmt.Errorf("no suitable riders found")
	}

	bestRider := riderScores[0]
	return &bestRider.Rider, bestRider.Distance, nil
}

func (rs *RoutingService) nearestNeighborAlgorithm(ctx context.Context, points []RoutePoint) ([]RoutePoint, float64, time.Duration, error) {
	if len(points) < 2 {
		return points, 0, 0, nil
	}

	optimized := make([]RoutePoint, 0, len(points))
	remaining := make([]RoutePoint, len(points))
	copy(remaining, points)

	// Start from first point
	current := remaining[0]
	optimized = append(optimized, current)
	remaining = remaining[1:]

	totalDistance := 0.0
	totalTime := time.Duration(0)

	for len(remaining) > 0 {
		// Find nearest point
		nearestIdx := -1
		nearestDist := math.MaxFloat64

		for i, point := range remaining {
			distance, err := rs.mappingService.CalculateDistance(ctx, current.Location, point.Location)
			if err != nil {
				continue
			}

			if distance < nearestDist {
				nearestDist = distance
				nearestIdx = i
			}
		}

		if nearestIdx == -1 {
			break
		}

		// Add to route
		nearest := remaining[nearestIdx]
		optimized = append(optimized, nearest)
		totalDistance += nearestDist
		totalTime += rs.calculateEstimatedTime(nearestDist, 30.0) // Assume 30 km/h average speed

		current = nearest
		remaining = append(remaining[:nearestIdx], remaining[nearestIdx+1:]...)
	}

	return optimized, totalDistance, totalTime, nil
}

func (rs *RoutingService) geneticAlgorithm(ctx context.Context, points []RoutePoint) ([]RoutePoint, float64, time.Duration, error) {
	const (
		populationSize = 50
		generations    = 100
		mutationRate   = 0.1
		elitismCount   = 5
	)

	if len(points) < 2 {
		return points, 0, 0, nil
	}

	// Initialize population
	population := rs.initializePopulation(points, populationSize)

	for gen := 0; gen < generations; gen++ {
		// Evaluate fitness
		fitnessScores := make([]float64, len(population))
		for i, individual := range population {
			distance, _ := rs.calculateRouteDistance(ctx, individual)
			fitnessScores[i] = 1.0 / (distance + 1.0) // Higher fitness for shorter routes
		}

		// Sort by fitness
		sort.Slice(population, func(i, j int) bool {
			return fitnessScores[i] > fitnessScores[j]
		})

		// Elitism: keep best individuals
		newPopulation := make([][]RoutePoint, 0, populationSize)
		for i := 0; i < elitismCount && i < len(population); i++ {
			newPopulation = append(newPopulation, population[i])
		}

		// Crossover and mutation
		for len(newPopulation) < populationSize {
			parent1 := rs.selectParent(population, fitnessScores)
			parent2 := rs.selectParent(population, fitnessScores)

			child := rs.crossover(parent1, parent2)
			child = rs.mutate(child, mutationRate)

			newPopulation = append(newPopulation, child)
		}

		population = newPopulation
	}

	// Return best solution
	bestRoute := population[0]
	distance, time := rs.calculateRouteDistance(ctx, bestRoute)
	return bestRoute, distance, time, nil
}

func (rs *RoutingService) simulatedAnnealingAlgorithm(ctx context.Context, points []RoutePoint) ([]RoutePoint, float64, time.Duration, error) {
	const (
		initialTemperature = 1000.0
		coolingRate        = 0.995
		minTemperature     = 0.01
	)

	if len(points) < 2 {
		return points, 0, 0, nil
	}

	// Initial solution
	currentSolution := make([]RoutePoint, len(points))
	copy(currentSolution, points)

	currentDistance, _ := rs.calculateRouteDistance(ctx, currentSolution)
	bestSolution := make([]RoutePoint, len(points))
	copy(bestSolution, currentSolution)
	bestDistance := currentDistance

	temperature := initialTemperature

	for temperature > minTemperature {
		// Generate neighbor by swapping two random points
		neighbor := rs.generateNeighbor(currentSolution)
		neighborDistance, _ := rs.calculateRouteDistance(ctx, neighbor)

		// Accept if better or with probability
		delta := neighborDistance - currentDistance
		if delta < 0 || rand.Float64() < math.Exp(-delta/temperature) {
			currentSolution = neighbor
			currentDistance = neighborDistance

			if currentDistance < bestDistance {
				bestSolution = make([]RoutePoint, len(currentSolution))
				copy(bestSolution, currentSolution)
				bestDistance = currentDistance
			}
		}

		temperature *= coolingRate
	}

	time := rs.calculateEstimatedTime(bestDistance, 30.0)
	return bestSolution, bestDistance, time, nil
}

func (rs *RoutingService) antColonyAlgorithm(ctx context.Context, points []RoutePoint) ([]RoutePoint, float64, time.Duration, error) {
	const (
		numAnts       = 20
		numIterations = 100
		alpha         = 1.0 // Pheromone importance
		beta          = 2.0 // Distance importance
		evaporation   = 0.5
		q             = 1.0
	)

	if len(points) < 2 {
		return points, 0, 0, nil
	}

	numPoints := len(points)

	// Initialize pheromone matrix
	pheromones := make([][]float64, numPoints)
	for i := range pheromones {
		pheromones[i] = make([]float64, numPoints)
		for j := range pheromones[i] {
			pheromones[i][j] = 1.0
		}
	}

	bestRoute := make([]RoutePoint, len(points))
	copy(bestRoute, points)
	bestDistance, _ := rs.calculateRouteDistance(ctx, bestRoute)

	for iter := 0; iter < numIterations; iter++ {
		// Each ant constructs a solution
		for ant := 0; ant < numAnts; ant++ {
			route := rs.constructAntRoute(ctx, points, pheromones, alpha, beta)
			distance, _ := rs.calculateRouteDistance(ctx, route)

			if distance < bestDistance {
				bestRoute = route
				bestDistance = distance
			}

			// Update pheromones
			deltaPheromone := q / distance
			for i := 0; i < len(route)-1; i++ {
				fromIdx := rs.findPointIndex(points, route[i])
				toIdx := rs.findPointIndex(points, route[i+1])
				pheromones[fromIdx][toIdx] += deltaPheromone
			}
		}

		// Evaporate pheromones
		for i := range pheromones {
			for j := range pheromones[i] {
				pheromones[i][j] *= (1.0 - evaporation)
			}
		}
	}

	time := rs.calculateEstimatedTime(bestDistance, 30.0)
	return bestRoute, bestDistance, time, nil
}

func (rs *RoutingService) initializePopulation(points []RoutePoint, size int) [][]RoutePoint {
	population := make([][]RoutePoint, size)
	for i := 0; i < size; i++ {
		shuffled := make([]RoutePoint, len(points))
		copy(shuffled, points)

		// Shuffle points (except first which is start point)
		rand.Shuffle(len(shuffled)-1, func(i, j int) {
			shuffled[i+1], shuffled[j+1] = shuffled[j+1], shuffled[i+1]
		})

		population[i] = shuffled
	}
	return population
}

func (rs *RoutingService) calculateRouteDistance(ctx context.Context, points []RoutePoint) (float64, time.Duration) {
	totalDistance := 0.0
	totalTime := time.Duration(0)

	for i := 0; i < len(points)-1; i++ {
		distance, _ := rs.mappingService.CalculateDistance(ctx, points[i].Location, points[i+1].Location)
		totalDistance += distance
		totalTime += rs.calculateEstimatedTime(distance, 30.0)
	}

	return totalDistance, totalTime
}

func (rs *RoutingService) selectParent(population [][]RoutePoint, fitnessScores []float64) []RoutePoint {
	// Tournament selection
	tournamentSize := 5
	bestIdx := rand.Intn(len(population))

	for i := 0; i < tournamentSize; i++ {
		idx := rand.Intn(len(population))
		if fitnessScores[idx] > fitnessScores[bestIdx] {
			bestIdx = idx
		}
	}

	return population[bestIdx]
}

func (rs *RoutingService) crossover(parent1, parent2 []RoutePoint) []RoutePoint {
	// Order crossover (OX1)
	size := len(parent1)
	start := rand.Intn(size)
	end := rand.Intn(size-start) + start

	child := make([]RoutePoint, size)
	for i, p := range parent1 {
		child[i] = p
	}

	// Copy segment from parent2
	segment := parent2[start:end]
	segmentMap := make(map[string]bool)
	for _, p := range segment {
		segmentMap[p.Address] = true
	}

	// Fill remaining positions
	childIdx := 0
	for _, p := range parent2 {
		if !segmentMap[p.Address] {
			for childIdx < start || childIdx >= end {
				childIdx++
			}
			if childIdx < size {
				child[childIdx] = p
				childIdx++
			}
		}
	}

	return child
}

func (rs *RoutingService) mutate(route []RoutePoint, rate float64) []RoutePoint {
	if rand.Float64() > rate {
		return route
	}

	size := len(route)
	i := rand.Intn(size)
	j := rand.Intn(size)

	route[i], route[j] = route[j], route[i]
	return route
}

func (rs *RoutingService) generateNeighbor(route []RoutePoint) []RoutePoint {
	neighbor := make([]RoutePoint, len(route))
	copy(neighbor, route)

	i := rand.Intn(len(neighbor))
	j := rand.Intn(len(neighbor))

	neighbor[i], neighbor[j] = neighbor[j], neighbor[i]
	return neighbor
}

func (rs *RoutingService) constructAntRoute(ctx context.Context, points []RoutePoint, pheromones [][]float64, alpha, beta float64) []RoutePoint {
	visited := make([]bool, len(points))
	route := make([]RoutePoint, 0, len(points))

	current := 0
	visited[current] = true
	route = append(route, points[current])

	for len(route) < len(points) {
		probabilities := make([]float64, len(points))
		total := 0.0

		for i := 0; i < len(points); i++ {
			if visited[i] {
				continue
			}

			distance, _ := rs.mappingService.CalculateDistance(ctx, points[current].Location, points[i].Location)
			pheromone := pheromones[current][i]

			probability := math.Pow(pheromone, alpha) * math.Pow(1.0/(distance+1e-6), beta)
			probabilities[i] = probability
			total += probability
		}

		// Select next point based on probabilities
		r := rand.Float64() * total
		sum := 0.0
		next := -1

		for i := 0; i < len(points); i++ {
			if visited[i] {
				continue
			}
			sum += probabilities[i]
			if sum >= r {
				next = i
				break
			}
		}

		if next == -1 {
			// Select first unvisited
			for i := 0; i < len(points); i++ {
				if !visited[i] {
					next = i
					break
				}
			}
		}

		visited[next] = true
		route = append(route, points[next])
		current = next
	}

	return route
}

func (rs *RoutingService) findPointIndex(points []RoutePoint, point RoutePoint) int {
	for i, p := range points {
		if p.Address == point.Address {
			return i
		}
	}
	return 0
}

func (rs *RoutingService) calculateRiderScore(rider RiderLocation, distance float64, time time.Duration, trafficFactor float64, priority int) float64 {
	// Base score from distance (closer is better)
	distanceScore := 100.0 / (distance + 1.0)

	// Time score (faster is better)
	timeScore := 100.0 / (time.Minutes() + 1.0)

	// Traffic penalty
	trafficScore := distanceScore / trafficFactor

	// Priority multiplier
	priorityMultiplier := 1.0 + float64(priority)/10.0

	// Combined score with weights
	score := (distanceScore * 0.4) + (timeScore * 0.3) + (trafficScore * 0.3)
	score *= priorityMultiplier

	return score
}

func (rs *RoutingService) calculateEstimatedTime(distance float64, speed float64) time.Duration {
	if speed <= 0 {
		speed = 30.0 // Default speed
	}
	hours := distance / speed
	return time.Duration(hours * float64(time.Hour))
}

func (rs *RoutingService) getRiderLocation(ctx context.Context, riderID uuid.UUID) (Location, error) {
	// Fetch rider location from database or cache
	return Location{}, nil
}
