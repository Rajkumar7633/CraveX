package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Zone struct {
	ID          uuid.UUID `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	Name        string    `json:"name" gorm:"not null"`
	Polygon     string    `json:"polygon" gorm:"type:jsonb"` // GeoJSON polygon
	City        string    `json:"city" gorm:"not null"`
	BaseDemand  float64   `json:"base_demand" gorm:"default:1.0"` // Base demand multiplier
	BaseSupply  float64   `json:"base_supply" gorm:"default:1.0"` // Base supply multiplier
	CreatedAt   time.Time `json:"created_at" gorm:"autoCreateTime"`
	UpdatedAt   time.Time `json:"updated_at" gorm:"autoUpdateTime"`
}

type DemandSnapshot struct {
	ID              uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	ZoneID          uuid.UUID  `json:"zone_id" gorm:"not null;index"`
	PendingOrders   int        `json:"pending_orders" gorm:"not null"`
	ActiveRiders    int        `json:"active_riders" gorm:"not null"`
	DemandScore     float64    `json:"demand_score" gorm:"not null"` // 0-100
	SupplyScore     float64    `json:"supply_score" gorm:"not null"` // 0-100
	ImbalanceFactor float64    `json:"imbalance_factor" gorm:"not null"` // demand/supply ratio
	SurgeMultiplier float64    `json:"surge_multiplier" gorm:"default:1.0"`
	Timestamp       time.Time  `json:"timestamp" gorm:"autoCreateTime"`
}

type RouteOptimization struct {
	ID               uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	RiderID          uuid.UUID  `json:"rider_id" gorm:"not null;index"`
	OrderIDs         string     `json:"order_ids" gorm:"type:jsonb"` // Array of order IDs
	OptimizedRoute   string     `json:"optimized_route" gorm:"type:jsonb"` // GeoJSON LineString
	TotalDistance    float64    `json:"total_distance" gorm:"not null"`
	TotalDuration    int        `json:"total_duration" gorm:"not null"` // in seconds
	Savings          float64    `json:"savings" gorm:"default:0.00"` // Distance/time saved
	AlgorithmUsed    string     `json:"algorithm_used" gorm:"not null"`
	ComputedAt       time.Time  `json:"computed_at" gorm:"autoCreateTime"`
}

type RiderLocation struct {
	ID           uuid.UUID  `json:"id" gorm:"type:uuid;primary_key;default:uuid_generate_v4()"`
	RiderID      uuid.UUID  `json:"rider_id" gorm:"not null;index"`
	Latitude     float64    `json:"latitude" gorm:"not null"`
	Longitude    float64    `json:"longitude" gorm:"not null"`
	Heading      float64    `json:"heading" gorm:"default:0"`
	Speed        float64    `json:"speed" gorm:"default:0"`
	Accuracy     float64    `json:"accuracy" gorm:"default:0"`
	Timestamp    time.Time  `json:"timestamp" gorm:"autoCreateTime"`
}

// BeforeCreate hooks
func (z *Zone) BeforeCreate(tx *gorm.DB) error {
	if z.ID == uuid.Nil {
		z.ID = uuid.New()
	}
	return nil
}

func (ds *DemandSnapshot) BeforeCreate(tx *gorm.DB) error {
	if ds.ID == uuid.Nil {
		ds.ID = uuid.New()
	}
	return nil
}

func (ro *RouteOptimization) BeforeCreate(tx *gorm.DB) error {
	if ro.ID == uuid.Nil {
		ro.ID = uuid.New()
	}
	return nil
}

func (rl *RiderLocation) BeforeCreate(tx *gorm.DB) error {
	if rl.ID == uuid.Nil {
		rl.ID = uuid.New()
	}
	return nil
}
