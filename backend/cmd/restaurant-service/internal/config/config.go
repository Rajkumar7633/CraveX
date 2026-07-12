package config

import (
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	DatabaseURL string
	RedisURL    string
	KafkaURL    string
}

func Load() *Config {
	godotenv.Load()

	return &Config{
		DatabaseURL: getEnv("DATABASE_URL", "postgres://postgres:Raj@76330Raj@localhost:5432/cravex?sslmode=disable"),
		RedisURL:    getEnv("REDIS_URL", "localhost:6379"),
		KafkaURL:    getEnv("KAFKA_URL", "localhost:9092"),
	}
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}
