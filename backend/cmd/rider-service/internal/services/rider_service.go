package services

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/zomato-clone/rider-service/internal/models"
	"github.com/zomato-clone/rider-service/internal/repository"
)

type RiderService interface {
	CreateRider(userID uuid.UUID, req *models.CreateRiderRequest) (*models.Rider, error)
	GetRider(id uuid.UUID) (*models.Rider, error)
	GetRiderByUserID(userID uuid.UUID) (*models.Rider, error)
	UpdateRider(id uuid.UUID, req *models.UpdateRiderRequest) error
	UpdateLocation(id uuid.UUID, latitude, longitude float64) error
	ToggleOnlineStatus(id uuid.UUID, isOnline bool) error
	UpdateAvailability(id uuid.UUID, isAvailable bool) error
	FindAvailableNearby(latitude, longitude float64, radiusKm float64) ([]*models.Rider, error)
}

type riderService struct {
	riderRepo repository.RiderRepository
}

func NewRiderService(riderRepo repository.RiderRepository) RiderService {
	return &riderService{
		riderRepo: riderRepo,
	}
}

func (s *riderService) CreateRider(userID uuid.UUID, req *models.CreateRiderRequest) (*models.Rider, error) {
	// Check if user already has a rider profile
	existingRider, _ := s.riderRepo.FindByUserID(userID)
	if existingRider != nil {
		return nil, errors.New("user already has a rider profile")
	}

	rider := &models.Rider{
		UserID:          userID,
		VehicleType:     req.VehicleType,
		VehicleNumber:   req.VehicleNumber,
		VehicleModel:    req.VehicleModel,
		LicenseNumber:   req.LicenseNumber,
		ZoneID:          req.ZoneID,
		IsOnline:        false,
		IsAvailable:     true,
		IsVerified:      false,
		IsActive:        true,
		Rating:          0.00,
		TotalDeliveries: 0,
		TotalEarnings:   0.00,
	}

	if err := s.riderRepo.Create(rider); err != nil {
		return nil, err
	}

	return rider, nil
}

func (s *riderService) GetRider(id uuid.UUID) (*models.Rider, error) {
	return s.riderRepo.FindByID(id)
}

func (s *riderService) GetRiderByUserID(userID uuid.UUID) (*models.Rider, error) {
	return s.riderRepo.FindByUserID(userID)
}

func (s *riderService) UpdateRider(id uuid.UUID, req *models.UpdateRiderRequest) error {
	rider, err := s.riderRepo.FindByID(id)
	if err != nil {
		return err
	}

	if req.VehicleType != nil {
		rider.VehicleType = *req.VehicleType
	}
	if req.VehicleNumber != nil {
		rider.VehicleNumber = *req.VehicleNumber
	}
	if req.VehicleModel != nil {
		rider.VehicleModel = *req.VehicleModel
	}
	if req.LicenseNumber != nil {
		rider.LicenseNumber = *req.LicenseNumber
	}
	if req.CurrentLatitude != nil {
		rider.CurrentLatitude = req.CurrentLatitude
	}
	if req.CurrentLongitude != nil {
		rider.CurrentLongitude = req.CurrentLongitude
	}
	if req.IsOnline != nil {
		rider.IsOnline = *req.IsOnline
	}
	if req.IsAvailable != nil {
		rider.IsAvailable = *req.IsAvailable
	}
	if req.ZoneID != nil {
		rider.ZoneID = *req.ZoneID
	}

	return s.riderRepo.Update(rider)
}

func (s *riderService) UpdateLocation(id uuid.UUID, latitude, longitude float64) error {
	return s.riderRepo.UpdateLocation(id, latitude, longitude)
}

func (s *riderService) ToggleOnlineStatus(id uuid.UUID, isOnline bool) error {
	return s.riderRepo.UpdateOnlineStatus(id, isOnline)
}

func (s *riderService) UpdateAvailability(id uuid.UUID, isAvailable bool) error {
	return s.riderRepo.UpdateAvailability(id, isAvailable)
}

func (s *riderService) FindAvailableNearby(latitude, longitude float64, radiusKm float64) ([]*models.Rider, error) {
	return s.riderRepo.FindAvailableNearby(latitude, longitude, radiusKm)
}

type RiderEarningService interface {
	AddEarning(riderID, orderID uuid.UUID, deliveryFee, tipAmount, bonusAmount float64) error
	GetEarnings(riderID uuid.UUID) ([]*models.RiderEarning, error)
	GetEarningsByDateRange(riderID uuid.UUID, startDate, endDate time.Time) ([]*models.RiderEarning, error)
	GetTotalEarnings(riderID uuid.UUID) (float64, error)
}

type riderEarningService struct {
	earningRepo repository.RiderEarningRepository
	riderRepo   repository.RiderRepository
}

func NewRiderEarningService(earningRepo repository.RiderEarningRepository, riderRepo repository.RiderRepository) RiderEarningService {
	return &riderEarningService{
		earningRepo: earningRepo,
		riderRepo:   riderRepo,
	}
}

func (s *riderEarningService) AddEarning(riderID, orderID uuid.UUID, deliveryFee, tipAmount, bonusAmount float64) error {
	totalEarned := deliveryFee + tipAmount + bonusAmount

	earning := &models.RiderEarning{
		RiderID:     riderID,
		OrderID:     orderID,
		DeliveryFee: deliveryFee,
		TipAmount:   tipAmount,
		BonusAmount: bonusAmount,
		TotalEarned: totalEarned,
	}

	if err := s.earningRepo.Create(earning); err != nil {
		return err
	}

	// Update rider total earnings
	rider, err := s.riderRepo.FindByID(riderID)
	if err != nil {
		return err
	}

	rider.TotalEarnings += totalEarned
	rider.TotalDeliveries += 1

	return s.riderRepo.Update(rider)
}

func (s *riderEarningService) GetEarnings(riderID uuid.UUID) ([]*models.RiderEarning, error) {
	return s.earningRepo.FindByRiderID(riderID)
}

func (s *riderEarningService) GetEarningsByDateRange(riderID uuid.UUID, startDate, endDate time.Time) ([]*models.RiderEarning, error) {
	return s.earningRepo.FindByDateRange(riderID, startDate, endDate)
}

func (s *riderEarningService) GetTotalEarnings(riderID uuid.UUID) (float64, error) {
	return s.earningRepo.GetTotalEarnings(riderID)
}
