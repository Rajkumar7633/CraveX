package logger

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"github.com/google/uuid"
)

type LogLevel string

const (
	LogLevelDebug LogLevel = "debug"
	LogLevelInfo  LogLevel = "info"
	LogLevelWarn  LogLevel = "warn"
	LogLevelError LogLevel = "error"
	LogLevelFatal LogLevel = "fatal"
)

type LogEntry struct {
	Timestamp  time.Time              `json:"timestamp"`
	Level      LogLevel               `json:"level"`
	Message    string                 `json:"message"`
	Service    string                 `json:"service"`
	RequestID  string                 `json:"request_id,omitempty"`
	UserID     string                 `json:"user_id,omitempty"`
	Error      string                 `json:"error,omitempty"`
	StackTrace string                 `json:"stack_trace,omitempty"`
	Duration   time.Duration          `json:"duration,omitempty"`
	Metadata   map[string]interface{} `json:"metadata,omitempty"`
}

type Logger struct {
	service      string
	level        LogLevel
	outputs      []LogOutput
	requestIDKey contextKey
	userIDKey    contextKey
}

type contextKey string

type LogOutput interface {
	Write(entry LogEntry) error
	Close() error
}

// ConsoleOutput writes logs to console
type ConsoleOutput struct {
	logger *log.Logger
}

func NewConsoleOutput() *ConsoleOutput {
	return &ConsoleOutput{
		logger: log.New(os.Stdout, "", 0),
	}
}

func (co *ConsoleOutput) Write(entry LogEntry) error {
	message := fmt.Sprintf("[%s] [%s] [%s] %s",
		entry.Timestamp.Format("2006-01-02 15:04:05"),
		entry.Level,
		entry.Service,
		entry.Message,
	)

	if entry.RequestID != "" {
		message += fmt.Sprintf(" [req:%s]", entry.RequestID)
	}
	if entry.UserID != "" {
		message += fmt.Sprintf(" [user:%s]", entry.UserID)
	}
	if entry.Error != "" {
		message += fmt.Sprintf(" error=%s", entry.Error)
	}
	if entry.Duration > 0 {
		message += fmt.Sprintf(" duration=%s", entry.Duration)
	}

	co.logger.Println(message)
	return nil
}

func (co *ConsoleOutput) Close() error {
	return nil
}

// FileOutput writes logs to file
type FileOutput struct {
	file   *os.File
	logger *log.Logger
}

func NewFileOutput(filename string) (*FileOutput, error) {
	file, err := os.OpenFile(filename, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return nil, err
	}

	return &FileOutput{
		file:   file,
		logger: log.New(file, "", 0),
	}, nil
}

func (fo *FileOutput) Write(entry LogEntry) error {
	message := fmt.Sprintf("[%s] [%s] [%s] %s",
		entry.Timestamp.Format("2006-01-02 15:04:05"),
		entry.Level,
		entry.Service,
		entry.Message,
	)

	if entry.RequestID != "" {
		message += fmt.Sprintf(" [req:%s]", entry.RequestID)
	}
	if entry.UserID != "" {
		message += fmt.Sprintf(" [user:%s]", entry.UserID)
	}
	if entry.Error != "" {
		message += fmt.Sprintf(" error=%s", entry.Error)
	}
	if entry.Duration > 0 {
		message += fmt.Sprintf(" duration=%s", entry.Duration)
	}

	fo.logger.Println(message)
	return nil
}

func (fo *FileOutput) Close() error {
	return fo.file.Close()
}

func NewLogger(service string, level LogLevel, outputs ...LogOutput) *Logger {
	if len(outputs) == 0 {
		outputs = []LogOutput{NewConsoleOutput()}
	}

	return &Logger{
		service:      service,
		level:        level,
		outputs:      outputs,
		requestIDKey: contextKey("request_id"),
		userIDKey:    contextKey("user_id"),
	}
}

func (l *Logger) Debug(ctx context.Context, message string, metadata map[string]interface{}) {
	l.log(ctx, LogLevelDebug, message, nil, 0, metadata)
}

func (l *Logger) Info(ctx context.Context, message string, metadata map[string]interface{}) {
	l.log(ctx, LogLevelInfo, message, nil, 0, metadata)
}

func (l *Logger) Warn(ctx context.Context, message string, metadata map[string]interface{}) {
	l.log(ctx, LogLevelWarn, message, nil, 0, metadata)
}

func (l *Logger) Error(ctx context.Context, message string, err error, metadata map[string]interface{}) {
	l.log(ctx, LogLevelError, message, err, 0, metadata)
}

func (l *Logger) Fatal(ctx context.Context, message string, err error, metadata map[string]interface{}) {
	l.log(ctx, LogLevelFatal, message, err, 0, metadata)
	os.Exit(1)
}

func (l *Logger) WithRequestID(ctx context.Context, requestID string) context.Context {
	return context.WithValue(ctx, l.requestIDKey, requestID)
}

func (l *Logger) WithUserID(ctx context.Context, userID string) context.Context {
	return context.WithValue(ctx, l.userIDKey, userID)
}

func (l *Logger) WithDuration(ctx context.Context, duration time.Duration) context.Context {
	return context.WithValue(ctx, contextKey("duration"), duration)
}

func (l *Logger) log(ctx context.Context, level LogLevel, message string, err error, duration time.Duration, metadata map[string]interface{}) {
	// Check log level
	if !l.shouldLog(level) {
		return
	}

	entry := LogEntry{
		Timestamp: time.Now(),
		Level:     level,
		Message:   message,
		Service:   l.service,
		Metadata:  metadata,
		Duration:  duration,
	}

	// Extract context values
	if ctx != nil {
		if requestID, ok := ctx.Value(l.requestIDKey).(string); ok {
			entry.RequestID = requestID
		}
		if userID, ok := ctx.Value(l.userIDKey).(string); ok {
			entry.UserID = userID
		}
		if d, ok := ctx.Value(contextKey("duration")).(time.Duration); ok {
			entry.Duration = d
		}
	}

	// Add error details
	if err != nil {
		entry.Error = err.Error()
	}

	// Write to all outputs
	for _, output := range l.outputs {
		if writeErr := output.Write(entry); writeErr != nil {
			// Fallback to console if output fails
			fmt.Printf("Failed to write log: %v\n", writeErr)
		}
	}
}

func (l *Logger) shouldLog(level LogLevel) bool {
	levels := map[LogLevel]int{
		LogLevelDebug: 0,
		LogLevelInfo:  1,
		LogLevelWarn:  2,
		LogLevelError: 3,
		LogLevelFatal: 4,
	}

	currentLevel, exists := levels[l.level]
	if !exists {
		currentLevel = 1 // Default to info
	}

	requestedLevel, exists := levels[level]
	if !exists {
		return true
	}

	return requestedLevel >= currentLevel
}

func (l *Logger) Close() error {
	for _, output := range l.outputs {
		if err := output.Close(); err != nil {
			return err
		}
	}
	return nil
}

// Helper function to generate request ID
func GenerateRequestID() string {
	return uuid.New().String()
}

// Middleware helper for logging HTTP requests
type LogMiddleware struct {
	logger *Logger
}

func NewLogMiddleware(logger *Logger) *LogMiddleware {
	return &LogMiddleware{logger: logger}
}

func (lm *LogMiddleware) LogRequest(ctx context.Context, method, path string, statusCode int, duration time.Duration) {
	metadata := map[string]interface{}{
		"method":      method,
		"path":        path,
		"status_code": statusCode,
	}

	level := LogLevelInfo
	if statusCode >= 500 {
		level = LogLevelError
	} else if statusCode >= 400 {
		level = LogLevelWarn
	}

	message := fmt.Sprintf("%s %s - %d", method, path, statusCode)
	lm.logger.log(ctx, level, message, nil, duration, metadata)
}
