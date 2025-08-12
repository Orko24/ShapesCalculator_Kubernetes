Great question! There are actually **two different scenarios** here - let me explain both:

## 1. Running Kubernetes ON a Load Balancer (Multi-Master HA)

This is about making your **Kubernetes control plane** highly available using a load balancer.

### Architecture:
```
                    ┌─────────────────┐
                    │  Load Balancer  │ ← External LB (HAProxy/nginx/cloud LB)
                    │  (API Server)   │
                    └─────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
   ┌─────────┐        ┌─────────┐        ┌─────────┐
   │Master 1 │        │Master 2 │        │Master 3 │ ← Multiple control planes
   │API+etcd │        │API+etcd │        │API+etcd │
   └─────────┘        └─────────┘        └─────────┘
        │                  │                  │
   ┌─────────┐        ┌─────────┐        ┌─────────┐
   │Worker 1 │        │Worker 2 │        │Worker 3 │ ← Worker nodes
   └─────────┘        └─────────┘        └─────────┘
```

### Setup Example (kubeadm):

**1. Load Balancer Configuration (HAProxy):**
```bash
# /etc/haproxy/haproxy.cfg
global
    chroot /var/lib/haproxy
    stats socket /run/haproxy/admin.sock mode 660 level admin
    stats timeout 30s

defaults
    mode http
    timeout connect 5000ms
    timeout client 50000ms
    timeout server 50000ms

frontend kubernetes-frontend
    bind *:6443
    mode tcp
    option tcplog
    default_backend kubernetes-backend

backend kubernetes-backend
    mode tcp
    balance roundrobin
    option tcp-check
    server master1 10.0.1.10:6443 check fall 3 rise 2
    server master2 10.0.1.11:6443 check fall 3 rise 2  
    server master3 10.0.1.12:6443 check fall 3 rise 2
```

**2. First Master Node:**
```bash
# Initialize first master with LB endpoint
kubeadm init \
  --control-plane-endpoint "loadbalancer.k8s.local:6443" \
  --upload-certs \
  --apiserver-advertise-address=10.0.1.10 \
  --pod-network-cidr=192.168.0.0/16
```

**3. Additional Master Nodes:**
```bash
# Join other masters
kubeadm join loadbalancer.k8s.local:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <cert-key>
```

## 2. Using Load Balancers IN Kubernetes (For Your Apps)

This is about exposing your **applications** through load balancers.

### Service Types for Load Balancing:

**A. Cloud LoadBalancer Service:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app-lb
spec:
  type: LoadBalancer
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
```

**What happens:**
1. Cloud provider creates external load balancer (AWS ALB/NLB, GCP LB, Azure LB)
2. Gets public IP address
3. Routes traffic to your pods across multiple nodes

**B. Ingress with Load Balancer:**
```yaml
# Ingress Controller (nginx)
apiVersion: v1
kind: Service
metadata:
  name: nginx-ingress-controller
  namespace: ingress-nginx
spec:
  type: LoadBalancer  # Creates cloud LB
  selector:
    app.kubernetes.io/name: ingress-nginx
  ports:
  - port: 80
    targetPort: 80
  - port: 443
    targetPort: 443

---
# Your application ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
spec:
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app
            port:
              number: 80
```

## 3. Advanced Load Balancing Patterns

### A. Service Mesh (Istio) Load Balancing:
```yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: web-app
spec:
  host: web-app
  trafficPolicy:
    loadBalancer:
      simple: LEAST_CONN  # or ROUND_ROBIN, RANDOM, PASSTHROUGH
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2

---
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: web-app
spec:
  http:
  - match:
    - headers:
        canary:
          exact: "true"
    route:
    - destination:
        host: web-app
        subset: v2
      weight: 100
  - route:
    - destination:
        host: web-app
        subset: v1
      weight: 90
    - destination:
        host: web-app
        subset: v2
      weight: 10  # 10% canary traffic
```

### B. External Load Balancer + NodePort:
```yaml
# NodePort service
apiVersion: v1
kind: Service
metadata:
  name: web-app-nodeport
spec:
  type: NodePort
  selector:
    app: web-app
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080  # Accessible on all nodes at this port

# External LB configuration (e.g., F5, HAProxy)
# Points to: node1:30080, node2:30080, node3:30080
```

## 4. Load Balancing Algorithms in Kubernetes

**Service-level (kube-proxy):**
- **Round Robin** (default)
- **Session Affinity** (sticky sessions)

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-app
spec:
  sessionAffinity: ClientIP  # Sticky sessions
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800  # 3 hours
```

**Ingress-level (nginx-ingress):**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/load-balance: "ewma"  # or ip_hash, least_conn
    nginx.ingress.kubernetes.io/upstream-hash-by: "$request_uri"  # Consistent hashing
```

## 5. Real-World Example: High-Traffic Web App

```yaml
# Frontend with horizontal scaling
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 10
  selector:
    matchLabels:
      app: frontend
      tier: web
  template:
    metadata:
      labels:
        app: frontend
        tier: web
    spec:
      containers:
      - name: frontend
        image: nginx:1.20
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi

---
# Internal service for frontend
apiVersion: v1
kind: Service
metadata:
  name: frontend-service
spec:
  selector:
    app: frontend
    tier: web
  ports:
  - port: 80
    targetPort: 80

---
# Load balancer ingress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: frontend-ingress
  annotations:
    kubernetes.io/ingress.class: "nginx"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
spec:
  tls:
  - hosts:
    - myapp.com
    secretName: myapp-tls
  rules:
  - host: myapp.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80

---
# HPA for auto-scaling
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: frontend-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: frontend
  minReplicas: 3
  maxReplicas: 50
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

## 6. Traffic Flow Example

```
Internet Traffic
       ↓
Cloud Load Balancer (AWS ALB)
       ↓
Ingress Controller (nginx)
       ↓
Service (ClusterIP)
       ↓
Pods (distributed across nodes)
```

## Which Approach to Choose?

**For production apps:**
- **Ingress + LoadBalancer Service** (most common)
- Single load balancer handles multiple services
- SSL termination, path-based routing

**For simple services:**
- **LoadBalancer Service** directly
- One load balancer per service (more expensive)

**For enterprise/on-prem:**
- **NodePort + External LB**
- More control over load balancer configuration

**For microservices:**
- **Service Mesh** (Istio/Linkerd)
- Advanced traffic management, security, observability

The key is that Kubernetes provides the **service abstraction** and **automatically manages endpoints**, while the load balancer (whether cloud or ingress controller) handles the actual traffic distribution.