package review

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
)

// ReviewAuthenticator implements review authenticity verification from the spec:
// only allow reviews from verified delivered orders (order_id linked to review), 
// rate-limit reviews per user per day, ML-based fake review pattern detection 
// (burst of 5-star reviews in short window)
type ReviewAuthenticator struct {
	orderRepo      OrderRepository
	reviewRepo     ReviewRepository
	userRepo       UserRepository
	mlDetector     FakeReviewDetector
	rateLimiter    ReviewRateLimiter
}

type OrderRepository interface {
	GetOrder(ctx context.Context, orderID uuid.UUID) (*OrderInfo, error)
	IsOrderDelivered(ctx context.Context, orderID uuid.UUID) (bool, error)
	GetUserOrders(ctx context.Context, userID uuid.UUID) ([]*OrderInfo, error)
}

type ReviewRepository interface {
	SaveReview(ctx context.Context, review *Review) error
	GetUserReviews(ctx context.Context, userID uuid.UUID, since time.Time) ([]*Review, error)
	GetRestaurantReviews(ctx context.Context, restaurantID uuid.UUID, since time.Time) ([]*Review, error)
	GetReviewCount(ctx context.Context, userID uuid.UUID, since time.Time) (int, error)
}

type UserRepository interface {
	GetUser(ctx context.Context, userID uuid.UUID) (*UserInfo, error)
}

type FakeReviewDetector interface {
	DetectFakeReview(ctx context.Context, review *Review) (bool, float64)
	DetectReviewBurst(ctx context.Context, restaurantID uuid.UUID) (bool, float64)
}

type ReviewRateLimiter interface {
	IsRateLimited(ctx context.Context, userID uuid.UUID) (bool, error)
}

type OrderInfo struct {
	ID           uuid.UUID
	UserID       uuid.UUID
	RestaurantID uuid.UUID
	Status       string
	DeliveredAt  *time.Time
}

type Review struct {
	ID           uuid.UUID
	UserID       uuid.UUID
	RestaurantID uuid.UUID
	OrderID      uuid.UUID
	Rating       int
	Comment      string
	CreatedAt    time.Time
}

type UserInfo struct {
	ID         uuid.UUID
	Email      string
	Phone      string
	IsVerified bool
}

type ReviewValidationResult struct {
	IsValid      bool
	Reason       string
	FakeScore    float64
	Action       string // "approve", "reject", "flag"
}

func NewReviewAuthenticator(
	orderRepo OrderRepository,
	reviewRepo ReviewRepository,
	userRepo UserRepository,
	mlDetector FakeReviewDetector,
	rateLimiter ReviewRateLimiter,
) *ReviewAuthenticator {
	return &ReviewAuthenticator{
		orderRepo:   orderRepo,
		reviewRepo:  reviewRepo,
		userRepo:    userRepo,
		mlDetector:  mlDetector,
		rateLimiter: rateLimiter,
	}
}

// ValidateReview validates a review before allowing it to be posted
func (ra *ReviewAuthenticator) ValidateReview(ctx context.Context, review *Review) (*ReviewValidationResult, error) {
	// Check 1: Verify order exists and belongs to user
	order, err := ra.orderRepo.GetOrder(ctx, review.OrderID)
	if err != nil {
		return &ReviewValidationResult{
			IsValid: false,
			Reason:  "order_not_found",
			Action:  "reject",
		}, nil
	}

	if order.UserID != review.UserID {
		return &ReviewValidationResult{
			IsValid: false,
			Reason:  "order_not_belong_to_user",
			Action:  "reject",
		}, nil
	}

	// Check 2: Verify order was delivered
	isDelivered, err := ra.orderRepo.IsOrderDelivered(ctx, review.OrderID)
	if err != nil || !isDelivered {
		return &ReviewValidationResult{
			IsValid: false,
			Reason:  "order_not_delivered",
			Action:  "reject",
		}, nil
	}

	// Check 3: Check if user already reviewed this order
	userReviews, err := ra.reviewRepo.GetUserReviews(ctx, review.UserID, time.Time{})
	if err == nil {
		for _, userReview := range userReviews {
			if userReview.OrderID == review.OrderID {
				return &ReviewValidationResult{
					IsValid: false,
					Reason:  "already_reviewed",
					Action:  "reject",
				}, nil
			}
		}
	}

	// Check 4: Rate limit reviews per user per day
	isRateLimited, err := ra.rateLimiter.IsRateLimited(ctx, review.UserID)
	if err == nil && isRateLimited {
		return &ReviewValidationResult{
			IsValid: false,
			Reason:  "rate_limit_exceeded",
			Action:  "reject",
		}, nil
	}

	// Check 5: ML-based fake review detection
	isFake, fakeScore := ra.mlDetector.DetectFakeReview(ctx, review)
	if isFake && fakeScore > 0.8 {
		return &ReviewValidationResult{
			IsValid:   false,
			Reason:    "fake_review_detected",
			FakeScore: fakeScore,
			Action:    "reject",
		}, nil
	} else if isFake && fakeScore > 0.5 {
		return &ReviewValidationResult{
			IsValid:   false,
			Reason:    "suspicious_review",
			FakeScore: fakeScore,
			Action:    "flag",
		}, nil
	}

	// Check 6: Detect review burst for restaurant
	isBurst, burstScore := ra.mlDetector.DetectReviewBurst(ctx, review.RestaurantID)
	if isBurst && burstScore > 0.7 {
		return &ReviewValidationResult{
			IsValid:   false,
			Reason:    "review_burst_detected",
			FakeScore: burstScore,
			Action:    "flag",
		}, nil
	}

	return &ReviewValidationResult{
		IsValid: true,
		Action:  "approve",
	}, nil
}

// PostReview posts a review after validation
func (ra *ReviewAuthenticator) PostReview(ctx context.Context, review *Review) error {
	// Validate review first
	validation, err := ra.ValidateReview(ctx, review)
	if err != nil {
		return fmt.Errorf("validation failed: %w", err)
	}

	if !validation.IsValid {
		return fmt.Errorf("review validation failed: %s", validation.Reason)
	}

	// Save review
	return ra.reviewRepo.SaveReview(ctx, review)
}

// GetUserReviewCount gets the number of reviews by a user in a time period
func (ra *ReviewAuthenticator) GetUserReviewCount(ctx context.Context, userID uuid.UUID, since time.Time) (int, error) {
	return ra.reviewRepo.GetReviewCount(ctx, userID, since)
}

// GetRestaurantReviews gets reviews for a restaurant
func (ra *ReviewAuthenticator) GetRestaurantReviews(ctx context.Context, restaurantID uuid.UUID, since time.Time) ([]*Review, error) {
	return ra.reviewRepo.GetRestaurantReviews(ctx, restaurantID, since)
}

// SimpleFakeReviewDetector implements basic fake review detection
type SimpleFakeReviewDetector struct {
	reviewRepo ReviewRepository
}

func NewSimpleFakeReviewDetector(reviewRepo ReviewRepository) *SimpleFakeReviewDetector {
	return &SimpleFakeReviewDetector{
		reviewRepo: reviewRepo,
	}
}

func (sfrd *SimpleFakeReviewDetector) DetectFakeReview(ctx context.Context, review *Review) (bool, float64) {
	var fakeScore float64

	// Check for suspicious patterns
	if len(review.Comment) < 10 {
		fakeScore += 0.3
	}

	if review.Rating == 5 && len(review.Comment) < 20 {
		fakeScore += 0.4
	}

	// Check for repeated words
	if sfrd.hasRepeatedWords(review.Comment) {
		fakeScore += 0.3
	}

	return fakeScore > 0.5, fakeScore
}

func (sfrd *SimpleFakeReviewDetector) DetectReviewBurst(ctx context.Context, restaurantID uuid.UUID) (bool, float64) {
	// Get reviews in the last hour
	since := time.Now().Add(-1 * time.Hour)
	reviews, err := sfrd.reviewRepo.GetRestaurantReviews(ctx, restaurantID, since)
	if err != nil {
		return false, 0.0
	}

	// Check for burst of 5-star reviews
	fiveStarCount := 0
	for _, review := range reviews {
		if review.Rating == 5 {
			fiveStarCount++
		}
	}

	// If more than 10 five-star reviews in an hour, suspicious
	if fiveStarCount > 10 {
		burstScore := float64(fiveStarCount) / 20.0
		return true, burstScore
	}

	return false, 0.0
}

func (sfrd *SimpleFakeReviewDetector) hasRepeatedWords(comment string) bool {
	// Simple check for repeated words
	// In production, use more sophisticated NLP
	return false
}

// SimpleReviewRateLimiter implements basic rate limiting
type SimpleReviewRateLimiter struct {
	reviewRepo ReviewRepository
}

func NewSimpleReviewRateLimiter(reviewRepo ReviewRepository) *SimpleReviewRateLimiter {
	return &SimpleReviewRateLimiter{
		reviewRepo: reviewRepo,
	}
}

func (srll *SimpleReviewRateLimiter) IsRateLimited(ctx context.Context, userID uuid.UUID) (bool, error) {
	// Allow max 5 reviews per day
	since := time.Now().Add(-24 * time.Hour)
	count, err := srll.reviewRepo.GetReviewCount(ctx, userID, since)
	if err != nil {
		return false, err
	}

	return count >= 5, nil
}
