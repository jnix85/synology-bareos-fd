#!/bin/bash

# Main test runner for Bareos File Daemon SPK package
# Runs all unit tests, integration tests, and generates reports

set -euo pipefail

# Test runner configuration
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
TEST_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$TEST_DIR")")"
REPORT_DIR="$TEST_DIR/reports"
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test suite configuration
UNIT_TESTS=(
    "unit/test_package_validation.sh"
    "unit/test_installation_scripts.sh"
    "unit/test_service_management.sh"
    "unit/test_configuration.sh"
)

INTEGRATION_TESTS=(
    "integration/test_complete_workflow.sh"
)

# Global counters
TOTAL_TESTS=0
TOTAL_PASSED=0
TOTAL_FAILED=0
SUITE_RESULTS=()

# Logging functions
log_header() {
    echo -e "\n${PURPLE}================================${NC}"
    echo -e "${PURPLE}$1${NC}"
    echo -e "${PURPLE}================================${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Setup test environment
setup_test_environment() {
    log_info "Setting up test environment..."
    
    # Create reports directory
    mkdir -p "$REPORT_DIR"
    
    # Ensure all test scripts are executable
    find "$TEST_DIR" -name "*.sh" -exec chmod +x {} \;
    
    # Check for required tools
    local missing_tools=()
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_tools+=("jq")
    fi
    
    if ! command -v timeout >/dev/null 2>&1; then
        missing_tools+=("timeout")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        log_warning "Missing optional tools: ${missing_tools[*]}"
        log_info "Some tests may be skipped. Install with: brew install ${missing_tools[*]}"
    fi
}

# Run a single test suite
run_test_suite() {
    local test_script="$1"
    local suite_name="$2"
    
    log_header "Running $suite_name"
    
    local full_path="$TEST_DIR/$test_script"
    if [[ ! -f "$full_path" ]]; then
        log_error "Test script not found: $full_path"
        return 1
    fi
    
    # Run the test and capture output
    local output_file="$REPORT_DIR/${suite_name}_${TIMESTAMP}.log"
    local start_time=$(date +%s)
    
    if timeout 300 bash "$full_path" > "$output_file" 2>&1; then
        local exit_code=0
        log_success "$suite_name completed successfully"
    else
        local exit_code=$?
        log_error "$suite_name failed (exit code: $exit_code)"
    fi
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # Parse test results from output
    local tests_run=$(grep -c "Total Tests:" "$output_file" 2>/dev/null || echo "0")
    local tests_passed=$(grep "Passed:" "$output_file" | tail -1 | sed 's/.*Passed: //' | sed 's/[^0-9].*$//' || echo "0")
    local tests_failed=$(grep "Failed:" "$output_file" | tail -1 | sed 's/.*Failed: //' | sed 's/[^0-9].*$//' || echo "0")
    
    # Update global counters
    TOTAL_TESTS=$((TOTAL_TESTS + tests_passed + tests_failed))
    TOTAL_PASSED=$((TOTAL_PASSED + tests_passed))
    TOTAL_FAILED=$((TOTAL_FAILED + tests_failed))
    
    # Store results
    SUITE_RESULTS+=("$suite_name:$exit_code:$tests_passed:$tests_failed:${duration}s")
    
    # Show summary for this suite
    echo -e "${CYAN}Suite Summary:${NC}"
    echo -e "  Tests Passed: ${GREEN}$tests_passed${NC}"
    echo -e "  Tests Failed: ${RED}$tests_failed${NC}"
    echo -e "  Duration: ${YELLOW}${duration}s${NC}"
    echo -e "  Log: $output_file"
    
    return $exit_code
}

# Run all unit tests
run_unit_tests() {
    log_header "UNIT TESTS"
    
    local unit_failures=0
    
    for test in "${UNIT_TESTS[@]}"; do
        local suite_name=$(basename "$test" .sh)
        if ! run_test_suite "$test" "$suite_name"; then
            unit_failures=$((unit_failures + 1))
        fi
        echo
    done
    
    if [[ $unit_failures -eq 0 ]]; then
        log_success "All unit tests passed!"
    else
        log_error "$unit_failures unit test suite(s) failed"
    fi
    
    return $unit_failures
}

# Run all integration tests
run_integration_tests() {
    log_header "INTEGRATION TESTS"
    
    local integration_failures=0
    
    for test in "${INTEGRATION_TESTS[@]}"; do
        local suite_name=$(basename "$test" .sh)
        if ! run_test_suite "$test" "$suite_name"; then
            integration_failures=$((integration_failures + 1))
        fi
        echo
    done
    
    if [[ $integration_failures -eq 0 ]]; then
        log_success "All integration tests passed!"
    else
        log_error "$integration_failures integration test suite(s) failed"
    fi
    
    return $integration_failures
}

# Generate test report
generate_test_report() {
    log_header "GENERATING TEST REPORT"
    
    local report_file="$REPORT_DIR/test_report_${TIMESTAMP}.html"
    
    cat > "$report_file" << EOF
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Bareos FD SPK - Test Report</title>
    <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; margin: 20px; background: #f5f5f5; }
        .container { max-width: 1200px; margin: 0 auto; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .header { text-align: center; color: #333; border-bottom: 2px solid #007acc; padding-bottom: 20px; margin-bottom: 30px; }
        .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
        .metric { background: #f8f9fa; padding: 15px; border-radius: 5px; text-align: center; border-left: 4px solid #007acc; }
        .metric-value { font-size: 2em; font-weight: bold; color: #007acc; }
        .metric-label { color: #666; margin-top: 5px; }
        .success { border-left-color: #28a745; } .success .metric-value { color: #28a745; }
        .danger { border-left-color: #dc3545; } .danger .metric-value { color: #dc3545; }
        .warning { border-left-color: #ffc107; } .warning .metric-value { color: #ffc107; }
        .suite-results { margin-top: 30px; }
        .suite { margin-bottom: 20px; padding: 15px; border-radius: 5px; background: #f8f9fa; }
        .suite-header { font-weight: bold; margin-bottom: 10px; }
        .suite.passed { border-left: 4px solid #28a745; }
        .suite.failed { border-left: 4px solid #dc3545; }
        .timestamp { text-align: center; color: #666; margin-top: 30px; font-size: 0.9em; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Bareos File Daemon SPK</h1>
            <h2>Test Report</h2>
            <p>Generated on $(date)</p>
        </div>
        
        <div class="summary">
            <div class="metric $([ $TOTAL_FAILED -eq 0 ] && echo 'success' || echo 'danger')">
                <div class="metric-value">$TOTAL_TESTS</div>
                <div class="metric-label">Total Tests</div>
            </div>
            <div class="metric success">
                <div class="metric-value">$TOTAL_PASSED</div>
                <div class="metric-label">Passed</div>
            </div>
            <div class="metric danger">
                <div class="metric-value">$TOTAL_FAILED</div>
                <div class="metric-label">Failed</div>
            </div>
            <div class="metric $([ $TOTAL_FAILED -eq 0 ] && echo 'success' || echo 'danger')">
                <div class="metric-value">$(echo "scale=1; $TOTAL_PASSED * 100 / $TOTAL_TESTS" | bc -l 2>/dev/null || echo "N/A")%</div>
                <div class="metric-label">Success Rate</div>
            </div>
        </div>
        
        <div class="suite-results">
            <h3>Test Suite Results</h3>
EOF

    for result in "${SUITE_RESULTS[@]}"; do
        IFS=':' read -r suite_name exit_code passed failed duration <<< "$result"
        local status_class=$([ "$exit_code" -eq 0 ] && echo "passed" || echo "failed")
        local status_text=$([ "$exit_code" -eq 0 ] && echo "PASSED" || echo "FAILED")
        
        cat >> "$report_file" << EOF
            <div class="suite $status_class">
                <div class="suite-header">$suite_name - $status_text</div>
                <div>Passed: $passed | Failed: $failed | Duration: $duration</div>
            </div>
EOF
    done
    
    cat >> "$report_file" << EOF
        </div>
        
        <div class="timestamp">
            Report generated on $(date) by Bareos FD SPK Test Suite
        </div>
    </div>
</body>
</html>
EOF

    log_success "Test report generated: $report_file"
    
    # Also generate a simple text report
    local text_report="$REPORT_DIR/test_summary_${TIMESTAMP}.txt"
    cat > "$text_report" << EOF
Bareos File Daemon SPK - Test Summary
Generated: $(date)

OVERALL RESULTS:
Total Tests: $TOTAL_TESTS
Passed: $TOTAL_PASSED
Failed: $TOTAL_FAILED
Success Rate: $(echo "scale=1; $TOTAL_PASSED * 100 / $TOTAL_TESTS" | bc -l 2>/dev/null || echo "N/A")%

SUITE RESULTS:
EOF

    for result in "${SUITE_RESULTS[@]}"; do
        IFS=':' read -r suite_name exit_code passed failed duration <<< "$result"
        local status=$([ "$exit_code" -eq 0 ] && echo "PASS" || echo "FAIL")
        printf "%-30s %s (P:%s F:%s %s)\n" "$suite_name" "$status" "$passed" "$failed" "$duration" >> "$text_report"
    done
    
    log_success "Text summary generated: $text_report"
}

# Run performance benchmarks
run_performance_tests() {
    log_header "PERFORMANCE TESTS"
    
    local start_time=$(date +%s)
    
    # Test build performance
    log_info "Testing SPK build performance..."
    cd "$PROJECT_ROOT"
    
    local build_start=$(date +%s)
    if timeout 120 bash build_spk.sh >/dev/null 2>&1; then
        local build_end=$(date +%s)
        local build_duration=$((build_end - build_start))
        log_success "SPK build completed in ${build_duration}s"
        
        # Check SPK file size
        local spk_file=$(ls *.spk 2>/dev/null | head -1)
        if [[ -f "$spk_file" ]]; then
            local size=$(stat -f%z "$spk_file" 2>/dev/null || stat -c%s "$spk_file" 2>/dev/null)
            local size_mb=$(echo "scale=2; $size / 1048576" | bc -l 2>/dev/null || echo "N/A")
            log_info "SPK file size: ${size_mb}MB"
        fi
    else
        log_error "SPK build failed or timed out"
    fi
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    log_info "Performance test duration: ${total_duration}s"
}

# Check code quality
run_quality_checks() {
    log_header "CODE QUALITY CHECKS"
    
    local quality_issues=0
    
    # Check shell script syntax
    log_info "Checking shell script syntax..."
    while IFS= read -r -d '' script; do
        if ! bash -n "$script" 2>/dev/null; then
            log_error "Syntax error in: $script"
            quality_issues=$((quality_issues + 1))
        fi
    done < <(find "$PROJECT_ROOT" -name "*.sh" -print0)
    
    if [[ $quality_issues -eq 0 ]]; then
        log_success "All shell scripts have valid syntax"
    fi
    
    # Check for TODO/FIXME comments
    log_info "Checking for TODO/FIXME comments..."
    local todo_count=$(grep -r "TODO\|FIXME\|XXX" "$PROJECT_ROOT" --exclude-dir=tests --exclude-dir=.git | wc -l)
    if [[ $todo_count -gt 0 ]]; then
        log_warning "Found $todo_count TODO/FIXME comments"
    else
        log_success "No TODO/FIXME comments found"
    fi
    
    # Check file permissions
    log_info "Checking executable permissions..."
    local script_count=0
    local executable_count=0
    local non_executable_scripts=()
    
    while IFS= read -r -d '' script; do
        script_count=$((script_count + 1))
        if [[ -x "$script" ]]; then
            executable_count=$((executable_count + 1))
        else
            non_executable_scripts+=("$script")
        fi
    done < <(find "$PROJECT_ROOT" -name "*.sh" -print0)
    
    log_info "Executable scripts: $executable_count/$script_count"
    
    if [[ $executable_count -eq $script_count ]]; then
        log_success "All shell scripts are executable"
    else
        log_error "Found non-executable scripts:"
        for script in "${non_executable_scripts[@]}"; do
            log_error "  - $script"
        done
        quality_issues=$((quality_issues + 1))
    fi
    
    return $quality_issues
}

# Main test runner
main() {
    local start_time=$(date +%s)
    
    log_header "BAREOS FILE DAEMON SPK TEST SUITE"
    echo -e "${CYAN}Project:${NC} Synology SPK Package for Bareos File Daemon"
    echo -e "${CYAN}Timestamp:${NC} $(date)"
    echo -e "${CYAN}Test Runner:${NC} $0"
    echo
    
    setup_test_environment
    
    local overall_failures=0
    
    # Run code quality checks
    if ! run_quality_checks; then
        overall_failures=$((overall_failures + 1))
    fi
    echo
    
    # Run unit tests
    if ! run_unit_tests; then
        overall_failures=$((overall_failures + 1))
    fi
    echo
    
    # Run integration tests
    if ! run_integration_tests; then
        overall_failures=$((overall_failures + 1))
    fi
    echo
    
    # Run performance tests
    run_performance_tests
    echo
    
    # Generate reports
    generate_test_report
    
    local end_time=$(date +%s)
    local total_duration=$((end_time - start_time))
    
    # Final summary
    log_header "FINAL RESULTS"
    echo -e "${CYAN}Total Test Duration:${NC} ${total_duration}s"
    echo -e "${CYAN}Total Tests Run:${NC} $TOTAL_TESTS"
    echo -e "${CYAN}Tests Passed:${NC} ${GREEN}$TOTAL_PASSED${NC}"
    echo -e "${CYAN}Tests Failed:${NC} ${RED}$TOTAL_FAILED${NC}"
    
    if [[ $TOTAL_FAILED -eq 0 && $overall_failures -eq 0 ]]; then
        echo -e "\n${GREEN}🎉 ALL TESTS PASSED! SPK package is ready for deployment.${NC}"
        exit 0
    else
        echo -e "\n${RED}❌ SOME TESTS FAILED! Please review the test results and fix issues.${NC}"
        exit 1
    fi
}

# Handle command line arguments
case "${1:-all}" in
    unit)
        setup_test_environment
        run_unit_tests
        ;;
    integration)
        setup_test_environment
        run_integration_tests
        ;;
    quality)
        setup_test_environment
        run_quality_checks
        ;;
    performance)
        setup_test_environment
        run_performance_tests
        ;;
    all|*)
        main
        ;;
esac