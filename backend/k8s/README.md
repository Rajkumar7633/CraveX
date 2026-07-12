# CraveX Backend - Kubernetes Deployment Guide

This guide provides instructions for deploying the CraveX backend services using Kubernetes.

## Prerequisites

- Kubernetes cluster (v1.24+)
- kubectl configured to access your cluster
- Docker installed
- Helm (optional, for easier deployments)

## Architecture

The CraveX backend consists of the following microservices:

- **Auth Service** (Port 8001) - Authentication and authorization
- **Restaurant Service** (Port 8002) - Restaurant management
- **Order Service** (Port 8003) - Order processing
- **Rider Service** (Port 8004) - Rider management
- **Payment Service** (Port 8005) - Payment processing
- **Notification Service** (Port 8006) - Notification delivery
- **Routing Service** (Port 8007) - Route optimization

## Deployment Steps

### 1. Create Namespace

```bash
kubectl apply -f k8s/namespace.yaml
```

### 2. Create ConfigMap

```bash
kubectl apply -f k8s/configmap.yaml
```

### 3. Create Secrets

Update the secrets.yaml file with your actual credentials, then apply:

```bash
kubectl apply -f k8s/secrets.yaml
```

### 4. Deploy Services

Deploy each service individually:

```bash
# Auth Service
kubectl apply -f k8s/auth-service-deployment.yaml

# Restaurant Service
kubectl apply -f k8s/restaurant-service-deployment.yaml

# Order Service
kubectl apply -f k8s/order-service-deployment.yaml

# Rider Service
kubectl apply -f k8s/rider-service-deployment.yaml

# Payment Service
kubectl apply -f k8s/payment-service-deployment.yaml

# Notification Service
kubectl apply -f k8s/notification-service-deployment.yaml

# Routing Service
kubectl apply -f k8s/routing-service-deployment.yaml
```

### 5. Deploy Ingress

```bash
kubectl apply -f k8s/ingress.yaml
```

### 6. Deploy Infrastructure Services

Deploy PostgreSQL, Redis, and Kafka:

```bash
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/redis-deployment.yaml
kubectl apply -f k8s/kafka-deployment.yaml
```

## Verification

### Check Pod Status

```bash
kubectl get pods -n cravex
```

### Check Services

```bash
kubectl get services -n cravex
```

### Check Logs

```bash
kubectl logs -n cravex -l app=auth-service
```

### Port Forwarding (for local testing)

```bash
kubectl port-forward -n cravex svc/auth-service 8001:8001
kubectl port-forward -n cravex svc/restaurant-service 8002:8002
kubectl port-forward -n cravex svc/order-service 8003:8003
```

## Scaling

### Manual Scaling

```bash
kubectl scale deployment auth-service -n cravex --replicas=5
```

### Horizontal Pod Autoscaler

The deployments include HPA configurations that automatically scale based on CPU and memory usage:

```bash
kubectl get hpa -n cravex
```

## Monitoring

### Install Metrics Server (if not already installed)

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### View Resource Usage

```bash
kubectl top pods -n cravex
kubectl top nodes
```

## Troubleshooting

### Pod Not Starting

```bash
kubectl describe pod <pod-name> -n cravex
kubectl logs <pod-name> -n cravex
```

### Service Not Accessible

```bash
kubectl get endpoints -n cravex
kubectl describe service <service-name> -n cravex
```

### Database Connection Issues

```bash
kubectl exec -it -n cravex <pod-name> -- sh
# Inside pod
ping postgres-service
telnet postgres-service 5432
```

## Updates

### Update Service Image

```bash
kubectl set image deployment/auth-service auth-service=cravex/auth-service:v2 -n cravex
```

### Rollback

```bash
kubectl rollout undo deployment/auth-service -n cravex
```

### Check Rollout Status

```bash
kubectl rollout status deployment/auth-service -n cravex
```

## Cleanup

### Delete All Resources

```bash
kubectl delete namespace cravex
```

### Delete Specific Service

```bash
kubectl delete deployment auth-service -n cravex
kubectl delete service auth-service -n cravex
```

## Security Best Practices

1. **Secrets Management**: Use proper secret management tools like HashiCorp Vault or AWS Secrets Manager for production
2. **Network Policies**: Implement network policies to restrict pod-to-pod communication
3. **RBAC**: Configure Role-Based Access Control for Kubernetes API access
4. **Image Scanning**: Scan container images for vulnerabilities before deployment
5. **TLS/SSL**: Ensure all communications are encrypted using TLS certificates

## Environment Variables

### Required Environment Variables

Each service requires the following environment variables:

- `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`
- `REDIS_HOST`, `REDIS_PORT`, `REDIS_PASSWORD`
- `KAFKA_BROKERS`
- `JWT_SECRET` (Auth Service)

### Optional Environment Variables

- `STRIPE_SECRET_KEY`, `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` (Payment Service)
- `SENDGRID_API_KEY`, `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` (Notification Service)
- `GOOGLE_MAPS_API_KEY` (Routing Service)
- `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` (S3 Storage)

## Support

For issues or questions, contact the DevOps team at devops@cravex.com
