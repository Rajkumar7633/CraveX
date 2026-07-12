package database

import (
	"context"
	"database/sql"
	"fmt"
	"os"
	"path/filepath"
	"sort"
	"strconv"
	"strings"
	"time"
)

// MigrationManager handles database migrations with versioning
// - Versioned migrations (never manual schema changes in prod)
// - Up and down migrations for rollback capability
// - Migration history tracking
type MigrationManager struct {
	db       *sql.DB
	migrator Migrator
}

type Migrator interface {
	Up(ctx context.Context, version int) error
	Down(ctx context.Context, version int) error
}

type Migration struct {
	Version   int
	Name      string
	UpSQL     string
	DownSQL   string
	AppliedAt *time.Time
	Checksum  string
}

type MigrationHistory struct {
	Version   int
	Name      string
	AppliedAt time.Time
	Checksum  string
}

func NewMigrationManager(db *sql.DB) *MigrationManager {
	return &MigrationManager{
		db: db,
	}
}

// InitializeMigrationTable creates the migration history table if it doesn't exist
func (mm *MigrationManager) InitializeMigrationTable(ctx context.Context) error {
	query := `
		CREATE TABLE IF NOT EXISTS schema_migrations (
			version INTEGER PRIMARY KEY,
			name VARCHAR(255) NOT NULL,
			applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
			checksum VARCHAR(64) NOT NULL
		);
	`

	_, err := mm.db.ExecContext(ctx, query)
	if err != nil {
		return fmt.Errorf("failed to create migration table: %w", err)
	}

	return nil
}

// GetAppliedMigrations returns all applied migrations from the history table
func (mm *MigrationManager) GetAppliedMigrations(ctx context.Context) ([]*MigrationHistory, error) {
	query := `SELECT version, name, applied_at, checksum FROM schema_migrations ORDER BY version ASC`

	rows, err := mm.db.QueryContext(ctx, query)
	if err != nil {
		return nil, fmt.Errorf("failed to get applied migrations: %w", err)
	}
	defer rows.Close()

	var migrations []*MigrationHistory
	for rows.Next() {
		var history MigrationHistory
		if err := rows.Scan(&history.Version, &history.Name, &history.AppliedAt, &history.Checksum); err != nil {
			return nil, fmt.Errorf("failed to scan migration history: %w", err)
		}
		migrations = append(migrations, &history)
	}

	return migrations, nil
}

// LoadMigrations loads migration files from a directory
func (mm *MigrationManager) LoadMigrations(migrationsDir string) ([]*Migration, error) {
	files, err := os.ReadDir(migrationsDir)
	if err != nil {
		return nil, fmt.Errorf("failed to read migrations directory: %w", err)
	}

	var migrations []*Migration
	for _, file := range files {
		if file.IsDir() {
			continue
		}

		// Parse migration filename: V001__initial_schema.up.sql
		filename := file.Name()
		if !strings.HasPrefix(filename, "V") || !strings.HasSuffix(filename, ".sql") {
			continue
		}

		parts := strings.Split(strings.TrimSuffix(filename, ".sql"), "__")
		if len(parts) < 2 {
			continue
		}

		versionStr := strings.TrimPrefix(parts[0], "V")
		version, err := strconv.Atoi(versionStr)
		if err != nil {
			continue
		}

		name := parts[1]
		migrationType := "up"
		if strings.Contains(filename, ".down.") {
			migrationType = "down"
		}

		content, err := os.ReadFile(filepath.Join(migrationsDir, filename))
		if err != nil {
			return nil, fmt.Errorf("failed to read migration file %s: %w", filename, err)
		}

		// Find or create migration entry
		var migration *Migration
		for _, m := range migrations {
			if m.Version == version {
				migration = m
				break
			}
		}

		if migration == nil {
			migration = &Migration{
				Version: version,
				Name:    name,
			}
			migrations = append(migrations, migration)
		}

		if migrationType == "up" {
			migration.UpSQL = string(content)
		} else {
			migration.DownSQL = string(content)
		}

		migration.Checksum = fmt.Sprintf("%x", len(content)) // Simple checksum
	}

	// Sort migrations by version
	sort.Slice(migrations, func(i, j int) bool {
		return migrations[i].Version < migrations[j].Version
	})

	return migrations, nil
}

// MigrateUp applies all pending migrations
func (mm *MigrationManager) MigrateUp(ctx context.Context, migrationsDir string) error {
	if err := mm.InitializeMigrationTable(ctx); err != nil {
		return err
	}

	migrations, err := mm.LoadMigrations(migrationsDir)
	if err != nil {
		return err
	}

	applied, err := mm.GetAppliedMigrations(ctx)
	if err != nil {
		return err
	}

	appliedVersions := make(map[int]bool)
	for _, h := range applied {
		appliedVersions[h.Version] = true
	}

	for _, migration := range migrations {
		if appliedVersions[migration.Version] {
			continue
		}

		if migration.UpSQL == "" {
			return fmt.Errorf("migration %d has no up SQL", migration.Version)
		}

		// Begin transaction
		tx, err := mm.db.BeginTx(ctx, nil)
		if err != nil {
			return fmt.Errorf("failed to begin transaction: %w", err)
		}

		// Execute migration
		if _, err := tx.ExecContext(ctx, migration.UpSQL); err != nil {
			tx.Rollback()
			return fmt.Errorf("failed to apply migration %d: %w", migration.Version, err)
		}

		// Record migration in history
		now := time.Now()
		if _, err := tx.ExecContext(ctx,
			`INSERT INTO schema_migrations (version, name, applied_at, checksum) VALUES ($1, $2, $3, $4)`,
			migration.Version, migration.Name, now, migration.Checksum); err != nil {
			tx.Rollback()
			return fmt.Errorf("failed to record migration %d: %w", migration.Version, err)
		}

		// Commit transaction
		if err := tx.Commit(); err != nil {
			return fmt.Errorf("failed to commit migration %d: %w", migration.Version, err)
		}

		fmt.Printf("Applied migration %d: %s\n", migration.Version, migration.Name)
	}

	return nil
}

// MigrateDown rolls back the last migration
func (mm *MigrationManager) MigrateDown(ctx context.Context, migrationsDir string, steps int) error {
	if err := mm.InitializeMigrationTable(ctx); err != nil {
		return err
	}

	migrations, err := mm.LoadMigrations(migrationsDir)
	if err != nil {
		return err
	}

	applied, err := mm.GetAppliedMigrations(ctx)
	if err != nil {
		return err
	}

	if len(applied) == 0 {
		return fmt.Errorf("no migrations to rollback")
	}

	// Get the last applied migrations
	var toRollback []*MigrationHistory
	for i := len(applied) - 1; i >= 0 && steps > 0; i-- {
		toRollback = append(toRollback, applied[i])
		steps--
	}

	for _, history := range toRollback {
		// Find migration
		var migration *Migration
		for _, m := range migrations {
			if m.Version == history.Version {
				migration = m
				break
			}
		}

		if migration == nil {
			return fmt.Errorf("migration %d not found", history.Version)
		}

		if migration.DownSQL == "" {
			return fmt.Errorf("migration %d has no down SQL", history.Version)
		}

		// Begin transaction
		tx, err := mm.db.BeginTx(ctx, nil)
		if err != nil {
			return fmt.Errorf("failed to begin transaction: %w", err)
		}

		// Execute rollback
		if _, err := tx.ExecContext(ctx, migration.DownSQL); err != nil {
			tx.Rollback()
			return fmt.Errorf("failed to rollback migration %d: %w", history.Version, err)
		}

		// Remove from history
		if _, err := tx.ExecContext(ctx,
			`DELETE FROM schema_migrations WHERE version = $1`, history.Version); err != nil {
			tx.Rollback()
			return fmt.Errorf("failed to remove migration %d from history: %w", history.Version, err)
		}

		// Commit transaction
		if err := tx.Commit(); err != nil {
			return fmt.Errorf("failed to commit rollback of migration %d: %w", history.Version, err)
		}

		fmt.Printf("Rolled back migration %d: %s\n", history.Version, history.Name)
	}

	return nil
}

// GetMigrationStatus returns the current migration status
func (mm *MigrationManager) GetMigrationStatus(ctx context.Context, migrationsDir string) (map[int]string, error) {
	if err := mm.InitializeMigrationTable(ctx); err != nil {
		return nil, err
	}

	migrations, err := mm.LoadMigrations(migrationsDir)
	if err != nil {
		return nil, err
	}

	applied, err := mm.GetAppliedMigrations(ctx)
	if err != nil {
		return nil, err
	}

	status := make(map[int]string)
	appliedVersions := make(map[int]bool)
	for _, h := range applied {
		appliedVersions[h.Version] = true
	}

	for _, migration := range migrations {
		if appliedVersions[migration.Version] {
			status[migration.Version] = "applied"
		} else {
			status[migration.Version] = "pending"
		}
	}

	return status, nil
}

// ValidateMigrations checks for any inconsistencies in migrations
func (mm *MigrationManager) ValidateMigrations(ctx context.Context, migrationsDir string) error {
	migrations, err := mm.LoadMigrations(migrationsDir)
	if err != nil {
		return err
	}

	applied, err := mm.GetAppliedMigrations(ctx)
	if err != nil {
		return err
	}

	appliedVersions := make(map[int]*MigrationHistory)
	for _, h := range applied {
		appliedVersions[h.Version] = h
	}

	for _, migration := range migrations {
		if history, exists := appliedVersions[migration.Version]; exists {
			// Verify checksum
			if history.Checksum != migration.Checksum {
				return fmt.Errorf("migration %d checksum mismatch: expected %s, got %s",
					migration.Version, migration.Checksum, history.Checksum)
			}
		}
	}

	return nil
}
