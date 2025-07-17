#!/bin/bash
# Service Dependency Manager
# Handles proper startup sequence and dependency management for foundation tests

set -e

# Colors for output (copied from common.sh to avoid circular dependency)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions (standalone versions)
log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Load environment variables from .env file
if [ -f ".env" ]; then
    export $(grep -v '^#' .env | grep -v '^$' | xargs)
    log_info "Loaded environment variables from .env"
else
    log_warning ".env file not found - using system defaults"
fi

# Service configuration (use .env values if available, fallback to defaults)
POSTGRES_PORT="${DB_PORT:-5432}"
HTTP_SERVER_PORT="${PORT:-3000}"
WEB_INTERFACE_PORT="${WEB_INTERFACE_PORT:-3002}"
VISUALIZATION_PORT="${VISUALIZATION_PORT:-3003}"

# Service status tracking
declare -A SERVICE_PIDS
declare -A SERVICE_STATUS
declare -A SERVICE_DEPENDENCIES

# Define service dependencies
SERVICE_DEPENDENCIES[database]=""  # No dependencies
SERVICE_DEPENDENCIES[http_server]="database"
SERVICE_DEPENDENCIES[web_interface]=""  # Isolated service
SERVICE_DEPENDENCIES[visualization]=""  # Isolated service
SERVICE_DEPENDENCIES[user_management]="database http_server"

# Check if a service is running on a specific port
is_service_running() {
    local port="$1"
    local service_name="$2"
    
    if command -v netstat >/dev/null 2>&1; then
        if netstat -tlnp 2>/dev/null | grep -q ":${port} "; then
            return 0
        fi
    elif command -v lsof >/dev/null 2>&1; then
        if lsof -ti:${port} 2>/dev/null | head -1 >/dev/null; then
            return 0
        fi
    elif command -v ss >/dev/null 2>&1; then
        if ss -tlnp 2>/dev/null | grep -q ":${port} "; then
            return 0
        fi
    fi
    
    # Also check if service responds to health check
    case "$service_name" in
        "http_server")
            curl -s -f "http://localhost:${port}/health" >/dev/null 2>&1 && return 0
            ;;
        "web_interface")
            curl -s -f "http://localhost:${port}/health" >/dev/null 2>&1 && return 0
            ;;
        "visualization")
            curl -s -f "http://localhost:${port}/health" >/dev/null 2>&1 && return 0
            ;;
        "database")
            if command -v docker-compose >/dev/null 2>&1; then
                docker-compose exec -T postgres pg_isready -U "${DB_USER:-postgres}" >/dev/null 2>&1 && return 0
            fi
            ;;
    esac
    
    return 1
}

# Get PID of service running on port
get_service_pid() {
    local port="$1"
    
    if command -v netstat >/dev/null 2>&1; then
        netstat -tlnp 2>/dev/null | grep ":$port " | awk '{print $7}' | cut -d'/' -f1 | head -1
    elif command -v lsof >/dev/null 2>&1; then
        lsof -ti:$port 2>/dev/null | head -1
    elif command -v ss >/dev/null 2>&1; then
        ss -tlnp 2>/dev/null | grep ":$port " | sed 's/.*pid=\([0-9]*\).*/\1/' | head -1
    fi
}

# Wait for service to be ready
wait_for_service() {
    local service_name="$1"
    local port="$2"
    local max_retries="${3:-30}"
    local health_endpoint="$4"
    
    log_info "Waiting for $service_name to be ready on port $port..."
    
    local retries=$max_retries
    while [ $retries -gt 0 ]; do
        case "$service_name" in
            "database")
                if command -v docker-compose >/dev/null 2>&1; then
                    if docker-compose exec -T postgres pg_isready -U "${DB_USER:-postgres}" >/dev/null 2>&1; then
                        log_success "$service_name is ready"
                        return 0
                    fi
                fi
                ;;
            "http_server"|"web_interface"|"visualization")
                if [ -n "$health_endpoint" ]; then
                    if curl -s -f "http://localhost:${port}${health_endpoint}" >/dev/null 2>&1; then
                        log_success "$service_name is ready"
                        return 0
                    fi
                else
                    if is_service_running "$port" "$service_name"; then
                        log_success "$service_name is ready"
                        return 0
                    fi
                fi
                ;;
            *)
                if is_service_running "$port" "$service_name"; then
                    log_success "$service_name is ready"
                    return 0
                fi
                ;;
        esac
        
        retries=$((retries - 1))
        sleep 1
    done
    
    log_error "$service_name failed to become ready within $max_retries seconds"
    return 1
}

# Start database service
start_database() {
    log_info "Starting database service..."
    
    # Check if already running
    if is_service_running "$POSTGRES_PORT" "database"; then
        log_info "Database already running - verifying health..."
        if wait_for_service "database" "$POSTGRES_PORT" 5; then
            SERVICE_STATUS[database]="running"
            return 0
        else
            log_warning "Database port in use but not healthy - attempting restart"
        fi
    fi
    
    # Check for docker-compose
    if ! command -v docker-compose >/dev/null 2>&1; then
        log_error "docker-compose not available - cannot start database"
        return 1
    fi
    
    if [ ! -f "docker-compose.yml" ]; then
        log_error "docker-compose.yml not found - cannot start database"
        return 1
    fi
    
    # Start PostgreSQL container
    log_info "Starting PostgreSQL container..."
    if docker-compose up -d postgres >/dev/null 2>&1; then
        if wait_for_service "database" "$POSTGRES_PORT" 60; then
            SERVICE_STATUS[database]="running"
            log_success "Database service started successfully"
            return 0
        else
            log_error "Database service failed to become ready"
            SERVICE_STATUS[database]="failed"
            return 1
        fi
    else
        log_error "Failed to start PostgreSQL container"
        SERVICE_STATUS[database]="failed"
        return 1
    fi
}

# Start HTTP server
start_http_server() {
    log_info "Starting HTTP server..."
    
    # Check dependencies
    if [ "${SERVICE_STATUS[database]}" != "running" ]; then
        log_error "HTTP server requires database to be running"
        return 1
    fi
    
    # Check if already running
    if is_service_running "$HTTP_SERVER_PORT" "http_server"; then
        log_info "HTTP server already running - verifying health..."
        if wait_for_service "http_server" "$HTTP_SERVER_PORT" 5 "/health"; then
            SERVICE_STATUS[http_server]="running"
            return 0
        else
            log_warning "HTTP server port in use but not healthy - attempting restart"
            stop_service_by_port "HTTP Server" "$HTTP_SERVER_PORT"
        fi
    fi
    
    # Check for server files
    if [ ! -f "src/index.js" ]; then
        log_error "HTTP server files not found at src/index.js"
        SERVICE_STATUS[http_server]="failed"
        return 1
    fi
    
    # Start server (environment already loaded from .env)
    log_info "Starting HTTP server on port $HTTP_SERVER_PORT with NODE_ENV=$NODE_ENV, LOG_LEVEL=$LOG_LEVEL..."
    node src/index.js > http_server_service.log 2>&1 &
    local server_pid=$!
    SERVICE_PIDS[http_server]=$server_pid
    
    if wait_for_service "http_server" "$HTTP_SERVER_PORT" 30 "/health"; then
        SERVICE_STATUS[http_server]="running"
        log_success "HTTP server started successfully (PID: $server_pid)"
        return 0
    else
        log_error "HTTP server failed to start or become ready"
        if [ -f http_server_service.log ]; then
            log_error "Server logs:"
            tail -10 http_server_service.log
        fi
        SERVICE_STATUS[http_server]="failed"
        return 1
    fi
}

# Start web interface
start_web_interface() {
    log_info "Starting web interface..."
    
    # Check if already running
    if is_service_running "$WEB_INTERFACE_PORT" "web_interface"; then
        log_info "Web interface already running - verifying health..."
        if wait_for_service "web_interface" "$WEB_INTERFACE_PORT" 5 "/health"; then
            SERVICE_STATUS[web_interface]="running"
            return 0
        else
            log_warning "Web interface port in use but not healthy - attempting restart"
            stop_service_by_port "Web Interface" "$WEB_INTERFACE_PORT"
        fi
    fi
    
    # Check for web interface files
    if [ ! -f "web-interface/index.js" ]; then
        log_error "Web interface files not found at web-interface/index.js"
        SERVICE_STATUS[web_interface]="failed"
        return 1
    fi
    
    # Check dependencies in web-interface directory
    cd web-interface/ || {
        log_error "Cannot enter web-interface directory"
        SERVICE_STATUS[web_interface]="failed"
        return 1
    }
    
    if [ ! -d "node_modules" ]; then
        log_info "Installing web interface dependencies..."
        if ! npm install > ../web-interface.log 2>&1; then
            log_error "Failed to install web interface dependencies"
            cat ../web-interface.log
            cd ..
            SERVICE_STATUS[web_interface]="failed"
            return 1
        fi
    fi
    
    # Start web interface
    export NODE_ENV=test
    export LOG_LEVEL=ERROR
    export WEB_INTERFACE_PORT=$WEB_INTERFACE_PORT
    
    log_info "Starting web interface on port $WEB_INTERFACE_PORT..."
    node index.js > ../web-interface.log 2>&1 &
    local web_interface_pid=$!
    cd ..
    
    SERVICE_PIDS[web_interface]=$web_interface_pid
    
    if wait_for_service "web_interface" "$WEB_INTERFACE_PORT" 30 "/health"; then
        SERVICE_STATUS[web_interface]="running"
        log_success "Web interface started successfully (PID: $web_interface_pid)"
        return 0
    else
        log_error "Web interface failed to start or become ready"
        if [ -f web-interface.log ]; then
            log_error "Web interface logs:"
            tail -10 web-interface.log
        fi
        SERVICE_STATUS[web_interface]="failed"
        return 1
    fi
}

# Start visualization
start_visualization() {
    log_info "Starting visualization..."
    
    # Check if already running
    if is_service_running "$VISUALIZATION_PORT" "visualization"; then
        log_info "Visualization already running - verifying health..."
        if wait_for_service "visualization" "$VISUALIZATION_PORT" 5 "/health"; then
            SERVICE_STATUS[visualization]="running"
            return 0
        else
            log_warning "Visualization port in use but not healthy - attempting restart"
            stop_service_by_port "Visualization" "$VISUALIZATION_PORT"
        fi
    fi
    
    # Check for visualization files
    if [ ! -f "visualization/index.js" ]; then
        log_error "Visualization files not found at visualization/index.js"
        SERVICE_STATUS[visualization]="failed"
        return 1
    fi
    
    # Check dependencies in visualization directory
    cd visualization/ || {
        log_error "Cannot enter visualization directory"
        SERVICE_STATUS[visualization]="failed"
        return 1
    }
    
    if [ ! -d "node_modules" ]; then
        log_info "Installing visualization dependencies..."
        if ! npm install > ../visualization.log 2>&1; then
            log_error "Failed to install visualization dependencies"
            cat ../visualization.log
            cd ..
            SERVICE_STATUS[visualization]="failed"
            return 1
        fi
    fi
    
    # Start visualization
    export NODE_ENV=test
    export LOG_LEVEL=ERROR
    export VISUALIZATION_PORT=$VISUALIZATION_PORT
    
    log_info "Starting visualization on port $VISUALIZATION_PORT..."
    node index.js > ../visualization.log 2>&1 &
    local visualization_pid=$!
    cd ..
    
    SERVICE_PIDS[visualization]=$visualization_pid
    
    if wait_for_service "visualization" "$VISUALIZATION_PORT" 30 "/health"; then
        SERVICE_STATUS[visualization]="running"
        log_success "Visualization started successfully (PID: $visualization_pid)"
        return 0
    else
        log_error "Visualization failed to start or become ready"
        if [ -f visualization.log ]; then
            log_error "Visualization logs:"
            tail -10 visualization.log
        fi
        SERVICE_STATUS[visualization]="failed"
        return 1
    fi
}

# Stop service by port
stop_service_by_port() {
    local service_name="$1"
    local port="$2"
    
    log_info "Stopping $service_name on port $port..."
    
    local pid=$(get_service_pid "$port")
    if [ -n "$pid" ] && [ "$pid" != "-" ]; then
        # Send SIGTERM for graceful shutdown
        kill -TERM "$pid" 2>/dev/null || true
        
        # Wait for graceful shutdown
        local retries=10
        while [ $retries -gt 0 ] && kill -0 "$pid" 2>/dev/null; do
            retries=$((retries - 1))
            sleep 1
        done
        
        # Force kill if still running
        if kill -0 "$pid" 2>/dev/null; then
            log_warning "$service_name did not stop gracefully, force killing..."
            kill -KILL "$pid" 2>/dev/null || true
        fi
        
        if ! kill -0 "$pid" 2>/dev/null; then
            log_success "$service_name stopped successfully"
        else
            log_error "Failed to stop $service_name"
            return 1
        fi
    else
        log_info "$service_name not running on port $port"
    fi
    
    return 0
}

# Stop all services
stop_all_services() {
    log_info "Stopping all services..."
    
    # Stop services in reverse dependency order
    stop_service_by_port "Visualization" "$VISUALIZATION_PORT"
    stop_service_by_port "Web Interface" "$WEB_INTERFACE_PORT"
    stop_service_by_port "HTTP Server" "$HTTP_SERVER_PORT"
    
    # Stop Docker services
    if command -v docker-compose >/dev/null 2>&1 && [ -f "docker-compose.yml" ]; then
        log_info "Stopping Docker Compose services..."
        if docker-compose down >/dev/null 2>&1; then
            log_success "Docker services stopped"
        else
            log_warning "Failed to stop Docker services"
        fi
    fi
    
    # Reset service status
    SERVICE_STATUS=()
    SERVICE_PIDS=()
    
    log_success "All services stopped"
}

# Ensure service dependencies are met
ensure_service_dependencies() {
    local service="$1"
    local dependencies="${SERVICE_DEPENDENCIES[$service]}"
    
    if [ -z "$dependencies" ]; then
        return 0  # No dependencies
    fi
    
    for dep in $dependencies; do
        if [ "${SERVICE_STATUS[$dep]}" != "running" ]; then
            log_info "Starting dependency: $dep for $service"
            if ! ensure_service "$dep"; then
                log_error "Failed to start dependency $dep for $service"
                return 1
            fi
        fi
    done
    
    return 0
}

# Ensure a specific service is running
ensure_service() {
    local service="$1"
    
    # Check if already running
    if [ "${SERVICE_STATUS[$service]}" == "running" ]; then
        return 0
    fi
    
    # Ensure dependencies are met first
    if ! ensure_service_dependencies "$service"; then
        return 1
    fi
    
    # Start the service
    case "$service" in
        "database")
            start_database
            ;;
        "http_server")
            start_http_server
            ;;
        "web_interface")
            start_web_interface
            ;;
        "visualization")
            start_visualization
            ;;
        *)
            log_error "Unknown service: $service"
            return 1
            ;;
    esac
}

# Service health check
check_service_health() {
    local service="$1"
    
    case "$service" in
        "database")
            is_service_running "$POSTGRES_PORT" "database"
            ;;
        "http_server")
            curl -s -f "http://localhost:$HTTP_SERVER_PORT/health" >/dev/null 2>&1
            ;;
        "web_interface")
            curl -s -f "http://localhost:$WEB_INTERFACE_PORT/health" >/dev/null 2>&1
            ;;
        "visualization")
            curl -s -f "http://localhost:$VISUALIZATION_PORT/health" >/dev/null 2>&1
            ;;
        *)
            return 1
            ;;
    esac
}

# Get service status report
get_service_status() {
    echo "Service Status Report:"
    echo "======================"
    
    for service in database http_server web_interface visualization; do
        local status="UNKNOWN"
        local health="UNKNOWN"
        
        if [ "${SERVICE_STATUS[$service]}" == "running" ]; then
            if check_service_health "$service"; then
                status="RUNNING"
                health="HEALTHY"
            else
                status="RUNNING"
                health="UNHEALTHY"
            fi
        elif [ "${SERVICE_STATUS[$service]}" == "failed" ]; then
            status="FAILED"
            health="N/A"
        else
            status="STOPPED"
            health="N/A"
        fi
        
        echo "  $service: $status ($health)"
    done
    echo ""
}

# Initialize service manager
init_service_manager() {
    log_info "Initializing service manager..."
    
    # Initialize service status
    SERVICE_STATUS[database]="unknown"
    SERVICE_STATUS[http_server]="unknown"
    SERVICE_STATUS[web_interface]="unknown"
    SERVICE_STATUS[visualization]="unknown"
    
    # Check current service states
    if is_service_running "$POSTGRES_PORT" "database"; then
        if check_service_health "database"; then
            SERVICE_STATUS[database]="running"
            log_info "Database already running and healthy"
        else
            SERVICE_STATUS[database]="failed"
            log_warning "Database port in use but unhealthy"
        fi
    fi
    
    if is_service_running "$HTTP_SERVER_PORT" "http_server"; then
        if check_service_health "http_server"; then
            SERVICE_STATUS[http_server]="running"
            log_info "HTTP server already running and healthy"
        else
            SERVICE_STATUS[http_server]="failed"
            log_warning "HTTP server port in use but unhealthy"
        fi
    fi
    
    if is_service_running "$WEB_INTERFACE_PORT" "web_interface"; then
        if check_service_health "web_interface"; then
            SERVICE_STATUS[web_interface]="running"
            log_info "Web interface already running and healthy"
        else
            SERVICE_STATUS[web_interface]="failed"
            log_warning "Web interface port in use but unhealthy"
        fi
    fi
    
    if is_service_running "$VISUALIZATION_PORT" "visualization"; then
        if check_service_health "visualization"; then
            SERVICE_STATUS[visualization]="running"
            log_info "Visualization already running and healthy"
        else
            SERVICE_STATUS[visualization]="failed"
            log_warning "Visualization port in use but unhealthy"
        fi
    fi
    
    log_info "Service manager initialized"
}

# Ensure foundation test dependencies
# Usage: ensure_foundation_dependencies "database" "http_server"
ensure_foundation_dependencies() {
    local required_services=("$@")
    
    if [ ${#required_services[@]} -eq 0 ]; then
        log_error "Usage: ensure_foundation_dependencies <service1> [service2] ..."
        return 1
    fi
    
    log_info "Ensuring foundation test dependencies: ${required_services[*]}"
    
    # Initialize service manager if not already done
    init_service_manager
    
    # Ensure each required service
    local failed_services=()
    for service in "${required_services[@]}"; do
        log_info "Checking service: $service"
        if ! ensure_service "$service"; then
            failed_services+=("$service")
        fi
    done
    
    # Report results
    if [ ${#failed_services[@]} -eq 0 ]; then
        log_success "All foundation dependencies ready: ${required_services[*]}"
        return 0
    else
        log_error "Failed to start required services: ${failed_services[*]}"
        log_error "Foundation test cannot proceed without these dependencies"
        return 1
    fi
}

# Main service management commands
# Only execute command handling if script is run directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-}" in
        "start")
            shift
            if [ $# -eq 0 ]; then
                log_error "Usage: $0 start <service>"
                exit 1
            fi
            init_service_manager
            ensure_service "$1"
            ;;
        "stop")
            shift
            if [ $# -eq 0 ]; then
                stop_all_services
            else
                stop_service_by_port "$1" "${2:-}"
            fi
            ;;
        "status")
            init_service_manager
            get_service_status
            ;;
        "health")
            shift
            if [ $# -eq 0 ]; then
                init_service_manager
                get_service_status
            else
                init_service_manager
                check_service_health "$1"
            fi
            ;;
        "restart")
            shift
            if [ $# -eq 0 ]; then
                stop_all_services
                sleep 2
                init_service_manager
                ensure_service "database"
                ensure_service "http_server"
            else
                stop_service_by_port "$1" "${2:-}"
                sleep 2
                init_service_manager
                ensure_service "$1"
            fi
            ;;
        *)
            echo "Service Dependency Manager"
            echo "=========================="
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  start <service>    Start a specific service"
            echo "  stop [service]     Stop a service or all services"
            echo "  status             Show service status"
            echo "  health [service]   Check service health"
            echo "  restart [service]  Restart a service or all services"
            echo ""
            echo "Services:"
            echo "  database           PostgreSQL database"
            echo "  http_server        Main HTTP server (port 3000)"
            echo "  web_interface      Web dashboard interface (port 3002)"
            echo "  visualization      Real-time visualization service (port 3003)"
            echo ""
            exit 1
            ;;
    esac
fi