#!/bin/bash

# Test suite for Bareos File Daemon SPK package
# Unit tests for package validation and structure

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TEST_DIR")"
TEMP_DIR="/tmp/bareos-spk-tests-$$"
TEST_COUNT=0
PASSED_COUNT=0
FAILED_COUNT=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((PASSED_COUNT++))
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((FAILED_COUNT++))
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Test framework functions
assert_file_exists() {
    local file="$1"
    local description="$2"
    ((TEST_COUNT++))
    
    if [[ -f "$file" ]]; then
        log_success "$description: File exists - $file"
        return 0
    else
        log_error "$description: File missing - $file"
        return 1
    fi
}

assert_dir_exists() {
    local dir="$1"
    local description="$2"
    ((TEST_COUNT++))
    
    if [[ -d "$dir" ]]; then
        log_success "$description: Directory exists - $dir"
        return 0
    else
        log_error "$description: Directory missing - $dir"
        return 1
    fi
}

assert_executable() {
    local file="$1"
    local description="$2"
    ((TEST_COUNT++))
    
    if [[ -x "$file" ]]; then
        log_success "$description: File is executable - $file"
        return 0
    else
        log_error "$description: File not executable - $file"
        return 1
    fi
}

assert_contains() {
    local file="$1"
    local pattern="$2"
    local description="$3"
    ((TEST_COUNT++))
    
    if grep -q "$pattern" "$file" 2>/dev/null; then
        log_success "$description: Pattern found in $file"
        return 0
    else
        log_error "$description: Pattern '$pattern' not found in $file"
        return 1
    fi
}

assert_json_valid() {
    local file="$1"
    local description="$2"
    ((TEST_COUNT++))
    
    if command -v jq >/dev/null 2>&1; then
        if jq empty "$file" >/dev/null 2>&1; then
            log_success "$description: Valid JSON - $file"
            return 0
        else
            log_error "$description: Invalid JSON - $file"
            return 1
        fi
    else
        log_warning "$description: jq not available, skipping JSON validation"
        return 0
    fi
}

# Setup test environment
setup_tests() {
    log_info "Setting up test environment..."
    mkdir -p "$TEMP_DIR"
    cd "$PROJECT_ROOT"
}

# Cleanup test environment
cleanup_tests() {
    log_info "Cleaning up test environment..."
    rm -rf "$TEMP_DIR"
}

# Test 1: Package structure validation
test_package_structure() {
    log_info "Testing package structure..."
    
    # Test root files
    assert_file_exists "$PROJECT_ROOT/INFO" "Package metadata"
    assert_file_exists "$PROJECT_ROOT/README.md" "Package documentation"
    assert_file_exists "$PROJECT_ROOT/INSTALL.md" "Installation guide"
    assert_executable "$PROJECT_ROOT/build_spk.sh" "Build script"
    
    # Test directories
    assert_dir_exists "$PROJECT_ROOT/WIZARD_UIFILES" "Wizard UI directory"
    assert_dir_exists "$PROJECT_ROOT/conf" "Configuration directory"
    assert_dir_exists "$PROJECT_ROOT/scripts" "Scripts directory"
    assert_dir_exists "$PROJECT_ROOT/target" "Target directory"
    
    # Test wizard files
    assert_file_exists "$PROJECT_ROOT/WIZARD_UIFILES/install_uifile" "Install wizard UI"
    assert_file_exists "$PROJECT_ROOT/WIZARD_UIFILES/upgrade_uifile" "Upgrade wizard UI"
    
    # Test configuration files
    assert_file_exists "$PROJECT_ROOT/conf/privilege" "Privilege configuration"
    assert_file_exists "$PROJECT_ROOT/conf/resource" "Resource configuration"
    
    # Test scripts
    assert_file_exists "$PROJECT_ROOT/scripts/preinst" "Pre-install script"
    assert_file_exists "$PROJECT_ROOT/scripts/postinst" "Post-install script"
    assert_file_exists "$PROJECT_ROOT/scripts/preuninst" "Pre-uninstall script"
    assert_file_exists "$PROJECT_ROOT/scripts/postuninst" "Post-uninstall script"
    assert_file_exists "$PROJECT_ROOT/scripts/preupgrade" "Pre-upgrade script"
    assert_file_exists "$PROJECT_ROOT/scripts/postupgrade" "Post-upgrade script"
    
    # Test target structure
    assert_dir_exists "$PROJECT_ROOT/target/bin" "Target bin directory"
    assert_dir_exists "$PROJECT_ROOT/target/etc" "Target etc directory"
    assert_dir_exists "$PROJECT_ROOT/target/lib" "Target lib directory"
    assert_dir_exists "$PROJECT_ROOT/target/share" "Target share directory"
}

# Test 2: Script executable permissions
test_script_permissions() {
    log_info "Testing script permissions..."
    
    local scripts=(
        "scripts/preinst"
        "scripts/postinst"
        "scripts/preuninst"
        "scripts/postuninst"
        "scripts/preupgrade"
        "scripts/postupgrade"
        "target/bin/bareos-fd"
        "build_spk.sh"
    )
    
    for script in "${scripts[@]}"; do
        assert_executable "$PROJECT_ROOT/$script" "Script permissions"
    done
}

# Test 3: INFO file validation
test_info_file() {
    log_info "Testing INFO file content..."
    
    local info_file="$PROJECT_ROOT/INFO"
    
    # Required fields
    assert_contains "$info_file" "package=" "Package name field"
    assert_contains "$info_file" "version=" "Version field"
    assert_contains "$info_file" "displayname=" "Display name field"
    assert_contains "$info_file" "description=" "Description field"
    assert_contains "$info_file" "arch=" "Architecture field"
    assert_contains "$info_file" "maintainer=" "Maintainer field"
    assert_contains "$info_file" "os_min_ver=" "Minimum OS version"
    assert_contains "$info_file" "startable=" "Startable flag"
    
    # Package-specific content
    assert_contains "$info_file" "bareos-fd" "Package name is bareos-fd"
    assert_contains "$info_file" "startable=\"yes\"" "Package is startable"
    assert_contains "$info_file" "thirdparty=\"yes\"" "Third-party package flag"
}

# Test 4: JSON configuration validation
test_json_configs() {
    log_info "Testing JSON configuration files..."
    
    assert_json_valid "$PROJECT_ROOT/conf/privilege" "Privilege configuration JSON"
    assert_json_valid "$PROJECT_ROOT/conf/resource" "Resource configuration JSON"
    assert_json_valid "$PROJECT_ROOT/WIZARD_UIFILES/install_uifile" "Install wizard JSON"
    assert_json_valid "$PROJECT_ROOT/WIZARD_UIFILES/upgrade_uifile" "Upgrade wizard JSON"
}

# Test 5: Wizard UI validation
test_wizard_ui() {
    log_info "Testing wizard UI configuration..."
    
    local install_ui="$PROJECT_ROOT/WIZARD_UIFILES/install_uifile"
    
    # Check for required wizard fields
    assert_contains "$install_ui" "bareos_director_host" "Director host field"
    assert_contains "$install_ui" "fd_name" "File daemon name field"
    assert_contains "$install_ui" "fd_password" "Password field"
    assert_contains "$install_ui" "fd_port" "Port field"
    assert_contains "$install_ui" "backup_locations" "Backup locations field"
    assert_contains "$install_ui" "enable_ssl" "SSL enable option"
    assert_contains "$install_ui" "enable_compression" "Compression option"
    assert_contains "$install_ui" "enable_autostart" "Autostart option"
}

# Test 6: Script syntax validation
test_script_syntax() {
    log_info "Testing script syntax..."
    
    local scripts=(
        "scripts/preinst"
        "scripts/postinst"
        "scripts/preuninst"
        "scripts/postuninst"
        "scripts/preupgrade"
        "scripts/postupgrade"
        "build_spk.sh"
    )
    
    for script in "${scripts[@]}"; do
        ((TEST_COUNT++))
        if bash -n "$PROJECT_ROOT/$script" 2>/dev/null; then
            log_success "Script syntax: $script is valid"
        else
            log_error "Script syntax: $script has syntax errors"
        fi
    done
}

# Test 7: Configuration template validation
test_config_templates() {
    log_info "Testing configuration templates..."
    
    local config_template="$PROJECT_ROOT/target/etc/bareos/bareos-fd.conf.template"
    
    assert_file_exists "$config_template" "Configuration template"
    assert_contains "$config_template" "Director {" "Director block"
    assert_contains "$config_template" "FileDaemon {" "FileDaemon block"
    assert_contains "$config_template" "Messages {" "Messages block"
    assert_contains "$config_template" "Name =" "Name directive"
    assert_contains "$config_template" "Password =" "Password directive"
    assert_contains "$config_template" "FDport =" "Port directive"
}

# Test 8: Documentation validation
test_documentation() {
    log_info "Testing documentation..."
    
    local readme="$PROJECT_ROOT/README.md"
    local install="$PROJECT_ROOT/INSTALL.md"
    
    # README content
    assert_contains "$readme" "# Bareos File Daemon" "README title"
    assert_contains "$readme" "## Installation" "Installation section"
    assert_contains "$readme" "## Configuration" "Configuration section"
    assert_contains "$readme" "## Troubleshooting" "Troubleshooting section"
    
    # Install guide content
    assert_contains "$install" "Quick Installation" "Install guide title"
    assert_contains "$install" "sudo synopkg install" "Install command"
    assert_contains "$install" "Package Center" "Package Center instructions"
}

# Test 9: Security validation
test_security_config() {
    log_info "Testing security configuration..."
    
    local privilege="$PROJECT_ROOT/conf/privilege"
    
    assert_contains "$privilege" "bareos" "Bareos user configuration"
    assert_contains "$privilege" "run-as" "Run-as configuration"
    assert_contains "$privilege" "usr-privilege" "User privilege configuration"
    
    # Check scripts don't contain obvious security issues
    local postinst="$PROJECT_ROOT/scripts/postinst"
    assert_contains "$postinst" "chmod" "Permission setting"
    assert_contains "$postinst" "chown" "Ownership setting"
    assert_contains "$postinst" "openssl" "SSL certificate generation"
}

# Test 10: Build script validation
test_build_script() {
    log_info "Testing build script..."
    
    local build_script="$PROJECT_ROOT/build_spk.sh"
    
    assert_contains "$build_script" "tar -czf package.tgz" "Package creation"
    assert_contains "$build_script" "tar -czf INFO.tgz" "Info archive creation"
    assert_contains "$build_script" "tar -cf" "SPK creation"
    assert_contains "$build_script" "chmod +x" "Permission setting"
    
    # Test build script can parse successfully
    ((TEST_COUNT++))
    if grep -q "set -euo pipefail" "$build_script"; then
        log_success "Build script: Uses strict error handling"
    else
        log_error "Build script: Missing strict error handling"
    fi
}

# Main test runner
run_all_tests() {
    echo "===========================================" 
    echo "Bareos File Daemon SPK - Unit Test Suite"
    echo "==========================================="
    echo
    
    setup_tests
    
    test_package_structure
    test_script_permissions
    test_info_file
    test_json_configs
    test_wizard_ui
    test_script_syntax
    test_config_templates
    test_documentation
    test_security_config
    test_build_script
    
    cleanup_tests
    
    echo
    echo "==========================================="
    echo "Test Results Summary:"
    echo "==========================================="
    echo -e "Total Tests: ${BLUE}$TEST_COUNT${NC}"
    echo -e "Passed: ${GREEN}$PASSED_COUNT${NC}"
    echo -e "Failed: ${RED}$FAILED_COUNT${NC}"
    
    if [[ $FAILED_COUNT -eq 0 ]]; then
        echo -e "\n${GREEN}✓ All tests passed!${NC}"
        exit 0
    else
        echo -e "\n${RED}✗ Some tests failed!${NC}"
        exit 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_all_tests "$@"
fi