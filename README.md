# CraveX — Enterprise Zomato Clone Suite

A production-grade, event-driven monorepo containing four Flutter applications and a scalable Go microservices backend backed by Kafka, Redis, and PostGIS.

---

## 1. Repository Structure

```
/zomato_clone
│   README.md               # Workspace documentation
│   melos.yaml              # Workspace definition
│   pubspec.yaml            # Monorepo dependencies
│
├── apps
│   ├── customer/           # Customer mobile app (iOS/Android)
│   ├── restaurant/         # Partner app for restaurants
│   ├── rider/              # Delivery rider app
│   └── admin/              # Admin dashboard
│
├── packages
│   ├── core/               # Shared models, constants, and network client
│   ├── theme/              # Shared design system, color palette, typography
│   ├── widgets/            # Reusable UI components
│   └── state/              # Shared Riverpod state models & auth providers
│
├── backend/                # Go Microservices
│   ├── cmd/
│   │   ├── auth-service/         # User auth, verification, and session service (Port 8001)
│   │   ├── restaurant-service/   # Restaurant profile, search, and menu catalog (Port 8002)
│   │   ├── order-service/        # Order booking, status flow, and ETA prediction (Port 8003)
│   │   ├── rider-service/        # Rider profiles, geo tracking, and earnings (Port 8004)
│   │   ├── payment-service/      # Transaction processing & wallet (Port 8005)
│   │   └── notification-service/ # Push, SMS, and transactional alert manager (Port 8006)
│   ├── database/                 # PostgreSQL PostGIS schema migration DDL
│   ├── pkg/                      # Shared helper utility packages
│   └── docker-compose.yml        # Orchestrated backend containers
│
└── infra/                  # Infrastructure configurations
```

---

## 2. Advanced Implemented Features

### Geospatial & Database Engine (PostGIS)
- ** delivery_zone geometry**: Stores polygon bounds (`ST_Contains`) to define service zones.
- ** location geography**: Tracks rider location (`POINT`) with GIST indices for spatial query optimization.
- **Geospatial Triggers**: Database-level triggers keep geography fields in sync on lat/long coordinate changes and dynamically allocate 5km bounding delivery zones to newly inserted restaurants.

### Event-Driven Order State Machine
- **Transition Engine**: Orchestrates order steps (`placed`, `restaurant_accepted`, `preparing`, `ready_for_pickup`, `rider_assigned`, `rider_arrived_restaurant`, `picked_up`, `rider_arrived_customer`, `delivered`, `cancelled`).
- **Kafka Integration**: Emits state transitions into the `order-events` Kafka topic.
- **Idempotency Keys**: Utilizes a unique constraint on history `event_id` keys to protect status endpoints against duplicate execution.

### Strict Checkout Pricing Formula
- **Fee Configuration**: Incorporates subtotal, flat packaging charges (₹0.99), and platform fees (₹0.50).
- **Peak Surge Surcharges**: Adds a 50% surge fee multiplier on delivery charges during peak lunch (12-3pm) and dinner (7-10pm) periods.
- **Tax/GST splits**: Calculates separate tax segments for food (5%) and service charges (18% on delivery/platform fees).
- **Coupon Rules**: Evaluates coupons (e.g. `CRAVEX50` offering 50% discount up to ₹5.00).

### Rider Matching & Assignment scoring
- **Geospatial Pooling**: Queries online active riders using PostGIS `ST_DWithin` geography distance queries.
- **Weighted scoring**: Ranks candidates using a scoring algorithm based on distance and rating:
  `score = w1 * (1 / distance) + w2 * rating`
- **15s Rejection Cascade**: Reverts orders to matching pools to trigger re-assignments if the assigned rider fails to accept within 15 seconds.

### ETA Prediction
- **State-Based Duration**: Estimates remaining durations by weighing current state and quantity buffers (+1m per item).
- **Active Recalculator**: Background worker recalculates ETA changes every 60 seconds and updates clients via Kafka.

### Scale & Performance Engineering (v3)
- **Grid-Based Spatial Restaurant Cache**: Implemented a caching mechanism grouping location-based nearby requests into ~1.1km geohash grid buckets using rounded coordinates, caching them in Redis with a 2-minute TTL.
- **Menu Write-Through Cache**: Integrates a 5-minute TTL caching layer for restaurant menus. Automatically invalidates cached entries immediately on item creation, updates, or deletions.
- **Database Scale Optimizations**: Added compound indexes for order history lookups (`idx_order_customer_created`) and partial index filters for active orders (`idx_order_status_restaurant`) and available items (`idx_menu_item_restaurant_available`) to prevent N+1 queries.
- **Flutter Image Cache**: Configured `CachedNetworkImage` inside `RestaurantCard` to cache assets on disk, prevent redundant network downloads, and optimize list view rendering.

---

## 3. Technology Stack

*   **Frontend**: Flutter 3.19+ (iOS/Android/Web), Dart, Riverpod
*   **Backend**: Go 1.25, Gin HTTP Framework, GORM
*   **Database**: PostgreSQL 14 (PostGIS enabled), Redis 7
*   **Messaging**: Kafka (Confluent Platform) & ZooKeeper
*   **Gateway**: Kong API Gateway

---

## 4. Getting Started

### Prerequisites
- Docker & Docker Compose
- Flutter SDK (3.19+)
- Dart

### 1. Launch Backend Services
Start the orchestrated Go microservices, database, caching, message brokers, and API gateway:
```bash
cd backend
docker compose build
docker compose up -d
```

### 2. Database & Schema Initialization
PostgreSQL tables, extensions, and spatial triggers are loaded via [schema.sql](file:///Users/apple/Desktop/zomato_clone/backend/database/schema.sql) during initial PostgreSQL container boot.
To run the Kong Gateway migrations:
```bash
docker compose run --rm api-gateway kong migrations bootstrap
docker compose restart api-gateway
```

### 3. Bootstrap Flutter Applications
From the workspace root, run Melos to fetch and link package dependencies:
```bash
dart pub global activate melos
melos bootstrap
```

### 4. Run Mobile Apps
For example, to run the customer mobile client:
```bash
cd apps/customer
flutter run
```

---

## 5. Network Port Mappings

| Service | Port | Endpoint URL |
|---|---|---|
| **Kong API Gateway** | `8080` | `http://localhost:8080/api/v1` |
| **Auth Service** | `8001` | `http://localhost:8001` |
| **Restaurant Service** | `8002` | `http://localhost:8002` |
| **Order Service** | `8003` | `http://localhost:8003` |
| **Rider Service** | `8004` | `http://localhost:8004` |
| **Payment Service** | `8005` | `http://localhost:8005` |
| **Notification Service** | `8006` | `http://localhost:8006` |
| **PostgreSQL Database** | `5435` | `localhost:5435` (cravex) |
