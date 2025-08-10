#!/bin/bash

# Build and Deploy Shapes Calculator
# This script handles Docker build and Kubernetes deployment

set -e

# Configuration
IMAGE_NAME="shapes-calculator"
IMAGE_TAG="${1:-latest}"
NAMESPACE="shapes-calculator"
REGISTRY="${DOCKER_REGISTRY:-}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to build Docker image
build_image() {
    log "Building Docker image: ${IMAGE_NAME}:${IMAGE_TAG}"
    
    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} -f backend/Dockerfile .
    
    if [ $? -eq 0 ]; then
        log "Docker image built successfully"
    else
        error "Failed to build Docker image"
        exit 1
    fi
}

# Function to tag and push image to registry (if registry is set)
push_image() {
    if [ -n "$REGISTRY" ]; then
        log "Tagging image for registry: ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"
        docker tag ${IMAGE_NAME}:${IMAGE_TAG} ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
        
        log "Pushing image to registry..."
        docker push ${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}
        
        if [ $? -eq 0 ]; then
            log "Image pushed successfully"
        else
            error "Failed to push image to registry"
            exit 1
        fi
    else
        warn "No registry specified. Skipping image push."
    fi
}

# Function to deploy to Kubernetes
deploy_k8s() {
    log "Deploying to Kubernetes..."
    
    # Check if kubectl is available
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed or not in PATH"
        exit 1
    fi
    
    # Create namespace if it doesn't exist
    kubectl create namespace ${NAMESPACE} --dry-run=client -o yaml | kubectl apply -f -
    
    # Apply all Kubernetes manifests
    log "Applying Kubernetes manifests..."
    kubectl apply -f k8s/
    
    # Update deployment image
    if [ -n "$REGISTRY" ]; then
        kubectl set image deployment/shapes-calculator shapes-calculator=${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG} -n ${NAMESPACE}
    else
        kubectl set image deployment/shapes-calculator shapes-calculator=${IMAGE_NAME}:${IMAGE_TAG} -n ${NAMESPACE}
    fi
    
    # Wait for rollout to complete
    log "Waiting for deployment rollout..."
    kubectl rollout status deployment/shapes-calculator -n ${NAMESPACE} --timeout=300s
    
    if [ $? -eq 0 ]; then
        log "Deployment completed successfully"
    else
        error "Deployment failed"
        exit 1
    fi
}

# Function to check deployment status
check_status() {
    log "Checking deployment status..."
    
    kubectl get pods -n ${NAMESPACE} -l app=shapes-calculator
    kubectl get services -n ${NAMESPACE}
    kubectl get ingress -n ${NAMESPACE}
    
    # Get service URL
    log "Service endpoints:"
    if kubectl get service shapes-calculator-nodeport -n ${NAMESPACE} &> /dev/null; then
        NODE_PORT=$(kubectl get service shapes-calculator-nodeport -n ${NAMESPACE} -o jsonpath='{.spec.ports[0].nodePort}')
        log "NodePort service available at: http://<node-ip>:${NODE_PORT}"
    fi
    
    if kubectl get ingress shapes-calculator-ingress -n ${NAMESPACE} &> /dev/null; then
        log "Ingress configured for: shapes-calculator.local"
        log "Add '127.0.0.1 shapes-calculator.local' to your /etc/hosts file for local access"
    fi
}

# Main execution
main() {
    log "Starting build and deployment process..."
    
    # Build image
    build_image
    
    # Push image if registry is specified
    push_image
    
    # Deploy to Kubernetes
    deploy_k8s
    
    # Check status
    check_status
    
    log "Build and deployment process completed!"
}

# Parse command line arguments
case "${2:-deploy}" in
    "build-only")
        build_image
        push_image
        ;;
    "deploy-only")
        deploy_k8s
        check_status
        ;;
    "deploy"|*)
        main
        ;;
esac
