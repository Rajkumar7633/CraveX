package rider

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// DynamicIncentiveEngine implements the dynamic incentive engine from the spec:
// backend rule engine (not hardcoded) where admin can configure:
// "complete 5 orders between 12-3pm → ₹50 bonus",
// evaluated via scheduled job checking rider's completed order count in time window
type DynamicIncentiveEngine struct {
	ruleRepo      IncentiveRuleRepository
	orderRepo     OrderRepository
	riderRepo     IncentiveRiderRepository
	payoutService PayoutService
}

type IncentiveRuleRepository interface {
	GetActiveRules(ctx context.Context) ([]*IncentiveRule, error)
	GetRule(ctx context.Context, ruleID uuid.UUID) (*IncentiveRule, error)
	SaveRule(ctx context.Context, rule *IncentiveRule) error
}

type OrderRepository interface {
	GetRiderCompletedOrders(ctx context.Context, riderID uuid.UUID, startTime, endTime time.Time) ([]*OrderInfo, error)
}

type IncentiveRiderRepository interface {
	GetRider(ctx context.Context, riderID uuid.UUID) (*IncentiveRiderInfo, error)
	CreditRiderWallet(ctx context.Context, riderID uuid.UUID, amount float64, reason string) error
}

type PayoutService interface {
	ProcessPayout(ctx context.Context, riderID uuid.UUID, amount float64) error
}

type IncentiveRule struct {
	ID          uuid.UUID
	Name        string
	Description string
	Type        string // "order_count", "time_window", "zone_bonus"
	StartTime   time.Time
	EndTime     time.Time
	TargetCount int
	BonusAmount float64
	ZoneIDs     []string
	IsActive    bool
	CreatedAt   time.Time
	UpdatedAt   time.Time
}

type OrderInfo struct {
	ID          uuid.UUID
	RiderID     uuid.UUID
	Status      string
	CompletedAt time.Time
	ZoneID      string
}

type IncentiveRiderInfo struct {
	ID     uuid.UUID
	Name   string
	Wallet float64
}

type IncentiveEvaluation struct {
	RiderID     uuid.UUID
	RuleID      uuid.UUID
	RuleName    string
	OrdersCount int
	TargetCount int
	BonusEarned float64
	EvaluatedAt time.Time
}

type IncentivePayout struct {
	ID          uuid.UUID
	RiderID     uuid.UUID
	RuleID      uuid.UUID
	Amount      float64
	Reason      string
	ProcessedAt time.Time
}

func NewDynamicIncentiveEngine(
	ruleRepo IncentiveRuleRepository,
	orderRepo OrderRepository,
	riderRepo IncentiveRiderRepository,
	payoutService PayoutService,
) *DynamicIncentiveEngine {
	return &DynamicIncentiveEngine{
		ruleRepo:      ruleRepo,
		orderRepo:     orderRepo,
		riderRepo:     riderRepo,
		payoutService: payoutService,
	}
}

// EvaluateIncentives evaluates all active incentive rules for a rider
func (die *DynamicIncentiveEngine) EvaluateIncentives(ctx context.Context, riderID uuid.UUID) ([]*IncentiveEvaluation, error) {
	// Get all active rules
	rules, err := die.ruleRepo.GetActiveRules(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to get active rules: %w", err)
	}

	var evaluations []*IncentiveEvaluation

	for _, rule := range rules {
		eval, err := die.evaluateRule(ctx, riderID, rule)
		if err != nil {
			continue
		}
		evaluations = append(evaluations, eval)
	}

	return evaluations, nil
}

// evaluateRule evaluates a single incentive rule for a rider
func (die *DynamicIncentiveEngine) evaluateRule(ctx context.Context, riderID uuid.UUID, rule *IncentiveRule) (*IncentiveEvaluation, error) {
	// Get rider's completed orders in the rule's time window
	orders, err := die.orderRepo.GetRiderCompletedOrders(ctx, riderID, rule.StartTime, rule.EndTime)
	if err != nil {
		return nil, fmt.Errorf("failed to get rider orders: %w", err)
	}

	// Filter orders by zone if rule specifies zones
	orderCount := len(orders)
	if len(rule.ZoneIDs) > 0 {
		orderCount = 0
		for _, order := range orders {
			for _, zoneID := range rule.ZoneIDs {
				if order.ZoneID == zoneID {
					orderCount++
					break
				}
			}
		}
	}

	// Check if target is met
	bonusEarned := 0.0
	if orderCount >= rule.TargetCount {
		bonusEarned = rule.BonusAmount
	}

	return &IncentiveEvaluation{
		RiderID:     riderID,
		RuleID:      rule.ID,
		RuleName:    rule.Name,
		OrdersCount: orderCount,
		TargetCount: rule.TargetCount,
		BonusEarned: bonusEarned,
		EvaluatedAt: time.Now(),
	}, nil
}

// ProcessIncentivePayouts processes incentive payouts for a rider
func (die *DynamicIncentiveEngine) ProcessIncentivePayouts(ctx context.Context, riderID uuid.UUID) ([]*IncentivePayout, error) {
	evaluations, err := die.EvaluateIncentives(ctx, riderID)
	if err != nil {
		return nil, fmt.Errorf("failed to evaluate incentives: %w", err)
	}

	var payouts []*IncentivePayout

	for _, eval := range evaluations {
		if eval.BonusEarned > 0 {
			// Credit rider's wallet
			reason := fmt.Sprintf("Incentive bonus: %s (%d orders)", eval.RuleName, eval.OrdersCount)
			err := die.riderRepo.CreditRiderWallet(ctx, riderID, eval.BonusEarned, reason)
			if err != nil {
				continue
			}

			payout := &IncentivePayout{
				ID:          uuid.New(),
				RiderID:     riderID,
				RuleID:      eval.RuleID,
				Amount:      eval.BonusEarned,
				Reason:      reason,
				ProcessedAt: time.Now(),
			}
			payouts = append(payouts, payout)
		}
	}

	return payouts, nil
}

// CreateIncentiveRule creates a new incentive rule
func (die *DynamicIncentiveEngine) CreateIncentiveRule(ctx context.Context, rule *IncentiveRule) error {
	return die.ruleRepo.SaveRule(ctx, rule)
}

// BatchEvaluateAllRiders evaluates incentives for all riders (scheduled job)
func (die *DynamicIncentiveEngine) BatchEvaluateAllRiders(ctx context.Context) error {
	// In production, this would get all active riders and evaluate their incentives
	// For now, this is a placeholder for the scheduled job
	return nil
}

// GetRiderIncentives gets all incentives for a rider
func (die *DynamicIncentiveEngine) GetRiderIncentives(ctx context.Context, riderID uuid.UUID) ([]*IncentiveEvaluation, error) {
	return die.EvaluateIncentives(ctx, riderID)
}

// RuleEngineConfig represents configurable rule parameters
type RuleEngineConfig struct {
	MaxDailyBonus   float64
	MaxWeeklyBonus  float64
	MinOrderValue   float64
	BonusMultiplier float64
	PeakHourBonus   float64
	WeatherBonus    float64
}

// ConfigurableRuleEngine allows admin to configure incentive rules
type ConfigurableRuleEngine struct {
	config RuleEngineConfig
}

func NewConfigurableRuleEngine(config RuleEngineConfig) *ConfigurableRuleEngine {
	return &ConfigurableRuleEngine{
		config: config,
	}
}

// CalculateDynamicBonus calculates bonus based on configurable factors
func (cre *ConfigurableRuleEngine) CalculateDynamicBonus(baseBonus float64, isPeakHour bool, isBadWeather bool) float64 {
	bonus := baseBonus

	if isPeakHour {
		bonus *= (1.0 + cre.config.PeakHourBonus)
	}

	if isBadWeather {
		bonus *= (1.0 + cre.config.WeatherBonus)
	}

	bonus *= cre.config.BonusMultiplier

	return bonus
}

// ValidateRule validates an incentive rule before saving
func (cre *ConfigurableRuleEngine) ValidateRule(rule *IncentiveRule) error {
	if rule.StartTime.After(rule.EndTime) {
		return fmt.Errorf("start time must be before end time")
	}

	if rule.TargetCount <= 0 {
		return fmt.Errorf("target count must be positive")
	}

	if rule.BonusAmount <= 0 {
		return fmt.Errorf("bonus amount must be positive")
	}

	return nil
}
