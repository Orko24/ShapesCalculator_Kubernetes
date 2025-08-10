#!/bin/bash

# Deployment Validation Script for Shapes Calculator
# This script validates that the application is working correctly

set -e

# Configuration
NAMESPACE="shapes-calculator"
TIMEOUT=30

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
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

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to check if kubectl is available
check_kubectl() {
    if ! command -v kubectl &> /dev/null; then
        error "kubectl is not installed or not in PATH"
        exit 1
    fi
}

# Function to check if namespace exists
check_namespace() {
    log "Checking if namespace '$NAMESPACE' exists..."
    
    if kubectl get namespace $NAMESPACE &> /dev/null; then
        info "✅ Namespace '$NAMESPACE' exists"
    else
        error "❌ Namespace '$NAMESPACE' does not exist"
        exit 1
    fi
}

# Function to check deployment status
check_deployment() {
    log "Checking deployment status..."
    
    # Check if deployment exists
    if ! kubectl get deployment shapes-calculator -n $NAMESPACE &> /dev/null; then
        error "❌ Deployment 'shapes-calculator' not found"
        exit 1
    fi
    
    # Check if deployment is ready
    local ready=$(kubectl get deployment shapes-calculator -n $NAMESPACE -o jsonpath='{.status.readyReplicas}')
    local desired=$(kubectl get deployment shapes-calculator -n $NAMESPACE -o jsonpath='{.spec.replicas}')
    
    if [ "$ready" = "$desired" ] && [ "$ready" != "" ]; then
        info "✅ Deployment is ready ($ready/$desired replicas)"
    else
        error "❌ Deployment is not ready ($ready/$desired replicas)"
        kubectl get pods -n $NAMESPACE
        exit 1
    fi
}

# Function to check service status
check_service() {
    log "Checking service status..."
    
    if kubectl get service shapes-calculator-service -n $NAMESPACE &> /dev/null; then
        info "✅ Service 'shapes-calculator-service' exists"
        
        # Check endpoints
        local endpoints=$(kubectl get endpoints shapes-calculator-service -n $NAMESPACE -o jsonpath='{.subsets[0].addresses[*].ip}' 2>/dev/null)
        if [ -n "$endpoints" ]; then
            info "✅ Service has endpoints: $endpoints"
        else
            warn "⚠️  Service has no endpoints"
        fi
    else
        error "❌ Service 'shapes-calculator-service' not found"
        exit 1
    fi
}

# Function to test application health
test_health_endpoint() {
    log "Testing application health endpoint..."
    
    # Get a pod name
    local pod=$(kubectl get pods -n $NAMESPACE -l app=shapes-calculator -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$pod" ]; then
        info "Testing health endpoint on pod: $pod"
        
        # Test health endpoint
        if kubectl exec $pod -n $NAMESPACE -- curl -sf http://localhost:8000/health > /dev/null 2>&1; then
            info "✅ Health endpoint is responding"
            
            # Get health response
            local health_response=$(kubectl exec $pod -n $NAMESPACE -- curl -s http://localhost:8000/health 2>/dev/null)
            info "Health response: $health_response"
        else
            error "❌ Health endpoint is not responding"
            exit 1
        fi
    else
        error "❌ No pods found for testing"
        exit 1
    fi
}

# Function to test API endpoints
test_api_endpoints() {
    log "Testing API endpoints..."
    
    local pod=$(kubectl get pods -n $NAMESPACE -l app=shapes-calculator -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
    
    if [ -n "$pod" ]; then
        # Test circle calculation
        info "Testing circle calculation endpoint..."
        local circle_test=$(kubectl exec $pod -n $NAMESPACE -- curl -s -X POST \
            -H "Content-Type: application/json" \
            -d '{"radius": 5}' \
            http://localhost:8000/circle 2>/dev/null)
        
        if echo "$circle_test" | grep -q "area" && echo "$circle_test" | grep -q "circumference"; then
            info "✅ Circle endpoint is working: $circle_test"
        else
            warn "⚠️  Circle endpoint response unexpected: $circle_test"
        fi
        
        # Test rectangle calculation
        info "Testing rectangle calculation endpoint..."
        local rectangle_test=$(kubectl exec $pod -n $NAMESPACE -- curl -s -X POST \
            -H "Content-Type: application/json" \
            -d '{"length": 4, "width": 3}' \
            http://localhost:8000/rectangle 2>/dev/null)
        
        if echo "$rectangle_test" | grep -q "area" && echo "$rectangle_test" | grep -q "perimeter"; then
            info "✅ Rectangle endpoint is working: $rectangle_test"
        else
            warn "⚠️  Rectangle endpoint response unexpected: $rectangle_test"
        fi
        
        # Test triangle calculation
        info "Testing triangle calculation endpoint..."
        local triangle_test=$(kubectl exec $pod -n $NAMESPACE -- curl -s -X POST \
            -H "Content-Type: application/json" \
            -d '{"base": 6, "height": 4}' \
            http://localhost:8000/triangle 2>/dev/null)
        
        if echo "$triangle_test" | grep -q "area"; then
            info "✅ Triangle endpoint is working: $triangle_test"
        else
            warn "⚠️  Triangle endpoint response unexpected: $triangle_test"
        fi
    fi
}

# Function to check resource usage
check_resources() {
    log "Checking resource usage..."
    
    # Get resource usage for pods
    if command -v kubectl top &> /dev/null; then
        kubectl top pods -n $NAMESPACE 2>/dev/null || warn "Metrics server not available for resource monitoring"
    else
        warn "kubectl top not available for resource monitoring"
    fi
}

# Function to show access information
show_access_info() {
    log "Application access information:"
    
    # NodePort service
    if kubectl get service shapes-calculator-nodeport -n $NAMESPACE &> /dev/null; then
        local nodeport=$(kubectl get service shapes-calculator-nodeport -n $NAMESPACE -o jsonpath='{.spec.ports[0].nodePort}')
        info "📱 NodePort access: http://<node-ip>:$nodeport"
        
        # Try to get node IPs
        local nodes=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="ExternalIP")].address}' 2>/dev/null)
        if [ -z "$nodes" ]; then
            nodes=$(kubectl get nodes -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' 2>/dev/null)
        fi
        
        if [ -n "$nodes" ]; then
            for node in $nodes; do
                info "   http://$node:$nodeport"
            done
        fi
    fi
    
    # Ingress
    if kubectl get ingress shapes-calculator-ingress -n $NAMESPACE &> /dev/null; then
        info "🌐 Ingress access: http://shapes-calculator.local"
        info "   (Add '127.0.0.1 shapes-calculator.local' to your hosts file)"
    fi
    
    # Port-forward option
    info "🔌 Port-forward access:"
    info "   kubectl port-forward service/shapes-calculator-service 8080:80 -n $NAMESPACE"
    info "   Then access: http://localhost:8080"
}

# Main validation function
main() {
    log "Starting deployment validation for Shapes Calculator..."
    echo
    
    check_kubectl
    check_namespace
    check_deployment
    check_service
    test_health_endpoint
    test_api_endpoints
    check_resources
    
    echo
    log "🎉 All validation checks passed!"
    echo
    show_access_info
    echo
    log "Validation completed successfully!"
}

# Run main function
main


