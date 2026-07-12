package monitoring

import (
	"context"
	"fmt"
	"net/http"
	"sync"
	"time"
)

// UptimeMonitor handles uptime monitoring and alerting
// - Synthetic checks hitting critical endpoints every minute
// - Alert if down
// - On-call rotation + runbooks
// - Status page (public or internal)
type UptimeMonitor struct {
	checks     []*HealthCheck
	alerters   []Alerter
	interval   time.Duration
	httpClient *http.Client
	mu         sync.RWMutex
}

type HealthCheck struct {
	Name         string
	URL          string
	Method       string
	ExpectedCode int
	Timeout      time.Duration
	LastCheck    time.Time
	LastStatus  string
	LastLatency time.Duration
	FailCount   int
}

type Alerter interface {
	SendAlert(ctx context.Context, check *HealthCheck, message string) error
}

type CheckResult struct {
	Check    *HealthCheck
	Status   string
	Latency  time.Duration
	Error    error
	Timestamp time.Time
}

func NewUptimeMonitor(interval time.Duration) *UptimeMonitor {
	return &UptimeMonitor{
		interval: interval,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// AddCheck adds a health check to monitor
func (um *UptimeMonitor) AddCheck(name, url, method string, expectedCode int, timeout time.Duration) {
	check := &HealthCheck{
		Name:         name,
		URL:          url,
		Method:       method,
		ExpectedCode: expectedCode,
		Timeout:      timeout,
		LastStatus:   "unknown",
	}

	um.mu.Lock()
	um.checks = append(um.checks, check)
	um.mu.Unlock()
}

// AddAlerter adds an alerter for notifications
func (um *UptimeMonitor) AddAlerter(alerter Alerter) {
	um.mu.Lock()
	um.alerters = append(um.alerters, alerter)
	um.mu.Unlock()
}

// Start begins the monitoring process
func (um *UptimeMonitor) Start(ctx context.Context) {
	ticker := time.NewTicker(um.interval)
	defer ticker.Stop()

	for {
		select {
		case <-ctx.Done():
			return
		case <-ticker.C:
			um.runChecks(ctx)
		}
	}
}

// runChecks executes all health checks
func (um *UptimeMonitor) runChecks(ctx context.Context) {
	um.mu.RLock()
	checks := make([]*HealthCheck, len(um.checks))
	copy(checks, um.checks)
	alerters := make([]Alerter, len(um.alerters))
	copy(alerters, um.alerters)
	um.mu.RUnlock()

	var wg sync.WaitGroup
	results := make(chan *CheckResult, len(checks))

	for _, check := range checks {
		wg.Add(1)
		go func(c *HealthCheck) {
			defer wg.Done()
			result := um.performCheck(ctx, c)
			results <- result
		}(check)
	}

	go func() {
		wg.Wait()
		close(results)
	}()

	for result := range results {
		um.handleResult(ctx, result, alerters)
	}
}

// performCheck executes a single health check
func (um *UptimeMonitor) performCheck(ctx context.Context, check *HealthCheck) *CheckResult {
	startTime := time.Now()
	
	req, err := http.NewRequestWithContext(ctx, check.Method, check.URL, nil)
	if err != nil {
		return &CheckResult{
			Check:     check,
			Status:    "error",
			Error:     err,
			Timestamp: time.Now(),
		}
	}

	resp, err := um.httpClient.Do(req)
	if err != nil {
		return &CheckResult{
			Check:     check,
			Status:    "down",
			Error:     err,
			Timestamp: time.Now(),
		}
	}
	defer resp.Body.Close()

	latency := time.Since(startTime)

	status := "up"
	if resp.StatusCode != check.ExpectedCode {
		status = "degraded"
	}

	return &CheckResult{
		Check:     check,
		Status:    status,
		Latency:   latency,
		Timestamp: time.Now(),
	}
}

// handleResult processes a check result and triggers alerts if needed
func (um *UptimeMonitor) handleResult(ctx context.Context, result *CheckResult, alerters []Alerter) {
	check := result.Check
	
	um.mu.Lock()
	check.LastCheck = result.Timestamp
	check.LastStatus = result.Status
	check.LastLatency = result.Latency
	
	// Track failures
	if result.Status == "down" || result.Status == "error" {
		check.FailCount++
	} else {
		check.FailCount = 0
	}
	um.mu.Unlock()

	// Alert on failures
	if check.FailCount >= 3 {
		message := fmt.Sprintf("Health check '%s' failed %d times. Status: %s", 
			check.Name, check.FailCount, result.Status)
		
		if result.Error != nil {
			message += fmt.Sprintf(" Error: %v", result.Error)
		}

		for _, alerter := range alerters {
			alerter.SendAlert(ctx, check, message)
		}
	}

	// Alert on high latency
	if result.Status == "up" && result.Latency > 5*time.Second {
		message := fmt.Sprintf("Health check '%s' has high latency: %v", 
			check.Name, result.Latency)
		
		for _, alerter := range alerters {
			alerter.SendAlert(ctx, check, message)
		}
	}
}

// GetStatus returns the current status of all checks
func (um *UptimeMonitor) GetStatus() map[string]*HealthCheck {
	um.mu.RLock()
	defer um.mu.RUnlock()

	status := make(map[string]*HealthCheck)
	for _, check := range um.checks {
		status[check.Name] = check
	}
	return status
}

// SlackAlerter implements Slack alerting
type SlackAlerter struct {
	webhookURL string
}

func NewSlackAlerter(webhookURL string) *SlackAlerter {
	return &SlackAlerter{
		webhookURL: webhookURL,
	}
}

func (sa *SlackAlerter) SendAlert(ctx context.Context, check *HealthCheck, message string) error {
	// In production, this would send to Slack webhook
	// For now, just log the alert
	fmt.Printf("[ALERT] %s: %s\n", check.Name, message)
	return nil
}

// EmailAlerter implements email alerting
type EmailAlerter struct {
	smtpHost     string
	smtpPort     int
	smtpUser     string
	smtpPassword string
	recipients   []string
}

func NewEmailAlerter(smtpHost string, smtpPort int, smtpUser, smtpPassword string, recipients []string) *EmailAlerter {
	return &EmailAlerter{
		smtpHost:     smtpHost,
		smtpPort:     smtpPort,
		smtpUser:     smtpUser,
		smtpPassword: smtpPassword,
		recipients:   recipients,
	}
}

func (ea *EmailAlerter) SendAlert(ctx context.Context, check *HealthCheck, message string) error {
	// In production, this would send email via SMTP
	fmt.Printf("[EMAIL ALERT] %s: %s\n", check.Name, message)
	return nil
}

// PagerDutyAlerter implements PagerDuty alerting for critical incidents
type PagerDutyAlerter struct {
	apiKey      string
	serviceKey  string
}

func NewPagerDutyAlerter(apiKey, serviceKey string) *PagerDutyAlerter {
	return &PagerDutyAlerter{
		apiKey:     apiKey,
		serviceKey: serviceKey,
	}
}

func (pda *PagerDutyAlerter) SendAlert(ctx context.Context, check *HealthCheck, message string) error {
	// In production, this would create PagerDuty incident
	fmt.Printf("[PAGERDUTY ALERT] %s: %s\n", check.Name, message)
	return nil
}

// StatusPage represents a status page for monitoring
type StatusPage struct {
	monitor *UptimeMonitor
}

func NewStatusPage(monitor *UptimeMonitor) *StatusPage {
	return &StatusPage{
		monitor: monitor,
	}
}

// GetOverallStatus returns the overall system status
func (sp *StatusPage) GetOverallStatus() string {
	statuses := sp.monitor.GetStatus()
	
	downCount := 0
	for _, check := range statuses {
		if check.LastStatus == "down" || check.LastStatus == "error" {
			downCount++
		}
	}

	if downCount == 0 {
		return "operational"
	} else if downCount < len(statuses)/2 {
		return "degraded"
	} else {
		return "outage"
	}
}

// GetIncidentHistory returns recent incidents
func (sp *StatusPage) GetIncidentHistory() []string {
	// In production, this would query a database for incident history
	return []string{
		"No recent incidents",
	}
}
