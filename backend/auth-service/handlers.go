package main

import (
    "net/http"
    "sync"
    "time"

    "github.com/gin-gonic/gin"
    "github.com/golang-jwt/jwt/v4"
)

// JWT secret – in production use env var / secret manager
var jwtSecret = []byte("super_secret_key")

type LoginRequest struct {
    Email    string `json:"email"`
    Password string `json:"password"`
}

type OTPRequest struct {
    PhoneNumber string `json:"phoneNumber"`
    OTP         string `json:"otp"`
}

type AuthResponse struct {
    Token string `json:"token"`
    User  struct {
        ID    string `json:"id"`
        Email string `json:"email"`
    } `json:"user"`
}

func generateJWT(userID, email string) (string, error) {
    claims := jwt.MapClaims{
        "sub": userID,
        "email": email,
        "exp": time.Now().Add(24 * time.Hour).Unix(),
        "iat": time.Now().Unix(),
    }
    token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
    return token.SignedString(jwtSecret)
}

func loginHandler(c *gin.Context) {
    var req LoginRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
        return
    }
    // TODO: validate against DB / Firebase. Here we mock a user.
    token, err := generateJWT("user-123", req.Email)
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "token generation failed"})
        return
    }
    resp := AuthResponse{Token: token}
    resp.User.ID = "user-123"
    resp.User.Email = req.Email
    c.JSON(http.StatusOK, resp)
}

type OTPTracker struct {
	Count       int
	LastRequest time.Time
}

var (
	otpTrackerMap = make(map[string]*OTPTracker)
	otpTrackerMu  sync.Mutex
)

func otpHandler(c *gin.Context) {
    var req OTPRequest
    if err := c.ShouldBindJSON(&req); err != nil {
        c.JSON(http.StatusBadRequest, gin.H{"error": "invalid request"})
        return
    }

	// OTP Abuse Protection Rate Limiter
	otpTrackerMu.Lock()
	tracker, exists := otpTrackerMap[req.PhoneNumber]
	now := time.Now()
	if !exists {
		tracker = &OTPTracker{Count: 1, LastRequest: now}
		otpTrackerMap[req.PhoneNumber] = tracker
	} else {
		// Reset count if last request was more than 1 hour ago
		if now.Sub(tracker.LastRequest) > time.Hour {
			tracker.Count = 1
			tracker.LastRequest = now
		} else {
			// Limit to maximum of 3 requests per hour
			if tracker.Count >= 3 {
				otpTrackerMu.Unlock()
				c.JSON(http.StatusTooManyRequests, gin.H{"error": "Maximum of 3 OTP requests per hour exceeded. Please try again later."})
				return
			}

			// Cooldown checks (exponential: 1st retry: 5s, 2nd retry: 30s)
			var cooldown time.Duration
			if tracker.Count == 1 {
				cooldown = 5 * time.Second
			} else if tracker.Count == 2 {
				cooldown = 30 * time.Second
			}
			if now.Sub(tracker.LastRequest) < cooldown {
				remaining := cooldown - now.Sub(tracker.LastRequest)
				otpTrackerMu.Unlock()
				c.JSON(http.StatusTooManyRequests, gin.H{
					"error":            "Rate limit exceeded. Cooldown active.",
					"cooldown_seconds": int(remaining.Seconds()),
				})
				return
			}

			tracker.Count++
			tracker.LastRequest = now
		}
	}
	otpTrackerMu.Unlock()

    // Mock OTP verification – always succeed
    token, err := generateJWT("user-otp-"+req.PhoneNumber, req.PhoneNumber+"@example.com")
    if err != nil {
        c.JSON(http.StatusInternalServerError, gin.H{"error": "token generation failed"})
        return
    }
    resp := AuthResponse{Token: token}
    resp.User.ID = "user-otp-" + req.PhoneNumber
    resp.User.Email = req.PhoneNumber + "@example.com"
    c.JSON(http.StatusOK, resp)
}

func registerRoutes(r *gin.Engine) {
    auth := r.Group("/auth")
    auth.POST("/login", loginHandler)
    auth.POST("/otp", otpHandler)
    // future: /signup, /refresh
}
