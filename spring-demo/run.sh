#!/bin/bash

# Spring Boot ELK Demo - Build and Run Script
# This script builds and runs the Spring Boot application with ELK Stack integration

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="elk-spring-demo"
DOCKER_IMAGE="elk-spring-demo:latest"
JAR_FILE="target/elk-spring-demo-0.0.1-SNAPSHOT.jar"

# Functions
print_banner() {
    echo -e "${BLUE}"
    echo "=================================================="
    echo "    Spring Boot ELK Demo - Build & Run Script"
    echo "=================================================="
    echo -e "${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."

    if ! command -v java &> /dev/null; then
        print_error "Java 21 is required but not installed"
        exit 1
    fi

    JAVA_VERSION=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1)
    if [ "$JAVA_VERSION" -lt 21 ]; then
        print_error "Java 21 or higher is required. Found Java $JAVA_VERSION"
        exit 1
    fi

    if ! command -v mvn &> /dev/null; then
        print_error "Maven is required but not installed"
        exit 1
    fi

    if ! command -v docker &> /dev/null; then
        print_warning "Docker not found. Docker-related features will be skipped"
    fi

    print_success "Prerequisites check completed"
}

# Clean previous builds
clean_build() {
    print_info "Cleaning previous builds..."

    if [ -d "target" ]; then
        rm -rf target
        print_success "Cleaned target directory"
    fi

    if [ -d "logs" ]; then
        rm -rf logs/*
        print_success "Cleaned logs directory"
    else
        mkdir -p logs
        print_success "Created logs directory"
    fi
}

# Build application
build_app() {
    print_info "Building Spring Boot application..."

    mvn clean package -DskipTests

    if [ -f "$JAR_FILE" ]; then
        print_success "Application built successfully: $JAR_FILE"
    else
        print_error "Build failed - JAR file not found"
        exit 1
    fi
}

# Run tests
run_tests() {
    print_info "Running tests..."
    mvn test
    print_success "Tests completed"
}

# Build Docker image
build_docker() {
    if command -v docker &> /dev/null; then
        print_info "Building Docker image..."
        docker build -t $DOCKER_IMAGE .
        print_success "Docker image built: $DOCKER_IMAGE"
    else
        print_warning "Docker not available, skipping Docker build"
    fi
}

# Run application locally
run_local() {
    print_info "Starting Spring Boot application locally..."
    print_info "Application will be available at: http://localhost:8080"
    print_info "Health check: http://localhost:8080/actuator/health"
    print_info "H2 Console: http://localhost:8080/h2-console"
    print_info "Press Ctrl+C to stop the application"

    java -jar $JAR_FILE
}

# Run with Docker Compose
run_docker() {
    if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
        print_info "Starting application with Docker Compose..."

        # Create network if it doesn't exist
        docker network create elk-network 2>/dev/null || true

        docker-compose up -d
        print_success "Application started with Docker Compose"
        print_info "Application URL: http://localhost:8080"
        print_info "View logs: docker-compose logs -f spring-demo"
    else
        print_error "Docker or Docker Compose not available"
        exit 1
    fi
}

# Generate sample logs
generate_logs() {
    print_info "Generating sample logs..."

    # Wait for application to start
    sleep 5

    # Generate different types of logs
    curl -s "http://localhost:8080/api/hello?name=TestUser" > /dev/null
    curl -s "http://localhost:8080/api/generate-logs?count=20&logLevel=all" > /dev/null
    curl -s -X POST "http://localhost:8080/api/simulate-error" \
         -H "Content-Type: application/json" \
         -d '{"errorType":"runtime"}' > /dev/null
    curl -s "http://localhost:8080/api/health" > /dev/null

    print_success "Sample logs generated"
}

# Show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  build           Build the application (clean + compile + package)"
    echo "  test            Run tests"
    echo "  run             Run application locally"
    echo "  docker-build    Build Docker image"
    echo "  docker-run      Run with Docker Compose"
    echo "  full-build      Complete build (clean + test + build + docker-build)"
    echo "  setup           Complete setup and run locally"
    echo "  docker-setup    Complete setup and run with Docker"
    echo "  logs            Generate sample logs (application must be running)"
    echo "  clean           Clean build artifacts"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 setup           # Build and run locally"
    echo "  $0 docker-setup    # Build and run with Docker"
    echo "  $0 logs            # Generate sample logs"
}

# Main script logic
main() {
    print_banner

    case "${1:-setup}" in
        "build")
            check_prerequisites
            clean_build
            build_app
            ;;
        "test")
            check_prerequisites
            run_tests
            ;;
        "run")
            check_prerequisites
            if [ ! -f "$JAR_FILE" ]; then
                print_warning "JAR file not found. Building application first..."
                build_app
            fi
            run_local
            ;;
        "docker-build")
            check_prerequisites
            if [ ! -f "$JAR_FILE" ]; then
                build_app
            fi
            build_docker
            ;;
        "docker-run")
            run_docker
            ;;
        "full-build")
            check_prerequisites
            clean_build
            run_tests
            build_app
            build_docker
            ;;
        "setup")
            check_prerequisites
            clean_build
            build_app
            print_success "Setup completed. Starting application..."
            run_local
            ;;
        "docker-setup")
            check_prerequisites
            clean_build
            build_app
            build_docker
            run_docker
            ;;
        "logs")
            generate_logs
            ;;
        "clean")
            clean_build
            ;;
        "help"|"--help"|"-h")
            show_usage
            ;;
        *)
            print_error "Unknown command: $1"
            show_usage
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
