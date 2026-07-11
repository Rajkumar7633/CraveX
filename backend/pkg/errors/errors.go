package errors

import (
	"fmt"
	"net/http"
)

// Error types for different categories of errors
type ErrorType string

const (
	ErrorTypeValidation    ErrorType = "validation"
	ErrorTypeNotFound      ErrorType = "not_found"
	ErrorTypeUnauthorized  ErrorType = "unauthorized"
	ErrorTypeForbidden     ErrorType = "forbidden"
	ErrorTypeConflict      ErrorType = "conflict"
	ErrorTypeInternal      ErrorType = "internal"
	ErrorTypeExternal      ErrorType = "external"
	ErrorTypeRateLimit     ErrorType = "rate_limit"
	ErrorTypePayment       ErrorType = "payment"
	ErrorTypeDatabase      ErrorType = "database"
	ErrorTypeCache         ErrorType = "cache"
	ErrorTypeMessaging     ErrorType = "messaging"
)

// AppError represents a structured application error
type AppError struct {
	Type       ErrorType              `json:"type"`
	Message    string                 `json:"message"`
	StatusCode int                    `json:"status_code"`
	Details    map[string]interface{} `json:"details,omitempty"`
	Cause      error                  `json:"-"`
	RequestID  string                 `json:"request_id,omitempty"`
}

func (e *AppError) Error() string {
	if e.Cause != nil {
		return fmt.Sprintf("%s: %v", e.Message, e.Cause)
	}
	return e.Message
}

func (e *AppError) Unwrap() error {
	return e.Cause
}

// Error constructors
func NewValidationError(message string, details map[string]interface{}) *AppError {
	return &AppError{
		Type:       ErrorTypeValidation,
		Message:    message,
		StatusCode: http.StatusBadRequest,
		Details:    details,
	}
}

func NewNotFoundError(resource string, identifier string) *AppError {
	return &AppError{
		Type:       ErrorTypeNotFound,
		Message:    fmt.Sprintf("%s not found: %s", resource, identifier),
		StatusCode: http.StatusNotFound,
		Details: map[string]interface{}{
			"resource":   resource,
			"identifier": identifier,
		},
	}
}

func NewUnauthorizedError(message string) *AppError {
	return &AppError{
		Type:       ErrorTypeUnauthorized,
		Message:    message,
		StatusCode: http.StatusUnauthorized,
	}
}

func NewForbiddenError(message string) *AppError {
	return &AppError{
		Type:       ErrorTypeForbidden,
		Message:    message,
		StatusCode: http.StatusForbidden,
	}
}

func NewConflictError(message string, details map[string]interface{}) *AppError {
	return &AppError{
		Type:       ErrorTypeConflict,
		Message:    message,
		StatusCode: http.StatusConflict,
		Details:    details,
	}
}

func NewInternalError(message string, cause error) *AppError {
	return &AppError{
		Type:       ErrorTypeInternal,
		Message:    message,
		StatusCode: http.StatusInternalServerError,
		Cause:      cause,
	}
}

func NewExternalError(service string, message string, cause error) *AppError {
	return &AppError{
		Type:       ErrorTypeExternal,
		Message:    fmt.Sprintf("%s error: %s", service, message),
		StatusCode: http.StatusBadGateway,
		Cause:      cause,
		Details: map[string]interface{}{
			"service": service,
		},
	}
}

func NewRateLimitError(message string) *AppError {
	return &AppError{
		Type:       ErrorTypeRateLimit,
		Message:    message,
		StatusCode: http.StatusTooManyRequests,
	}
}

func NewPaymentError(message string, details map[string]interface{}) *AppError {
	return &AppError{
		Type:       ErrorTypePayment,
		Message:    message,
		StatusCode: http.StatusPaymentRequired,
		Details:    details,
	}
}

func NewDatabaseError(message string, cause error) *AppError {
	return &AppError{
		Type:       ErrorTypeDatabase,
		Message:    message,
		StatusCode: http.StatusInternalServerError,
		Cause:      cause,
	}
}

func NewCacheError(message string, cause error) *AppError {
	return &AppError{
		Type:       ErrorTypeCache,
		Message:    message,
		StatusCode: http.StatusInternalServerError,
		Cause:      cause,
	}
}

func NewMessagingError(message string, cause error) *AppError {
	return &AppError{
		Type:       ErrorTypeMessaging,
		Message:    message,
		StatusCode: http.StatusInternalServerError,
		Cause:      cause,
	}
}

// WrapError wraps an existing error with additional context
func WrapError(err error, message string) *AppError {
	if appErr, ok := err.(*AppError); ok {
		return &AppError{
			Type:       appErr.Type,
			Message:    fmt.Sprintf("%s: %s", message, appErr.Message),
			StatusCode: appErr.StatusCode,
			Details:    appErr.Details,
			Cause:      appErr,
		}
	}
	return &AppError{
		Type:       ErrorTypeInternal,
		Message:    message,
		StatusCode: http.StatusInternalServerError,
		Cause:      err,
	}
}

// IsAppError checks if an error is an AppError
func IsAppError(err error) bool {
	_, ok := err.(*AppError)
	return ok
}

// GetAppError converts an error to AppError if possible
func GetAppError(err error) *AppError {
	if appErr, ok := err.(*AppError); ok {
		return appErr
	}
	return NewInternalError("internal server error", err)
}
