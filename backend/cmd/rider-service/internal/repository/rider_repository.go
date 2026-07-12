package repository

import (
	"time"

	"github.com/google/uuid"
	"github.com/zomato-clone/rider-service/internal/models"
	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

type RiderRepository interface {
	Create(rider *models.Rider) error
	FindByID(id uuid.UUID) (*models.Rider, error)
	FindByUserID(userID uuid.UUID) (*models.Rider, error)
	Update(rider *models.Rider) error
	UpdateLocation(id uuid.UUID, latitude, longitude float64) error
	UpdateOnlineStatus(id uuid.UUID, isOnline bool) error
	UpdateAvailability(id uuid.UUID, isAvailable bool) error
	FindAvailableNearby(latitude, longitude float64, radiusKm float64) ([]*models.Rider, error)
	FindByZone(zoneID string) ([]*models.Rider, error)
}

type riderRepository struct {
	db *gorm.DB
}

func NewRiderRepository(db *gorm.DB) RiderRepository {
	return &riderRepository{db: db}
}

func (r *riderRepository) Create(rider *models.Rider) error {
	return r.db.Create(rider).Error
}

func (r *riderRepository) FindByID(id uuid.UUID) (*models.Rider, error) {
	var rider models.Rider
	err := r.db.Where("id = ?", id).First(&rider).Error
	if err != nil {
		return nil, err
	}
	return &rider, nil
}

func (r *riderRepository) FindByUserID(userID uuid.UUID) (*models.Rider, error) {
	var rider models.Rider
	err := r.db.Where("user_id = ?", userID).First(&rider).Error
	if err != nil {
		return nil, err
	}
	return &rider, nil
}

func (r *riderRepository) Update(rider *models.Rider) error {
	return r.db.Save(rider).Error
}

func (r *riderRepository) UpdateLocation(id uuid.UUID, latitude, longitude float64) error {
	now := time.Now()
	return r.db.Model(&models.Rider{}).Where("id = ?", id).Updates(map[string]interface{}{
		"current_latitude":    latitude,
		"current_longitude":   longitude,
		"last_location_update": now,
	}).Error
}

func (r *riderRepository) UpdateOnlineStatus(id uuid.UUID, isOnline bool) error {
	return r.db.Model(&models.Rider{}).Where("id = ?", id).Update("is_online", isOnline).Error
}

func (r *riderRepository) UpdateAvailability(id uuid.UUID, isAvailable bool) error {
	return r.db.Model(&models.Rider{}).Where("id = ?", id).Update("is_available", isAvailable).Error
}

func (r *riderRepository) FindAvailableNearby(latitude, longitude float64, radiusKm float64) ([]*models.Rider, error) {
	var riders []*models.Rider
	radiusMeters := radiusKm * 1000.0
	err := r.db.Where("is_online = ? AND is_available = ? AND is_active = ?", true, true, true).
		Where("ST_DWithin(location::geography, ST_SetSRID(ST_Point(?, ?), 4326)::geography, ?)", longitude, latitude, radiusMeters).
		Find(&riders).Error
	if err != nil {
		return nil, err
	}
	return riders, nil
}

func (r *riderRepository) FindByZone(zoneID string) ([]*models.Rider, error) {
	var riders []*models.Rider
	err := r.db.Where("zone_id = ? AND is_online = ? AND is_available = ?", zoneID, true, true).Find(&riders).Error
	if err != nil {
		return nil, err
	}
	return riders, nil
}

type RiderEarningRepository interface {
	Create(earning *models.RiderEarning) error
	FindByRiderID(riderID uuid.UUID) ([]*models.RiderEarning, error)
	FindByDateRange(riderID uuid.UUID, startDate, endDate time.Time) ([]*models.RiderEarning, error)
	GetTotalEarnings(riderID uuid.UUID) (float64, error)
}

type riderEarningRepository struct {
	db *gorm.DB
}

func NewRiderEarningRepository(db *gorm.DB) RiderEarningRepository {
	return &riderEarningRepository{db: db}
}

func (r *riderEarningRepository) Create(earning *models.RiderEarning) error {
	return r.db.Create(earning).Error
}

func (r *riderEarningRepository) FindByRiderID(riderID uuid.UUID) ([]*models.RiderEarning, error) {
	var earnings []*models.RiderEarning
	err := r.db.Where("rider_id = ?", riderID).Order("earned_at DESC").Find(&earnings).Error
	if err != nil {
		return nil, err
	}
	return earnings, nil
}

func (r *riderEarningRepository) FindByDateRange(riderID uuid.UUID, startDate, endDate time.Time) ([]*models.RiderEarning, error) {
	var earnings []*models.RiderEarning
	err := r.db.Where("rider_id = ? AND earned_at >= ? AND earned_at <= ?", riderID, startDate, endDate).Order("earned_at DESC").Find(&earnings).Error
	if err != nil {
		return nil, err
	}
	return earnings, nil
}

func (r *riderEarningRepository) GetTotalEarnings(riderID uuid.UUID) (float64, error) {
	var total float64
	err := r.db.Model(&models.RiderEarning{}).Where("rider_id = ?", riderID).Select("COALESCE(SUM(total_earned), 0)").Scan(&total).Error
	return total, err
}

func InitDB(databaseURL string) (*gorm.DB, error) {
	db, err := gorm.Open(postgres.Open(databaseURL), &gorm.Config{})
	if err != nil {
		return nil, err
	}

	// Auto migrate tables
	err = db.AutoMigrate(
		&models.Rider{},
		&models.RiderDocument{},
		&models.RiderEarning{},
	)
	if err != nil {
		return nil, err
	}

	return db, nil
}
