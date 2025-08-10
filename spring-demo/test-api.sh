#!/bin/bash

# Spring Boot ELK Demo - API Test Script
# This script tests various API endpoints and generates different types of logs

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

BASE_URL="http://localhost:8080"

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if application is running
check_app() {
    print_info "Checking if Spring Boot application is running..."

    if curl -s "$BASE_URL/actuator/health" > /dev/null; then
        print_success "Application is running"
    else
        print_error "Application is not running. Please start it first with: ./run.sh"
        exit 1
    fi
}

# Test basic endpoints
test_basic_endpoints() {
    print_info "Testing basic endpoints..."

    # Test hello endpoint
    print_info "Testing /api/hello endpoint..."
    response=$(curl -s "$BASE_URL/api/hello?name=ELKDemo")
    echo "Response: $response"
    print_success "Hello endpoint test completed"

    # Test health endpoint
    print_info "Testing /api/health endpoint..."
    response=$(curl -s "$BASE_URL/api/health")
    echo "Response: $response"
    print_success "Health endpoint test completed"
}

# Test error simulation
test_error_simulation() {
    print_info "Testing error simulation endpoints..."

    # Runtime error
    print_info "Testing runtime error simulation..."
    response=$(curl -s -X POST "$BASE_URL/api/simulate-error" \
                   -H "Content-Type: application/json" \
                   -d '{"errorType":"runtime"}')
    echo "Response: $response"

    # Validation error
    print_info "Testing validation error simulation..."
    response=$(curl -s -X POST "$BASE_URL/api/simulate-error" \
                   -H "Content-Type: application/json" \
                   -d '{"errorType":"validation"}')
    echo "Response: $response"

    # Database error
    print_info "Testing database error simulation..."
    response=$(curl -s -X POST "$BASE_URL/api/simulate-error" \
                   -H "Content-Type: application/json" \
                   -d '{"errorType":"database"}')
    echo "Response: $response"

    print_success "Error simulation tests completed"
}

# Test log generation
test_log_generation() {
    print_info "Testing log generation endpoints..."

    # Generate DEBUG logs
    print_info "Generating DEBUG logs..."
    response=$(curl -s "$BASE_URL/api/generate-logs?count=10&logLevel=debug")
    echo "Response: $response"

    # Generate INFO logs
    print_info "Generating INFO logs..."
    response=$(curl -s "$BASE_URL/api/generate-logs?count=15&logLevel=info")
    echo "Response: $response"

    # Generate WARN logs
    print_info "Generating WARN logs..."
    response=$(curl -s "$BASE_URL/api/generate-logs?count=8&logLevel=warn")
    echo "Response: $response"

    # Generate ERROR logs
    print_info "Generating ERROR logs..."
    response=$(curl -s "$BASE_URL/api/generate-logs?count=5&logLevel=error")
    echo "Response: $response"

    # Generate mixed logs
    print_info "Generating mixed level logs..."
    response=$(curl -s "$BASE_URL/api/generate-logs?count=25&logLevel=all")
    echo "Response: $response"

    print_success "Log generation tests completed"
}

# Load test
load_test() {
    print_info "Running load test..."

    for i in {1..20}; do
        curl -s "$BASE_URL/api/hello?name=User$i" > /dev/null &
        if [ $((i % 5)) -eq 0 ]; then
            curl -s -X POST "$BASE_URL/api/simulate-error" \
                 -H "Content-Type: application/json" \
                 -d '{"errorType":"validation"}' > /dev/null &
        fi
    done

    wait
    print_success "Load test completed"
}

# Generate continuous logs
continuous_logs() {
    print_info "Starting continuous log generation (Press Ctrl+C to stop)..."

    while true; do
        # Random user
        USER_ID=$((RANDOM % 100))

        # Random endpoint call
        ENDPOINT_CHOICE=$((RANDOM % 4))

        case $ENDPOINT_CHOICE in
            0)
                curl -s "$BASE_URL/api/hello?name=User$USER_ID" > /dev/null
                ;;
            1)
                curl -s "$BASE_URL/api/health" > /dev/null
                ;;
            2)
                curl -s "$BASE_URL/api/generate-logs?count=5&logLevel=all" > /dev/null
                ;;
            3)
                ERROR_TYPES=("runtime" "validation" "database")
                ERROR_TYPE=${ERROR_TYPES[$((RANDOM % 3))]}
                curl -s -X POST "$BASE_URL/api/simulate-error" \
                     -H "Content-Type: application/json" \
                     -d "{\"errorType\":\"$ERROR_TYPE\"}" > /dev/null
                ;;
        esac

        # Random sleep between 1-5 seconds
        sleep $((RANDOM % 5 + 1))
    done
}

# Show usage
show_usage() {
    echo "Usage: $0 [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  basic           Test basic endpoints"
    echo "  errors          Test error simulation"
    echo "  logs            Test log generation"
    echo "  load            Run load test"
    echo "  continuous      Generate continuous logs (Ctrl+C to stop)"
    echo "  all             Run all tests"
    echo "  help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 all           # Run all tests"
    echo "  $0 continuous    # Generate continuous logs"
    echo "  $0 logs          # Test log generation only"
}

# Main script logic
main() {
    echo -e "${BLUE}"
    echo "=================================================="
    echo "    Spring Boot ELK Demo - API Test Script"
    echo "=================================================="
    echo -e "${NC}"

    case "${1:-all}" in
        "basic")
            check_app
            test_basic_endpoints
            ;;
        "errors")
            check_app
            test_error_simulation
            ;;
        "logs")
            check_app
            test_log_generation
            ;;
        "load")
            check_app
            load_test
            ;;
        "continuous")
            check_app
            continuous_logs
            ;;
        "all")
            check_app
            test_basic_endpoints
            test_error_simulation
            test_log_generation
            load_test
            print_success "All tests completed successfully!"
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
