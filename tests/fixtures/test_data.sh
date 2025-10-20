# Test fixtures and mock data for Bareos FD SPK tests

# Mock Synology system information
mock_dsm_version="7.2-64570"
mock_hostname="synology-nas"
mock_architecture="x86_64"

# Mock wizard configuration values
export TEST_BAREOS_DIRECTOR_HOST="test-bareos-dir.local"
export TEST_FD_NAME="test-synology-fd"
export TEST_FD_PASSWORD="test-secure-password-123"
export TEST_FD_PORT="9102"
export TEST_BACKUP_LOCATIONS="/volume1/shared,/volume2/backups"
export TEST_ENABLE_SSL="true"
export TEST_ENABLE_COMPRESSION="true"
export TEST_ENABLE_AUTOSTART="true"

# Mock file paths
export MOCK_VAR_DIR="/tmp/bareos-test-var"
export MOCK_ETC_DIR="/tmp/bareos-test-etc"
export MOCK_USR_DIR="/tmp/bareos-test-usr"

# Expected configuration content patterns
expected_director_block='Director {
  Name = test-bareos-dir.local-dir
  Password = "test-secure-password-123"
}'

expected_filedaemon_block='FileDaemon {
  Name = test-synology-fd
  FDport = 9102
  WorkingDirectory = /var/lib/bareos
  Pid Directory = /var/run/bareos
  Plugin Directory = /var/packages/bareos-fd/target/lib/bareos/plugins
  Maximum Concurrent Jobs = 20
}'

expected_messages_block='Messages {
  Name = Standard
  director = test-bareos-dir.local-dir = all, !skipped, !restored
  File = /var/log/bareos/bareos-fd.log = all, !skipped
}'

# Test SSL certificate data (for validation)
test_ssl_ca_cert="-----BEGIN CERTIFICATE-----
MIIFazCCA1OgAwIBAgIUQvxvKvwxrPYweq4Y7BOTEiE9DAgwDQYJKoZIhvcNAQEL
BQAwRTELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRAwDgYDVQQHDAdMb2NhbEwx
FzAVBgNVBAoMDkJhcmVvcyBUZXN0IENBMB4XDTIzMTAxOTAwMDAwMFoXDTMzMTAx
OTAwMDAwMFowRTELMAkGA1UEBhMCVVMxCzAJBgNVBAgMAkNBMRAwDgYDVQQHDAdM
b2NhbEwxFzAVBgNVBAoMDkJhcmVvcyBUZXN0IENBMIICIJ...
-----END CERTIFICATE-----"

# Mock system commands for testing
create_mock_commands() {
    local mock_dir="$1"
    mkdir -p "$mock_dir"
    
    # Mock synouser command
    cat > "$mock_dir/synouser" << 'EOF'
#!/bin/bash
case "$1" in
    --add) echo "Mock: Created user $2"; exit 0 ;;
    --del) echo "Mock: Deleted user $2"; exit 0 ;;
    *) echo "Mock synouser: $*"; exit 0 ;;
esac
EOF
    
    # Mock synogroup command
    cat > "$mock_dir/synogroup" << 'EOF'
#!/bin/bash
echo "Mock synogroup: $*"
exit 0
EOF
    
    # Mock openssl command
    cat > "$mock_dir/openssl" << 'EOF'
#!/bin/bash
case "$1" in
    genrsa) echo "Mock: Generated RSA key" >&2; touch "${@: -1}" ;;
    req) echo "Mock: Created certificate request" >&2; touch "${@: -1}" ;;
    x509) echo "Mock: Signed certificate" >&2; touch "${@: -1}" ;;
    *) echo "Mock openssl: $*" >&2 ;;
esac
exit 0
EOF
    
    # Mock get_key_value function (from Synology)
    cat > "$mock_dir/get_key_value" << 'EOF'
#!/bin/bash
if [ "$1" = "/etc/VERSION" ] && [ "$2" = "buildnumber" ]; then
    echo "42000"
else
    echo "mock_value"
fi
EOF
    
    chmod +x "$mock_dir"/*
}

# Create mock file system structure
create_mock_filesystem() {
    local base_dir="$1"
    
    # Create directory structure
    mkdir -p "$base_dir"/{var/{packages,lib,log,run},etc,usr/syno/sbin,tmp}
    mkdir -p "$base_dir/volume1/shared" "$base_dir/volume2/backups"
    
    # Create mock system files
    echo "buildnumber=42000" > "$base_dir/etc/VERSION"
    echo "productversion=7.2" >> "$base_dir/etc/VERSION"
    echo "buildphase=GM" >> "$base_dir/etc/VERSION"
    
    # Create mock package directory
    mkdir -p "$base_dir/var/packages/bareos-fd/target"/{bin,etc/bareos,lib/bareos,share}
    
    # Create mock commands
    create_mock_commands "$base_dir/usr/syno/sbin"
    
    echo "$base_dir"
}

# Cleanup mock environment
cleanup_mock_filesystem() {
    local base_dir="$1"
    rm -rf "$base_dir"
}