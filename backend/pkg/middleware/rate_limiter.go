package middleware

import (
	"context"
	"fmt"
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"
)

type RateLimiter struct {
	redisClient *redis.Client
	rateLimit   int
	window      time.Duration
}

type RateLimitConfig struct {
	RateLimit int           `json:"rate_limit"`
	Window    time.Duration `json:"window"`
}

func NewRateLimiter(redisClient *redis.Client, rateLimit int, window time.Duration) *RateLimiter {
	return &RateLimiter{
		redisClient: redisClient,
		rateLimit:   rateLimit,
		window:      window,
	}
}

func (rl *RateLimiter) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		key := rl.generateKey(c)

		ctx := context.Background()

		// Increment counter
		current, err := rl.redisClient.Incr(ctx, key).Result()
		if err != nil {
			c.Next()
			return
		}

		// Set expiration on first request
		if current == 1 {
			rl.redisClient.Expire(ctx, key, rl.window)
		}

		// Check if rate limit exceeded
		if current > int64(rl.rateLimit) {
			ttl, _ := rl.redisClient.TTL(ctx, key).Result()
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error":       "Rate limit exceeded",
				"retry_after": ttl.Seconds(),
			})
			c.Abort()
			return
		}

		// Add rate limit headers
		c.Header("X-RateLimit-Limit", strconv.Itoa(rl.rateLimit))
		c.Header("X-RateLimit-Remaining", strconv.Itoa(int(rl.rateLimit)-int(current)))
		c.Header("X-RateLimit-Reset", strconv.FormatInt(time.Now().Add(rl.window).Unix(), 10))

		c.Next()
	}
}

func (rl *RateLimiter) generateKey(c *gin.Context) string {
	clientIP := c.ClientIP()
	userAgent := c.GetHeader("User-Agent")
	path := c.Request.URL.Path

	return fmt.Sprintf("ratelimit:%s:%s:%s", clientIP, userAgent, path)
}

// Sliding Window Rate Limiter for more precise control
type SlidingWindowRateLimiter struct {
	redisClient *redis.Client
	rateLimit   int
	window      time.Duration
}

func NewSlidingWindowRateLimiter(redisClient *redis.Client, rateLimit int, window time.Duration) *SlidingWindowRateLimiter {
	return &SlidingWindowRateLimiter{
		redisClient: redisClient,
		rateLimit:   rateLimit,
		window:      window,
	}
}

func (swrl *SlidingWindowRateLimiter) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		key := swrl.generateKey(c)
		now := time.Now().Unix()

		ctx := context.Background()

		// Remove old entries outside the window
		swrl.redisClient.ZRemRangeByScore(ctx, key, "0", strconv.FormatInt(now-int64(swrl.window.Seconds()), 10))

		// Add current request
		swrl.redisClient.ZAdd(ctx, key, redis.Z{Score: float64(now), Member: now})

		// Count requests in window
		count, err := swrl.redisClient.ZCard(ctx, key).Result()
		if err != nil {
			c.Next()
			return
		}

		// Set expiration
		swrl.redisClient.Expire(ctx, key, swrl.window)

		// Check if rate limit exceeded
		if count > int64(swrl.rateLimit) {
			c.JSON(http.StatusTooManyRequests, gin.H{
				"error": "Rate limit exceeded",
			})
			c.Abort()
			return
		}

		c.Next()
	}
}

func (swrl *SlidingWindowRateLimiter) generateKey(c *gin.Context) string {
	clientIP := c.ClientIP()
	path := c.Request.URL.Path

	return fmt.Sprintf("slidingratelimit:%s:%s", clientIP, path)
}

// Token Bucket Rate Limiter for API endpoints
type TokenBucketRateLimiter struct {
	redisClient *redis.Client
	capacity    int64
	refillRate  int64 // tokens per second
}

func NewTokenBucketRateLimiter(redisClient *redis.Client, capacity, refillRate int64) *TokenBucketRateLimiter {
	return &TokenBucketRateLimiter{
		redisClient: redisClient,
		capacity:    capacity,
		refillRate:  refillRate,
	}
}

func (tbrl *TokenBucketRateLimiter) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		key := tbrl.generateKey(c)
		ctx := context.Background()

		now := time.Now().Unix()

		// Get current bucket state
		result, err := tbrl.redisClient.Get(ctx, key).Result()
		if err != nil && err != redis.Nil {
			c.Next()
			return
		}

		var tokens, lastRefill int64
		if result == "" {
			tokens = tbrl.capacity
			lastRefill = now
		} else {
			// Parse stored state
			fmt.Sscanf(result, "%d:%d", &tokens, &lastRefill)

			// Refill tokens based on time elapsed
			elapsed := now - lastRefill
			tokensToAdd := elapsed * tbrl.refillRate
			tokens = min(tokens+tokensToAdd, tbrl.capacity)
			lastRefill = now
		}

		// Check if tokens available
		if tokens > 0 {
			tokens--

			// Store updated state
			state := fmt.Sprintf("%d:%d", tokens, lastRefill)
			tbrl.redisClient.Set(ctx, key, state, time.Hour)

			c.Next()
			return
		}

		c.JSON(http.StatusTooManyRequests, gin.H{
			"error": "Rate limit exceeded",
		})
		c.Abort()
	}
}

func (tbrl *TokenBucketRateLimiter) generateKey(c *gin.Context) string {
	clientIP := c.ClientIP()
	path := c.Request.URL.Path

	return fmt.Sprintf("tokenbucket:%s:%s", clientIP, path)
}

func min(a, b int64) int64 {
	if a < b {
		return a
	}
	return b
}
