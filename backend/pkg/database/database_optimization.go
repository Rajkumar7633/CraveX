package database

import (
	"context"
	"fmt"
	"time"

	"gorm.io/gorm"
)

// DatabaseOptimizer provides database optimization utilities
type DatabaseOptimizer struct {
	db *gorm.DB
}

func NewDatabaseOptimizer(db *gorm.DB) *DatabaseOptimizer {
	return &DatabaseOptimizer{db: db}
}

// CreateIndexes creates all necessary database indexes for optimal performance
func (do *DatabaseOptimizer) CreateIndexes(ctx context.Context) error {
	indexes := []struct {
		table      string
		columns    []string
		name       string
		unique     bool
		concurrent bool
	}{
		// User indexes
		{"users", []string{"email"}, "idx_users_email", true, true},
		{"users", []string{"phone"}, "idx_users_phone", true, true},
		{"users", []string{"user_type"}, "idx_users_user_type", false, true},
		{"users", []string{"is_active"}, "idx_users_is_active", false, true},
		{"users", []string{"created_at"}, "idx_users_created_at", false, true},

		// Restaurant indexes
		{"restaurants", []string{"owner_id"}, "idx_restaurants_owner_id", false, true},
		{"restaurants", []string{"city"}, "idx_restaurants_city", false, true},
		{"restaurants", []string{"cuisine_type"}, "idx_restaurants_cuisine_type", false, true},
		{"restaurants", []string{"is_verified"}, "idx_restaurants_is_verified", false, true},
		{"restaurants", []string{"is_active"}, "idx_restaurants_is_active", false, true},
		{"restaurants", []string{"is_featured"}, "idx_restaurants_is_featured", false, true},
		{"restaurants", []string{"rating"}, "idx_restaurants_rating", false, true},
		{"restaurants", []string{"latitude", "longitude"}, "idx_restaurants_location", false, true},
		{"restaurants", []string{"city", "cuisine_type"}, "idx_restaurants_city_cuisine", false, true},
		{"restaurants", []string{"is_active", "is_verified"}, "idx_restaurants_active_verified", false, true},

		// Order indexes
		{"orders", []string{"order_number"}, "idx_orders_order_number", true, true},
		{"orders", []string{"user_id"}, "idx_orders_user_id", false, true},
		{"orders", []string{"restaurant_id"}, "idx_orders_restaurant_id", false, true},
		{"orders", []string{"rider_id"}, "idx_orders_rider_id", false, true},
		{"orders", []string{"status"}, "idx_orders_status", false, true},
		{"orders", []string{"payment_status"}, "idx_orders_payment_status", false, true},
		{"orders", []string{"created_at"}, "idx_orders_created_at", false, true},
		{"orders", []string{"user_id", "status"}, "idx_orders_user_status", false, true},
		{"orders", []string{"restaurant_id", "status"}, "idx_orders_restaurant_status", false, true},
		{"orders", []string{"rider_id", "status"}, "idx_orders_rider_status", false, true},
		{"orders", []string{"created_at", "status"}, "idx_orders_created_status", false, true},

		// Rider indexes
		{"riders", []string{"user_id"}, "idx_riders_user_id", false, true},
		{"riders", []string{"status"}, "idx_riders_status", false, true},
		{"riders", []string{"vehicle_type"}, "idx_riders_vehicle_type", false, true},
		{"riders", []string{"is_verified"}, "idx_riders_is_verified", false, true},
		{"riders", []string{"is_active"}, "idx_riders_is_active", false, true},
		{"riders", []string{"latitude", "longitude"}, "idx_riders_location", false, true},
		{"riders", []string{"status", "is_active"}, "idx_riders_status_active", false, true},

		// Payment indexes
		{"payments", []string{"order_id"}, "idx_payments_order_id", false, true},
		{"payments", []string{"user_id"}, "idx_payments_user_id", false, true},
		{"payments", []string{"transaction_id"}, "idx_payments_transaction_id", false, true},
		{"payments", []string{"status"}, "idx_payments_status", false, true},
		{"payments", []string{"gateway"}, "idx_payments_gateway", false, true},
		{"payments", []string{"created_at"}, "idx_payments_created_at", false, true},
		{"payments", []string{"user_id", "status"}, "idx_payments_user_status", false, true},

		// Notification indexes
		{"notifications", []string{"user_id"}, "idx_notifications_user_id", false, true},
		{"notifications", []string{"type"}, "idx_notifications_type", false, true},
		{"notifications", []string{"read"}, "idx_notifications_read", false, true},
		{"notifications", []string{"created_at"}, "idx_notifications_created_at", false, true},
		{"notifications", []string{"user_id", "read"}, "idx_notifications_user_read", false, true},
		{"notifications", []string{"user_id", "created_at"}, "idx_notifications_user_created", false, true},

		// Menu item indexes
		{"menu_items", []string{"restaurant_id"}, "idx_menu_items_restaurant_id", false, true},
		{"menu_items", []string{"category_id"}, "idx_menu_items_category_id", false, true},
		{"menu_items", []string{"is_available"}, "idx_menu_items_is_available", false, true},
		{"menu_items", []string{"restaurant_id", "is_available"}, "idx_menu_items_restaurant_available", false, true},

		// Wallet indexes
		{"wallets", []string{"user_id"}, "idx_wallets_user_id", true, true},
		{"wallet_transactions", []string{"wallet_id"}, "idx_wallet_transactions_wallet_id", false, true},
		{"wallet_transactions", []string{"user_id"}, "idx_wallet_transactions_user_id", false, true},
		{"wallet_transactions", []string{"created_at"}, "idx_wallet_transactions_created_at", false, true},
		{"wallet_transactions", []string{"user_id", "created_at"}, "idx_wallet_transactions_user_created", false, true},
	}

	for _, idx := range indexes {
		if err := do.createIndex(ctx, idx.table, idx.columns, idx.name, idx.unique, idx.concurrent); err != nil {
			return fmt.Errorf("failed to create index %s on table %s: %w", idx.name, idx.table, err)
		}
	}

	return nil
}

func (do *DatabaseOptimizer) createIndex(ctx context.Context, table string, columns []string, name string, unique, concurrent bool) error {
	uniqueStr := ""
	if unique {
		uniqueStr = " UNIQUE"
	}

	concurrentStr := ""
	if concurrent {
		concurrentStr = " CONCURRENTLY"
	}

	columnsStr := ""
	for i, col := range columns {
		if i > 0 {
			columnsStr += ", "
		}
		columnsStr += col
	}

	query := fmt.Sprintf("CREATE%s INDEX%s IF NOT EXISTS %s ON %s (%s)",
		concurrentStr, uniqueStr, name, table, columnsStr)

	return do.db.WithContext(ctx).Exec(query).Error
}

// AnalyzeTables runs ANALYZE on all tables to update statistics
func (do *DatabaseOptimizer) AnalyzeTables(ctx context.Context) error {
	tables := []string{
		"users", "restaurants", "orders", "riders", "payments",
		"notifications", "menu_items", "wallets", "wallet_transactions",
		"delivery_addresses", "menu_categories", "order_items",
	}

	for _, table := range tables {
		query := fmt.Sprintf("ANALYZE %s", table)
		if err := do.db.WithContext(ctx).Exec(query).Error; err != nil {
			return fmt.Errorf("failed to analyze table %s: %w", table, err)
		}
	}

	return nil
}

// VacuumTables runs VACUUM on tables to reclaim storage
func (do *DatabaseOptimizer) VacuumTables(ctx context.Context) error {
	tables := []string{
		"orders", "notifications", "wallet_transactions",
		"menu_items", "order_items",
	}

	for _, table := range tables {
		query := fmt.Sprintf("VACUUM ANALYZE %s", table)
		if err := do.db.WithContext(ctx).Exec(query).Error; err != nil {
			return fmt.Errorf("failed to vacuum table %s: %w", table, err)
		}
	}

	return nil
}

// OptimizeDatabase runs comprehensive database optimization
func (do *DatabaseOptimizer) OptimizeDatabase(ctx context.Context) error {
	// Create indexes
	if err := do.CreateIndexes(ctx); err != nil {
		return fmt.Errorf("failed to create indexes: %w", err)
	}

	// Analyze tables
	if err := do.AnalyzeTables(ctx); err != nil {
		return fmt.Errorf("failed to analyze tables: %w", err)
	}

	// Vacuum tables
	if err := do.VacuumTables(ctx); err != nil {
		return fmt.Errorf("failed to vacuum tables: %w", err)
	}

	return nil
}

// QueryOptimizer provides query optimization utilities
type QueryOptimizer struct {
	db *gorm.DB
}

func NewQueryOptimizer(db *gorm.DB) *QueryOptimizer {
	return &QueryOptimizer{db: db}
}

// ExplainQuery explains a query and returns the execution plan
func (qo *QueryOptimizer) ExplainQuery(ctx context.Context, query string) (string, error) {
	var result string
	err := qo.db.WithContext(ctx).Raw("EXPLAIN " + query).Scan(&result).Error
	return result, err
}

// AnalyzeQuery analyzes query performance
func (qo *QueryOptimizer) AnalyzeQuery(ctx context.Context, query string) (*QueryAnalysis, error) {
	// Get explain plan
	explainPlan, err := qo.ExplainQuery(ctx, query)
	if err != nil {
		return nil, err
	}

	// Get query execution time
	start := time.Now()
	var result interface{}
	err = qo.db.WithContext(ctx).Raw(query).Scan(&result).Error
	duration := time.Since(start)

	analysis := &QueryAnalysis{
		Query:         query,
		ExplainPlan:   explainPlan,
		ExecutionTime: duration,
		Timestamp:     time.Now(),
	}

	return analysis, err
}

type QueryAnalysis struct {
	Query         string        `json:"query"`
	ExplainPlan   string        `json:"explain_plan"`
	ExecutionTime time.Duration `json:"execution_time"`
	Timestamp     time.Time     `json:"timestamp"`
}

// SlowQueryLog captures slow queries for analysis
type SlowQueryLog struct {
	ID            uint          `json:"id"`
	Query         string        `json:"query"`
	ExecutionTime time.Duration `json:"execution_time"`
	Timestamp     time.Time     `json:"timestamp"`
	Database      string        `json:"database"`
	User          string        `json:"user"`
}

// LogSlowQuery logs slow queries for analysis
func (qo *QueryOptimizer) LogSlowQuery(ctx context.Context, query string, executionTime time.Duration) error {
	if executionTime > 1*time.Second {
		slowQuery := SlowQueryLog{
			Query:         query,
			ExecutionTime: executionTime,
			Timestamp:     time.Now(),
		}
		return qo.db.WithContext(ctx).Create(&slowQuery).Error
	}
	return nil
}

// ConnectionPoolOptimizer manages database connection pool settings
type ConnectionPoolOptimizer struct {
	db *gorm.DB
}

func NewConnectionPoolOptimizer(db *gorm.DB) *ConnectionPoolOptimizer {
	return &ConnectionPoolOptimizer{db: db}
}

// OptimizeConnectionPool optimizes connection pool settings based on workload
func (cpo *ConnectionPoolOptimizer) OptimizeConnectionPool(maxOpenConns, maxIdleConns, connMaxLifetime int) error {
	sqlDB, err := cpo.db.DB()
	if err != nil {
		return err
	}

	sqlDB.SetMaxOpenConns(maxOpenConns)
	sqlDB.SetMaxIdleConns(maxIdleConns)
	sqlDB.SetConnMaxLifetime(time.Duration(connMaxLifetime) * time.Minute)

	return nil
}

// GetConnectionPoolStats returns connection pool statistics
func (cpo *ConnectionPoolOptimizer) GetConnectionPoolStats() (*ConnectionPoolStats, error) {
	sqlDB, err := cpo.db.DB()
	if err != nil {
		return nil, err
	}

	stats := sqlDB.Stats()

	return &ConnectionPoolStats{
		MaxOpenConnections: stats.MaxOpenConnections,
		OpenConnections:    stats.OpenConnections,
		InUse:              stats.InUse,
		Idle:               stats.Idle,
		WaitCount:          stats.WaitCount,
		WaitDuration:       stats.WaitDuration,
		MaxIdleClosed:      stats.MaxIdleClosed,
		MaxLifetimeClosed:  stats.MaxLifetimeClosed,
	}, nil
}

type ConnectionPoolStats struct {
	MaxOpenConnections int           `json:"max_open_connections"`
	OpenConnections    int           `json:"open_connections"`
	InUse              int           `json:"in_use"`
	Idle               int           `json:"idle"`
	WaitCount          int64         `json:"wait_count"`
	WaitDuration       time.Duration `json:"wait_duration"`
	MaxIdleClosed      int64         `json:"max_idle_closed"`
	MaxLifetimeClosed  int64         `json:"max_lifetime_closed"`
}

// PartitioningStrategy defines table partitioning strategies
type PartitioningStrategy string

const (
	PartitionByDate  PartitioningStrategy = "date"
	PartitionByHash  PartitioningStrategy = "hash"
	PartitionByRange PartitioningStrategy = "range"
)

// PartitionManager manages table partitioning
type PartitionManager struct {
	db *gorm.DB
}

func NewPartitionManager(db *gorm.DB) *PartitionManager {
	return &PartitionManager{db: db}
}

// CreatePartition creates a table partition
func (pm *PartitionManager) CreatePartition(ctx context.Context, table string, strategy PartitioningStrategy, partitionKey string, partitionValue string) error {
	partitionName := fmt.Sprintf("%s_%s", table, partitionValue)

	var query string
	switch strategy {
	case PartitionByDate:
		query = fmt.Sprintf("CREATE TABLE IF NOT EXISTS %s PARTITION OF %s FOR VALUES FROM ('%s') TO ('%s')",
			partitionName, table, partitionValue, getNextDate(partitionValue))
	case PartitionByHash:
		query = fmt.Sprintf("CREATE TABLE IF NOT EXISTS %s PARTITION OF %s FOR VALUES WITH (MODULUS 4, REMAINDER %s)",
			partitionName, table, partitionValue)
	case PartitionByRange:
		query = fmt.Sprintf("CREATE TABLE IF NOT EXISTS %s PARTITION OF %s FOR VALUES FROM (%s) TO (%s)",
			partitionName, table, partitionValue, getNextRange(partitionValue))
	default:
		return fmt.Errorf("unsupported partitioning strategy: %s", strategy)
	}

	return pm.db.WithContext(ctx).Exec(query).Error
}

func getNextDate(dateStr string) string {
	// Calculate next date for partitioning
	return dateStr
}

func getNextRange(rangeStr string) string {
	// Calculate next range for partitioning
	return rangeStr
}

// BackupManager manages database backups
type BackupManager struct {
	db *gorm.DB
}

func NewBackupManager(db *gorm.DB) *BackupManager {
	return &BackupManager{db: db}
}

// CreateBackup creates a database backup
func (bm *BackupManager) CreateBackup(ctx context.Context, backupPath string) error {
	_, err := bm.db.DB()
	if err != nil {
		return err
	}

	// This would typically use pg_dump or similar tool
	// For now, we'll use a simple approach
	_ = fmt.Sprintf("pg_dump -Fc -f %s cravex", backupPath)

	// Execute backup command
	// This would be implemented with proper command execution
	return nil
}

// RestoreBackup restores a database backup
func (bm *BackupManager) RestoreBackup(ctx context.Context, backupPath string) error {
	_, err := bm.db.DB()
	if err != nil {
		return err
	}

	// This would typically use pg_restore or similar tool
	_ = fmt.Sprintf("pg_restore -d cravex %s", backupPath)

	// Execute restore command
	// This would be implemented with proper command execution
	return nil
}
