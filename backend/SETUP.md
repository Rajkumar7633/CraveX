# Backend Setup Guide

## Prerequisites

- Go 1.21 or higher
- Docker and Docker Compose
- PostgreSQL 14+ (or use Docker)
- Redis 7+ (or use Docker)
- Kafka 3.5+ (or use Docker)

## Quick Start with Docker

### 1. Clone and Navigate
```bash
cd backend
```

### 2. Start Infrastructure
```bash
docker-compose up -d postgres redis kafka zookeeper
```

### 3. Initialize Database
```bash
# The database schema will be automatically applied via docker-compose
# Or manually apply it:
docker exec -it zomato-postgres psql -U postgres -d zomato_clone -f /docker-entrypoint-initdb.d/schema.sql
```

### 4. Setup Auth Service
```bash
cd cmd/auth-service

# Install dependencies
go mod download
go mod tidy

# Copy environment file
cp .env.example .env

# Update .env with your configuration
# DATABASE_URL=postgres://postgres:postgres@localhost:5432/zomato_clone?sslmode=disable
# JWT_SECRET=your-super-secret-jwt-key
# OTP_SECRET=your-otp-secret-key
# REDIS_URL=localhost:6379
# KAFKA_URL=localhost:9092
# PORT=8001

# Run the service
go run cmd/auth-service/main.go
```

### 5. Test Auth Service
```bash
# Health check
curl http://localhost:8001/health

# Register user
curl -X POST http://localhost:8001/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+919876543210",
    "email": "user@example.com",
    "password": "password123",
    "first_name": "John",
    "last_name": "Doe"
  }'

# Login
curl -X POST http://localhost:8001/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "phone_number": "+919876543210",
    "password": "password123"
  }'
```

## Manual Setup (Without Docker)

### 1. Install PostgreSQL
```bash
# macOS
brew install postgresql@14
brew services start postgresql@14

# Create database
createdb zomato_clone

# Apply schema
psql -d zomato_clone -f database/schema.sql
```

### 2. Install Redis
```bash
# macOS
brew install redis
brew services start redis
```

### 3. Install Kafka
```bash
# macOS
brew install kafka
brew services start kafka
```

### 4. Setup Go Environment
```bash
# Set GOPATH if not set
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Install Go dependencies
cd cmd/auth-service
go mod download
go mod tidy
```

### 5. Configure Environment
```bash
cp .env.example .env
# Edit .env with your local configuration
```

### 6. Run Services
```bash
# Auth Service
cd cmd/auth-service
go run main.go

# Restaurant Service (to be implemented)
cd cmd/restaurant-service
go run main.go

# Order Service (to be implemented)
cd cmd/order-service
go run main.go
```

## Service Architecture

### Current Services
- **Auth Service** (Port 8001): User authentication, JWT tokens, OTP verification

### Planned Services
- **Restaurant Service** (Port 8002): Restaurant management, menu, inventory
- **Order Service** (Port 8003): Order processing, tracking, management
- **Rider Service** (Port 8004): Rider management, delivery coordination
- **Payment Service** (Port 8005): Payment processing, wallet, settlements
- **Notification Service** (Port 8006): Push notifications, SMS, email
- **Analytics Service** (Port 8007): Business intelligence, reporting
- **Admin Service** (Port 8008): Admin operations, content management

### Infrastructure
- **API Gateway** (Port 8080): Kong for routing and load balancing
- **PostgreSQL** (Port 5432): Primary database
- **Redis** (Port 6379): Caching and session management
- **Kafka** (Port 9092): Event streaming

## Development Workflow

### Adding a New Service

1. Create service directory:
```bash
mkdir -p cmd/new-service/internal/{config,models,repository,services,handlers,middleware}
```

2. Initialize Go module:
```bash
cd cmd/new-service
go mod init github.com/zomato-clone/new-service
```

3. Add dependencies:
```bash
go get github.com/gin-gonic/gin
go get github.com/google/uuid
go get gorm.io/gorm
go get gorm.io/driver/postgres
# ... other dependencies
```

4. Create main.go, models, repositories, services, handlers

5. Add to docker-compose.yml

### Database Migrations

For schema changes:
1. Update `database/schema.sql`
2. Apply changes to database:
```bash
psql -d zomato_clone -f database/schema.sql
```

### Testing

```bash
# Run tests
go test ./...

# Run tests with coverage
go test -cover ./...

# Run specific test
go test ./internal/services -v
```

## Troubleshooting

### Import Errors
If you see import errors like "cannot find package", run:
```bash
go mod download
go mod tidy
```

### Database Connection Issues
- Ensure PostgreSQL is running
- Check DATABASE_URL in .env
- Verify database exists: `psql -l`

### Port Conflicts
- Change ports in .env files
- Check what's using the port: `lsof -i :8001`

### Docker Issues
- Restart Docker Desktop
- Remove volumes: `docker-compose down -v`
- Rebuild: `docker-compose build --no-cache`

## API Documentation

### Auth Service Endpoints

#### Public Routes
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - User login
- `POST /api/v1/auth/logout` - User logout
- `POST /api/v1/auth/refresh` - Refresh JWT token
- `POST /api/v1/auth/verify-otp` - Verify OTP
- `POST /api/v1/auth/send-otp` - Send OTP
- `POST /api/v1/auth/forgot-password` - Forgot password
- `POST /api/v1/auth/reset-password` - Reset password
- `POST /api/v1/auth/social-login` - Social login

#### Protected Routes (requires JWT)
- `GET /api/v1/auth/me` - Get current user
- `PUT /api/v1/auth/me` - Update profile
- `POST /api/v1/auth/change-password` - Change password
- `DELETE /api/v1/auth/me` - Delete account

## Next Steps

1. Implement Restaurant Service
2. Implement Order Service
3. Implement Rider Service
4. Implement Payment Service
5. Implement Notification Service
6. Set up API Gateway with Kong
7. Add monitoring and logging
8. Implement WebSocket for real-time updates
9. Add unit and integration tests
10. Deploy to production environment

## Production Deployment

### Environment Variables
Set these in production:
- Strong JWT_SECRET
- Strong OTP_SECRET
- Production DATABASE_URL
- Redis password
- Kafka security settings
- API keys for external services

### Security
- Enable HTTPS
- Use strong passwords
- Enable rate limiting
- Implement IP whitelisting
- Regular security audits

### Scaling
- Use Kubernetes for orchestration
- Enable horizontal pod autoscaling
- Use load balancers
- Implement circuit breakers
- Add monitoring and alerting
