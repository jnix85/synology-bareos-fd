#!/bin/bash

# Test suite for installation scripts
# Tests the pre/post install/uninstall/upgrade scripts

set -euo pipefail

# Source test framework
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$TEST_DIR")")"
source "$TEST_DIR/test_package_validation.sh" 2>/dev/null || {
    # If sourcing fails, define minimal framework
    log_info() { echo "[INFO] $1"; }
    log_success() { echo "[PASS] $1"; ((PASSED_COUNT++)); }
    log_error() { echo "[FAIL] $1"; ((FAILED_COUNT++)); }
    TEST_COUNT=0; PASSED_COUNT=0; FAILED_COUNT=0
}

# Test configuration
MOCK_ENV_DIR="/tmp/bareos-script-tests-$$"
MOCK_PACKAGES_DIR="$MOCK_ENV_DIR/var/packages"
MOCK_BAREOS_HOME="$MOCK_PACKAGES_DIR/bareos-fd/target"

# Mock functions for testing
setup_mock_environment() {
    log_info "Setting up mock environment for script testing..."
    
    mkdir -p "$MOCK_ENV_DIR"/{var/{packages,lib,log,run},usr/syno/sbin,etc,tmp}
    mkdir -p "$MOCK_BAREOS_HOME"/{bin,etc/bareos,lib/bareos}
    
    # Create mock syno commands
    cat > "$MOCK_ENV_DIR/usr/syno/sbin/synouser" << 'EOF'
#!/bin/bash
echo "Mock synouser: $*"
exit 0
EOF
    
    cat > "$MOCK_ENV_DIR/usr/syno/sbin/synogroup" << 'EOF'
#!/bin/bash
echo "Mock synogroup: $*"
exit 0
EOF
    
    chmod +x "$MOCK_ENV_DIR/usr/syno/sbin"/*
    
    # Create mock system files
    echo "buildnumber=42000" > "$MOCK_ENV_DIR/etc/VERSION"
    echo "#!/bin/bash" > "$MOCK_ENV_DIR/tmp/bareos_install_vars"
    
    # Mock environment variables for testing
    export PATH="$MOCK_ENV_DIR/usr/syno/sbin:$PATH"
    export MOCK_MODE=1
}

cleanup_mock_environment() {
    log_info "Cleaning up mock environment..."
    rm -rf "$MOCK_ENV_DIR"
}

# Test pre-installation script
test_preinst_script() {
    log_info "Testing pre-installation script..."
    
    local script="$PROJECT_ROOT/scripts/preinst"
    
    # Test 1: Script executes without errors
    ((TEST_COUNT++))
    if timeout 30 bash "$script" >/dev/null 2>&1; then
        log_success "Pre-install script: Executes successfully"
    else
        log_error "Pre-install script: Failed to execute or timed out"
    fi
    
    # Test 2: Script contains required checks
    assert_contains "$script" "DSM_VERSION" "DSM version check"
    assert_contains "$script" "AVAILABLE_SPACE" "Disk space check"
    assert_contains "$script" "bareos_install_vars" "Variable saving"
    
    # Test 3: Script has proper error handling
    assert_contains "$script" "log_error" "Error logging"
    assert_contains "$script" "exit 1" "Error exit handling"
}

# Test post-installation script
test_postinst_script() {
    log_info "Testing post-installation script..."
    
    local script="$PROJECT_ROOT/scripts/postinst"
    
    # Test 1: Script structure validation
    assert_contains "$script" "BAREOS_HOME" "Bareos home directory"
    assert_contains "$script" "BAREOS_USER" "Bareos user variable"
    assert_contains "$script" "mkdir -p" "Directory creation"
    assert_contains "$script" "chown" "Ownership setting"
    assert_contains "$script" "chmod" "Permission setting"
    
    # Test 2: Configuration generation
    assert_contains "$script" "bareos-fd.conf" "Configuration generation"
    assert_contains "$script" "Director {" "Director block generation"
    assert_contains "$script" "FileDaemon {" "FileDaemon block generation"
    
    # Test 3: SSL certificate generation
    assert_contains "$script" "openssl" "SSL certificate generation"
    assert_contains "$script" "bareos-ca.key" "CA key generation"
    assert_contains "$script" "bareos-fd.pem" "FD certificate generation"
    
    # Test 4: Service configuration
    assert_contains "$script" "rc.d" "Service script creation"
    assert_contains "$script" "logrotate" "Log rotation setup"
}

# Test pre-uninstall script
test_preuninst_script() {
    log_info "Testing pre-uninstall script..."
    
    local script="$PROJECT_ROOT/scripts/preuninst"
    
    # Test 1: Service stopping
    assert_contains "$script" "pgrep" "Process checking"
    assert_contains "$script" "start-stop-status stop" "Service stopping"
    
    # Test 2: Cleanup preparation
    assert_contains "$script" "autostart" "Autostart removal"
    assert_contains "$script" "rc.local" "Startup script cleanup"
}

# Test post-uninstall script
test_postuninst_script() {
    log_info "Testing post-uninstall script..."
    
    local script="$PROJECT_ROOT/scripts/postuninst"
    
    # Test 1: File cleanup
    assert_contains "$script" "rm -f" "File removal"
    assert_contains "$script" "rc.d" "Service file cleanup"
    assert_contains "$script" "logrotate" "Log rotation cleanup"
    
    # Test 2: Optional cleanups (commented out by default)
    assert_contains "$script" "# rm -rf.*bareos" "Optional log cleanup"
    assert_contains "$script" "# .*synouser.*del" "Optional user removal"
}

# Test upgrade scripts
test_upgrade_scripts() {
    log_info "Testing upgrade scripts..."
    
    local preupgrade="$PROJECT_ROOT/scripts/preupgrade"
    local postupgrade="$PROJECT_ROOT/scripts/postupgrade"
    
    # Pre-upgrade tests
    assert_contains "$preupgrade" "backup_config" "Configuration backup"
    assert_contains "$preupgrade" "start-stop-status stop" "Service stopping"
    assert_contains "$preupgrade" "cp -r" "Configuration backup copy"
    
    # Post-upgrade tests
    assert_contains "$postupgrade" "preserve_config" "Configuration preservation"
    assert_contains "$postupgrade" "start-stop-status start" "Service restart"
    assert_contains "$postupgrade" "bareos-fd -t" "Configuration validation"
}

# Test script error handling
test_script_error_handling() {
    log_info "Testing script error handling..."
    
    local scripts=(
        "scripts/preinst"
        "scripts/postinst"
        "scripts/preuninst"
        "scripts/postuninst"
        "scripts/preupgrade"
        "scripts/postupgrade"
    )
    
    for script in "${scripts[@]}"; do
        local full_path="$PROJECT_ROOT/$script"
        
        # Test for error logging functions
        ((TEST_COUNT++))
        if grep -q "log_error\|log_info" "$full_path"; then
            log_success "Error handling: $script has logging functions"
        else
            log_error "Error handling: $script missing logging functions"
        fi
        
        # Test for exit codes
        ((TEST_COUNT++))
        if grep -q "exit [01]" "$full_path"; then
            log_success "Exit codes: $script has proper exit codes"
        else
            log_error "Exit codes: $script missing proper exit codes"
        fi
    done
}

# Test script variable validation
test_script_variables() {
    log_info "Testing script variable validation..."
    
    local postinst="$PROJECT_ROOT/scripts/postinst"
    
    # Test for required variables
    local required_vars=(
        "BAREOS_HOME"
        "BAREOS_USER"
        "BAREOS_CONFIG_DIR"
        "BAREOS_WORK_DIR"
    )
    
    for var in "${required_vars[@]}"; do
        assert_contains "$postinst" "$var=" "Variable definition: $var"
    done
    
    # Test for wizard variable usage
    local wizard_vars=(
        "bareos_director_host"
        "fd_name"
        "fd_password"
        "fd_port"
        "backup_locations"
        "enable_ssl"
        "enable_compression"
        "enable_autostart"
    )
    
    for var in "${wizard_vars[@]}"; do
        assert_contains "$postinst" "\${$var" "Wizard variable usage: $var"
    done
}

# Test configuration file generation
test_config_generation() {
    log_info "Testing configuration file generation..."
    
    local postinst="$PROJECT_ROOT/scripts/postinst"
    
    # Test main configuration generation
    assert_contains "$postinst" "cat > .*bareos-fd.conf" "Main config generation"
    assert_contains "$postinst" "Director {" "Director block in script"
    assert_contains "$postinst" "FileDaemon {" "FileDaemon block in script"
    assert_contains "$postinst" "Messages {" "Messages block in script"
    
    # Test additional config directory structure
    assert_contains "$postinst" "bareos-fd.d" "Config directory structure"
    assert_contains "$postinst" "client/myself.conf" "Client config generation"
    
    # Test SSL certificate generation logic
    assert_contains "$postinst" "if.*enable_ssl" "SSL conditional logic"
    assert_contains "$postinst" "openssl genrsa" "RSA key generation"
    assert_contains "$postinst" "openssl req" "Certificate request"
    assert_contains "$postinst" "openssl x509" "Certificate signing"
}

# Test service integration
test_service_integration() {
    log_info "Testing service integration..."
    
    local postinst="$PROJECT_ROOT/scripts/postinst"
    
    # Test service file creation
    assert_contains "$postinst" "/usr/local/etc/rc.d" "Service directory"
    assert_contains "$postinst" "bareos-fd.sh" "Service script name"
    
    # Test autostart configuration
    assert_contains "$postinst" "enable_autostart" "Autostart logic"
    assert_contains "$postinst" "rc.local" "Startup script integration"
    
    # Test log rotation setup
    assert_contains "$postinst" "/etc/logrotate.d" "Log rotation config"
    assert_contains "$postinst" "weekly" "Log rotation frequency"
    assert_contains "$postinst" "postrotate" "Log rotation hook"
}

# Mock test for script execution in controlled environment
test_script_execution_mock() {
    log_info "Testing script execution in mock environment..."
    
    setup_mock_environment
    
    # Test pre-installation in mock environment
    ((TEST_COUNT++))
    local preinst="$PROJECT_ROOT/scripts/preinst"
    
    # Create a modified version for testing
    local test_preinst="$MOCK_ENV_DIR/test_preinst.sh"
    sed 's|/etc/VERSION|'"$MOCK_ENV_DIR"'/etc/VERSION|g' "$preinst" > "$test_preinst"
    chmod +x "$test_preinst"
    
    if timeout 10 bash "$test_preinst" >/dev/null 2>&1; then
        log_success "Mock execution: Pre-install script runs in mock environment"
    else
        log_error "Mock execution: Pre-install script failed in mock environment"
    fi
    
    cleanup_mock_environment
}

# Main test runner for installation scripts
run_installation_script_tests() {
    echo "================================================"
    echo "Bareos FD SPK - Installation Script Tests"
    echo "================================================"
    echo
    
    test_preinst_script
    test_postinst_script
    test_preuninst_script
    test_postuninst_script
    test_upgrade_scripts
    test_script_error_handling
    test_script_variables
    test_config_generation
    test_service_integration
    test_script_execution_mock
    
    echo
    echo "================================================"
    echo "Installation Script Test Results:"
    echo "================================================"
    echo "Total Tests: $TEST_COUNT"
    echo "Passed: $PASSED_COUNT"
    echo "Failed: $FAILED_COUNT"
    
    if [[ $FAILED_COUNT -eq 0 ]]; then
        echo "✓ All installation script tests passed!"
        return 0
    else
        echo "✗ Some installation script tests failed!"
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_installation_script_tests "$@"
fi