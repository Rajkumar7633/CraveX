package config

import (
	"context"
	"fmt"
	"os"
	"strconv"
	"time"

	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
)

// SecretsManager handles secrets management using AWS Secrets Manager
// - No API keys in code/git
// - Secure storage and rotation
// - Environment-specific secrets
type SecretsManager struct {
	smClient *secretsmanager.Client
	cache    map[string]*Secret
}

type Secret struct {
	Name      string
	Value     string
	Version   string
	ExpiresAt time.Time
}

type SecretConfig struct {
	DatabaseURL      string
	JWTSecret        string
	StripeAPIKey     string
	RazorpayAPIKey   string
	PaytmAPIKey      string
	PhonePeAPIKey    string
	RedisPassword    string
	KafkaBrokers     string
	AWSAccessKey     string
	AWSSecretKey     string
	AWSRegion        string
}

func NewSecretManager(useAWS bool) (*SecretsManager, error) {
	sm := &SecretsManager{
		cache: make(map[string]*Secret),
	}

	if useAWS {
		cfg, err := config.LoadDefaultConfig(context.TODO())
		if err != nil {
			return nil, fmt.Errorf("failed to load AWS config: %w", err)
		}

		sm.smClient = secretsmanager.NewFromConfig(cfg)
	}

	return sm, nil
}

// GetSecret retrieves a secret from AWS Secrets Manager or environment variables
func (sm *SecretsManager) GetSecret(ctx context.Context, secretName string) (string, error) {
	// Check cache first
	if cached, exists := sm.cache[secretName]; exists && time.Now().Before(cached.ExpiresAt) {
		return cached.Value, nil
	}

	// Try environment variables first (for local development)
	if value := os.Getenv(secretName); value != "" {
		sm.cache[secretName] = &Secret{
			Name:      secretName,
			Value:     value,
			ExpiresAt: time.Now().Add(5 * time.Minute),
		}
		return value, nil
	}

	// Try AWS Secrets Manager
	if sm.smClient != nil {
		input := &secretsmanager.GetSecretValueInput{
			SecretId: &secretName,
		}

		result, err := sm.smClient.GetSecretValue(ctx, input)
		if err != nil {
			return "", fmt.Errorf("failed to get secret from AWS: %w", err)
		}

		var secretValue string
		if result.SecretString != nil {
			secretValue = *result.SecretString
		} else if result.SecretBinary != nil {
			secretValue = string(result.SecretBinary)
		}

		sm.cache[secretName] = &Secret{
			Name:      secretName,
			Value:     secretValue,
			Version:   *result.VersionId,
			ExpiresAt: time.Now().Add(10 * time.Minute),
		}

		return secretValue, nil
	}

	return "", fmt.Errorf("secret not found: %s", secretName)
}

// GetSecretConfig retrieves all application secrets
func (sm *SecretsManager) GetSecretConfig(ctx context.Context) (*SecretConfig, error) {
	config := &SecretConfig{}

	var err error
	config.DatabaseURL, err = sm.GetSecret(ctx, "DATABASE_URL")
	if err != nil {
		return nil, fmt.Errorf("failed to get database URL: %w", err)
	}

	config.JWTSecret, err = sm.GetSecret(ctx, "JWT_SECRET")
	if err != nil {
		return nil, fmt.Errorf("failed to get JWT secret: %w", err)
	}

	config.StripeAPIKey, err = sm.GetSecret(ctx, "STRIPE_API_KEY")
	if err != nil {
		return nil, fmt.Errorf("failed to get Stripe API key: %w", err)
	}

	config.RazorpayAPIKey, err = sm.GetSecret(ctx, "RAZORPAY_API_KEY")
	if err != nil {
		return nil, fmt.Errorf("failed to get Razorpay API key: %w", err)
	}

	config.PaytmAPIKey, err = sm.GetSecret(ctx, "PAYTM_API_KEY")
	if err != nil {
		return nil, fmt.Errorf("failed to get Paytm API key: %w", err)
	}

	config.PhonePeAPIKey, err = sm.GetSecret(ctx, "PHONEPE_API_KEY")
	if err != nil {
		return nil, fmt.Errorf("failed to get PhonePe API key: %w", err)
	}

	config.RedisPassword, err = sm.GetSecret(ctx, "REDIS_PASSWORD")
	if err != nil {
		return nil, fmt.Errorf("failed to get Redis password: %w", err)
	}

	config.KafkaBrokers, err = sm.GetSecret(ctx, "KAFKA_BROKERS")
	if err != nil {
		return nil, fmt.Errorf("failed to get Kafka brokers: %w", err)
	}

	config.AWSAccessKey, err = sm.GetSecret(ctx, "AWS_ACCESS_KEY")
	if err != nil {
		return nil, fmt.Errorf("failed to get AWS access key: %w", err)
	}

	config.AWSSecretKey, err = sm.GetSecret(ctx, "AWS_SECRET_KEY")
	if err != nil {
		return nil, fmt.Errorf("failed to get AWS secret key: %w", err)
	}

	config.AWSRegion, err = sm.GetSecret(ctx, "AWS_REGION")
	if err != nil {
		return nil, fmt.Errorf("failed to get AWS region: %w", err)
	}

	return config, nil
}

// RotateSecret rotates a secret in AWS Secrets Manager
func (sm *SecretsManager) RotateSecret(ctx context.Context, secretName, newValue string) error {
	if sm.smClient == nil {
		return fmt.Errorf("AWS Secrets Manager not configured")
	}

	input := &secretsmanager.PutSecretValueInput{
		SecretId:     &secretName,
		SecretString: &newValue,
	}

	_, err := sm.smClient.PutSecretValue(ctx, input)
	if err != nil {
		return fmt.Errorf("failed to rotate secret: %w", err)
	}

	// Clear cache
	delete(sm.cache, secretName)

	return nil
}

// InvalidateCache invalidates the secrets cache
func (sm *SecretsManager) InvalidateCache() {
	sm.cache = make(map[string]*Secret)
}

// GetSecretAsInt retrieves a secret as an integer
func (sm *SecretsManager) GetSecretAsInt(ctx context.Context, secretName string) (int, error) {
	value, err := sm.GetSecret(ctx, secretName)
	if err != nil {
		return 0, err
	}

	return strconv.Atoi(value)
}

// GetSecretAsBool retrieves a secret as a boolean
func (sm *SecretsManager) GetSecretAsBool(ctx context.Context, secretName string) (bool, error) {
	value, err := sm.GetSecret(ctx, secretName)
	if err != nil {
		return false, err
	}

	return strconv.ParseBool(value)
}

// GetSecretAsDuration retrieves a secret as a duration
func (sm *SecretsManager) GetSecretAsDuration(ctx context.Context, secretName string) (time.Duration, error) {
	value, err := sm.GetSecret(ctx, secretName)
	if err != nil {
		return 0, err
	}

	return time.ParseDuration(value)
}

// EnvironmentConfig represents environment-specific configuration
type EnvironmentConfig struct {
	Environment string // "dev", "staging", "prod"
	Debug       bool
	LogLevel    string
}

// GetEnvironmentConfig returns environment configuration
func GetEnvironmentConfig() *EnvironmentConfig {
	env := os.Getenv("ENVIRONMENT")
	if env == "" {
		env = "dev"
	}

	debug := os.Getenv("DEBUG") == "true"
	logLevel := os.Getenv("LOG_LEVEL")
	if logLevel == "" {
		logLevel = "info"
	}

	return &EnvironmentConfig{
		Environment: env,
		Debug:       debug,
		LogLevel:    logLevel,
	}
}

// IsProduction checks if running in production
func (ec *EnvironmentConfig) IsProduction() bool {
	return ec.Environment == "prod"
}

// IsDevelopment checks if running in development
func (ec *EnvironmentConfig) IsDevelopment() bool {
	return ec.Environment == "dev"
}

// IsStaging checks if running in staging
func (ec *EnvironmentConfig) IsStaging() bool {
	return ec.Environment == "staging"
}
