#!/bin/bash

# Integration tests for Bareos File Daemon SPK package
# Tests complete workflows and end-to-end functionality

set -euo pipefail

# Source test framework
SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
TEST_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$TEST_DIR")")"
source "$TEST_DIR/../unit/test_package_validation.sh" 2>/dev/null || {
    # If sourcing fails, define minimal framework
    log_info() { echo "[INFO] $1"; }
    log_success() { echo "[PASS] $1"; PASSED_COUNT=$((PASSED_COUNT + 1)); }
    log_error() { echo "[FAIL] $1"; FAILED_COUNT=$((FAILED_COUNT + 1)); }
    log_warning() { echo "[WARN] $1"; }
    TEST_COUNT=0; PASSED_COUNT=0; FAILED_COUNT=0
}

# Integration test configuration
INTEGRATION_TEMP_DIR="/tmp/bareos-integration-tests-$$"
BUILD_TEST_DIR="$INTEGRATION_TEMP_DIR/build"
INSTALL_TEST_DIR="$INTEGRATION_TEMP_DIR/install"

# Setup integration test environment
setup_integration_tests() {
    log_info "Setting up integration test environment..."
    
    mkdir -p "$INTEGRATION_TEMP_DIR"
    mkdir -p "$BUILD_TEST_DIR"
    mkdir -p "$INSTALL_TEST_DIR"
    
    # Copy project to test directory
    cp -r "$PROJECT_ROOT"/* "$BUILD_TEST_DIR/" 2>/dev/null || true
}

# Cleanup integration test environment
cleanup_integration_tests() {
    log_info "Cleaning up integration test environment..."
    rm -rf "$INTEGRATION_TEMP_DIR"
}

# Test complete SPK build process
test_spk_build_process() {
    log_info "Testing complete SPK build process..."
    
    cd "$BUILD_TEST_DIR"
    
    # Test build script execution
    TEST_COUNT=$((TEST_COUNT + 1))
    if timeout 60 bash build_spk.sh >/dev/null 2>&1; then
        log_success "SPK build: Build script executed successfully"
    else
        log_error "SPK build: Build script failed or timed out"
        return 1
    fi
    
    # Test SPK file creation
    TEST_COUNT=$((TEST_COUNT + 1))
    local spk_file=$(ls *.spk 2>/dev/null | head -1)
    if [[ -f "$spk_file" ]]; then
        log_success "SPK build: SPK file created ($spk_file)"
    else
        log_error "SPK build: No SPK file created"
        return 1
    fi
    
    # Test SPK file structure
    TEST_COUNT=$((TEST_COUNT + 1))
    if tar -tf "$spk_file" | grep -q "package.tgz\|INFO.tgz\|scripts"; then
        log_success "SPK build: SPK file has correct structure"
    else
        log_error "SPK build: SPK file has incorrect structure"
        return 1
    fi
    
    # Test SPK file size (should be reasonable)
    TEST_COUNT=$((TEST_COUNT + 1))
    local size=$(stat -f%z "$spk_file" 2>/dev/null || stat -c%s "$spk_file" 2>/dev/null)
    if [[ $size -gt 1024 && $size -lt 10485760 ]]; then  # Between 1KB and 10MB
        log_success "SPK build: SPK file size is reasonable ($size bytes)"
    else
        log_error "SPK build: SPK file size is suspicious ($size bytes)"
    fi
    
    return 0
}

# Test SPK package content validation
test_spk_content_validation() {
    log_info "Testing SPK package content validation..."
    
    cd "$BUILD_TEST_DIR"
    local spk_file=$(ls *.spk 2>/dev/null | head -1)
    
    if [[ ! -f "$spk_file" ]]; then
        log_error "SPK content: No SPK file found for validation"
        return 1
    fi
    
    # Extract SPK for examination
    local extract_dir="$BUILD_TEST_DIR/extracted"
    mkdir -p "$extract_dir"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    if tar -xf "$spk_file" -C "$extract_dir" 2>/dev/null; then
        log_success "SPK content: SPK file extracts successfully"
    else
        log_error "SPK content: SPK file extraction failed"
        return 1
    fi
    
    # Test required archives exist
    TEST_COUNT=$((TEST_COUNT + 1))
    if [[ -f "$extract_dir/package.tgz" && -f "$extract_dir/INFO.tgz" ]]; then
        log_success "SPK content: Required archives present"
    else
        log_error "SPK content: Missing required archives"
        return 1
    fi
    
    # Test scripts directory
    TEST_COUNT=$((TEST_COUNT + 1))
    if [[ -d "$extract_dir/scripts" ]]; then
        log_success "SPK content: Scripts directory present"
    else
        log_error "SPK content: Scripts directory missing"
        return 1
    fi
    
    # Test package.tgz content
    TEST_COUNT=$((TEST_COUNT + 1))
    if tar -tzf "$extract_dir/package.tgz" | grep -q "target/"; then
        log_success "SPK content: Package archive contains target directory"
    else
        log_error "SPK content: Package archive missing target directory"
        return 1
    fi
    
    # Test INFO.tgz content
    TEST_COUNT=$((TEST_COUNT + 1))
    if tar -tzf "$extract_dir/INFO.tgz" | grep -q "INFO\|WIZARD_UIFILES"; then
        log_success "SPK content: Info archive contains required files"
    else
        log_error "SPK content: Info archive missing required files"
        return 1
    fi
    
    return 0
}

# Test installation workflow simulation
test_installation_workflow() {
    log_info "Testing installation workflow simulation..."
    
    # Create mock installation environment
    local mock_root="$INSTALL_TEST_DIR/mock_synology"
    mkdir -p "$mock_root"/{var/{packages,lib,log,run},usr/syno/sbin,etc,tmp}
    
    # Create mock Synology commands
    cat > "$mock_root/usr/syno/sbin/synouser" << 'EOF'
#!/bin/bash
echo "Mock: Creating user $3" >&2
exit 0
EOF
    
    cat > "$mock_root/usr/syno/sbin/synogroup" << 'EOF'
#!/bin/bash
echo "Mock: Adding user to group" >&2
exit 0
EOF
    
    chmod +x "$mock_root/usr/syno/sbin"/*
    
    # Create mock system files
    echo "buildnumber=42000" > "$mock_root/etc/VERSION"
    
    # Create mock package installation directory
    local package_dir="$mock_root/var/packages/bareos-fd"
    mkdir -p "$package_dir"
    
    # Copy target directory from project
    cp -r "$PROJECT_ROOT/target" "$package_dir/"
    cp -r "$PROJECT_ROOT/scripts" "$package_dir/"
    
    # Set environment variables for mock
    export PATH="$mock_root/usr/syno/sbin:$PATH"
    export bareos_director_host="test-director"
    export fd_name="test-fd"
    export fd_password="test-password"
    export fd_port="9102"
    export backup_locations="/volume1"
    export enable_ssl="true"
    export enable_compression="true"
    export enable_autostart="true"
    
    # Save wizard variables
    env | grep -E "^(bareos_|fd_|enable_|backup_)" > "$mock_root/tmp/bareos_install_vars"
    
    # Test pre-installation script
    TEST_COUNT=$((TEST_COUNT + 1))
    cd "$mock_root"
    local preinst="$package_dir/scripts/preinst"
    if timeout 30 bash "$preinst" >/dev/null 2>&1; then
        log_success "Installation workflow: Pre-install script succeeded"
    else
        log_error "Installation workflow: Pre-install script failed"
    fi
    
    # Test post-installation script (with mocked commands)
    TEST_COUNT=$((TEST_COUNT + 1))
    local postinst="$package_dir/scripts/postinst"
    # Create mock commands that could be called
    cat > "$mock_root/openssl" << 'EOF'
#!/bin/bash
# Mock openssl command
case "$1" in
    genrsa) echo "Mock: Generating RSA key" >&2 ;;
    req) echo "Mock: Creating certificate request" >&2 ;;
    x509) echo "Mock: Signing certificate" >&2 ;;
esac
exit 0
EOF
    chmod +x "$mock_root/openssl"
    export PATH="$mock_root:$PATH"
    
    if timeout 30 bash "$postinst" >/dev/null 2>&1; then
        log_success "Installation workflow: Post-install script succeeded"
    else
        log_error "Installation workflow: Post-install script failed"
    fi
    
    # Test configuration file generation
    TEST_COUNT=$((TEST_COUNT + 1))
    local config_file="$package_dir/target/etc/bareos/bareos-fd.conf"
    if [[ -f "$config_file" ]]; then
        log_success "Installation workflow: Configuration file generated"
        
        # Test configuration content
        TEST_COUNT=$((TEST_COUNT + 1))
        if grep -q "test-director\|test-fd\|test-password" "$config_file"; then
            log_success "Installation workflow: Configuration contains wizard values"
        else
            log_error "Installation workflow: Configuration missing wizard values"
        fi
    else
        log_error "Installation workflow: Configuration file not generated"
    fi
    
    return 0
}

# Test service lifecycle simulation
test_service_lifecycle() {
    log_info "Testing service lifecycle simulation..."
    
    local mock_root="$INSTALL_TEST_DIR/mock_synology"
    local package_dir="$mock_root/var/packages/bareos-fd"
    local service_script="$package_dir/scripts/start-stop-status"
    
    if [[ ! -f "$service_script" ]]; then
        log_error "Service lifecycle: Service script not found"
        return 1
    fi
    
    # Create mock bareos-fd binary
    mkdir -p "$package_dir/target/lib/bareos"
    cat > "$package_dir/target/lib/bareos/bareos-fd" << 'EOF'
#!/bin/bash
# Mock bareos-fd binary
case "$1" in
    -t) echo "Mock: Configuration test OK"; exit 0 ;;
    -c) echo "Mock: Starting with config $2"; echo $$ > /var/run/bareos-fd.pid; sleep 60 & exit 0 ;;
    *) echo "Mock bareos-fd: $*"; exit 0 ;;
esac
EOF
    chmod +x "$package_dir/target/lib/bareos/bareos-fd"
    
    # Create directories that service script expects
    mkdir -p "$mock_root/var/run" "$mock_root/var/log"
    
    cd "$mock_root"
    
    # Test service status when not running
    TEST_COUNT=$((TEST_COUNT + 1))
    if timeout 10 bash "$service_script" status >/dev/null 2>&1; then
        # Status should return non-zero when not running, but script should execute
        log_success "Service lifecycle: Status command executes (daemon not running)"
    else
        log_error "Service lifecycle: Status command failed to execute"
    fi
    
    # Test invalid command handling
    TEST_COUNT=$((TEST_COUNT + 1))
    if bash "$service_script" invalid_command 2>&1 | grep -q "Usage:"; then
        log_success "Service lifecycle: Invalid command shows usage"
    else
        log_error "Service lifecycle: Invalid command doesn't show usage"
    fi
    
    return 0
}

# Test upgrade workflow simulation
test_upgrade_workflow() {
    log_info "Testing upgrade workflow simulation..."
    
    local mock_root="$INSTALL_TEST_DIR/mock_synology"
    local package_dir="$mock_root/var/packages/bareos-fd"
    
    # Set upgrade variables
    export preserve_config="true"
    export backup_config="true"
    
    # Test pre-upgrade script
    TEST_COUNT=$((TEST_COUNT + 1))
    local preupgrade="$package_dir/scripts/preupgrade"
    if timeout 30 bash "$preupgrade" >/dev/null 2>&1; then
        log_success "Upgrade workflow: Pre-upgrade script succeeded"
    else
        log_error "Upgrade workflow: Pre-upgrade script failed"
    fi
    
    # Test that configuration backup was created
    TEST_COUNT=$((TEST_COUNT + 1))
    if [[ -f "/tmp/bareos_config_backup_location" ]]; then
        log_success "Upgrade workflow: Configuration backup location saved"
    else
        log_error "Upgrade workflow: Configuration backup location not saved"
    fi
    
    # Test post-upgrade script
    TEST_COUNT=$((TEST_COUNT + 1))
    local postupgrade="$package_dir/scripts/postupgrade"
    if timeout 30 bash "$postupgrade" >/dev/null 2>&1; then
        log_success "Upgrade workflow: Post-upgrade script succeeded"
    else
        log_error "Upgrade workflow: Post-upgrade script failed"
    fi
    
    return 0
}

# Test uninstallation workflow simulation
test_uninstallation_workflow() {
    log_info "Testing uninstallation workflow simulation..."
    
    local mock_root="$INSTALL_TEST_DIR/mock_synology"
    local package_dir="$mock_root/var/packages/bareos-fd"
    
    cd "$mock_root"
    
    # Test pre-uninstall script
    TEST_COUNT=$((TEST_COUNT + 1))
    local preuninst="$package_dir/scripts/preuninst"
    if timeout 30 bash "$preuninst" >/dev/null 2>&1; then
        log_success "Uninstallation workflow: Pre-uninstall script succeeded"
    else
        log_error "Uninstallation workflow: Pre-uninstall script failed"
    fi
    
    # Test post-uninstall script
    TEST_COUNT=$((TEST_COUNT + 1))
    local postuninst="$package_dir/scripts/postuninst"
    if timeout 30 bash "$postuninst" >/dev/null 2>&1; then
        log_success "Uninstallation workflow: Post-uninstall script succeeded"
    else
        log_error "Uninstallation workflow: Post-uninstall script failed"
    fi
    
    return 0
}

# Test wizard UI integration
test_wizard_integration() {
    log_info "Testing wizard UI integration..."
    
    # Test wizard UI JSON validation
    local install_ui="$PROJECT_ROOT/WIZARD_UIFILES/install_uifile"
    local upgrade_ui="$PROJECT_ROOT/WIZARD_UIFILES/upgrade_uifile"
    
    TEST_COUNT=$((TEST_COUNT + 1))
    if command -v jq >/dev/null 2>&1; then
        if jq empty "$install_ui" >/dev/null 2>&1 && jq empty "$upgrade_ui" >/dev/null 2>&1; then
            log_success "Wizard integration: UI files are valid JSON"
        else
            log_error "Wizard integration: UI files have invalid JSON"
        fi
    else
        log_warning "Wizard integration: jq not available, skipping JSON validation"
    fi
    
    # Test wizard field extraction
    TEST_COUNT=$((TEST_COUNT + 1))
    local required_fields=(
        "bareos_director_host"
        "fd_name"
        "fd_password"
        "fd_port"
        "backup_locations"
        "enable_ssl"
        "enable_compression"
        "enable_autostart"
    )
    
    local all_fields_found=true
    for field in "${required_fields[@]}"; do
        if ! grep -q "\"$field\"" "$install_ui"; then
            all_fields_found=false
            break
        fi
    done
    
    if $all_fields_found; then
        log_success "Wizard integration: All required fields present in UI"
    else
        log_error "Wizard integration: Missing required fields in UI"
    fi
    
    return 0
}

# Test security validation
test_security_integration() {
    log_info "Testing security integration..."
    
    local mock_root="$INSTALL_TEST_DIR/mock_synology"
    local package_dir="$mock_root/var/packages/bareos-fd"
    
    # Test user creation and permissions
    TEST_COUNT=$((TEST_COUNT + 1))
    if grep -q "synouser.*add.*bareos" "$package_dir/scripts/postinst"; then
        log_success "Security integration: User creation script present"
    else
        log_error "Security integration: User creation script missing"
    fi
    
    # Test file permissions in postinst
    TEST_COUNT=$((TEST_COUNT + 1))
    if grep -q "chmod.*chown" "$package_dir/scripts/postinst"; then
        log_success "Security integration: File permission setting present"
    else
        log_error "Security integration: File permission setting missing"
    fi
    
    # Test SSL certificate generation
    TEST_COUNT=$((TEST_COUNT + 1))
    if grep -q "openssl.*bareos-fd.key\|bareos-fd.pem" "$package_dir/scripts/postinst"; then
        log_success "Security integration: SSL certificate generation present"
    else
        log_error "Security integration: SSL certificate generation missing"
    fi
    
    return 0
}

# Test error handling and recovery
test_error_handling_integration() {
    log_info "Testing error handling and recovery..."
    
    local mock_root="$INSTALL_TEST_DIR/mock_synology"
    local package_dir="$mock_root/var/packages/bareos-fd"
    
    # Test script error handling
    local scripts=(
        "scripts/preinst"
        "scripts/postinst"
        "scripts/preupgrade"
        "scripts/postupgrade"
        "scripts/preuninst"
        "scripts/postuninst"
    )
    
    TEST_COUNT=$((TEST_COUNT + 1))
    local error_handling_count=0
    for script in "${scripts[@]}"; do
        if grep -q "log_error\|exit 1" "$package_dir/$script"; then
            error_handling_count=$((error_handling_count + 1))
        fi
    done
    
    if [[ $error_handling_count -eq ${#scripts[@]} ]]; then
        log_success "Error handling: All scripts have error handling"
    else
        log_error "Error handling: Some scripts missing error handling ($error_handling_count/${#scripts[@]})"
    fi
    
    return 0
}

# Main integration test runner
run_integration_tests() {
    echo "=================================================="
    echo "Bareos FD SPK - Integration Tests"
    echo "=================================================="
    echo
    
    setup_integration_tests
    
    # Run integration tests
    test_spk_build_process
    test_spk_content_validation
    test_installation_workflow
    test_service_lifecycle
    test_upgrade_workflow
    test_uninstallation_workflow
    test_wizard_integration
    test_security_integration
    test_error_handling_integration
    
    cleanup_integration_tests
    
    echo
    echo "=================================================="
    echo "Integration Test Results:"
    echo "=================================================="
    echo "Total Tests: $TEST_COUNT"
    echo "Passed: $PASSED_COUNT"
    echo "Failed: $FAILED_COUNT"
    
    if [[ $FAILED_COUNT -eq 0 ]]; then
        echo "✓ All integration tests passed!"
        exit 0
    else
        echo "✗ Some integration tests failed!"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_integration_tests "$@"
fi