package cart

import (
	"context"
	"fmt"
	"math"
	"time"

	"github.com/google/uuid"
)

// CartPricingService implements the exact pricing formula from the spec
type CartPricingService struct {
	restaurantService RestaurantService
	cacheService      CacheService
}

type RestaurantService interface {
	GetRestaurant(ctx context.Context, restaurantID uuid.UUID) (*RestaurantInfo, error)
	GetPackagingCharges(ctx context.Context, restaurantID uuid.UUID) (*PackagingCharges, error)
}

type CacheService interface {
	Get(ctx context.Context, key string) (string, error)
	Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error
}

type RestaurantInfo struct {
	ID              uuid.UUID
	City            string
	GSTRate         float64 // Restaurant's GST rate
	PlatformFeeRate float64 // Platform fee rate
}

type PackagingCharges struct {
	Type    string // "per_item" or "flat"
	Amount  float64
	PerItem float64 // If per_item type
}

type CartItem struct {
	ItemID      uuid.UUID
	Name        string
	Price       float64
	Quantity    int
	VariantMod  float64
	AddOnsPrice float64
}

type CartPricingRequest struct {
	UserID          uuid.UUID
	RestaurantID    uuid.UUID
	Items           []*CartItem
	DeliveryAddress *DeliveryAddress
	CouponCode      string
	TipAmount       float64
}

type DeliveryAddress struct {
	Latitude  float64
	Longitude float64
	Address   string
}

type CartPricingBreakdown struct {
	// Item totals
	ItemTotal float64 `json:"item_total"`

	// Packaging charges
	PackagingCharge float64 `json:"packaging_charge"`

	// Platform fee
	PlatformFee    float64 `json:"platform_fee"`
	PlatformFeeGST float64 `json:"platform_fee_gst"`

	// Delivery fee
	DeliveryFee    float64 `json:"delivery_fee"`
	DeliveryFeeGST float64 `json:"delivery_fee_gst"`

	// GST on food items
	FoodGST float64 `json:"food_gst"`

	// Discount
	DiscountAmount float64 `json:"discount_amount"`
	DiscountType   string  `json:"discount_type"` // "coupon", "promo", etc.

	// Tip
	TipAmount float64 `json:"tip_amount"`

	// Final totals
	Subtotal   float64 `json:"subtotal"`
	TotalGST   float64 `json:"total_gst"`
	GrandTotal float64 `json:"grand_total"`

	// Metadata
	AppliedCoupon   *CouponApplication `json:"applied_coupon,omitempty"`
	SurgeMultiplier float64            `json:"surge_multiplier"`
	ComputedAt      time.Time          `json:"computed_at"`
}

type CouponApplication struct {
	Code         string
	DiscountType string // "flat", "percentage"
	Value        float64
	MinOrder     float64
	MaxDiscount  float64
}

type SurgeFactors struct {
	DemandFactor    float64
	WeatherFactor   float64
	DistanceFactor  float64
	TimeOfDayFactor float64
}

func NewCartPricingService(restaurantService RestaurantService, cacheService CacheService) *CartPricingService {
	return &CartPricingService{
		restaurantService: restaurantService,
		cacheService:      cacheService,
	}
}

// CalculateCartPricing implements the exact formula from the spec:
// item_total = Σ(item_price × qty)
// restaurant_packaging_charge = per-item or flat, restaurant-configured
// platform_fee = flat or % (admin-configured, city-wise possible)
// delivery_fee = base_fee + surge_multiplier(demand/weather/distance_slab)
// gst = (item_total + packaging) × gst_rate  [varies: restaurant vs delivery GST differ in India]
// discount = coupon_value (validate: min_order_value, max_discount_cap, usage_limit_per_user, restaurant_scope)
// grand_total = item_total + packaging + platform_fee + delivery_fee + gst - discount + tip
func (cps *CartPricingService) CalculateCartPricing(ctx context.Context, req *CartPricingRequest) (*CartPricingBreakdown, error) {
	// Get restaurant info
	restaurant, err := cps.restaurantService.GetRestaurant(ctx, req.RestaurantID)
	if err != nil {
		return nil, fmt.Errorf("failed to get restaurant info: %w", err)
	}

	// Get packaging charges
	packagingCharges, err := cps.restaurantService.GetPackagingCharges(ctx, req.RestaurantID)
	if err != nil {
		return nil, fmt.Errorf("failed to get packaging charges: %w", err)
	}

	breakdown := &CartPricingBreakdown{
		ComputedAt: time.Now(),
	}

	// 1. Calculate item total
	itemTotal := 0.0
	for _, item := range req.Items {
		itemPrice := item.Price + item.VariantMod + item.AddOnsPrice
		itemTotal += itemPrice * float64(item.Quantity)
	}
	breakdown.ItemTotal = itemTotal

	// 2. Calculate packaging charge
	packagingCharge := 0.0
	if packagingCharges.Type == "per_item" {
		totalItems := 0
		for _, item := range req.Items {
			totalItems += item.Quantity
		}
		packagingCharge = float64(totalItems) * packagingCharges.PerItem
	} else {
		packagingCharge = packagingCharges.Amount
	}
	breakdown.PackagingCharge = packagingCharge

	// 3. Calculate platform fee
	platformFee := 0.0
	if restaurant.PlatformFeeRate > 0 {
		platformFee = itemTotal * (restaurant.PlatformFeeRate / 100)
	} else {
		// Flat fee (city-wise configured)
		platformFee = 5.0 // Default flat fee
	}
	breakdown.PlatformFee = platformFee

	// Platform fee GST (18% in India)
	platformFeeGST := platformFee * 0.18
	breakdown.PlatformFeeGST = platformFeeGST

	// 4. Calculate delivery fee with surge
	baseDeliveryFee := 30.0 // Base delivery fee
	surgeFactors := cps.calculateSurgeFactors(ctx, req.DeliveryAddress)
	surgeMultiplier := cps.calculateSurgeMultiplier(surgeFactors)

	deliveryFee := baseDeliveryFee * surgeMultiplier
	breakdown.DeliveryFee = deliveryFee
	breakdown.SurgeMultiplier = surgeMultiplier

	// Delivery fee GST (5% in India)
	deliveryFeeGST := deliveryFee * 0.05
	breakdown.DeliveryFeeGST = deliveryFeeGST

	// 5. Calculate GST on food items (5% on food in India)
	foodGST := (itemTotal + packagingCharge) * (restaurant.GSTRate / 100)
	breakdown.FoodGST = foodGST

	// 6. Calculate discount if coupon provided
	if req.CouponCode != "" {
		couponApp, err := cps.applyCoupon(ctx, req, itemTotal)
		if err == nil {
			breakdown.DiscountAmount = couponApp.Value
			breakdown.DiscountType = couponApp.DiscountType
			breakdown.AppliedCoupon = couponApp
		}
	}

	// 7. Calculate subtotal
	subtotal := itemTotal + packagingCharge + platformFee + deliveryFee + foodGST
	breakdown.Subtotal = subtotal

	// 8. Calculate total GST
	totalGST := foodGST + platformFeeGST + deliveryFeeGST
	breakdown.TotalGST = totalGST

	// 9. Calculate grand total
	grandTotal := subtotal + platformFeeGST + deliveryFeeGST - breakdown.DiscountAmount + req.TipAmount
	breakdown.GrandTotal = grandTotal
	breakdown.TipAmount = req.TipAmount

	// Round to 2 decimal places (paise precision)
	breakdown.ItemTotal = roundToTwoDecimals(breakdown.ItemTotal)
	breakdown.PackagingCharge = roundToTwoDecimals(breakdown.PackagingCharge)
	breakdown.PlatformFee = roundToTwoDecimals(breakdown.PlatformFee)
	breakdown.PlatformFeeGST = roundToTwoDecimals(breakdown.PlatformFeeGST)
	breakdown.DeliveryFee = roundToTwoDecimals(breakdown.DeliveryFee)
	breakdown.DeliveryFeeGST = roundToTwoDecimals(breakdown.DeliveryFeeGST)
	breakdown.FoodGST = roundToTwoDecimals(breakdown.FoodGST)
	breakdown.DiscountAmount = roundToTwoDecimals(breakdown.DiscountAmount)
	breakdown.Subtotal = roundToTwoDecimals(breakdown.Subtotal)
	breakdown.TotalGST = roundToTwoDecimals(breakdown.TotalGST)
	breakdown.GrandTotal = roundToTwoDecimals(breakdown.GrandTotal)
	breakdown.TipAmount = roundToTwoDecimals(breakdown.TipAmount)

	return breakdown, nil
}

func (cps *CartPricingService) calculateSurgeFactors(ctx context.Context, address *DeliveryAddress) *SurgeFactors {
	// In production, this would call external services for real-time data
	return &SurgeFactors{
		DemandFactor:    1.0,
		WeatherFactor:   1.0,
		DistanceFactor:  1.0,
		TimeOfDayFactor: 1.0,
	}
}

func (cps *CartPricingService) calculateSurgeMultiplier(factors *SurgeFactors) float64 {
	// Combined surge multiplier
	multiplier := factors.DemandFactor * factors.WeatherFactor * factors.DistanceFactor * factors.TimeOfDayFactor

	// Cap surge multiplier at 3.0x
	if multiplier > 3.0 {
		multiplier = 3.0
	}

	// Minimum multiplier is 1.0x
	if multiplier < 1.0 {
		multiplier = 1.0
	}

	return multiplier
}

func (cps *CartPricingService) applyCoupon(ctx context.Context, req *CartPricingRequest, orderValue float64) (*CouponApplication, error) {
	// In production, this would validate against coupon database
	// For now, return a placeholder
	return &CouponApplication{
		Code:         req.CouponCode,
		DiscountType: "percentage",
		Value:        orderValue * 0.10, // 10% discount
		MinOrder:     100.0,
		MaxDiscount:  50.0,
	}, nil
}

// ValidatePricingAtCheckout re-validates pricing at checkout to catch price changes
func (cps *CartPricingService) ValidatePricingAtCheckout(ctx context.Context, req *CartPricingRequest, cachedPricing *CartPricingBreakdown) (*CartPricingBreakdown, error) {
	currentPricing, err := cps.CalculateCartPricing(ctx, req)
	if err != nil {
		return nil, err
	}

	// Check if pricing has changed significantly (more than 1%)
	priceChangePercent := math.Abs((currentPricing.GrandTotal-cachedPricing.GrandTotal)/cachedPricing.GrandTotal) * 100

	if priceChangePercent > 1.0 {
		// Pricing has changed, return new pricing
		return currentPricing, nil
	}

	// Pricing is stable, return cached pricing
	return cachedPricing, nil
}

func roundToTwoDecimals(value float64) float64 {
	return math.Round(value*100) / 100
}
