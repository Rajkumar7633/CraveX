# Redis Setup Guide for CraveX

This guide explains how to set up and configure Redis for caching in the CraveX food delivery platform.

## Overview

Redis will be used for:
- **Session Management**: Store user sessions and authentication tokens
- **Rate Limiting**: Implement API rate limiting for all services
- **Caching**: Cache frequently accessed data (restaurant menus, user profiles, etc.)
- **Real-time Data**: Store real-time rider locations and order statuses
- **Pub/Sub**: Enable real-time notifications between services

## Prerequisites

- Docker and Docker Compose installed
- Redis CLI tools (optional)

## Installation

### Using Docker Compose (Recommended)

Add the following to your `docker-compose.yml`:

```yaml
version: '3.8'

services:
  redis:
    image: redis:7-alpine
    container_name: cravex-redis
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: redis-server --appendonly yes
    networks:
      - cravex-network
    restart: unless-stopped

  redis-commander:
    image: rediscommander/redis-commander:latest
    container_name: cravex-redis-commander
    environment:
      - REDIS_HOSTS=local:redis:6379
    ports:
      - "8081:8081"
    networks:
      - cravex-network
    depends_on:
      - redis

volumes:
  redis-data:
    driver: local

networks:
  cravex-network:
    driver: bridge
```

Start Redis:
```bash
docker-compose up -d redis redis-commander
```

### Manual Installation

```bash
# macOS
brew install redis

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install redis-server

# Start Redis
redis-server
```

## Configuration

### Redis Configuration File

Create `redis.conf`:

```conf
# Network
bind 0.0.0.0
port 6379
protected-mode no

# Persistence
appendonly yes
appendfsync everysec
save 900 1
save 300 10
save 60 10000

# Memory Management
maxmemory 2gb
maxmemory-policy allkeys-lru

# Logging
loglevel notice
logfile /var/log/redis/redis.log

# Security
requirepass cravex_secure_password_2024

# Performance
tcp-backlog 511
timeout 300
tcp-keepalive 300
```

## Go Integration

### Install Redis Client

```bash
go get github.com/go-redis/redis/v8
```

### Redis Client Implementation

Create `backend/pkg/cache/redis_client.go`:

```go
package cache

import (
	"context"
	"fmt"
	"time"

	"github.com/go-redis/redis/v8"
)

type RedisClient struct {
	client *redis.Client
}

func NewRedisClient(addr, password string, db int) (*RedisClient, error) {
	rdb := redis.NewClient(&redis.Options{
		Addr:     addr,
		Password: password,
		DB:       db,
	})

	// Test connection
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := rdb.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("failed to connect to Redis: %w", err)
	}

	return &RedisClient{client: rdb}, nil
}

func (r *RedisClient) Set(ctx context.Context, key string, value interface{}, expiration time.Duration) error {
	return r.client.Set(ctx, key, value, expiration).Err()
}

func (r *RedisClient) Get(ctx context.Context, key string) (string, error) {
	return r.client.Get(ctx, key).Result()
}

func (r *RedisClient) Delete(ctx context.Context, keys ...string) error {
	return r.client.Del(ctx, keys...).Err()
}

func (r *RedisClient) Exists(ctx context.Context, keys ...string) (int64, error) {
	return r.client.Exists(ctx, keys...).Result()
}

func (r *RedisClient) SetJSON(ctx context.Context, key string, value interface{}, expiration time.Duration) error {
	return r.client.Set(ctx, key, value, expiration).Err()
}

func (r *RedisClient) GetJSON(ctx context.Context, key string, dest interface{}) error {
	val, err := r.client.Get(ctx, key).Result()
	if err != nil {
		return err
	}
	return r.client.Get(ctx, val).Scan(dest)
}

func (r *RedisClient) Increment(ctx context.Context, key string) (int64, error) {
	return r.client.Incr(ctx, key).Result()
}

func (r *RedisClient) Decrement(ctx context.Context, key string) (int64, error) {
	return r.client.Decr(ctx, key).Result()
}

func (r *RedisClient) Expire(ctx context.Context, key string, expiration time.Duration) error {
	return r.client.Expire(ctx, key, expiration).Err()
}

func (r *RedisClient) Close() error {
	return r.client.Close()
}
```

### Cache Service Implementation

Create `backend/pkg/cache/cache_service.go`:

```go
package cache

import (
	"context"
	"encoding/json"
	"time"
)

type CacheService struct {
	redis *RedisClient
}

func NewCacheService(redis *RedisClient) *CacheService {
	return &CacheService{redis: redis}
}

// Cache user session
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

// Cache restaurant menu
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

// Cache user profile
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

// Rate limiting
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

// Invalidate cache
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
```

## Service Integration

### Auth Service Integration

Update `backend/cmd/auth-service/main.go`:

```go
package main

import (
    "context"
    "log"
    "time"
    
    "github.com/zomato-clone/pkg/cache"
)

func main() {
    // Initialize Redis
    redisClient, err := cache.NewRedisClient(
        os.Getenv("REDIS_ADDR"),
        os.Getenv("REDIS_PASSWORD"),
        0,
    )
    if err != nil {
        log.Fatalf("Failed to connect to Redis: %v", err)
    }
    defer redisClient.Close()

    cacheService := cache.NewCacheService(redisClient)

    // Use cache service in handlers
    // ...
}
```

### Restaurant Service Integration

```go
// Cache menu after fetching
func (s *RestaurantService) GetMenu(ctx context.Context, restaurantID string) (*Menu, error) {
    // Try cache first
    var menu Menu
    err := s.cache.GetRestaurantMenu(ctx, restaurantID, &menu)
    if err == nil {
        return &menu, nil
    }

    // Fetch from database
    menu, err = s.repository.GetMenu(ctx, restaurantID)
    if err != nil {
        return nil, err
    }

    // Cache for 1 hour
    s.cache.SetRestaurantMenu(ctx, restaurantID, menu, time.Hour)
    
    return menu, nil
}
```

## Environment Variables

Add to `.env` files:

```bash
# Redis Configuration
REDIS_ADDR=redis:6379
REDIS_PASSWORD=cravex_secure_password_2024
REDIS_DB=0
REDIS_CACHE_TTL=3600
```

## Monitoring

### Redis Commander

Access Redis Commander at `http://localhost:8081` to:
- View all keys
- Monitor Redis operations
- Execute Redis commands
- Analyze memory usage

### CLI Monitoring

```bash
# Connect to Redis
redis-cli -h localhost -p 6379 -a cravex_secure_password_2024

# Monitor commands
MONITOR

# Check memory
INFO memory

# Check connected clients
CLIENT LIST

# Slow log
SLOWLOG GET 10
```

## Best Practices

1. **Key Naming Convention**: Use consistent naming like `service:entity:id`
   - `session:user:123`
   - `menu:restaurant:456`
   - `profile:user:789`

2. **Expiration**: Always set TTL for cached data
   - Sessions: 24 hours
   - Menus: 1 hour
   - User profiles: 6 hours
   - Rate limits: 1 minute

3. **Memory Management**: Monitor memory usage and set appropriate limits
   - Use `maxmemory-policy allkeys-lru`
   - Monitor with `INFO memory`

4. **Security**: Always use password authentication in production
   - Set `requirepass` in redis.conf
   - Use environment variables for passwords

5. **Persistence**: Enable AOF for durability
   - `appendonly yes`
   - `appendfsync everysec`

## Troubleshooting

### Connection Issues

```bash
# Check if Redis is running
redis-cli ping

# Check logs
docker logs cravex-redis

# Test connection from Go
redis-cli -h localhost -p 6379 -a cravex_secure_password_2024 ping
```

### Memory Issues

```bash
# Check memory usage
redis-cli INFO memory

# Clear all keys (use with caution)
redis-cli FLUSHALL

# Clear specific pattern
redis-cli --scan --pattern "menu:*" | xargs redis-cli DEL
```

### Performance Issues

```bash
# Check slow queries
redis-cli SLOWLOG GET 10

# Monitor in real-time
redis-cli MONITOR

# Check client connections
redis-cli CLIENT LIST
```

## Production Considerations

1. **High Availability**: Use Redis Sentinel or Redis Cluster
2. **Persistence**: Enable both RDB and AOF
3. **Security**: Use TLS encryption
4. **Monitoring**: Set up alerts for memory usage and connection counts
5. **Backup**: Regular backups of RDB files
6. **Scaling**: Consider sharding for large datasets

## Next Steps

- [ ] Set up Redis Sentinel for high availability
- [ ] Implement Redis Pub/Sub for real-time notifications
- [ ] Add Redis monitoring to observability stack
- [ ] Set up automated backups
- [ ] Implement cache warming strategies
