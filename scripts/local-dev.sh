#!/bin/bash

# Local Development Script for Shapes Calculator
# This script handles local Docker Compose operations

set -e

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

# Function to start development environment
start_dev() {
    log "Starting development environment..."
    
    # Check if Docker and Docker Compose are available
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed or not in PATH"
        exit 1
    fi
    
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        error "Docker Compose is not installed or not in PATH"
        exit 1
    fi
    
    # Build and start services
    log "Building and starting services..."
    docker-compose up --build -d
    
    if [ $? -eq 0 ]; then
        log "Development environment started successfully"
        show_status
    else
        error "Failed to start development environment"
        exit 1
    fi
}

# Function to start production-like environment with nginx
start_prod() {
    log "Starting production-like environment with nginx..."
    
    docker-compose --profile production up --build -d
    
    if [ $? -eq 0 ]; then
        log "Production environment started successfully"
        show_status
    else
        error "Failed to start production environment"
        exit 1
    fi
}

# Function to stop development environment
stop_dev() {
    log "Stopping development environment..."
    
    docker-compose down
    
    if [ $? -eq 0 ]; then
        log "Development environment stopped successfully"
    else
        error "Failed to stop development environment"
        exit 1
    fi
}

# Function to show logs
show_logs() {
    local service="${1:-}"
    
    if [ -n "$service" ]; then
        log "Showing logs for service: $service"
        docker-compose logs -f "$service"
    else
        log "Showing logs for all services..."
        docker-compose logs -f
    fi
}

# Function to show status
show_status() {
    log "Service status:"
    docker-compose ps
    
    echo
    info "Application URLs:"
    info "  - Main application: http://localhost:8000"
    info "  - API health check: http://localhost:8000/health"
    info "  - Circle calculator: http://localhost:8000/circle-page"
    info "  - Rectangle calculator: http://localhost:8000/rectangle-page"
    info "  - Triangle calculator: http://localhost:8000/triangle-page"
    
    # Check if nginx is running (production profile)
    if docker-compose ps | grep -q nginx; then
        info "  - Nginx frontend: http://localhost"
    fi
    
    echo
    info "Useful commands:"
    info "  - View logs: ./scripts/local-dev.sh logs [service-name]"
    info "  - Stop services: ./scripts/local-dev.sh stop"
    info "  - Restart services: ./scripts/local-dev.sh restart"
    info "  - Clean up: ./scripts/local-dev.sh clean"
}

# Function to restart services
restart_dev() {
    log "Restarting development environment..."
    
    docker-compose restart
    
    if [ $? -eq 0 ]; then
        log "Development environment restarted successfully"
        show_status
    else
        error "Failed to restart development environment"
        exit 1
    fi
}

# Function to clean up everything
clean_up() {
    warn "This will remove all containers, networks, and images related to this project"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Cleaning up development environment..."
        
        # Stop and remove containers, networks, and volumes
        docker-compose down -v --remove-orphans
        
        # Remove images
        docker rmi $(docker images shapes-calculator* -q) 2>/dev/null || true
        
        log "Cleanup completed"
    else
        log "Cleanup cancelled"
    fi
}

# Function to run tests inside container
run_tests() {
    log "Running tests..."
    
    if docker-compose ps | grep -q shapes-calculator-app; then
        docker-compose exec shapes-calculator python -m pytest tests/ -v
    else
        error "Application container is not running. Start it first with: ./scripts/local-dev.sh start"
        exit 1
    fi
}

# Function to enter container shell
shell() {
    log "Opening shell in application container..."
    
    if docker-compose ps | grep -q shapes-calculator-app; then
        docker-compose exec shapes-calculator /bin/bash
    else
        error "Application container is not running. Start it first with: ./scripts/local-dev.sh start"
        exit 1
    fi
}

# Show usage information
show_usage() {
    echo "Usage: $0 <command> [options]"
    echo
    echo "Commands:"
    echo "  start         Start development environment"
    echo "  start-prod    Start production-like environment with nginx"
    echo "  stop          Stop development environment"
    echo "  restart       Restart development environment"
    echo "  status        Show service status and URLs"
    echo "  logs [service] Show logs (optionally for specific service)"
    echo "  test          Run tests inside container"
    echo "  shell         Open shell in application container"
    echo "  clean         Clean up all containers, networks, and images"
    echo "  help          Show this help message"
    echo
    echo "Examples:"
    echo "  $0 start                  # Start development environment"
    echo "  $0 logs shapes-calculator # Show logs for main service"
    echo "  $0 status                 # Show current status"
}

# Main command handling
case "${1:-help}" in
    "start")
        start_dev
        ;;
    "start-prod")
        start_prod
        ;;
    "stop")
        stop_dev
        ;;
    "restart")
        restart_dev
        ;;
    "status")
        show_status
        ;;
    "logs")
        show_logs "$2"
        ;;
    "test")
        run_tests
        ;;
    "shell")
        shell
        ;;
    "clean")
        clean_up
        ;;
    "help"|*)
        show_usage
        ;;
esac
