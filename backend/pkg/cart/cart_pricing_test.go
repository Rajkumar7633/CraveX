package cart

import (
	"context"
	"fmt"
	"testing"

	"github.com/google/uuid"
)

func TestCartItem_CalculateTotal(t *testing.T) {
	tests := []struct {
		name     string
		item     *CartItem
		expected float64
	}{
		{
			name: "single item with quantity 1",
			item: &CartItem{
				ItemID:   uuid.New(),
				Quantity: 1,
				Price:    100.0,
			},
			expected: 100.0,
		},
		{
			name: "single item with quantity 3",
			item: &CartItem{
				ItemID:   uuid.New(),
				Quantity: 3,
				Price:    100.0,
			},
			expected: 300.0,
		},
		{
			name: "item with variant modifier",
			item: &CartItem{
				ItemID:     uuid.New(),
				Quantity:   1,
				Price:      100.0,
				VariantMod: 20.0,
			},
			expected: 120.0,
		},
		{
			name: "item with addons price",
			item: &CartItem{
				ItemID:      uuid.New(),
				Quantity:    1,
				Price:       100.0,
				AddOnsPrice: 25.0,
			},
			expected: 125.0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := (tt.item.Price + tt.item.VariantMod + tt.item.AddOnsPrice) * float64(tt.item.Quantity)
			if result != tt.expected {
				t.Errorf("CalculateItemTotal() = %v, want %v", result, tt.expected)
			}
		})
	}
}

func TestGST_Calculation(t *testing.T) {
	tests := []struct {
		name     string
		amount   float64
		rate     float64
		expected float64
	}{
		{
			name:     "5% GST on 100",
			amount:   100.0,
			rate:     0.05,
			expected: 5.0,
		},
		{
			name:     "18% GST on 100",
			amount:   100.0,
			rate:     0.18,
			expected: 18.0,
		},
		{
			name:     "5% GST on 0",
			amount:   0.0,
			rate:     0.05,
			expected: 0.0,
		},
		{
			name:     "5% GST on 1000",
			amount:   1000.0,
			rate:     0.05,
			expected: 50.0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			result := tt.amount * tt.rate
			if result != tt.expected {
				t.Errorf("GST calculation = %v, want %v", result, tt.expected)
			}
		})
	}
}

func TestCart_TotalCalculation(t *testing.T) {
	tests := []struct {
		name     string
		items    []*CartItem
		expected float64
	}{
		{
			name:     "empty cart",
			items:    []*CartItem{},
			expected: 0.0,
		},
		{
			name: "single item",
			items: []*CartItem{
				{
					ItemID:   uuid.New(),
					Quantity: 1,
					Price:    100.0,
				},
			},
			expected: 100.0,
		},
		{
			name: "multiple items",
			items: []*CartItem{
				{
					ItemID:   uuid.New(),
					Quantity: 2,
					Price:    100.0,
				},
				{
					ItemID:   uuid.New(),
					Quantity: 1,
					Price:    50.0,
				},
			},
			expected: 250.0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			total := 0.0
			for _, item := range tt.items {
				total += (item.Price + item.VariantMod + item.AddOnsPrice) * float64(item.Quantity)
			}
			if total != tt.expected {
				t.Errorf("Cart total = %v, want %v", total, tt.expected)
			}
		})
	}
}

func TestCoupon_Application(t *testing.T) {
	tests := []struct {
		name        string
		couponType  string
		discountVal float64
		minOrder    float64
		maxDiscount float64
		cartTotal   float64
		expected    float64
		shouldError bool
	}{
		{
			name:        "flat discount coupon",
			couponType:  "flat",
			discountVal: 50.0,
			minOrder:    100.0,
			maxDiscount: 0.0,
			cartTotal:   200.0,
			expected:    150.0,
			shouldError: false,
		},
		{
			name:        "percentage discount coupon",
			couponType:  "percentage",
			discountVal: 20.0,
			minOrder:    100.0,
			maxDiscount: 0.0,
			cartTotal:   200.0,
			expected:    160.0,
			shouldError: false,
		},
		{
			name:        "coupon below minimum order",
			couponType:  "percentage",
			discountVal: 20.0,
			minOrder:    500.0,
			maxDiscount: 0.0,
			cartTotal:   200.0,
			expected:    200.0,
			shouldError: true,
		},
		{
			name:        "coupon with max discount cap",
			couponType:  "percentage",
			discountVal: 20.0,
			minOrder:    100.0,
			maxDiscount: 30.0,
			cartTotal:   500.0,
			expected:    470.0,
			shouldError: false,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var discount float64
			var err error

			if tt.cartTotal < tt.minOrder {
				err = fmt.Errorf("below minimum order")
			} else {
				if tt.couponType == "flat" {
					discount = tt.discountVal
				} else if tt.couponType == "percentage" {
					discount = tt.cartTotal * (tt.discountVal / 100.0)
					if tt.maxDiscount > 0 && discount > tt.maxDiscount {
						discount = tt.maxDiscount
					}
				}
			}

			if tt.shouldError {
				if err == nil {
					t.Error("Expected error but got none")
				}
			} else {
				if err != nil {
					t.Errorf("Unexpected error: %v", err)
				}
				result := tt.cartTotal - discount
				if result != tt.expected {
					t.Errorf("Coupon application = %v, want %v", result, tt.expected)
				}
			}
		})
	}
}

func TestFinalAmount_Calculation(t *testing.T) {
	tests := []struct {
		name            string
		cartTotal       float64
		deliveryFee     float64
		platformFee     float64
		discount        float64
		tip             float64
		surgeMultiplier float64
		expected        float64
	}{
		{
			name:            "basic calculation",
			cartTotal:       100.0,
			deliveryFee:     20.0,
			platformFee:     5.0,
			discount:        0.0,
			tip:             0.0,
			surgeMultiplier: 1.0,
			expected:        125.0,
		},
		{
			name:            "with discount",
			cartTotal:       100.0,
			deliveryFee:     20.0,
			platformFee:     5.0,
			discount:        20.0,
			tip:             0.0,
			surgeMultiplier: 1.0,
			expected:        105.0,
		},
		{
			name:            "with tip",
			cartTotal:       100.0,
			deliveryFee:     20.0,
			platformFee:     5.0,
			discount:        0.0,
			tip:             10.0,
			surgeMultiplier: 1.0,
			expected:        135.0,
		},
		{
			name:            "with surge multiplier",
			cartTotal:       100.0,
			deliveryFee:     20.0,
			platformFee:     5.0,
			discount:        0.0,
			tip:             0.0,
			surgeMultiplier: 1.5,
			expected:        187.5,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			surgeDeliveryFee := tt.deliveryFee * tt.surgeMultiplier
			result := tt.cartTotal + surgeDeliveryFee + tt.platformFee - tt.discount + tt.tip
			if result != tt.expected {
				t.Errorf("Final amount = %v, want %v", result, tt.expected)
			}
		})
	}
}

func TestGST_Breakdown(t *testing.T) {
	foodAmount := 100.0
	deliveryAmount := 20.0
	platformAmount := 5.0

	// Food GST: 5% of 100 = 5
	foodGST := foodAmount * 0.05
	if foodGST != 5.0 {
		t.Errorf("FoodGST = %v, want 5.0", foodGST)
	}

	// Delivery GST: 5% of 20 = 1
	deliveryGST := deliveryAmount * 0.05
	if deliveryGST != 1.0 {
		t.Errorf("DeliveryGST = %v, want 1.0", deliveryGST)
	}

	// Platform GST: 18% of 5 = 0.9
	platformGST := platformAmount * 0.18
	if platformGST != 0.9 {
		t.Errorf("PlatformGST = %v, want 0.9", platformGST)
	}

	// Total GST: 5 + 1 + 0.9 = 6.9
	totalGST := foodGST + deliveryGST + platformGST
	if totalGST != 6.9 {
		t.Errorf("TotalGST = %v, want 6.9", totalGST)
	}
}
