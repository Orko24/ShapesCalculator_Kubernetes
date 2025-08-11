Perfect! Let me break down **everything** you need to know about Kubernetes using your actual files as examples. This will give you both theoretical knowledge and practical understanding for your interview.

## Core Kubernetes Architecture

**Master Components:**
- **API Server** - The front-end to the Kubernetes control plane
- **etcd** - Key-value store for all cluster data
- **Scheduler** - Assigns pods to nodes
- **Controller Manager** - Runs controllers that regulate cluster state

**Node Components:**
- **kubelet** - Agent that runs on each node, manages pods
- **kube-proxy** - Network proxy, handles service networking
- **Container Runtime** - Docker/containerd that actually runs containers

## Your Kubernetes Resources Explained

### 1. **Namespace** (`namespace.yaml`)
```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: shapes-calculator
```

**What it does:** Creates an isolated environment within your cluster
**Interview points:**
- Namespaces provide logical separation (like folders)
- Default namespaces: `default`, `kube-system`, `kube-public`
- Resource quotas can be applied per namespace
- Names must be unique within a namespace, not across cluster

### 2. **ConfigMap** (`configmap.yaml`)
```yaml
kind: ConfigMap
data:
  FRONTEND_PATH: "/app/frontend"
  PYTHONPATH: "/app"
  HOST: "0.0.0.0"
  PORT: "8000"
```

**What it does:** Stores non-sensitive configuration data
**Interview points:**
- Separates configuration from application code
- Can be mounted as volumes or environment variables
- Immutable - changes require pod restart
- Alternative to hardcoding config in Docker images

### 3. **Deployment** (`deployment.yaml`)
This is the **most important** resource - study this thoroughly!

```yaml
apiVersion: apps/v1
kind: Deployment
spec:
  replicas: 3  # How many pod copies
  selector:
    matchLabels:
      app: shapes-calculator  # Which pods this manages
  template:  # Pod template
    spec:
      containers:
      - name: shapes-calculator
        image: shapes-calculator:latest
        imagePullPolicy: Never  # Don't pull from registry
```

**Key Deployment Concepts:**

**Replica Management:**
- Ensures 3 pods are always running
- If a pod dies, Deployment creates a new one
- **Rolling updates** - gradual replacement of old pods with new ones

**Resource Limits:**
```yaml
resources:
  requests:  # Guaranteed resources
    memory: "128Mi"
    cpu: "100m"
  limits:    # Maximum allowed
    memory: "512Mi" 
    cpu: "500m"
```

**Health Checks:**
```yaml
livenessProbe:   # Is the container alive?
  httpGet:
    path: /health
    port: 8000
readinessProbe:  # Is the container ready to serve traffic?
  httpGet:
    path: /health
    port: 8000
```

**Interview points:**
- **Liveness probe fails** → Kubernetes restarts the container
- **Readiness probe fails** → Kubernetes removes pod from service endpoints
- **CPU units:** 100m = 0.1 CPU core, 1000m = 1 full core
- **Memory units:** Mi = Mebibytes, Gi = Gibibytes

### 4. **Service** (`service.yaml`)

You have TWO service types:

**ClusterIP Service:**
```yaml
type: ClusterIP  # Internal cluster access only
ports:
- port: 80      # Service port
  targetPort: 8000  # Container port
```

**NodePort Service:**
```yaml
type: NodePort
ports:
- nodePort: 30000  # External port on every node
  port: 80
  targetPort: 8000
```

**Service Types (Critical for interviews):**
1. **ClusterIP** - Internal cluster communication only
2. **NodePort** - Exposes service on each node's IP at a static port
3. **LoadBalancer** - Cloud provider creates external load balancer
4. **ExternalName** - Maps service to external DNS name

**How Services Work:**
- Uses **selectors** to find pods: `app: shapes-calculator`
- Creates **endpoints** - list of pod IPs that match the selector
- **kube-proxy** updates iptables rules for load balancing

### 5. **Horizontal Pod Autoscaler** (`hpa.yaml`)

```yaml
kind: HorizontalPodAutoscaler
spec:
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        averageUtilization: 70
```

**What it does:** Automatically scales pod replicas based on metrics
**Interview points:**
- Requires **metrics server** to be installed
- Checks metrics every 15 seconds (default)
- **Scale up:** Fast (can double replicas)
- **Scale down:** Conservative (removes 1 pod at a time)
- Works with CPU, memory, and custom metrics

### 6. **Ingress** (`ingress.yaml`)

```yaml
kind: Ingress
spec:
  rules:
  - host: shapes-calculator.local
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: shapes-calculator-service
```

**What it does:** HTTP/HTTPS routing to services
**Interview points:**
- Requires **Ingress Controller** (nginx, traefik, etc.)
- Provides Layer 7 load balancing
- Can terminate SSL/TLS
- Path-based and host-based routing
- More cost-effective than multiple LoadBalancer services

### 7. **Pod Disruption Budget** (`pdb.yaml`)

```yaml
kind: PodDisruptionBudget
spec:
  minAvailable: 1  # Always keep at least 1 pod running
```

**What it does:** Protects applications during voluntary disruptions
**Interview points:**
- Prevents all pods from being terminated during updates
- **Voluntary disruptions:** Node maintenance, cluster upgrades
- **Involuntary disruptions:** Hardware failures, kernel panics
- Can specify `minAvailable` or `maxUnavailable`

## Critical Kubernetes Concepts for Interviews

### **1. Pod Lifecycle**
- **Pending** → Waiting for scheduling
- **Running** → At least one container is running
- **Succeeded** → All containers terminated successfully
- **Failed** → At least one container failed
- **Unknown** → Cannot determine pod status

### **2. Rolling Updates**
```bash
# Update deployment image
kubectl set image deployment/shapes-calculator shapes-calculator=new-image:v2

# Check rollout status
kubectl rollout status deployment/shapes-calculator

# Rollback to previous version
kubectl rollout undo deployment/shapes-calculator
```

### **3. Labels and Selectors**
```yaml
metadata:
  labels:
    app: shapes-calculator
    tier: frontend
    version: v1
```
- **Labels** - Key-value pairs attached to objects
- **Selectors** - Query labels to find resources
- Used by Services, Deployments, and many other resources

### **4. Storage (You'll need this for file projects)**
- **Volumes** - Shared storage for containers in a pod
- **PersistentVolumes** - Cluster-wide storage resources
- **PersistentVolumeClaims** - Requests for storage by pods
- **StorageClasses** - Dynamic provisioning of storage

### **5. Security**
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  capabilities:
    drop:
    - ALL
```
- **RBAC** - Role-Based Access Control
- **Security Contexts** - Define security settings for pods/containers
- **Network Policies** - Control traffic between pods
- **Secrets** - Store sensitive data (passwords, tokens)

## Common Interview Questions & Answers

**Q: What happens when a pod dies?**
A: The Deployment controller detects the missing pod and creates a new one to maintain the desired replica count.

**Q: How does Service discovery work?**
A: Kubernetes provides DNS records for services. Pods can access `shapes-calculator-service.shapes-calculator.svc.cluster.local`

**Q: What's the difference between Deployment and StatefulSet?**
A: Deployments are for stateless apps (pods are interchangeable). StatefulSets are for stateful apps (pods have stable identities, ordered deployment).

**Q: How do you troubleshoot a failing pod?**
A: 
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- /bin/bash
```

**Q: What's the difference between requests and limits?**
A: **Requests** = guaranteed resources (used for scheduling). **Limits** = maximum allowed resources (container killed if exceeded).

## Essential kubectl Commands

```bash
# Basic operations
kubectl get pods -n shapes-calculator
kubectl describe deployment shapes-calculator -n shapes-calculator
kubectl logs -f deployment/shapes-calculator -n shapes-calculator

# Scaling
kubectl scale deployment shapes-calculator --replicas=5 -n shapes-calculator

# Updates
kubectl set image deployment/shapes-calculator shapes-calculator=new-image:v2 -n shapes-calculator

# Port forwarding for testing
kubectl port-forward service/shapes-calculator-service 8080:80 -n shapes-calculator

# Apply configurations
kubectl apply -f namespace.yaml
kubectl apply -f .  # All YAML files in directory
```

This covers the **core concepts** you need for Kubernetes interviews. Your file structure shows you understand production-ready Kubernetes deployments with proper resource management, health checks, scaling, and networking!
