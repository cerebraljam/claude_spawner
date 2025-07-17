#!/bin/bash
# Common utilities for foundation tests
# Provides logging, state management, and file tracking
#
# New Features for Detailed Error Capture:
# - Captures detailed output from failing tests automatically
# - Adds captured output to bug-tracker.md for easier debugging
# - Enhanced test functions provide verbose error information
# - Use run_test_with_capture() for individual test execution with capture
# - Use run_command_with_capture() for command execution with capture

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
STATE_FILE="foundation-test-state.json"
RESULTS_FILE="foundation-test-results.md"
BUG_TRACKER_FILE="bug-tracker.md"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

VERBOSE=false

# Test output capture variables
TEST_OUTPUT_BUFFER=""
CURRENT_TEST_NAME=""

# Initialize state file if it doesn't exist
init_state_file() {
    if [ ! -f "$STATE_FILE" ]; then
        echo "{}" > "$STATE_FILE"
    fi
}

# Logging functions
log_success() {
    if [ "$QUIET_MODE" = true ]; then
        # In quiet mode: only write to file, no console output
        echo -e "${GREEN}✅ $1${NC}" >> "$RESULTS_FILE"
    else
        # Normal mode: show on console and write to file
        echo -e "${GREEN}✅ $1${NC}" | tee -a "$RESULTS_FILE"
    fi
}

log_error() {
    # Always show errors (both quiet and normal mode)
    echo -e "${RED}❌ $1${NC}" | tee -a "$RESULTS_FILE"
}

log_warning() {
    # Always show warnings (both quiet and normal mode)
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$RESULTS_FILE"
}

log_info() {
    if [ "$VERBOSE" = true ] && [ "$QUIET_MODE" != true ]; then
        echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$RESULTS_FILE"
    elif [ "$QUIET_MODE" != true ]; then
        # In normal mode but not verbose, still log to file only
        echo -e "${BLUE}ℹ️  $1${NC}" >> "$RESULTS_FILE"
    fi
    return 0
}

# Foundation test print functions for compatibility
print_header() {
    # Always show headers (test identification) regardless of quiet mode
    echo -e "${BLUE}[FOUNDATION TEST 015]${NC} $1"
}

print_test() {
    # Always show test step names regardless of quiet mode
    echo -e "${BLUE}[FOUNDATION TEST 015]${NC} $1"
}

print_success() {
    if [ "$QUIET_MODE" != true ]; then
        echo -e "${GREEN}✅ $1${NC}"
    fi
}

print_error() {
    # Always show errors regardless of quiet mode
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    if [ "$QUIET_MODE" != true ]; then
        echo -e "${BLUE}ℹ️  $1${NC}"
    fi
}

# Calculate checksum of tracked files
calculate_files_checksum() {
    local files=("$@")
    local checksum=""
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            checksum="${checksum}$(md5sum "$file" | cut -d' ' -f1)"
        elif [ -d "$file" ]; then
            # For directories, checksum all files recursively
            checksum="${checksum}$(find "$file" -type f -exec md5sum {} \; | sort | md5sum | cut -d' ' -f1)"
        fi
    done
    
    echo "$checksum" | md5sum | cut -d' ' -f1
}

# Get newest modification time among tracked files
get_newest_file_time() {
    local files=("$@")
    local newest=0
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            file_time=$(stat -c %Y "$file" 2>/dev/null || echo 0)
        elif [ -d "$file" ]; then
            # For directories, find newest file inside
            file_time=$(find "$file" -type f -printf '%T@\n' 2>/dev/null | sort -n | tail -1 | cut -d. -f1)
            [ -z "$file_time" ] && file_time=0
        else
            file_time=0
        fi
        
        if [ "$file_time" -gt "$newest" ]; then
            newest=$file_time
        fi
    done
    
    echo "$newest"
}

# Check if test should be re-run based on file modifications
should_run_test() {
    local test_name="$1"
    shift
    local tracked_files=("$@")
    
    init_state_file
    
    # Get test state from JSON
    local test_data=$(jq -r ".\"$test_name\" // {}" "$STATE_FILE")
    local last_run=$(echo "$test_data" | jq -r '.last_run // ""')
    local last_checksum=$(echo "$test_data" | jq -r '.checksum // ""')
    local status=$(echo "$test_data" | jq -r '.status // "never_run"')
    
    # Always run if never run before or failed
    if [ "$status" != "passed" ] || [ -z "$last_run" ]; then
        log_info "Test $test_name: Never passed or no history - running"
        return 0
    fi
    
    # Convert last_run to timestamp for comparison
    local last_run_timestamp
    if command -v date >/dev/null 2>&1; then
        last_run_timestamp=$(date -d "$last_run" +%s 2>/dev/null || echo 0)
    else
        last_run_timestamp=0
    fi
    
    # Check if any tracked files are newer than last run
    local newest_file_time=$(get_newest_file_time "${tracked_files[@]}")
    if [ "$newest_file_time" -gt "$last_run_timestamp" ]; then
        log_info "Test $test_name: Files modified since last run - running"
        return 0
    fi
    
    # Check if file checksums changed
    local current_checksum=$(calculate_files_checksum "${tracked_files[@]}")
    if [ "$current_checksum" != "$last_checksum" ]; then
        log_info "Test $test_name: File content changed - running"
        return 0
    fi
    
    # Check if --force flag is set
    if [ "$FORCE_TESTS" = "true" ]; then
        log_info "Test $test_name: Force flag set - running"
        return 0
    fi
    
    log_success "Test $test_name: Up to date - skipping"
    return 1
}

# Mark test as passed in state file
mark_test_passed() {
    local test_name="$1"
    shift
    local tracked_files=("$@")
    
    init_state_file
    
    local current_time=$(date -Iseconds)
    local checksum=$(calculate_files_checksum "${tracked_files[@]}")
    local files_json=$(printf '%s\n' "${tracked_files[@]}" | jq -R . | jq -s .)
    
    # Update state file using jq
    local temp_file=$(mktemp)
    jq ".\"$test_name\" = {
        \"status\": \"passed\",
        \"last_run\": \"$current_time\",
        \"files_tracked\": $files_json,
        \"checksum\": \"$checksum\"
    }" "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE"
}

# Mark test as failed in state file
mark_test_failed() {
    local test_name="$1"
    shift
    local tracked_files=("$@")
    
    init_state_file
    
    local current_time=$(date -Iseconds)
    local checksum=$(calculate_files_checksum "${tracked_files[@]}")
    local files_json=$(printf '%s\n' "${tracked_files[@]}" | jq -R . | jq -s .)
    
    local temp_file=$(mktemp)
    jq ".\"$test_name\" = {
        \"status\": \"failed\",
        \"last_run\": \"$current_time\",
        \"files_tracked\": $files_json,
        \"checksum\": \"$checksum\"
    }" "$STATE_FILE" > "$temp_file" && mv "$temp_file" "$STATE_FILE"
}

# Add bug to tracker
add_bug() {
    local severity="$1"  # 🔥 CRITICAL, ⚠️ WARNING, ℹ️ INFO
    local title="$2"
    local description="$3"
    
    echo "## $severity $title" >> "$BUG_TRACKER_FILE"
    echo "$description" >> "$BUG_TRACKER_FILE"
    echo "" >> "$BUG_TRACKER_FILE"
}

# Add detailed bug report with captured output
add_detailed_bug() {
    local severity="$1"  # 🔥 CRITICAL, ⚠️ WARNING, ℹ️ INFO
    local title="$2"
    local description="$3"
    local detailed_output="$4"
    
    echo "## $severity $title" >> "$BUG_TRACKER_FILE"
    echo "$description" >> "$BUG_TRACKER_FILE"
    echo "" >> "$BUG_TRACKER_FILE"
    
    if [ -n "$detailed_output" ]; then
        echo "### Detailed Error Output" >> "$BUG_TRACKER_FILE"
        echo "\`\`\`" >> "$BUG_TRACKER_FILE"
        echo "$detailed_output" >> "$BUG_TRACKER_FILE"
        echo "\`\`\`" >> "$BUG_TRACKER_FILE"
        echo "" >> "$BUG_TRACKER_FILE"
    fi
}

# Start capturing test output for a specific test
start_test_capture() {
    local test_name="$1"
    CURRENT_TEST_NAME="$test_name"
    TEST_OUTPUT_BUFFER=""
}

# Capture output from a command and store it
capture_output() {
    local command="$1"
    local output
    
    # Run command and capture both stdout and stderr
    output=$(eval "$command" 2>&1)
    local exit_code=$?
    
    # Add to buffer with timestamp
    TEST_OUTPUT_BUFFER="${TEST_OUTPUT_BUFFER}[$(date '+%Y-%m-%d %H:%M:%S')] Command: $command
$output

"
    
    return $exit_code
}

# Capture output from a test function
capture_test_function() {
    local test_function="$1"
    local output
    
    # Run test function and capture both stdout and stderr
    output=$("$test_function" 2>&1)
    local exit_code=$?
    
    # Add to buffer with timestamp
    TEST_OUTPUT_BUFFER="${TEST_OUTPUT_BUFFER}[$(date '+%Y-%m-%d %H:%M:%S')] Test: $test_function
$output

"
    
    return $exit_code
}

# Finish test capture and add to bug tracker if failed
finish_test_capture() {
    local test_passed="$1"
    local error_message="$2"
    
    if [ "$test_passed" != "true" ] && [ -n "$CURRENT_TEST_NAME" ] && [ -n "$TEST_OUTPUT_BUFFER" ]; then
        local title="Test Failed: $CURRENT_TEST_NAME"
        local description="${error_message:-Test failed with detailed output below}"
        
        add_detailed_bug "🔥 CRITICAL" "$title" "$description" "$TEST_OUTPUT_BUFFER"
    fi
    
    # Reset capture variables
    TEST_OUTPUT_BUFFER=""
    CURRENT_TEST_NAME=""
}

# Enhanced test execution wrapper that captures detailed output on failure
run_test_with_capture() {
    local test_name="$1"
    local test_function="$2"
    
    start_test_capture "$test_name"
    
    if capture_test_function "$test_function"; then
        finish_test_capture "true"
        return 0
    else
        finish_test_capture "false" "Test function '$test_function' failed"
        return 1
    fi
}

# Enhanced command execution that captures output on failure
run_command_with_capture() {
    local command_description="$1"
    local command="$2"
    
    # Add command info to buffer
    TEST_OUTPUT_BUFFER="${TEST_OUTPUT_BUFFER}[$(date '+%Y-%m-%d %H:%M:%S')] $command_description
Command: $command
"
    
    # Execute and capture
    if capture_output "$command"; then
        return 0
    else
        return 1
    fi
}

# Run a series of test functions for a layer
run_layer_tests() {
    local layer_name="$1"
    local test_name="$2"
    shift 2
    local all_args=("$@")
    local tracked_files=()
    local test_functions=()
    
    # Separate test functions from tracked files
    # Functions start with "test_", files don't
    for arg in "${all_args[@]}"; do
        if [[ "$arg" =~ ^test_ ]]; then
            test_functions+=("$arg")
        else
            tracked_files+=("$arg")
        fi
    done
    
    echo ""
    echo "🧪 Testing Layer: $layer_name"
    echo "📁 Tracked files: ${tracked_files[*]}"
    
    # Start capturing output for this layer test
    start_test_capture "$test_name"
    
    local layer_passed=true
    local failed_function=""
    
    for test_func in "${test_functions[@]}"; do
        echo "  Running: $test_func"
        
        # Capture the test function output
        if ! capture_test_function "$test_func"; then
            layer_passed=false
            failed_function="$test_func"
            break
        fi
    done
    
    if [ "$layer_passed" = true ]; then
        log_success "Layer $layer_name: All tests PASSED"
        mark_test_passed "$test_name" "${tracked_files[@]}"
        finish_test_capture "true"
        return 0
    else
        log_error "Layer $layer_name: Tests FAILED (failed at: $failed_function)"
        mark_test_failed "$test_name" "${tracked_files[@]}"
        finish_test_capture "false" "Layer $layer_name failed at test function: $failed_function"
        return 1
    fi
}

# Initialize results file
init_results_file() {
    cat > "$RESULTS_FILE" << EOF
# Foundation Test Results - $TIMESTAMP

## Test Summary
- **Status**: RUNNING
- **Timestamp**: $(date)
- **Command**: $0 $*

## Foundation Layers Test Results

EOF
}

# Initialize bug tracker
init_bug_tracker() {
    cat > "$BUG_TRACKER_FILE" << EOF
# Bug Tracker - Foundation Issues

Issues found during foundation testing that must be fixed before development:

EOF
}

# Check for required commands
check_requirements() {
    local missing_commands=()
    
    for cmd in jq md5sum; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        log_error "Missing required commands: ${missing_commands[*]}"
        echo "Please install missing commands:"
        for cmd in "${missing_commands[@]}"; do
            case "$cmd" in
                jq) echo "  sudo apt-get install jq" ;;
                md5sum) echo "  sudo apt-get install coreutils" ;;
            esac
        done
        return 1
    fi
    
    return 0
}

# Foundation prerequisite test functions for user story tests
# These allow user story tests to verify foundation layers are working

test_database_connection() {
    # Test basic database connectivity
    local db_status_response
    if ! db_status_response=$(curl -s -f "http://localhost:3000/db-status" 2>&1); then
        echo "Failed to connect to database status endpoint: $db_status_response"
        return 1
    fi
    
    echo "Database status response: $db_status_response"
    
    # Check for nested JSON structure: data.connection.status = "connected"
    if echo "$db_status_response" | grep -q '"data".*"connection".*"status":"connected"'; then
        echo "Database connection status: CONNECTED"
        return 0
    else
        echo "Database connection status: FAILED - Expected 'connected' status in response"
        echo "Full response: $db_status_response"
        return 1
    fi
}

test_http_health_endpoint() {
    # Test main application health endpoint
    local health_response
    if ! health_response=$(curl -s -f "http://localhost:3000/health" 2>&1); then
        echo "Failed to connect to health endpoint: $health_response"
        return 1
    fi
    
    echo "Health endpoint response: $health_response"
    
    # Check for nested JSON structure: data.status = "healthy"
    if echo "$health_response" | grep -q '"data".*"status":"healthy"'; then
        echo "Health status: HEALTHY"
        return 0
    else
        echo "Health status: FAILED - Expected 'healthy' status in response"
        echo "Full response: $health_response"
        return 1
    fi
}

test_user_management_endpoints() {
    # Test user management API endpoints are responding
    local test_user_id="U_TEST_PREREQ_CHECK"
    
    # Test user registration status endpoint
    local user_response
    if ! user_response=$(curl -s -f "http://localhost:3000/api/users/$test_user_id/registered" 2>&1); then
        echo "Failed to connect to user management endpoint: $user_response"
        return 1
    fi
    
    echo "User management endpoint response: $user_response"
    
    # Test that endpoint returns proper JSON
    if echo "$user_response" | grep -q '"registered":'; then
        echo "User management endpoint: WORKING"
        return 0
    else
        echo "User management endpoint: FAILED - Expected 'registered' field in response"
        echo "Full response: $user_response"
        return 1
    fi
}

test_slack_simulator_running() {
    # Test Slack simulator is running and responding
    local simulator_response
    if ! simulator_response=$(curl -s -f "http://localhost:3001/health" 2>&1); then
        echo "Failed to connect to Slack simulator: $simulator_response"
        return 1
    fi
    
    echo "Slack simulator response: $simulator_response"
    
    if echo "$simulator_response" | grep -q '"ok":true'; then
        echo "Slack simulator: RUNNING"
        return 0
    else
        echo "Slack simulator: FAILED - Expected 'ok:true' in response"
        echo "Full response: $simulator_response"
        return 1
    fi
}

# Record test result function (wrapper for mark_test_passed/failed)
record_test_result() {
    local test_name="$1"
    local status="$2"
    local message="$3"
    
    if [ "$status" = "PASS" ]; then
        mark_test_passed "$test_name"
    else
        mark_test_failed "$test_name"
    fi
}

# Run database migrations using the migration system
run_migrations() {
    log_info "Running database migrations..."
    
    # Check if we're in the right directory
    if [ ! -f "package.json" ]; then
        log_error "package.json not found - must run from project root"
        return 1
    fi
    
    if [ ! -f "migrations/migrate.js" ]; then
        log_error "Migration script not found at migrations/migrate.js"
        return 1
    fi
    
    # Run the migration script using npm with output capture
    local migration_output
    migration_output=$(npm run migrate 2>&1)
    local migration_exit_code=$?
    
    # Log the migration output for debugging
    echo "$migration_output"
    
    # Add to test output buffer if capturing
    if [ -n "$CURRENT_TEST_NAME" ]; then
        TEST_OUTPUT_BUFFER="${TEST_OUTPUT_BUFFER}[$(date '+%Y-%m-%d %H:%M:%S')] Database Migration
Command: npm run migrate
$migration_output

"
    fi
    
    if [ $migration_exit_code -eq 0 ]; then
        log_success "Database migrations completed successfully"
        return 0
    else
        log_error "Database migrations failed with exit code $migration_exit_code"
        echo "Migration output: $migration_output"
        
        # If not currently capturing, add as immediate bug report
        if [ -z "$CURRENT_TEST_NAME" ]; then
            add_detailed_bug "🔥 CRITICAL" "Database Migration Failed" "Migration failed with exit code $migration_exit_code" "$migration_output"
        fi
        
        return 1
    fi
}

# Ensure HTTP server is running for tests that depend on it
ensure_http_server() {
    log_info "Ensuring HTTP server is available..."
    
    # Use service manager to ensure HTTP server is running
    local script_dir="$(dirname "${BASH_SOURCE[0]}")"
    if [ -f "$script_dir/service-manager.sh" ]; then
        # Call service manager as external command to start HTTP server
        if "$script_dir/service-manager.sh" start http_server >/dev/null 2>&1; then
            log_success "HTTP server is running"
            return 0
        else
            log_error "Failed to start HTTP server"
            return 1
        fi
    else
        # Fallback to legacy method if service manager not available
        log_warning "Service manager not found - using legacy HTTP server startup"
        
        # First check if server is already running
        if curl -s -f "http://localhost:3000/health" >/dev/null 2>&1; then
            log_info "HTTP server already running - reusing existing server"
            return 0
        fi
        
        # Check if we have the server files
        if [ ! -f "src/index.js" ]; then
            log_error "HTTP server files not found - cannot start server"
            return 1
        fi
        
        # Start the server in background
        export NODE_ENV=test
        export LOG_LEVEL=ERROR
        
        log_info "Starting HTTP server for foundation tests..."
        node src/index.js > foundation_http_server.log 2>&1 &
        local server_pid=$!
        
        # Wait for server to become ready
        local retries=30
        local server_ready=false
        
        while [ $retries -gt 0 ] && [ "$server_ready" = false ]; do
            if kill -0 "$server_pid" 2>/dev/null; then
                # Server process is running, check if it responds
                if curl -s -f "http://localhost:3000/health" >/dev/null 2>&1; then
                    server_ready=true
                    log_success "HTTP server started successfully for foundation tests"
                    return 0
                fi
            else
                log_error "HTTP server process died during startup"
                local server_logs=""
                if [ -f foundation_http_server.log ]; then
                    server_logs=$(cat foundation_http_server.log | tail -10)
                    log_error "Server startup logs:"
                    echo "$server_logs"
                fi
                
                # Add to bug tracker if not currently capturing
                if [ -z "$CURRENT_TEST_NAME" ]; then
                    add_detailed_bug "🔥 CRITICAL" "HTTP Server Startup Failed" "HTTP server process died during startup" "$server_logs"
                elif [ -n "$server_logs" ]; then
                    # Add to current test capture
                    TEST_OUTPUT_BUFFER="${TEST_OUTPUT_BUFFER}[$(date '+%Y-%m-%d %H:%M:%S')] HTTP Server Startup Failed
Server logs:
$server_logs

"
                fi
                return 1
            fi
            
            retries=$((retries - 1))
            sleep 1
        done
        
        log_error "HTTP server failed to start within 30 seconds"
        local server_logs=""
        if [ -f foundation_http_server.log ]; then
            server_logs=$(cat foundation_http_server.log | tail -10)
            log_error "Server startup logs:"
            echo "$server_logs"
        fi
        
        # Add to bug tracker if not currently capturing
        if [ -z "$CURRENT_TEST_NAME" ]; then
            add_detailed_bug "🔥 CRITICAL" "HTTP Server Startup Timeout" "HTTP server failed to start within 30 seconds" "$server_logs"
        elif [ -n "$server_logs" ]; then
            # Add to current test capture
            TEST_OUTPUT_BUFFER="${TEST_OUTPUT_BUFFER}[$(date '+%Y-%m-%d %H:%M:%S')] HTTP Server Startup Timeout
Server logs:
$server_logs

"
        fi
        return 1
    fi
}

# Ensure database is running for tests that depend on it
ensure_database() {
    log_info "Ensuring database is available..."
    
    # Use service manager to ensure database is running
    local script_dir="$(dirname "${BASH_SOURCE[0]}")"
    if [ -f "$script_dir/service-manager.sh" ]; then
        # Call service manager as external command to start database
        if "$script_dir/service-manager.sh" start database >/dev/null 2>&1; then
            log_success "Database service is running"
            return 0
        else
            log_error "Failed to start database service"
            return 1
        fi
    else
        log_warning "Service manager not found - using legacy database check"
        return 0
    fi
}

# Ensure Slack simulator is running for tests that depend on it
ensure_slack_simulator() {
    log_info "Ensuring Slack simulator is available..."
    
    # Use service manager to ensure Slack simulator is running
    local script_dir="$(dirname "${BASH_SOURCE[0]}")"
    if [ -f "$script_dir/service-manager.sh" ]; then
        # Call service manager as external command to start Slack simulator
        if "$script_dir/service-manager.sh" start slack_simulator >/dev/null 2>&1; then
            log_success "Slack simulator is running"
            return 0
        else
            log_error "Failed to start Slack simulator"
            return 1
        fi
    else
        log_warning "Service manager not found - cannot ensure Slack simulator"
        return 1
    fi
}

# Test LLM integration availability
test_llm_integration_available() {
    echo "Testing LLM integration availability..."
    
    # Test LLM service endpoint with required variables
    local response
    local endpoint_url="http://localhost:3000/api/templates/onboarding_initial/en?userName=TestUser&botName=Proximus"
    
    if response=$(curl -s "$endpoint_url" 2>&1); then
        echo "LLM template endpoint response: $response"
        
        if echo "$response" | grep -q "onboarding"; then
            echo "LLM integration: AVAILABLE - templates accessible"
            return 0
        else
            echo "LLM integration: FAILED - templates not working properly"
            echo "Expected 'onboarding' content in template response"
            echo "Full response: $response"
            return 1
        fi
    else
        echo "LLM integration: FAILED - templates endpoint not responding"
        echo "Endpoint: $endpoint_url"
        echo "Error: $response"
        return 1
    fi
}