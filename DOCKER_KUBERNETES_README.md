# Docker & Kubernetes Setup for Shapes Calculator

This document provides comprehensive instructions for containerizing and deploying the Shapes Calculator application using Docker and Kubernetes.

## 📁 Project Structure

```
ShapeCalculator/
├── backend/
│   ├── Dockerfile              # Backend container definition
│   ├── main.py                 # FastAPI application entry point
│   ├── application_infastructructure.py  # FastAPI routes and middleware
│   └── shapes_models.py        # Shape calculation logic
├── frontend/                   # Static HTML/CSS/JS files
├── k8s/                        # Kubernetes manifests
│   ├── namespace.yaml          # Kubernetes namespace
│   ├── configmap.yaml          # Application configuration
│   ├── deployment.yaml         # Application deployment
│   ├── service.yaml           # Service definitions
│   ├── ingress.yaml           # Ingress configuration
│   ├── hpa.yaml               # Horizontal Pod Autoscaler
│   └── pdb.yaml               # Pod Disruption Budget
├── scripts/
│   ├── build-and-deploy.sh    # Automated build and deployment
│   └── local-dev.sh           # Local development helper
├── docker-compose.yml         # Local development environment
├── nginx.conf                 # Nginx configuration for production
├── requirements.txt           # Python dependencies
└── .dockerignore             # Docker ignore patterns
```

## 🐳 Docker Setup

### Prerequisites

- Docker Desktop installed and running
- Docker Compose (usually included with Docker Desktop)

### Local Development with Docker Compose

#### Quick Start

1. **Start the development environment:**
   ```bash
   # On Windows (PowerShell)
   ./scripts/local-dev.sh start
   
   # Alternative: Direct docker-compose
   docker-compose up --build -d
   ```

2. **Access the application:**
   - Main application: http://localhost:8000
   - API health check: http://localhost:8000/health
   - Circle calculator: http://localhost:8000/circle-page
   - Rectangle calculator: http://localhost:8000/rectangle-page
   - Triangle calculator: http://localhost:8000/triangle-page

#### Development Commands

```bash
# View service status
./scripts/local-dev.sh status

# View logs
./scripts/local-dev.sh logs                    # All services
./scripts/local-dev.sh logs shapes-calculator  # Specific service

# Restart services
./scripts/local-dev.sh restart

# Stop services
./scripts/local-dev.sh stop

# Clean up everything
./scripts/local-dev.sh clean

# Open shell in container
./scripts/local-dev.sh shell
```

#### Production-like Environment

Start with nginx reverse proxy:
```bash
./scripts/local-dev.sh start-prod
```

Access via:
- Frontend (nginx): http://localhost
- Backend API: http://localhost/health

### Manual Docker Commands

#### Build the Image
```bash
docker build -t shapes-calculator:latest -f backend/Dockerfile .
```

#### Run the Container
```bash
docker run -d \
  --name shapes-calculator \
  -p 8000:8000 \
  -e FRONTEND_PATH=/app/frontend \
  shapes-calculator:latest
```

## ☸️ Kubernetes Setup

### Prerequisites

- Kubernetes cluster (local: minikube, Docker Desktop, or cloud: EKS, GKE, AKS)
- kubectl configured to connect to your cluster
- (Optional) NGINX Ingress Controller for ingress functionality

### Deployment Options

#### Option 1: Automated Deployment

Use the provided script:
```bash
# Build and deploy
./scripts/build-and-deploy.sh latest

# Deploy only (if image already exists)
./scripts/build-and-deploy.sh latest deploy-only

# Build only
./scripts/build-and-deploy.sh latest build-only
```

#### Option 2: Manual Deployment

1. **Build and load image (for local clusters):**
   ```bash
   # Build image
   docker build -t shapes-calculator:latest -f backend/Dockerfile .
   
   # For minikube
   minikube image load shapes-calculator:latest
   
   # For Docker Desktop Kubernetes
   # Image is automatically available
   ```

2. **Deploy to Kubernetes:**
   ```bash
   # Apply all manifests
   kubectl apply -f k8s/
   
   # Check deployment status
   kubectl get pods -n shapes-calculator
   kubectl get services -n shapes-calculator
   ```

### Accessing the Application

#### NodePort Access
```bash
# Get NodePort
kubectl get service shapes-calculator-nodeport -n shapes-calculator

# Access via: http://<node-ip>:30000
```

#### Ingress Access (if NGINX Ingress Controller is installed)
```bash
# Add to /etc/hosts (Linux/Mac) or C:\Windows\System32\drivers\etc\hosts (Windows)
127.0.0.1 shapes-calculator.local

# Access via: http://shapes-calculator.local
```

#### Port Forward (for testing)
```bash
kubectl port-forward service/shapes-calculator-service 8080:80 -n shapes-calculator
# Access via: http://localhost:8080
```

### Scaling and Management

#### Manual Scaling
```bash
kubectl scale deployment shapes-calculator --replicas=5 -n shapes-calculator
```

#### Auto-scaling (HPA)
The Horizontal Pod Autoscaler is configured to:
- Min replicas: 2
- Max replicas: 10
- Scale up when CPU > 70% or Memory > 80%

```bash
# Check HPA status
kubectl get hpa -n shapes-calculator

# View HPA details
kubectl describe hpa shapes-calculator-hpa -n shapes-calculator
```

### Monitoring and Troubleshooting

#### Check Application Logs
```bash
kubectl logs -f deployment/shapes-calculator -n shapes-calculator
```

#### Check Pod Status
```bash
kubectl get pods -n shapes-calculator -o wide
kubectl describe pod <pod-name> -n shapes-calculator
```

#### Check Service Endpoints
```bash
kubectl get endpoints -n shapes-calculator
```

#### Health Checks
```bash
# Test health endpoint
kubectl exec -it deployment/shapes-calculator -n shapes-calculator -- curl http://localhost:8000/health
```

## 🔧 Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `FRONTEND_PATH` | `/app/frontend` | Path to frontend files |
| `PYTHONPATH` | `/app` | Python path for imports |
| `HOST` | `0.0.0.0` | Server bind address |
| `PORT` | `8000` | Server port |

### Resource Limits

**Development (Docker Compose):**
- No limits set for easier development

**Production (Kubernetes):**
- CPU Request: 100m, Limit: 500m
- Memory Request: 128Mi, Limit: 512Mi

## 🚀 CI/CD Integration

### GitHub Actions Example

```yaml
name: Build and Deploy

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Build and push Docker image
      run: |
        docker build -t myregistry/shapes-calculator:${{ github.sha }} -f backend/Dockerfile .
        docker push myregistry/shapes-calculator:${{ github.sha }}
    
    - name: Deploy to Kubernetes
      run: |
        DOCKER_REGISTRY=myregistry ./scripts/build-and-deploy.sh ${{ github.sha }} deploy-only
```

## 🔒 Security Considerations

### Docker Security
- ✅ Non-root user in container
- ✅ Read-only root filesystem (where possible)
- ✅ Minimal base image (Python slim)
- ✅ Security context configured

### Kubernetes Security
- ✅ Security contexts with non-root user
- ✅ Pod security standards
- ✅ Resource limits
- ✅ Network policies (can be added)
- ✅ RBAC (can be added)

## 📊 Performance Optimization

### Docker Optimizations
- Multi-stage builds (can be implemented)
- Layer caching optimization
- .dockerignore to reduce context size

### Kubernetes Optimizations
- Horizontal Pod Autoscaler configured
- Pod Disruption Budget for availability
- Resource requests/limits for scheduling
- Readiness/liveness probes for health

## 🐛 Troubleshooting

### Common Issues

#### 1. Image Pull Errors
```bash
# Check if image exists locally
docker images | grep shapes-calculator

# For minikube, ensure image is loaded
minikube image load shapes-calculator:latest
```

#### 2. Frontend Files Not Found
```bash
# Check FRONTEND_PATH environment variable
kubectl exec -it deployment/shapes-calculator -n shapes-calculator -- ls -la /app/frontend/
```

#### 3. Service Not Accessible
```bash
# Check service and endpoints
kubectl get svc,endpoints -n shapes-calculator

# Test internal connectivity
kubectl run test-pod --image=busybox -it --rm -- wget -qO- http://shapes-calculator-service.shapes-calculator.svc.cluster.local/health
```

#### 4. Windows Script Execution
On Windows, if you can't run the bash scripts:
```powershell
# Use WSL
wsl ./scripts/local-dev.sh start

# Or use Git Bash
"C:\Program Files\Git\bin\bash.exe" ./scripts/local-dev.sh start

# Or run Docker commands directly
docker-compose up --build -d
```

## 📝 Next Steps

1. **Add monitoring** (Prometheus/Grafana)
2. **Implement logging** (ELK stack)
3. **Add SSL/TLS** (cert-manager)
4. **Database integration** (if needed)
5. **CI/CD pipeline** (GitHub Actions/GitLab CI)
6. **Testing automation** (pytest in CI)

## 🤝 Contributing

When adding new features:
1. Update Dockerfile if new dependencies are added
2. Update Kubernetes manifests if new configuration is needed
3. Test both Docker Compose and Kubernetes deployments
4. Update this documentation

## 📚 Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)


