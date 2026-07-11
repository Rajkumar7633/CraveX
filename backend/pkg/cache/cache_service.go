package cache

import (
	"context"
	"encoding/json"
	"fmt"
	"time"
)

type CacheService struct {
	redis *RedisClient
}

func NewCacheService(redis *RedisClient) *CacheService {
	return &CacheService{redis: redis}
}

func (c *CacheService) SetUserSession(ctx context.Context, userID string, sessionData interface{}, expiration time.Duration) error {
	key := fmt.Sprintf("session:%s", userID)
	data, err := json.Marshal(sessionData)
	if err != nil {
		return err
	}
	return c.redis.Set(ctx, key, data, expiration)
}

func (c *CacheService) GetUserSession(ctx context.Context, userID string, dest interface{}) error {
	key := fmt.Sprintf("session:%s", userID)
	val, err := c.redis.Get(ctx, key)
	if err != nil {
		return err
	}
	return json.Unmarshal([]byte(val), dest)
}

func (c *CacheService) SetRestaurantMenu(ctx context.Context, restaurantID string, menu interface{}, expiration time.Duration) error {
	key := fmt.Sprintf("menu:%s", restaurantID)
	data, err := json.Marshal(menu)
	if err != nil {
		return err
	}
	return c.redis.Set(ctx, key, data, expiration)
}

func (c *CacheService) GetRestaurantMenu(ctx context.Context, restaurantID string, dest interface{}) error {
	key := fmt.Sprintf("menu:%s", restaurantID)
	val, err := c.redis.Get(ctx, key)
	if err != nil {
		return err
	}
	return json.Unmarshal([]byte(val), dest)
}

func (c *CacheService) SetUserProfile(ctx context.Context, userID string, profile interface{}, expiration time.Duration) error {
	key := fmt.Sprintf("profile:%s", userID)
	data, err := json.Marshal(profile)
	if err != nil {
		return err
	}
	return c.redis.Set(ctx, key, data, expiration)
}

func (c *CacheService) GetUserProfile(ctx context.Context, userID string, dest interface{}) error {
	key := fmt.Sprintf("profile:%s", userID)
	val, err := c.redis.Get(ctx, key)
	if err != nil {
		return err
	}
	return json.Unmarshal([]byte(val), dest)
}

func (c *CacheService) CheckRateLimit(ctx context.Context, key string, limit int, window time.Duration) (bool, error) {
	current, err := c.redis.Increment(ctx, key)
	if err != nil {
		return false, err
	}

	if current == 1 {
		c.redis.Expire(ctx, key, window)
	}

	return current <= int64(limit), nil
}

func (c *CacheService) InvalidateUserCache(ctx context.Context, userID string) error {
	pattern := fmt.Sprintf("*:%s", userID)
	keys, err := c.redis.client.Keys(ctx, pattern).Result()
	if err != nil {
		return err
	}
	if len(keys) > 0 {
		return c.redis.Delete(ctx, keys...)
	}
	return nil
}

func (c *CacheService) InvalidateRestaurantCache(ctx context.Context, restaurantID string) error {
	pattern := fmt.Sprintf("menu:%s", restaurantID)
	return c.redis.Delete(ctx, pattern)
}
