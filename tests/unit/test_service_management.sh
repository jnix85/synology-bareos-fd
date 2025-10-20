#!/bin/bash

# Test suite for service management script
# Tests the start-stop-status script functionality

set -euo pipefail

# Source test framework
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
TEST_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$TEST_DIR")")"
source "$TEST_DIR/test_package_validation.sh" 2>/dev/null || {
    # If sourcing fails, define minimal framework
    log_info() { echo "[INFO] $1"; }
    log_success() { echo "[PASS] $1"; PASSED_COUNT=$((PASSED_COUNT + 1)); }
    log_error() { echo "[FAIL] $1"; FAILED_COUNT=$((FAILED_COUNT + 1)); }
    TEST_COUNT=0; PASSED_COUNT=0; FAILED_COUNT=0
}

# Service script path
SERVICE_SCRIPT="$PROJECT_ROOT/scripts/start-stop-status"

# Test service script structure
test_service_script_structure() {
    log_info "Testing service script structure..."
    
    # Test file exists and is executable
    assert_file_exists "$SERVICE_SCRIPT" "Service management script"
    assert_executable "$SERVICE_SCRIPT" "Service script executable"
    
    # Test required variables
    assert_contains "$SERVICE_SCRIPT" "BAREOS_USER=" "Bareos user variable"
    assert_contains "$SERVICE_SCRIPT" "BAREOS_HOME=" "Bareos home variable"
    assert_contains "$SERVICE_SCRIPT" "BAREOS_BIN=" "Bareos binary variable"
    assert_contains "$SERVICE_SCRIPT" "BAREOS_CONFIG=" "Bareos config variable"
    assert_contains "$SERVICE_SCRIPT" "BAREOS_PID=" "PID file variable"
    
    # Test script has required functions
    assert_contains "$SERVICE_SCRIPT" "case.*\$1.*in" "Command case statement"
    assert_contains "$SERVICE_SCRIPT" "start)" "Start command"
    assert_contains "$SERVICE_SCRIPT" "stop)" "Stop command" 
    assert_contains "$SERVICE_SCRIPT" "status)" "Status command"
    assert_contains "$SERVICE_SCRIPT" "reload)" "Reload command"
}

# Test start functionality
test_start_functionality() {
    log_info "Testing start functionality..."
    
    # Test start command logic
    assert_contains "$SERVICE_SCRIPT" "Starting Bareos File Daemon" "Start message"
    assert_contains "$SERVICE_SCRIPT" "kill -0.*cat.*BAREOS_PID" "Running check"
    assert_contains "$SERVICE_SCRIPT" "already running" "Already running check"
    assert_contains "$SERVICE_SCRIPT" "mkdir -p" "Directory creation"
    assert_contains "$SERVICE_SCRIPT" "chown" "Ownership setting"
    assert_contains "$SERVICE_SCRIPT" "-t -c.*BAREOS_CONFIG" "Configuration validation"
    assert_contains "$SERVICE_SCRIPT" "Configuration validation failed" "Config validation error"
    
    # Test daemon startup
    assert_contains "$SERVICE_SCRIPT" "su.*BAREOS_USER" "User switching"
    assert_contains "$SERVICE_SCRIPT" "-d 200" "Debug level setting"
    assert_contains "$SERVICE_SCRIPT" "sleep 3" "Startup wait"
    assert_contains "$SERVICE_SCRIPT" "started successfully\|Failed to start" "Startup result messages"
}

# Test stop functionality  
test_stop_functionality() {
    log_info "Testing stop functionality..."
    
    # Test stop command logic
    assert_contains "$SERVICE_SCRIPT" "Stopping Bareos File Daemon" "Stop message"
    assert_contains "$SERVICE_SCRIPT" "cat.*BAREOS_PID" "PID file reading"
    assert_contains "$SERVICE_SCRIPT" "kill -TERM" "Graceful shutdown"
    assert_contains "$SERVICE_SCRIPT" "kill -KILL" "Force kill"
    assert_contains "$SERVICE_SCRIPT" "rm -f.*BAREOS_PID" "PID file cleanup"
    
    # Test graceful shutdown timeout
    assert_contains "$SERVICE_SCRIPT" "for i in.*30" "Shutdown timeout"
    assert_contains "$SERVICE_SCRIPT" "sleep 1" "Shutdown wait loop"
    assert_contains "$SERVICE_SCRIPT" "stopped successfully\|force stopped" "Stop result messages"
}

# Test status functionality
test_status_functionality() {
    log_info "Testing status functionality..."
    
    # Test status command logic
    assert_contains "$SERVICE_SCRIPT" "status)" "Status case"
    assert_contains "$SERVICE_SCRIPT" "is running.*PID" "Running status message"
    assert_contains "$SERVICE_SCRIPT" "is not running" "Not running message"
    assert_contains "$SERVICE_SCRIPT" "exit 0" "Status success exit code"
    assert_contains "$SERVICE_SCRIPT" "exit 1" "Status failure exit code"
}

# Test reload functionality
test_reload_functionality() {
    log_info "Testing reload functionality..."
    
    # Test reload command logic
    assert_contains "$SERVICE_SCRIPT" "reload)" "Reload case"
    assert_contains "$SERVICE_SCRIPT" "Reloading.*configuration" "Reload message"
    assert_contains "$SERVICE_SCRIPT" "kill -HUP" "HUP signal"
    assert_contains "$SERVICE_SCRIPT" "Configuration reloaded" "Reload success message"
    assert_contains "$SERVICE_SCRIPT" "not running" "Reload error handling"
}

# Test error handling
test_error_handling() {
    log_info "Testing error handling..."
    
    # Test error conditions
    assert_contains "$SERVICE_SCRIPT" "exit 1" "Error exit codes"
    assert_contains "$SERVICE_SCRIPT" ">/dev/null 2>&1" "Output redirection"
    
    # Test signal handling
    assert_contains "$SERVICE_SCRIPT" "kill -0" "Process existence check"
    assert_contains "$SERVICE_SCRIPT" "2>/dev/null" "Error suppression"
}

# Test command line argument handling
test_argument_handling() {
    log_info "Testing argument handling..."
    
    # Test usage message
    assert_contains "$SERVICE_SCRIPT" "Usage:.*start.*stop.*status" "Usage message"
    assert_contains "$SERVICE_SCRIPT" "\*)" "Default case"
    assert_contains "$SERVICE_SCRIPT" "Usage" "Usage message"
    assert_contains "$SERVICE_SCRIPT" "exit 1" "Usage exit code"
    
    # Test restart functionality
    if grep -q "restart)" "$SERVICE_SCRIPT"; then
        assert_contains "$SERVICE_SCRIPT" "\$0 stop" "Restart stop call"
        assert_contains "$SERVICE_SCRIPT" "\$0 start" "Restart start call"
        assert_contains "$SERVICE_SCRIPT" "sleep 2" "Restart delay"
        log_success "Restart functionality: Present in service script"
        TEST_COUNT=$((TEST_COUNT + 1))
    else
        log_error "Restart functionality: Missing from service script"
        TEST_COUNT=$((TEST_COUNT + 1))
    fi
}

# Test file path validation
test_file_paths() {
    log_info "Testing file path validation..."
    
    # Test expected file paths
    local expected_paths=(
        "/var/packages/bareos-fd/target"
        "/var/run/bareos-fd.pid"
        "/var/log/bareos-fd.log"
        "etc/bareos/bareos-fd.conf"
        "lib/bareos/bareos-fd"
    )
    
    for path in "${expected_paths[@]}"; do
        TEST_COUNT=$((TEST_COUNT + 1))
        if grep -q "$path" "$SERVICE_SCRIPT"; then
            log_success "File paths: $path found in service script"
        else
            log_error "File paths: $path missing from service script"
        fi
    done
}

# Test security considerations
test_security() {
    log_info "Testing security considerations..."
    
    # Test user privilege handling
    assert_contains "$SERVICE_SCRIPT" "BAREOS_USER" "User variable usage"
    assert_contains "$SERVICE_SCRIPT" "su.*BAREOS_USER" "User switching for security"
    
    # Test file permission handling
    assert_contains "$SERVICE_SCRIPT" "chown.*BAREOS_USER" "File ownership"
    
    # Test configuration validation
    assert_contains "$SERVICE_SCRIPT" "-t -c" "Configuration testing before start"
    
    # Test PID file security
    assert_contains "$SERVICE_SCRIPT" "/var/run" "Secure PID file location"
}

# Test compatibility
test_compatibility() {
    log_info "Testing compatibility considerations..."
    
    # Test Synology-specific features
    assert_contains "$SERVICE_SCRIPT" "pkg_util.sh" "Synology package utilities"
    
    # Test fallback mechanisms
    if grep -q "command -v su" "$SERVICE_SCRIPT"; then
        log_success "Compatibility: Has fallback for su command"
        TEST_COUNT=$((TEST_COUNT + 1))
    else
        log_error "Compatibility: Missing fallback for su command"
        TEST_COUNT=$((TEST_COUNT + 1))
    fi
    
    # Test signal handling compatibility
    assert_contains "$SERVICE_SCRIPT" "kill -0" "POSIX signal handling"
    assert_contains "$SERVICE_SCRIPT" "kill -TERM" "Standard termination signal"
    assert_contains "$SERVICE_SCRIPT" "kill -HUP" "Standard reload signal"
}

# Test logging and output
test_logging() {
    log_info "Testing logging and output..."
    
    # Test timestamp logging
    assert_contains "$SERVICE_SCRIPT" "date.*Y.*m.*d.*H.*M.*S" "Timestamp format"
    
    # Test log levels
    assert_contains "$SERVICE_SCRIPT" "INFO" "Info log level"
    assert_contains "$SERVICE_SCRIPT" "ERROR" "Error log level"
    
    # Test output redirection
    assert_contains "$SERVICE_SCRIPT" ">&2" "Error output redirection"
    assert_contains "$SERVICE_SCRIPT" "> \".*BAREOS_LOG\"" "Log file output"
}

# Mock test for service script execution
test_service_script_execution() {
    log_info "Testing service script execution scenarios..."
    
    # Test syntax validation
    TEST_COUNT=$((TEST_COUNT + 1))
    if bash -n "$SERVICE_SCRIPT" 2>/dev/null; then
        log_success "Service script syntax: Valid bash syntax"
    else
        log_error "Service script syntax: Contains syntax errors"
    fi
    
    # Test with invalid arguments
    TEST_COUNT=$((TEST_COUNT + 1))
    local output
    if output=$(timeout 5 bash "$SERVICE_SCRIPT" invalid_command 2>&1); then
        if echo "$output" | grep -q "Usage:"; then
            log_success "Service script execution: Shows usage for invalid commands"
        else
            log_error "Service script execution: Doesn't show usage for invalid commands"
        fi
    else
        log_error "Service script execution: Failed to handle invalid commands"
    fi
    
    # Test status command (should be safe to run)
    TEST_COUNT=$((TEST_COUNT + 1))
    if timeout 5 bash "$SERVICE_SCRIPT" status >/dev/null 2>&1; then
        log_success "Service script execution: Status command executes without error"
    else
        log_error "Service script execution: Status command failed"
    fi
}

# Main test runner for service management
run_service_management_tests() {
    echo "=============================================="
    echo "Bareos FD SPK - Service Management Tests"
    echo "=============================================="
    echo
    
    test_service_script_structure
    test_start_functionality
    test_stop_functionality
    test_status_functionality
    test_reload_functionality
    test_error_handling
    test_argument_handling
    test_file_paths
    test_security
    test_compatibility
    test_logging
    test_service_script_execution
    
    echo
    echo "=============================================="
    echo "Service Management Test Results:"
    echo "=============================================="
    echo "Total Tests: $TEST_COUNT"
    echo "Passed: $PASSED_COUNT"
    echo "Failed: $FAILED_COUNT"
    
    if [[ $FAILED_COUNT -eq 0 ]]; then
        echo "✓ All service management tests passed!"
        return 0
    else
        echo "✗ Some service management tests failed!"
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_service_management_tests "$@"
fi