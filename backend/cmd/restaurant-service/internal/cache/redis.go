package cache

import (
	"context"
	"encoding/json"
	"time"

	"github.com/redis/go-redis/v9"
)

type CacheService interface {
	Get(ctx context.Context, key string, dest interface{}) error
	Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error
	Delete(ctx context.Context, key string) error
}

type cacheService struct {
	client *redis.Client
}

func NewCacheService(redisURL string) (CacheService, error) {
	opts, err := redis.ParseURL(redisURL)
	var client *redis.Client
	if err != nil {
		client = redis.NewClient(&redis.Options{
			Addr: redisURL,
		})
	} else {
		client = redis.NewClient(opts)
	}

	return &cacheService{client: client}, nil
}

func (s *cacheService) Get(ctx context.Context, key string, dest interface{}) error {
	val, err := s.client.Get(ctx, key).Result()
	if err != nil {
		return err
	}
	return json.Unmarshal([]byte(val), dest)
}

func (s *cacheService) Set(ctx context.Context, key string, value interface{}, ttl time.Duration) error {
	data, err := json.Marshal(value)
	if err != nil {
		return err
	}
	return s.client.Set(ctx, key, data, ttl).Err()
}

func (s *cacheService) Delete(ctx context.Context, key string) error {
	return s.client.Del(ctx, key).Err()
}
