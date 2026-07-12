# CraveX Security Hardening Architecture

This document details the security principles, cryptographic verification steps, and protection mechanisms implemented across the CraveX microservice services.

---

## 1. Authentication & Token Management

- **JWT Access/Refresh Split**:
  - Access tokens are short-lived (15 minutes) and carry the user's role and scopes/permissions.
  - Refresh tokens are long-lived (30 days) and stored securely in the database for rotation and revocation.
- **Role-Based Access Control (RBAC)**:
  - Endpoints validate token claims (`sub`, `role`, `permissions`) using Go middleware to ensure only authorized callers (e.g. Riders, Restaurants, Customers, Admins) can perform mutation operations on resources.

---

## 2. OTP Abuse Prevention

To protect SMS gateway billing and prevent bulk brute-forcing / credential stuffing:
- **Strict Limit**: Maximum of 3 OTP request cycles allowed per hour per phone number.
- **Exponential Cooldowns**:
  - Request 1: Instant
  - Request 2: Cooldown of 5 seconds required
  - Request 3: Cooldown of 30 seconds required
  - Any subsequent attempts inside the hour return a `429 Too Many Requests` status code.
- **State Tracking**: Tracked using memory-safe thread-safe maps guarded by mutex locks inside `auth-service` handlers.

---

## 3. Stripe Webhook Cryptographic Verification

To secure payments processing against webhook spoofing and replay attacks:
- **HMAC-SHA256 Handshake Verification**:
  - Computes expected HMAC signatures of raw payload bytes combined with headers timestamps.
  - Compares header signature `v1` with computed hashes.
- **Constant-Time Comparison**:
  - Employs `crypto/subtle` / `hmac.Equal` to compare byte arrays, mitigating side-channel timing analysis attacks.
- **Replay Attack Protection**:
  - Extracts timestamp `t` from Stripe headers.
  - Rejects any webhook events where the timestamp delta is older than **5 minutes** (300 seconds).

---

## 4. Database Security & Sanitization

- **SQL Injection Prevention**:
  - Avoids dynamic SQL string interpolation.
  - Enforces parameterized queries using GORM ORM bindings (`db.Where("column = ?", value)`), ensuring the database driver handles input sanitization.
- **Sensitive Data Handling**:
  - Application secrets (database passwords, Redis connection parameters, API key hashes) are masked and managed through configuration variables (`.env` files) rather than checked into version control.
