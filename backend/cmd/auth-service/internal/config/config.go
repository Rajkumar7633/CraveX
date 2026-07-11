package config

import (
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	DatabaseURL string
	JWTSecret   string
	OTPSecret   string
	RedisURL    string
	KafkaURL    string
}

func Load() *Config {
	godotenv.Load()

	return &Config{
		DatabaseURL: getEnv("DATABASE_URL", "postgres://user:password@localhost:5432/zomato_clone?sslmode=disable"),
		JWTSecret:   getEnv("JWT_SECRET", "your-secret-key"),
		OTPSecret:   getEnv("OTP_SECRET", "your-otp-secret"),
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
