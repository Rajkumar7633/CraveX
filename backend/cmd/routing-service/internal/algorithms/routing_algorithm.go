package algorithms

import (
	"math"
	"sort"
	"time"
)

// Location represents a geographic point
type Location struct {
	Latitude  float64
	Longitude float64
}

// Route represents a delivery route
type Route struct {
	OrderIDs      []string
	TotalDistance float64
	TotalDuration time.Duration
	Stops         []Location
}

// Rider represents a delivery rider
type Rider struct {
	ID           string
	CurrentLoc   Location
	IsAvailable  bool
	VehicleType  string
	ActiveOrders int
}

// Order represents a delivery order
type Order struct {
	ID         string
	PickupLoc  Location
	DropoffLoc Location
	Priority   int // 1-5, 5 being highest
	ReadyAt    time.Time
	Deadline   time.Time
}

// RoutingAlgorithm interface for different routing strategies
type RoutingAlgorithm interface {
	OptimizeRoute(rider *Rider, orders []Order) (*Route, error)
	CalculateDistance(loc1, loc2 Location) float64
	CalculateETA(loc1, loc2 Location, speed float64) time.Duration
}

// NearestNeighborAlgorithm implements greedy nearest neighbor approach
type NearestNeighborAlgorithm struct{}

func (n *NearestNeighborAlgorithm) OptimizeRoute(rider *Rider, orders []Order) (*Route, error) {
	if len(orders) == 0 {
		return &Route{}, nil
	}

	// Start from rider's current location
	currentLoc := rider.CurrentLoc
	unvisited := make([]Order, len(orders))
	copy(unvisited, orders)

	var route Route
	route.Stops = append(route.Stops, currentLoc)
	route.OrderIDs = make([]string, 0)

	for len(unvisited) > 0 {
		// Find nearest unvisited order
		nearestIdx := 0
		minDistance := math.MaxFloat64

		for i, order := range unvisited {
			// Check if order is ready for pickup
			if time.Now().Before(order.ReadyAt) {
				continue
			}

			// Calculate distance to pickup location
			dist := n.CalculateDistance(currentLoc, order.PickupLoc)

			// Consider priority (higher priority orders get preference)
			priorityBonus := float64(order.Priority) * 0.5 // 500m bonus per priority level
			adjustedDist := dist - priorityBonus

			if adjustedDist < minDistance {
				minDistance = adjustedDist
				nearestIdx = i
			}
		}

		if minDistance == math.MaxFloat64 {
			// No ready orders found, wait for the next ready one
			nearestReadyIdx := -1
			earliestReady := time.Now().Add(24 * time.Hour)

			for i, order := range unvisited {
				if order.ReadyAt.Before(earliestReady) {
					earliestReady = order.ReadyAt
					nearestReadyIdx = i
				}
			}

			if nearestReadyIdx == -1 {
				break
			}
			nearestIdx = nearestReadyIdx
		}

		nearestOrder := unvisited[nearestIdx]

		// Add pickup stop
		route.Stops = append(route.Stops, nearestOrder.PickupLoc)
		route.OrderIDs = append(route.OrderIDs, nearestOrder.ID)
		route.TotalDistance += n.CalculateDistance(currentLoc, nearestOrder.PickupLoc)

		// Add dropoff stop
		route.Stops = append(route.Stops, nearestOrder.DropoffLoc)
		route.TotalDistance += n.CalculateDistance(nearestOrder.PickupLoc, nearestOrder.DropoffLoc)

		currentLoc = nearestOrder.DropoffLoc

		// Remove visited order
		unvisited = append(unvisited[:nearestIdx], unvisited[nearestIdx+1:]...)
	}

	// Calculate total duration (assuming average speed of 20 km/h for city delivery)
	avgSpeed := 20.0 // km/h
	route.TotalDuration = time.Duration(route.TotalDistance/avgSpeed) * time.Hour

	return &route, nil
}

func (n *NearestNeighborAlgorithm) CalculateDistance(loc1, loc2 Location) float64 {
	// Haversine formula for calculating distance between two points on Earth
	const earthRadius = 6371.0 // km

	lat1Rad := loc1.Latitude * math.Pi / 180
	lat2Rad := loc2.Latitude * math.Pi / 180
	deltaLat := (loc2.Latitude - loc1.Latitude) * math.Pi / 180
	deltaLon := (loc2.Longitude - loc1.Longitude) * math.Pi / 180

	a := math.Sin(deltaLat/2)*math.Sin(deltaLat/2) +
		math.Cos(lat1Rad)*math.Cos(lat2Rad)*
			math.Sin(deltaLon/2)*math.Sin(deltaLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))

	return earthRadius * c
}

func (n *NearestNeighborAlgorithm) CalculateETA(loc1, loc2 Location, speed float64) time.Duration {
	distance := n.CalculateDistance(loc1, loc2)
	return time.Duration(distance/speed) * time.Hour
}

// GeneticAlgorithm implements genetic algorithm for route optimization
type GeneticAlgorithm struct {
	PopulationSize int
	Generations    int
	MutationRate   float64
	CrossoverRate  float64
	ElitismCount   int
}

func (g *GeneticAlgorithm) OptimizeRoute(rider *Rider, orders []Order) (*Route, error) {
	if len(orders) == 0 {
		return &Route{}, nil
	}

	if len(orders) <= 2 {
		// For small number of orders, use nearest neighbor
		nn := &NearestNeighborAlgorithm{}
		return nn.OptimizeRoute(rider, orders)
	}

	// Initialize population
	population := g.initializePopulation(rider, orders)

	for gen := 0; gen < g.Generations; gen++ {
		// Evaluate fitness
		fitnessScores := g.evaluatePopulation(population, rider)

		// Selection
		selected := g.selection(population, fitnessScores)

		// Crossover
		offspring := g.crossover(selected)

		// Mutation
		g.mutate(offspring)

		// Elitism - keep best individuals
		population = g.elitism(population, offspring, fitnessScores, g.ElitismCount)
	}

	// Get best solution
	bestIdx := g.getBestSolution(population, rider)
	return population[bestIdx], nil
}

func (g *GeneticAlgorithm) initializePopulation(rider *Rider, orders []Order) []*Route {
	population := make([]*Route, g.PopulationSize)

	for i := 0; i < g.PopulationSize; i++ {
		// Create random permutation of orders
		shuffledOrders := make([]Order, len(orders))
		copy(shuffledOrders, orders)

		// Fisher-Yates shuffle
		for j := len(shuffledOrders) - 1; j > 0; j-- {
			k := randInt(0, j+1)
			shuffledOrders[j], shuffledOrders[k] = shuffledOrders[k], shuffledOrders[j]
		}

		population[i] = g.buildRoute(rider, shuffledOrders)
	}

	return population
}

func (g *GeneticAlgorithm) buildRoute(rider *Rider, orders []Order) *Route {
	route := &Route{
		OrderIDs: make([]string, len(orders)),
		Stops:    make([]Location, 0, len(orders)*2+1),
	}

	currentLoc := rider.CurrentLoc
	route.Stops = append(route.Stops, currentLoc)

	for i, order := range orders {
		route.OrderIDs[i] = order.ID
		route.Stops = append(route.Stops, order.PickupLoc)
		route.Stops = append(route.Stops, order.DropoffLoc)
		route.TotalDistance += g.CalculateDistance(currentLoc, order.PickupLoc)
		route.TotalDistance += g.CalculateDistance(order.PickupLoc, order.DropoffLoc)
		currentLoc = order.DropoffLoc
	}

	avgSpeed := 20.0
	route.TotalDuration = time.Duration(route.TotalDistance/avgSpeed) * time.Hour

	return route
}

func (g *GeneticAlgorithm) evaluatePopulation(population []*Route, rider *Rider) []float64 {
	scores := make([]float64, len(population))

	for i, route := range population {
		// Fitness is inverse of total distance (lower distance = higher fitness)
		scores[i] = 1.0 / (route.TotalDistance + 0.001)
	}

	return scores
}

func (g *GeneticAlgorithm) selection(population []*Route, fitnessScores []float64) []*Route {
	selected := make([]*Route, len(population))

	// Tournament selection
	for i := 0; i < len(population); i++ {
		tournamentSize := 3
		bestIdx := randInt(0, len(population))

		for j := 1; j < tournamentSize; j++ {
			competitorIdx := randInt(0, len(population))
			if fitnessScores[competitorIdx] > fitnessScores[bestIdx] {
				bestIdx = competitorIdx
			}
		}

		selected[i] = population[bestIdx]
	}

	return selected
}

func (g *GeneticAlgorithm) crossover(population []*Route) []*Route {
	offspring := make([]*Route, len(population))

	for i := 0; i < len(population); i += 2 {
		if i+1 >= len(population) {
			offspring[i] = population[i]
			break
		}

		if randFloat() < g.CrossoverRate {
			parent1 := population[i]
			parent2 := population[i+1]

			child1, child2 := g.orderCrossover(parent1, parent2)
			offspring[i] = child1
			offspring[i+1] = child2
		} else {
			offspring[i] = population[i]
			offspring[i+1] = population[i+1]
		}
	}

	return offspring
}

func (g *GeneticAlgorithm) orderCrossover(parent1, parent2 *Route) (*Route, *Route) {
	// Order crossover (OX1) for permutation problems
	n := len(parent1.OrderIDs)
	if n < 2 {
		return parent1, parent2
	}

	start := randInt(0, n)
	end := randInt(start+1, n+1)

	child1 := &Route{
		OrderIDs: make([]string, n),
		Stops:    make([]Location, 0),
	}
	child2 := &Route{
		OrderIDs: make([]string, n),
		Stops:    make([]Location, 0),
	}

	// Copy segment from parent1 to child1
	for i := start; i < end; i++ {
		child1.OrderIDs[i] = parent1.OrderIDs[i]
	}

	// Copy segment from parent2 to child2
	for i := start; i < end; i++ {
		child2.OrderIDs[i] = parent2.OrderIDs[i]
	}

	// Fill remaining positions
	g.fillRemaining(child1, parent2, start, end)
	g.fillRemaining(child2, parent1, start, end)

	return child1, child2
}

func (g *GeneticAlgorithm) fillRemaining(child, parent *Route, start, end int) {
	n := len(child.OrderIDs)
	childIdx := 0

	for i := 0; i < n; i++ {
		if childIdx == start {
			childIdx = end
		}

		orderID := parent.OrderIDs[i]
		if !contains(child.OrderIDs[start:end], orderID) {
			child.OrderIDs[childIdx] = orderID
			childIdx++
		}
	}
}

func (g *GeneticAlgorithm) mutate(population []*Route) {
	for _, route := range population {
		if randFloat() < g.MutationRate {
			// Swap mutation
			i := randInt(0, len(route.OrderIDs))
			j := randInt(0, len(route.OrderIDs))
			route.OrderIDs[i], route.OrderIDs[j] = route.OrderIDs[j], route.OrderIDs[i]
		}
	}
}

func (g *GeneticAlgorithm) elitism(population, offspring []*Route, fitnessScores []float64, elitismCount int) []*Route {
	newPopulation := make([]*Route, len(population))

	// Sort by fitness
	sortedIndices := make([]int, len(population))
	for i := range sortedIndices {
		sortedIndices[i] = i
	}

	sort.Slice(sortedIndices, func(i, j int) bool {
		return fitnessScores[sortedIndices[i]] > fitnessScores[sortedIndices[j]]
	})

	// Keep best individuals
	for i := 0; i < elitismCount; i++ {
		newPopulation[i] = population[sortedIndices[i]]
	}

	// Fill rest with offspring
	for i := elitismCount; i < len(population); i++ {
		newPopulation[i] = offspring[i-elitismCount]
	}

	return newPopulation
}

func (g *GeneticAlgorithm) getBestSolution(population []*Route, rider *Rider) int {
	bestIdx := 0
	bestFitness := 0.0

	for i, route := range population {
		fitness := 1.0 / (route.TotalDistance + 0.001)
		if fitness > bestFitness {
			bestFitness = fitness
			bestIdx = i
		}
	}

	return bestIdx
}

func (g *GeneticAlgorithm) CalculateDistance(loc1, loc2 Location) float64 {
	const earthRadius = 6371.0
	lat1Rad := loc1.Latitude * math.Pi / 180
	lat2Rad := loc2.Latitude * math.Pi / 180
	deltaLat := (loc2.Latitude - loc1.Latitude) * math.Pi / 180
	deltaLon := (loc2.Longitude - loc1.Longitude) * math.Pi / 180
	a := math.Sin(deltaLat/2)*math.Sin(deltaLat/2) +
		math.Cos(lat1Rad)*math.Cos(lat2Rad)*
			math.Sin(deltaLon/2)*math.Sin(deltaLon/2)
	c := 2 * math.Atan2(math.Sqrt(a), math.Sqrt(1-a))
	return earthRadius * c
}

func (g *GeneticAlgorithm) CalculateETA(loc1, loc2 Location, speed float64) time.Duration {
	distance := g.CalculateDistance(loc1, loc2)
	return time.Duration(distance/speed) * time.Hour
}

// Helper functions
func randInt(min, max int) int {
	return min + int(float64(max-min)*randFloat())
}

func randFloat() float64 {
	return float64(time.Now().UnixNano()%1000) / 1000.0
}

func contains(slice []string, item string) bool {
	for _, s := range slice {
		if s == item {
			return true
		}
	}
	return false
}
