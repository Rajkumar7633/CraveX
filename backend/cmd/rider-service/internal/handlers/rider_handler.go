package handlers

import (
	"fmt"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
	"github.com/zomato-clone/rider-service/internal/models"
	"github.com/zomato-clone/rider-service/internal/services"
)

type RiderHandler struct {
	riderService   services.RiderService
	earningService services.RiderEarningService
}

func NewRiderHandler(riderService services.RiderService, earningService services.RiderEarningService) *RiderHandler {
	return &RiderHandler{
		riderService:   riderService,
		earningService: earningService,
	}
}

func (h *RiderHandler) CreateRider(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	userUUID, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user ID"})
		return
	}

	var req models.CreateRiderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	rider, err := h.riderService.CreateRider(userUUID, &req)
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusCreated, rider)
}

func (h *RiderHandler) GetRider(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid rider ID"})
		return
	}

	rider, err := h.riderService.GetRider(id)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "rider not found"})
		return
	}

	c.JSON(http.StatusOK, rider)
}

func (h *RiderHandler) GetMyProfile(c *gin.Context) {
	userID, exists := c.Get("user_id")
	if !exists {
		c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
		return
	}

	userUUID, err := uuid.Parse(userID.(string))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid user ID"})
		return
	}

	rider, err := h.riderService.GetRiderByUserID(userUUID)
	if err != nil {
		c.JSON(http.StatusNotFound, gin.H{"error": "rider profile not found"})
		return
	}

	c.JSON(http.StatusOK, rider)
}

func (h *RiderHandler) UpdateRider(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid rider ID"})
		return
	}

	var req models.UpdateRiderRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.riderService.UpdateRider(id, &req); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "rider updated successfully"})
}

func (h *RiderHandler) UpdateLocation(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid rider ID"})
		return
	}

	var req models.UpdateLocationRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.riderService.UpdateLocation(id, req.Latitude, req.Longitude); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "location updated successfully"})
}

func (h *RiderHandler) ToggleOnlineStatus(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid rider ID"})
		return
	}

	var req models.ToggleOnlineRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.riderService.ToggleOnlineStatus(id, req.IsOnline); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "online status updated successfully"})
}

func (h *RiderHandler) UpdateAvailability(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid rider ID"})
		return
	}

	var req struct {
		IsAvailable bool `json:"is_available" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
		return
	}

	if err := h.riderService.UpdateAvailability(id, req.IsAvailable); err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"message": "availability updated successfully"})
}

func (h *RiderHandler) FindAvailableNearby(c *gin.Context) {
	lat := c.Query("lat")
	lng := c.Query("lng")
	radius := c.Query("radius")

	if lat == "" || lng == "" {
		c.JSON(http.StatusBadRequest, gin.H{"error": "latitude and longitude are required"})
		return
	}

	latitude := parseFloat(lat)
	longitude := parseFloat(lng)
	radiusKm := 5.0 // default 5km
	if radius != "" {
		radiusKm = parseFloat(radius)
	}

	riders, err := h.riderService.FindAvailableNearby(latitude, longitude, radiusKm)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, riders)
}

func (h *RiderHandler) GetEarnings(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid rider ID"})
		return
	}

	earnings, err := h.earningService.GetEarnings(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, earnings)
}

func (h *RiderHandler) GetTotalEarnings(c *gin.Context) {
	id, err := uuid.Parse(c.Param("id"))
	if err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"error": "invalid rider ID"})
		return
	}

	total, err := h.earningService.GetTotalEarnings(id)
	if err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
		return
	}

	c.JSON(http.StatusOK, gin.H{"total_earnings": total})
}

func parseFloat(s string) float64 {
	var f float64
	fmt.Sscanf(s, "%f", &f)
	return f
}
