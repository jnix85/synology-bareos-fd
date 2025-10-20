#!/bin/bash

# Test suite for configuration validation
# Tests Bareos configuration files and templates

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

# Configuration paths
CONFIG_TEMPLATE="$PROJECT_ROOT/target/etc/bareos/bareos-fd.conf.template"
POSTINST_SCRIPT="$PROJECT_ROOT/scripts/postinst"

# Test configuration template structure
test_config_template_structure() {
    log_info "Testing configuration template structure..."
    
    # Test template file exists
    assert_file_exists "$CONFIG_TEMPLATE" "Configuration template"
    
    # Test required blocks
    assert_contains "$CONFIG_TEMPLATE" "Director {" "Director block"
    assert_contains "$CONFIG_TEMPLATE" "FileDaemon {" "FileDaemon block"
    assert_contains "$CONFIG_TEMPLATE" "Messages {" "Messages block"
    
    # Test required directives
    assert_contains "$CONFIG_TEMPLATE" "Name =" "Name directive"
    assert_contains "$CONFIG_TEMPLATE" "Password =" "Password directive"
    assert_contains "$CONFIG_TEMPLATE" "FDport =" "Port directive"
    assert_contains "$CONFIG_TEMPLATE" "WorkingDirectory =" "Working directory directive"
    assert_contains "$CONFIG_TEMPLATE" "Pid Directory =" "PID directory directive"
}

# Test configuration template content
test_config_template_content() {
    log_info "Testing configuration template content..."
    
    # Test default values
    assert_contains "$CONFIG_TEMPLATE" "bareos-dir" "Default director name"
    assert_contains "$CONFIG_TEMPLATE" "bareos-fd" "Default client name"
    assert_contains "$CONFIG_TEMPLATE" "9102" "Default port"
    assert_contains "$CONFIG_TEMPLATE" "/var/lib/bareos" "Default working directory"
    assert_contains "$CONFIG_TEMPLATE" "/var/run/bareos" "Default PID directory"
    
    # Test security settings
    assert_contains "$CONFIG_TEMPLATE" "changeme" "Default password placeholder"
    assert_contains "$CONFIG_TEMPLATE" "Maximum Concurrent Jobs" "Job limit setting"
    
    # Test logging configuration
    assert_contains "$CONFIG_TEMPLATE" "File =" "File logging directive"
    assert_contains "$CONFIG_TEMPLATE" "/var/log/bareos" "Log directory"
    assert_contains "$CONFIG_TEMPLATE" "director =" "Director logging"
}

# Test generated configuration in postinst
test_generated_config() {
    log_info "Testing generated configuration in postinst..."
    
    # Test configuration generation logic
    assert_contains "$POSTINST_SCRIPT" "cat > .*bareos-fd.conf" "Config generation"
    assert_contains "$POSTINST_SCRIPT" "Director {" "Generated Director block"
    assert_contains "$POSTINST_SCRIPT" "FileDaemon {" "Generated FileDaemon block"
    assert_contains "$POSTINST_SCRIPT" "Messages {" "Generated Messages block"
    
    # Test variable substitution
    assert_contains "$POSTINST_SCRIPT" "\${bareos_director_host" "Director host substitution"
    assert_contains "$POSTINST_SCRIPT" "\${fd_name" "File daemon name substitution"
    assert_contains "$POSTINST_SCRIPT" "\${fd_password" "Password substitution"
    assert_contains "$POSTINST_SCRIPT" "\${fd_port" "Port substitution"
    
    # Test conditional SSL configuration
    assert_contains "$POSTINST_SCRIPT" "if.*enable_ssl" "SSL conditional"
    assert_contains "$POSTINST_SCRIPT" "TLS Enable = yes" "TLS enable directive"
    assert_contains "$POSTINST_SCRIPT" "TLS Certificate" "TLS certificate directive"
    assert_contains "$POSTINST_SCRIPT" "TLS Key" "TLS key directive"
}

# Test additional configuration directories
test_config_directories() {
    log_info "Testing configuration directory structure..."
    
    # Test directory creation in postinst
    assert_contains "$POSTINST_SCRIPT" "bareos-fd.d" "Additional config directory"
    assert_contains "$POSTINST_SCRIPT" "client.*director.*messages" "Config subdirectories"
    
    # Test client configuration generation
    assert_contains "$POSTINST_SCRIPT" "client/myself.conf" "Client config file"
    assert_contains "$POSTINST_SCRIPT" "Client {" "Generated client block"
    assert_contains "$POSTINST_SCRIPT" "Maximum Concurrent Jobs" "Client job limit"
    
    # Test compression configuration
    assert_contains "$POSTINST_SCRIPT" "enable_compression" "Compression option"
    assert_contains "$POSTINST_SCRIPT" "compression = GZIP" "GZIP compression"
}

# Test SSL/TLS configuration
test_ssl_config() {
    log_info "Testing SSL/TLS configuration..."
    
    # Test SSL certificate generation
    assert_contains "$POSTINST_SCRIPT" "openssl genrsa" "RSA key generation"
    assert_contains "$POSTINST_SCRIPT" "openssl req" "Certificate request"
    assert_contains "$POSTINST_SCRIPT" "openssl x509" "Certificate signing"
    
    # Test certificate files
    assert_contains "$POSTINST_SCRIPT" "bareos-ca.key" "CA key file"
    assert_contains "$POSTINST_SCRIPT" "bareos-ca.pem" "CA certificate file"
    assert_contains "$POSTINST_SCRIPT" "bareos-fd.key" "FD key file"
    assert_contains "$POSTINST_SCRIPT" "bareos-fd.pem" "FD certificate file"
    
    # Test certificate permissions
    assert_contains "$POSTINST_SCRIPT" "chmod 600.*key" "Private key permissions"
    assert_contains "$POSTINST_SCRIPT" "chmod 644.*pem" "Certificate permissions"
    assert_contains "$POSTINST_SCRIPT" "chown.*bareos.*key.*pem" "Certificate ownership"
}

# Test configuration validation
test_config_validation() {
    log_info "Testing configuration validation..."
    
    # Test validation in scripts
    assert_contains "$POSTINST_SCRIPT" "bareos-fd -t" "Configuration test"
    assert_contains "$POSTINST_SCRIPT" "-c.*bareos-fd.conf" "Config file specification"
    
    # Test validation in service script
    local service_script="$PROJECT_ROOT/scripts/start-stop-status"
    if [[ -f "$service_script" ]]; then
        assert_contains "$service_script" "-t -c.*BAREOS_CONFIG" "Service script validation"
        assert_contains "$service_script" "Configuration validation failed" "Validation error handling"
    fi
    
    # Test final validation in postinst
    assert_contains "$POSTINST_SCRIPT" "Configuration validation failed" "Final validation error"
    assert_contains "$POSTINST_SCRIPT" "exit 1.*validation" "Validation exit code"
}

# Test backup location configuration
test_backup_locations() {
    log_info "Testing backup location configuration..."
    
    # Test backup location processing
    assert_contains "$POSTINST_SCRIPT" "backup_locations" "Backup locations variable"
    assert_contains "$POSTINST_SCRIPT" "IFS=','" "Comma separator parsing"
    assert_contains "$POSTINST_SCRIPT" "read -ra LOCATIONS" "Location array parsing"
    
    # Test ACL configuration
    assert_contains "$POSTINST_SCRIPT" "setfacl" "ACL setting"
    assert_contains "$POSTINST_SCRIPT" "u:bareos:r-x" "Bareos user ACL"
    
    # Test directory existence check
    assert_contains "$POSTINST_SCRIPT" "if.*-d.*location" "Directory existence check"
}

# Test message and logging configuration
test_logging_config() {
    log_info "Testing logging configuration..."
    
    # Test log directory configuration
    assert_contains "$POSTINST_SCRIPT" "/var/log/bareos" "Log directory"
    assert_contains "$POSTINST_SCRIPT" "mkdir -p.*log" "Log directory creation"
    assert_contains "$POSTINST_SCRIPT" "chown.*log" "Log directory ownership"
    
    # Test log rotation configuration
    assert_contains "$POSTINST_SCRIPT" "logrotate.d" "Log rotation config"
    assert_contains "$POSTINST_SCRIPT" "weekly" "Rotation frequency"
    assert_contains "$POSTINST_SCRIPT" "rotate 4" "Rotation count"
    assert_contains "$POSTINST_SCRIPT" "compress" "Log compression"
    assert_contains "$POSTINST_SCRIPT" "postrotate" "Post-rotation script"
    
    # Test log file permissions
    assert_contains "$POSTINST_SCRIPT" "create 644 bareos" "Log file permissions"
}

# Test configuration defaults and fallbacks
test_config_defaults() {
    log_info "Testing configuration defaults and fallbacks..."
    
    # Test default value patterns
    local defaults=(
        "bareos_director_host:-bareos-dir"
        "fd_name:-.*hostname.*-fd"
        "fd_password:-changeme"
        "fd_port:-9102"
        "backup_locations:-/volume1"
        "enable_ssl:-true"
        "enable_compression:-true"
        "enable_autostart:-true"
    )
    
    for default in "${defaults[@]}"; do
        ((TEST_COUNT++))
        if grep -q "\${$default}" "$POSTINST_SCRIPT"; then
            log_success "Configuration defaults: $default found"
        else
            log_error "Configuration defaults: $default missing"
        fi
    done
}

# Test configuration file syntax validation
test_config_syntax() {
    log_info "Testing configuration file syntax..."
    
    # Create a temporary config file for testing
    local temp_config="/tmp/test_bareos_config_$$"
    
    # Extract the configuration template from postinst script
    sed -n '/cat > .*bareos-fd\.conf/,/^EOF$/p' "$POSTINST_SCRIPT" | \
    sed '1d;$d' | \
    sed 's/\${[^}]*:-[^}]*}/test_value/g' | \
    sed 's/\${[^}]*}/test_value/g' | \
    sed '/^\s*\$(if.*then$/,/^\s*fi)$/d' > "$temp_config"
    
    ((TEST_COUNT++))
    if [[ -s "$temp_config" ]]; then
        # Basic syntax check - should have proper braces
        if grep -q "^[[:space:]]*}[[:space:]]*$" "$temp_config"; then
            log_success "Config syntax: Generated config has proper block structure"
        else
            log_error "Config syntax: Generated config missing proper block structure"
        fi
    else
        log_error "Config syntax: Could not extract config template for testing"
    fi
    
    # Cleanup
    rm -f "$temp_config"
}

# Test plugin directory configuration
test_plugin_config() {
    log_info "Testing plugin directory configuration..."
    
    # Test plugin directory in template
    assert_contains "$CONFIG_TEMPLATE" "Plugin Directory" "Plugin directory directive"
    assert_contains "$CONFIG_TEMPLATE" "lib/bareos" "Plugin directory path"
    
    # Test plugin directory in generated config
    assert_contains "$POSTINST_SCRIPT" "Plugin Directory.*lib/bareos" "Generated plugin directory"
    
    # Test plugin directory creation
    local lib_dir="$PROJECT_ROOT/target/lib/bareos"
    assert_dir_exists "$lib_dir" "Plugin directory exists"
    
    # Test plugin documentation
    local plugin_readme="$lib_dir/README-BINARIES.txt"
    assert_file_exists "$plugin_readme" "Plugin documentation"
}

# Test working directory configuration
test_working_directory() {
    log_info "Testing working directory configuration..."
    
    # Test working directory variable
    assert_contains "$POSTINST_SCRIPT" "BAREOS_WORK_DIR" "Working directory variable"
    assert_contains "$POSTINST_SCRIPT" "/var/lib/bareos" "Working directory path"
    
    # Test directory creation and permissions
    assert_contains "$POSTINST_SCRIPT" "mkdir -p.*BAREOS_WORK_DIR" "Working directory creation"
    assert_contains "$POSTINST_SCRIPT" "chown.*BAREOS_WORK_DIR" "Working directory ownership"
    assert_contains "$POSTINST_SCRIPT" "chmod 750.*BAREOS_WORK_DIR" "Working directory permissions"
}

# Main test runner for configuration tests
run_configuration_tests() {
    echo "============================================"
    echo "Bareos FD SPK - Configuration Tests"
    echo "============================================"
    echo
    
    test_config_template_structure
    test_config_template_content
    test_generated_config
    test_config_directories
    test_ssl_config
    test_config_validation
    test_backup_locations
    test_logging_config
    test_config_defaults
    test_config_syntax
    test_plugin_config
    test_working_directory
    
    echo
    echo "============================================"
    echo "Configuration Test Results:"
    echo "============================================"
    echo "Total Tests: $TEST_COUNT"
    echo "Passed: $PASSED_COUNT"
    echo "Failed: $FAILED_COUNT"
    
    if [[ $FAILED_COUNT -eq 0 ]]; then
        echo "✓ All configuration tests passed!"
        return 0
    else
        echo "✗ Some configuration tests failed!"
        return 1
    fi
}

# Run tests if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    run_configuration_tests "$@"
fi