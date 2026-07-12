package monitoring

import (
	"context"
	"fmt"
	"os"
	"runtime"
	"time"

	"github.com/getsentry/sentry-go"
	sentrygin "github.com/getsentry/sentry-go/gin"
	"github.com/gin-gonic/gin"
)

// SentryIntegration handles error tracking and performance monitoring
// - Error tracking for both Flutter apps and backend
// - Alert on error rate spike
// - Performance monitoring
// - User context tracking
type SentryIntegration struct {
	enabled bool
	dsn     string
	env     string
}

func NewSentryIntegration(dsn, environment string) (*SentryIntegration, error) {
	if dsn == "" {
		return &SentryIntegration{enabled: false}, nil
	}

	err := sentry.Init(sentry.ClientOptions{
		Dsn:              dsn,
		Environment:      environment,
		Release:          os.Getenv("APP_VERSION"),
		TracesSampleRate: 1.0,
		SampleRate:       1.0,
		BeforeSend: func(event *sentry.Event, hint *sentry.EventHint) *sentry.Event {
			// Filter out sensitive data
			if event.Request != nil {
				// Remove sensitive headers
				if event.Request.Headers != nil {
					delete(event.Request.Headers, "Authorization")
					delete(event.Request.Headers, "Cookie")
				}
			}
			return event
		},
	})

	if err != nil {
		return nil, fmt.Errorf("failed to initialize Sentry: %w", err)
	}

	return &SentryIntegration{
		enabled: true,
		dsn:     dsn,
		env:     environment,
	}, nil
}

// CaptureException captures an exception and sends it to Sentry
func (si *SentryIntegration) CaptureException(ctx context.Context, err error, tags map[string]string, extra map[string]interface{}) {
	if !si.enabled {
		return
	}

	hub := sentry.GetHubFromContext(ctx)
	if hub == nil {
		hub = sentry.CurrentHub()
	}

	scope := hub.Scope()
	for k, v := range tags {
		scope.SetTag(k, v)
	}
	for k, v := range extra {
		scope.SetExtra(k, v)
	}

	hub.CaptureException(err)
}

// CaptureMessage captures a message and sends it to Sentry
func (si *SentryIntegration) CaptureMessage(ctx context.Context, message string, level sentry.Level) {
	if !si.enabled {
		return
	}

	hub := sentry.GetHubFromContext(ctx)
	if hub == nil {
		hub = sentry.CurrentHub()
	}

	hub.CaptureMessage(message, level)
}

// CaptureUserFeedback captures user feedback for errors
func (si *SentryIntegration) CaptureUserFeedback(ctx context.Context, userEmail, message string) {
	if !si.enabled {
		return
	}

	hub := sentry.GetHubFromContext(ctx)
	if hub == nil {
		hub = sentry.CurrentHub()
	}

	user := sentry.User{
		Email: userEmail,
	}

	hub.ConfigureScope(func(scope *sentry.Scope) {
		scope.SetUser(user)
	})

	hub.CaptureMessage(message, sentry.LevelInfo)
}

// SetUserContext sets the user context for error tracking
func (si *SentryIntegration) SetUserContext(ctx context.Context, userID, email string) {
	if !si.enabled {
		return
	}

	hub := sentry.GetHubFromContext(ctx)
	if hub == nil {
		hub = sentry.CurrentHub()
	}

	user := sentry.User{
		ID:    userID,
		Email: email,
	}

	hub.ConfigureScope(func(scope *sentry.Scope) {
		scope.SetUser(user)
	})
}

// SetTransactionContext sets transaction context for performance monitoring
func (si *SentryIntegration) SetTransactionContext(ctx context.Context, operation string) {
	if !si.enabled {
		return
	}

	hub := sentry.GetHubFromContext(ctx)
	if hub == nil {
		hub = sentry.CurrentHub()
	}

	transaction := sentry.StartTransaction(ctx, operation)
	hub.Scope().SetTransaction(transaction)

	defer transaction.Finish()
}

// AddBreadcrumb adds a breadcrumb for better error context
func (si *SentryIntegration) AddBreadcrumb(ctx context.Context, category, message string, level sentry.Level) {
	if !si.enabled {
		return
	}

	hub := sentry.GetHubFromContext(ctx)
	if hub == nil {
		hub = sentry.CurrentHub()
	}

	breadcrumb := &sentry.Breadcrumb{
		Category: category,
		Message:  message,
		Level:    level,
		Timestamp: time.Now(),
	}

	hub.AddBreadcrumb(breadcrumb)
}

// GetSystemInfo returns system information for error context
func GetSystemInfo() map[string]interface{} {
	return map[string]interface{}{
		"os":           runtime.GOOS,
		"arch":         runtime.GOARCH,
		"go_version":   runtime.Version(),
		"num_cpu":      runtime.NumCPU(),
		"goroutines":   runtime.NumGoroutine(),
		"memory_stats": getMemoryStats(),
	}
}

func getMemoryStats() map[string]interface{} {
	var m runtime.MemStats
	runtime.ReadMemStats(&m)

	return map[string]interface{}{
		"alloc":       m.Alloc,
		"total_alloc": m.TotalAlloc,
		"sys":         m.Sys,
		"num_gc":      m.NumGC,
		"heap_alloc":  m.HeapAlloc,
		"heap_sys":    m.HeapSys,
	}
}

// GinMiddleware returns Gin middleware for Sentry integration
func (si *SentryIntegration) GinMiddleware() gin.HandlerFunc {
	if !si.enabled {
		return func(c *gin.Context) {
			c.Next()
		}
	}

	return sentrygin.New(sentrygin.Options{
		Repanic:         true,
		WaitForDelivery: false,
		Timeout:         5 * time.Second,
	})
}

// Flush ensures all events are sent before shutdown
func (si *SentryIntegration) Flush(timeout time.Duration) bool {
	if !si.enabled {
		return true
	}

	return sentry.Flush(timeout)
}

// PerformanceMonitor tracks performance metrics
type PerformanceMonitor struct {
	sentry *SentryIntegration
}

func NewPerformanceMonitor(sentry *SentryIntegration) *PerformanceMonitor {
	return &PerformanceMonitor{
		sentry: sentry,
	}
}

// TrackOperation tracks an operation's performance
func (pm *PerformanceMonitor) TrackOperation(ctx context.Context, operation string, fn func() error) error {
	if !pm.sentry.enabled {
		return fn()
	}

	transaction := sentry.StartTransaction(ctx, operation)
	defer transaction.Finish()

	startTime := time.Now()
	err := fn()
	duration := time.Since(startTime)

	transaction.SetData("duration_ms", duration.Milliseconds())

	if err != nil {
		transaction.SetStatus(sentry.SpanStatusInternalError)
		transaction.SetData("error", err.Error())
	} else {
		transaction.SetStatus(sentry.SpanStatusOK)
	}

	return err
}

// TrackDatabaseQuery tracks database query performance
func (pm *PerformanceMonitor) TrackDatabaseQuery(ctx context.Context, query string, fn func() error) error {
	if !pm.sentry.enabled {
		return fn()
	}

	transaction := sentry.StartTransaction(ctx, "db.query")
	defer transaction.Finish()

	transaction.SetData("query", query)
	transaction.SetData("db.system", "postgresql")

	startTime := time.Now()
	err := fn()
	duration := time.Since(startTime)

	transaction.SetData("duration_ms", duration.Milliseconds())

	if err != nil {
		transaction.SetStatus(sentry.SpanStatusInternalError)
		transaction.SetData("error", err.Error())
	} else {
		transaction.SetStatus(sentry.SpanStatusOK)
	}

	return err
}

// TrackAPICall tracks external API call performance
func (pm *PerformanceMonitor) TrackAPICall(ctx context.Context, service, endpoint string, fn func() error) error {
	if !pm.sentry.enabled {
		return fn()
	}

	transaction := sentry.StartTransaction(ctx, "http.client")
	defer transaction.Finish()

	transaction.SetData("service", service)
	transaction.SetData("endpoint", endpoint)

	startTime := time.Now()
	err := fn()
	duration := time.Since(startTime)

	transaction.SetData("duration_ms", duration.Milliseconds())

	if err != nil {
		transaction.SetStatus(sentry.SpanStatusInternalError)
		transaction.SetData("error", err.Error())
	} else {
		transaction.SetStatus(sentry.SpanStatusOK)
	}

	return err
}
