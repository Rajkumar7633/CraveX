# Zomato Clone Suite

A monorepo containing four Flutter applications and a backend stack for a full‑featured food‑delivery platform.

## Repository Structure
```
/zomato_clone
│   README.md               # ← This file
│   melos.yaml              # Workspace definition
│
├── apps
│   ├── customer/           # Flutter mobile app (iOS/Android)
│   ├── restaurant/         # Partner app for restaurants
│   ├── rider/              # Delivery rider app
│   └── admin/              # Admin dashboard (Flutter Web or React)
│
├── packages
│   ├── core/               # Network, models, utilities
│   ├── theme/              # Design system, color palette, typography
│   ├── widgets/            # Reusable UI widgets
│   └── state/              # Riverpod/Bloc base classes
│
├── backend/                # Microservice skeletons (Spring Boot / Go)
│   ├── auth-service/
│   ├── restaurant-service/
│   ├── order-service/
│   ├── payment-service/
│   └── rider-service/
│
├── infra/                  # IaC (Terraform, Docker‑Compose)
└── docs/                   # Design system, API specs, ER diagram, roadmap
```

## Getting Started
1. **Prerequisites**: Flutter 3.19+, Dart 3, Java 11 (for Spring Boot), Node 20 (if using React), Docker.
2. **Install melos** (workspace manager):
   ```bash
   dart pub global activate melos
   ```
3. **Bootstrap packages**:
   ```bash
   melos bootstrap
   ```
4. **Run an app** (example – Customer app):
   ```bash
   cd apps/customer
   flutter run
   ```

---
Generated from the approved implementation plan.
