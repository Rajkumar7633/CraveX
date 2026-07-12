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

// Endpoint-specific rate limit configuration
type EndpointRateLimit struct {
	Path       string
	Method     string
	RateLimit  int
	Window     time.Duration
	BurstLimit int // For token bucket
}

// ConfigurableRateLimiter allows different rate limits per endpoint type
type ConfigurableRateLimiter struct {
	redisClient *redis.Client
	configs     map[string]*EndpointRateLimit // key: "METHOD:path"
}

func NewConfigurableRateLimiter(redisClient *redis.Client) *ConfigurableRateLimiter {
	return &ConfigurableRateLimiter{
		redisClient: redisClient,
		configs:     make(map[string]*EndpointRateLimit),
	}
}

// AddEndpointConfig adds rate limit configuration for a specific endpoint
func (crl *ConfigurableRateLimiter) AddEndpointConfig(config *EndpointRateLimit) {
	key := fmt.Sprintf("%s:%s", config.Method, config.Path)
	crl.configs[key] = config
}

// Middleware returns a middleware that applies endpoint-specific rate limits
func (crl *ConfigurableRateLimiter) Middleware() gin.HandlerFunc {
	return func(c *gin.Context) {
		key := fmt.Sprintf("%s:%s", c.Request.Method, c.Request.URL.Path)

		config, exists := crl.configs[key]
		if !exists {
			// No specific config, use default
			c.Next()
			return
		}

		// Apply rate limiting based on config
		limiter := NewRateLimiter(crl.redisClient, config.RateLimit, config.Window)
		limiter.Middleware()(c)
	}
}

// GetDefaultRateLimitConfigs returns default configurations for common endpoints
func GetDefaultRateLimitConfigs() []*EndpointRateLimit {
	return []*EndpointRateLimit{
		// OTP endpoints - very strict to prevent abuse
		{Path: "/api/v1/auth/send-otp", Method: "POST", RateLimit: 3, Window: time.Hour},
		{Path: "/api/v1/auth/verify-otp", Method: "POST", RateLimit: 10, Window: time.Hour},

		// Authentication endpoints
		{Path: "/api/v1/auth/login", Method: "POST", RateLimit: 5, Window: time.Minute},
		{Path: "/api/v1/auth/register", Method: "POST", RateLimit: 3, Window: time.Hour},

		// Order endpoints
		{Path: "/api/v1/orders", Method: "POST", RateLimit: 10, Window: time.Minute},
		{Path: "/api/v1/orders", Method: "GET", RateLimit: 100, Window: time.Minute},

		// Payment endpoints
		{Path: "/api/v1/payments", Method: "POST", RateLimit: 5, Window: time.Minute},

		// Search endpoints
		{Path: "/api/v1/restaurants/search", Method: "GET", RateLimit: 50, Window: time.Minute},

		// Review endpoints
		{Path: "/api/v1/reviews", Method: "POST", RateLimit: 5, Window: time.Hour},
	}
}
