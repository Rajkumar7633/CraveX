# Zomato Clone Backend - Go Microservices

## Architecture Overview

This backend uses a microservices architecture with the following services:

### Services
1. **Auth Service** - Authentication, authorization, user management
2. **Restaurant Service** - Restaurant management, menu, inventory
3. **Order Service** - Order processing, tracking, management
4. **Rider Service** - Rider management, delivery coordination
5. **Payment Service** - Payment processing, wallet, settlements
6. **Notification Service** - Push notifications, SMS, email
7. **Analytics Service** - Business intelligence, reporting
8. **Admin Service** - Admin operations, content management

### Infrastructure
- **API Gateway** - Kong/Nginx for routing and load balancing
- **Service Discovery** - Consul/Eureka for service registration
- **Message Broker** - Kafka for event streaming
- **Cache** - Redis for caching and session management
- **Database** - PostgreSQL for relational data
- **Object Storage** - AWS S3 for file storage
- **Search** - Elasticsearch for search functionality

## Technology Stack

### Core
- **Language**: Go 1.21+
- **Framework**: Gin/Echo for HTTP servers
- **ORM**: GORM for database operations
- **Database**: PostgreSQL 14+
- **Cache**: Redis 7+
- **Message Broker**: Apache Kafka 3.5+
- **Object Storage**: AWS S3

### External Services
- **Authentication**: Firebase Auth
- **SMS**: MSG91/Twilio
- **Push Notifications**: Firebase Cloud Messaging
- **Payments**: Razorpay/Stripe
- **Maps**: Google Maps API
- **Email**: SendGrid/AWS SES

### DevOps
- **Containerization**: Docker
- **Orchestration**: Kubernetes
- **CI/CD**: GitHub Actions
- **Monitoring**: Prometheus + Grafana
- **Logging**: ELK Stack
- **Tracing**: Jaeger

## Service Communication

### Synchronous Communication
- REST API via HTTP/HTTPS
- gRPC for internal service-to-service communication
- Protocol Buffers for serialization

### Asynchronous Communication
- Kafka for event-driven architecture
- Event topics: orders, payments, notifications, rider_updates

## Database Schema

### Main Database (PostgreSQL)
- users
- restaurants
- menu_items
- orders
- order_items
- riders
- payments
- addresses
- reviews
- coupons
- notifications

### Cache (Redis)
- User sessions
- Restaurant availability
- Order status cache
- Rider location cache
- Rate limiting

## API Design

### RESTful Endpoints
- Versioned APIs: `/api/v1/`
- JWT authentication
- Rate limiting
- Request validation
- Standard response format

### WebSocket Endpoints
- `/ws/orders/{order_id}` - Order tracking
- `/ws/rider/{rider_id}` - Rider location updates
- `/ws/chat/{order_id}` - In-app chat

## Security

### Authentication
- JWT tokens with refresh tokens
- OAuth 2.0 for social login
- Phone OTP verification
- 2FA for admin accounts

### Authorization
- Role-based access control (RBAC)
- API key authentication for external services
- IP whitelisting for admin operations

### Data Security
- Encryption at rest (AES-256)
- TLS 1.3 for data in transit
- PCI DSS compliance for payments
- GDPR compliance for user data

## Deployment

### Development
- Docker Compose for local development
- Hot reload with air
- Mock services for external dependencies

### Production
- Kubernetes cluster
- Horizontal Pod Autoscaling
- Circuit breakers
- Retry mechanisms
- Rate limiting

## Monitoring

### Metrics
- Request rate, latency, error rate
- Database connection pool metrics
- Cache hit/miss ratio
- Kafka consumer lag
- Custom business metrics

### Logging
- Structured logging with JSON
- Log levels: DEBUG, INFO, WARN, ERROR
- Correlation IDs for request tracing
- Sensitive data masking

### Alerting
- Service health checks
- Error rate thresholds
- Database connection failures
- Kafka consumer lag alerts
- Payment gateway failures

## Getting Started

### Prerequisites
- Go 1.21+
- Docker & Docker Compose
- PostgreSQL 14+
- Redis 7+
- Kafka 3.5+

### Setup
1. Clone the repository
2. Copy `.env.example` to `.env`
3. Configure environment variables
4. Run `docker-compose up -d` for infrastructure
5. Run `make build` to build services
6. Run `make run` to start all services

### Development
```bash
# Run specific service
go run cmd/auth-service/main.go

# Run tests
go test ./...

# Generate mocks
go generate ./...
```

## Service Port Allocation

- Auth Service: 8001
- Restaurant Service: 8002
- Order Service: 8003
- Rider Service: 8004
- Payment Service: 8005
- Notification Service: 8006
- Analytics Service: 8007
- Admin Service: 8008
- API Gateway: 8080
