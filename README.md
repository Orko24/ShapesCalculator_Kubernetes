# 🔺 Shapes Calculator

A modern, containerized web application for geometric calculations built with FastAPI and deployed on Kubernetes.

![Python](https://img.shields.io/badge/Python-3.11-blue)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104.1-green)
![Docker](https://img.shields.io/badge/Docker-Container-blue)
![Kubernetes](https://img.shields.io/badge/Kubernetes-Ready-green)
![HTML5](https://img.shields.io/badge/HTML5-Frontend-orange)

## 🚀 Tech Stack

### **Backend**
- **Python 3.11** - Core programming language
- **FastAPI 0.104.1** - Modern, fast web framework for building APIs
- **Uvicorn 0.24.0** - Lightning-fast ASGI server
- **Pydantic 2.5.0** - Data validation using Python type annotations
- **Pandas 2.1.3** - Data manipulation and analysis
- **Python-multipart 0.0.6** - Multipart form data parsing

### **Frontend**
- **HTML5** - Semantic markup
- **CSS3** - Modern styling with gradients, animations, and responsive design
- **Vanilla JavaScript** - Interactive frontend with API integration
- **Responsive Design** - Mobile-first approach

### **Infrastructure & DevOps**
- **Docker** - Containerization
- **Kubernetes** - Container orchestration
- **Docker Compose** - Local development environment
- **NGINX** - Reverse proxy and static file serving (optional)

### **Kubernetes Features**
- **Horizontal Pod Autoscaler (HPA)** - Auto-scaling based on CPU/memory
- **Pod Disruption Budget (PDB)** - High availability
- **ConfigMaps** - Configuration management
- **Services** - Load balancing and service discovery
- **Ingress** - External access management
- **Health Checks** - Liveness and readiness probes

## 🏗️ Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Browser  │───▶│  Kubernetes     │───▶│   FastAPI       │
│                 │    │  (LoadBalancer) │    │   Backend       │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │                        │
                              ▼                        ▼
                    ┌─────────────────┐    ┌─────────────────┐
                    │   Frontend      │    │   Shape Models  │
                    │   (HTML/CSS/JS) │    │   (Calculations)│
                    └─────────────────┘    └─────────────────┘
```

## 📱 Features

### **Shape Calculations**
- **🔵 Circle Calculator** - Area and circumference
- **🔲 Rectangle Calculator** - Area and perimeter  
- **🔺 Triangle Calculator** - Area calculation
- **📊 Real-time Results** - Instant calculations with beautiful animations

### **API Endpoints**
- `GET /health` - Health check endpoint
- `POST /circle` - Circle calculations
- `POST /rectangle` - Rectangle calculations
- `POST /triangle` - Triangle calculations
- `GET /` - Serves the main application

### **Production Features**
- ✅ **Auto-scaling** - 2-10 pods based on load
- ✅ **Health Monitoring** - Automatic restart on failure
- ✅ **Load Balancing** - Traffic distribution across pods
- ✅ **Security** - Non-root containers, security contexts
- ✅ **Resource Management** - CPU and memory limits
- ✅ **High Availability** - Multiple replicas with pod disruption budget

## 🚀 Quick Start

### **Prerequisites**
- Docker Desktop with Kubernetes enabled
- kubectl configured
- Git (for cloning)

### **1. Clone & Navigate**
```bash
git clone <repository-url>
cd ShapeCalculator
```

### **2. Deploy to Kubernetes**
```bash
# Build Docker image
docker build -t shapes-calculator:latest -f backend/Dockerfile .

# Deploy to Kubernetes
kubectl apply -f k8s/

# Restart deployment to use local image
kubectl rollout restart deployment/shapes-calculator -n shapes-calculator
```

### **3. Access Application**
- **Main App**: http://localhost:30000
- **Health Check**: http://localhost:30000/health
- **API Docs**: http://localhost:30000/docs (FastAPI auto-generated)

## 🛠️ Development

### **Local Development (Docker Compose)**
```bash
# Start development environment
docker-compose up --build -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### **Kubernetes Development**
```bash
# Check pod status
kubectl get pods -n shapes-calculator

# View application logs
kubectl logs -f deployment/shapes-calculator -n shapes-calculator

# Scale application
kubectl scale deployment shapes-calculator --replicas=5 -n shapes-calculator

# Update after code changes
docker build -t shapes-calculator:latest -f backend/Dockerfile .
kubectl rollout restart deployment/shapes-calculator -n shapes-calculator
```

## 📊 API Usage Examples

### **Circle Calculation**
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"radius": 5}' \
  http://localhost:30000/circle
```
**Response:**
```json
{
  "area": 78.53981633974483,
  "circumference": 31.41592653589793
}
```

### **Rectangle Calculation**
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"length": 4, "width": 3}' \
  http://localhost:30000/rectangle
```
**Response:**
```json
{
  "area": 12,
  "perimeter": 14
}
```

### **Triangle Calculation**
```bash
curl -X POST -H "Content-Type: application/json" \
  -d '{"base": 6, "height": 4}' \
  http://localhost:30000/triangle
```
**Response:**
```json
{
  "area": 12.0
}
```

## 🔧 Configuration

### **Environment Variables**
| Variable | Default | Description |
|----------|---------|-------------|
| `FRONTEND_PATH` | `/app/frontend` | Path to frontend files |
| `PYTHONPATH` | `/app` | Python module path |
| `HOST` | `0.0.0.0` | Server bind address |
| `PORT` | `8000` | Server port |

### **Resource Limits (Kubernetes)**
- **CPU**: 100m request, 500m limit
- **Memory**: 128Mi request, 512Mi limit
- **Replicas**: 2-10 (auto-scaling)

## 🔍 Monitoring & Troubleshooting

### **Check Application Status**
```bash
# Pod status
kubectl get pods -n shapes-calculator

# Service status  
kubectl get services -n shapes-calculator

# HPA status
kubectl get hpa -n shapes-calculator
```

### **View Logs**
```bash
# Application logs
kubectl logs -f deployment/shapes-calculator -n shapes-calculator

# Specific pod logs
kubectl logs <pod-name> -n shapes-calculator
```

### **Health Checks**
```bash
# Health endpoint
curl http://localhost:30000/health

# Kubernetes health
kubectl describe pod <pod-name> -n shapes-calculator
```

## 🏗️ Project Structure

```
ShapeCalculator/
├── backend/
│   ├── Dockerfile              # Backend container
│   ├── main.py                 # Application entry point
│   ├── application_infastructructure.py  # FastAPI routes
│   └── shapes_models.py        # Calculation logic
├── frontend/                   # Static web files
│   ├── index.html             # Main page
│   ├── circle.html            # Circle calculator
│   ├── rectangle.html         # Rectangle calculator
│   ├── triangle.html          # Triangle calculator
│   └── shared.css             # Shared styles
├── k8s/                       # Kubernetes manifests
│   ├── namespace.yaml         # K8s namespace
│   ├── configmap.yaml         # Configuration
│   ├── deployment.yaml        # App deployment
│   ├── service.yaml           # Services
│   ├── ingress.yaml           # Ingress rules
│   ├── hpa.yaml              # Auto-scaler
│   └── pdb.yaml              # Disruption budget
├── scripts/                   # Automation scripts
│   ├── build-and-deploy.sh   # Build & deploy
│   ├── local-dev.sh          # Local development
│   └── validate-deployment.sh # Deployment validation
├── docker-compose.yml         # Local development
├── nginx.conf                 # Nginx configuration
├── requirements.txt           # Python dependencies
├── .dockerignore             # Docker ignore
└── README.md                 # This file
```

## 🔒 Security Features

- ✅ **Non-root containers** - Enhanced security
- ✅ **Security contexts** - Pod security standards
- ✅ **Resource limits** - Prevent resource exhaustion
- ✅ **Health checks** - Automatic failure recovery
- ✅ **Network policies** - (Can be added)
- ✅ **RBAC** - (Can be added)

## 🚀 Deployment Options

### **Local Development**
- Docker Compose for quick local testing
- Hot reload for development

### **Kubernetes (Production)**
- Auto-scaling based on load
- High availability with multiple replicas
- Load balancing across pods
- Health monitoring and auto-recovery

### **Cloud Deployment**
- Compatible with any Kubernetes cluster
- AWS EKS, Google GKE, Azure AKS
- On-premises Kubernetes

## 📈 Performance

- **Fast API responses** - Sub-millisecond calculations
- **Efficient scaling** - Horizontal pod autoscaler
- **Optimized images** - Multi-stage Docker builds
- **Caching** - Static asset caching with nginx

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test locally and on Kubernetes
5. Submit a pull request

## 📄 License

This project is open source and available under the [MIT License](LICENSE).

## 🔗 Links

- **Application**: http://localhost:30000
- **API Documentation**: http://localhost:30000/docs
- **Health Check**: http://localhost:30000/health

---

**Built with using FastAPI, Kubernetes, and modern web technologies.**
