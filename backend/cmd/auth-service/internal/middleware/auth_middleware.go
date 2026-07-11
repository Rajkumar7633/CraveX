package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/zomato-clone/auth-service/internal/services"
)

type AuthMiddleware struct {
	authService services.AuthService
}

func NewAuthMiddleware(authService services.AuthService) *AuthMiddleware {
	return &AuthMiddleware{
		authService: authService,
	}
}

func (m *AuthMiddleware) Authenticate() gin.HandlerFunc {
	return func(c *gin.Context) {
		authHeader := c.GetHeader("Authorization")
		if authHeader == "" {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "authorization header required"})
			c.Abort()
			return
		}

		tokenString := strings.TrimPrefix(authHeader, "Bearer ")
		if tokenString == authHeader {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid authorization header format"})
			c.Abort()
			return
		}

		user, err := m.authService.ValidateToken(tokenString)
		if err != nil {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "invalid token"})
			c.Abort()
			return
		}

		c.Set("user_id", user.ID.String())
		c.Set("user_type", user.UserType)
		c.Next()
	}
}

func (m *AuthMiddleware) RequireUserType(userType string) gin.HandlerFunc {
	return func(c *gin.Context) {
		currentUserType, exists := c.Get("user_type")
		if !exists {
			c.JSON(http.StatusUnauthorized, gin.H{"error": "unauthorized"})
			c.Abort()
			return
		}

		if currentUserType != userType {
			c.JSON(http.StatusForbidden, gin.H{"error": "insufficient permissions"})
			c.Abort()
			return
		}

		c.Next()
	}
}

func (m *AuthMiddleware) RequireAdmin() gin.HandlerFunc {
	return m.RequireUserType("admin")
}

func (m *AuthMiddleware) RequireRestaurant() gin.HandlerFunc {
	return m.RequireUserType("restaurant")
}

func (m *AuthMiddleware) RequireRider() gin.HandlerFunc {
	return m.RequireUserType("rider")
}

func (m *AuthMiddleware) RequireCustomer() gin.HandlerFunc {
	return m.RequireUserType("customer")
}
