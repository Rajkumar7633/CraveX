package menu

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// MenuItem represents the complete menu item structure
type MenuItem struct {
	ID                 uuid.UUID           `json:"id"`
	RestaurantID       uuid.UUID           `json:"restaurant_id"`
	CategoryID         uuid.UUID           `json:"category_id"`
	Name               string              `json:"name"`
	Description        string              `json:"description"`
	BasePrice          float64             `json:"base_price"`
	IsVeg              bool                `json:"is_veg"`
	IsAvailable        bool                `json:"is_available"`
	PrepTimeMinutes    int                 `json:"prep_time_minutes"`
	ImageURLs          []string            `json:"image_urls"`
	NutritionalInfo    *NutritionalInfo    `json:"nutritional_info,omitempty"`
	AllergenTags       []string            `json:"allergen_tags"`
	Variants           []ItemVariant       `json:"variants"`
	AddOnGroups        []AddOnGroup        `json:"add_on_groups"`
	CustomizationRules *CustomizationRules `json:"customization_rules"`
	CreatedAt          time.Time           `json:"created_at"`
	UpdatedAt          time.Time           `json:"updated_at"`
}

// NutritionalInfo contains nutritional information for menu items
type NutritionalInfo struct {
	Calories    float64 `json:"calories"`
	Protein     float64 `json:"protein"`
	Carbs       float64 `json:"carbs"`
	Fat         float64 `json:"fat"`
	Fiber       float64 `json:"fiber"`
	Sugar       float64 `json:"sugar"`
	Sodium      float64 `json:"sodium"`
	ServingSize string  `json:"serving_size"`
}

// ItemVariant represents different sizes/types of a menu item
type ItemVariant struct {
	ID          uuid.UUID `json:"id"`
	ItemID      uuid.UUID `json:"item_id"`
	Name        string    `json:"name"`      // e.g., "Small", "Medium", "Large"
	PriceMod    float64   `json:"price_mod"` // Price modification from base
	IsDefault   bool      `json:"is_default"`
	IsAvailable bool      `json:"is_available"`
}

// AddOnGroup represents a group of add-ons (e.g., toppings)
type AddOnGroup struct {
	ID         uuid.UUID `json:"id"`
	ItemID     uuid.UUID `json:"item_id"`
	Name       string    `json:"name"`       // e.g., "Choose Size", "Add Toppings"
	MinSelect  int       `json:"min_select"` // Minimum selections required
	MaxSelect  int       `json:"max_select"` // Maximum selections allowed
	IsRequired bool      `json:"is_required"`
	AddOns     []AddOn   `json:"add_ons"`
}

// AddOn represents individual add-on options
type AddOn struct {
	ID          uuid.UUID `json:"id"`
	GroupID     uuid.UUID `json:"group_id"`
	Name        string    `json:"name"`
	Price       float64   `json:"price"`
	IsAvailable bool      `json:"is_available"`
	IsVeg       bool      `json:"is_veg"`
}

// CustomizationRules defines customization constraints
type CustomizationRules struct {
	AllowSpecialInstructions bool `json:"allow_special_instructions"`
	MaxInstructionLength     int  `json:"max_instruction_length"`
	AllowQuantityChange      bool `json:"allow_quantity_change"`
	MinQuantity              int  `json:"min_quantity"`
	MaxQuantity              int  `json:"max_quantity"`
}

// MenuCategory represents menu categories
type MenuCategory struct {
	ID           uuid.UUID `json:"id"`
	RestaurantID uuid.UUID `json:"restaurant_id"`
	Name         string    `json:"name"`
	Description  string    `json:"description"`
	DisplayOrder int       `json:"display_order"`
	IsAvailable  bool      `json:"is_available"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// CartItem represents an item in the cart with all selections
type CartItem struct {
	ItemID              uuid.UUID   `json:"item_id"`
	VariantID           *uuid.UUID  `json:"variant_id,omitempty"`
	AddOnIDs            []uuid.UUID `json:"add_on_ids"`
	Quantity            int         `json:"quantity"`
	SpecialInstructions string      `json:"special_instructions,omitempty"`
	ComputedPrice       float64     `json:"computed_price"` // Cached computed price
	ComputedAt          time.Time   `json:"computed_at"`    // When price was computed
}

// CartItemRequest represents a cart item request from client
type CartItemRequest struct {
	ItemID              uuid.UUID   `json:"item_id" binding:"required"`
	VariantID           *uuid.UUID  `json:"variant_id"`
	AddOnIDs            []uuid.UUID `json:"add_on_ids"`
	Quantity            int         `json:"quantity" binding:"required,min=1"`
	SpecialInstructions string      `json:"special_instructions"`
}

// PriceBreakdown represents the detailed price calculation
type PriceBreakdown struct {
	BasePrice        float64   `json:"base_price"`
	VariantPriceMod  float64   `json:"variant_price_mod"`
	AddOnsPrice      float64   `json:"add_ons_price"`
	Quantity         int       `json:"quantity"`
	ItemTotal        float64   `json:"item_total"`
	ComputedAt       time.Time `json:"computed_at"`
	ValidationErrors []string  `json:"validation_errors,omitempty"`
}

// MenuService handles menu operations
type MenuService struct {
	cacheService CacheService
}

type CacheService interface {
	Get(ctx context.Context, key string) (string, error)
	Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error
	Delete(ctx context.Context, keys ...string) error
}

func NewMenuService(cacheService CacheService) *MenuService {
	return &MenuService{
		cacheService: cacheService,
	}
}

// CalculateItemPrice computes the exact price for a cart item
func (ms *MenuService) CalculateItemPrice(ctx context.Context, item *MenuItem, cartItem *CartItem) (*PriceBreakdown, error) {
	breakdown := &PriceBreakdown{
		BasePrice:  item.BasePrice,
		ComputedAt: time.Now(),
	}

	variantPriceMod := 0.0
	addOnsPrice := 0.0
	var validationErrors []string

	// Handle variant selection
	if cartItem.VariantID != nil {
		variant := ms.findVariant(item.Variants, *cartItem.VariantID)
		if variant == nil {
			validationErrors = append(validationErrors, "variant not found or unavailable")
		} else if !variant.IsAvailable {
			validationErrors = append(validationErrors, "variant not available")
		} else {
			variantPriceMod = variant.PriceMod
		}
	}

	// Handle add-on selections
	for _, addOnID := range cartItem.AddOnIDs {
		addOn := ms.findAddOn(item.AddOnGroups, addOnID)
		if addOn == nil {
			validationErrors = append(validationErrors, "add-on not found or unavailable")
		} else if !addOn.IsAvailable {
			validationErrors = append(validationErrors, "add-on not available")
		} else {
			addOnsPrice += addOn.Price
		}
	}

	// Validate customization rules
	if item.CustomizationRules != nil {
		// Check quantity limits
		if cartItem.Quantity < item.CustomizationRules.MinQuantity {
			validationErrors = append(validationErrors, "quantity below minimum")
		}
		if cartItem.Quantity > item.CustomizationRules.MaxQuantity {
			validationErrors = append(validationErrors, "quantity above maximum")
		}

		// Check special instructions length
		if len(cartItem.SpecialInstructions) > item.CustomizationRules.MaxInstructionLength {
			validationErrors = append(validationErrors, "special instructions too long")
		}

		// Validate add-on group constraints
		for _, group := range item.AddOnGroups {
			selectedCount := ms.countSelectedAddOns(group.AddOns, cartItem.AddOnIDs)
			if selectedCount < group.MinSelect {
				validationErrors = append(validationErrors,
					fmt.Sprintf("minimum %d selections required for %s", group.MinSelect, group.Name))
			}
			if selectedCount > group.MaxSelect {
				validationErrors = append(validationErrors,
					fmt.Sprintf("maximum %d selections allowed for %s", group.MaxSelect, group.Name))
			}
		}
	}

	breakdown.VariantPriceMod = variantPriceMod
	breakdown.AddOnsPrice = addOnsPrice
	breakdown.Quantity = cartItem.Quantity
	breakdown.ItemTotal = (item.BasePrice + variantPriceMod + addOnsPrice) * float64(cartItem.Quantity)
	breakdown.ValidationErrors = validationErrors

	return breakdown, nil
}

// ValidateCart validates the entire cart before checkout
func (ms *MenuService) ValidateCart(ctx context.Context, items []*MenuItem, cartItems []*CartItem) ([]string, error) {
	var allErrors []string

	for _, cartItem := range cartItems {
		item := ms.findItem(items, cartItem.ItemID)
		if item == nil {
			allErrors = append(allErrors, fmt.Sprintf("item %s not found", cartItem.ItemID))
			continue
		}

		if !item.IsAvailable {
			allErrors = append(allErrors, fmt.Sprintf("item %s is not available", item.Name))
			continue
		}

		breakdown, err := ms.CalculateItemPrice(ctx, item, cartItem)
		if err != nil {
			allErrors = append(allErrors, fmt.Sprintf("error calculating price for %s: %v", item.Name, err))
			continue
		}

		allErrors = append(allErrors, breakdown.ValidationErrors...)
	}

	return allErrors, nil
}

// RecalculateCartPrices recalculates prices for cart items (for checkout validation)
func (ms *MenuService) RecalculateCartPrices(ctx context.Context, items []*MenuItem, cartItems []*CartItem) ([]*PriceBreakdown, error) {
	var breakdowns []*PriceBreakdown

	for _, cartItem := range cartItems {
		item := ms.findItem(items, cartItem.ItemID)
		if item == nil {
			continue
		}

		breakdown, err := ms.CalculateItemPrice(ctx, item, cartItem)
		if err != nil {
			return nil, err
		}

		breakdowns = append(breakdowns, breakdown)
	}

	return breakdowns, nil
}

func (ms *MenuService) findVariant(variants []ItemVariant, variantID uuid.UUID) *ItemVariant {
	for _, variant := range variants {
		if variant.ID == variantID {
			return &variant
		}
	}
	return nil
}

func (ms *MenuService) findAddOn(groups []AddOnGroup, addOnID uuid.UUID) *AddOn {
	for _, group := range groups {
		for _, addOn := range group.AddOns {
			if addOn.ID == addOnID {
				return &addOn
			}
		}
	}
	return nil
}

func (ms *MenuService) findItem(items []*MenuItem, itemID uuid.UUID) *MenuItem {
	for _, item := range items {
		if item.ID == itemID {
			return item
		}
	}
	return nil
}

func (ms *MenuService) countSelectedAddOns(addOns []AddOn, selectedIDs []uuid.UUID) int {
	count := 0
	for _, addOn := range addOns {
		for _, selectedID := range selectedIDs {
			if addOn.ID == selectedID {
				count++
				break
			}
		}
	}
	return count
}
