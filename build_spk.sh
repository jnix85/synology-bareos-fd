#!/bin/bash

set -euo pipefail

# Bareos File Daemon SPK Build Script
PACKAGE_NAME="bareos-fd"
VERSION="23.0.0-1"
ARCH="noarch"
BUILD_DIR="build"
SPK_NAME="${PACKAGE_NAME}-${VERSION}-${ARCH}.spk"

log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*"
}

# Clean previous builds
log "Cleaning previous builds..."
rm -rf "$BUILD_DIR" *.spk

# Create build directory
mkdir -p "$BUILD_DIR"

# Download and compile Bareos (or use pre-built binaries)
log "Preparing Bareos binaries..."

# For this example, we'll create a placeholder for the actual binary
# In production, you'd want to compile from source or use official binaries
BAREOS_VERSION="23.0.0"

# Create a simple placeholder bareos-fd binary for demonstration
cat > target/lib/bareos/bareos-fd << 'EOF'
#!/bin/bash
# Bareos File Daemon placeholder binary
# In a production build, this would be the actual compiled bareos-fd binary

echo "Bareos File Daemon $BAREOS_VERSION"
echo "This is a placeholder binary for SPK building demonstration"
echo "In production, replace this with the actual bareos-fd binary"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--config)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -t|--test)
            TEST_CONFIG=1
            shift
            ;;
        -d|--debug)
            DEBUG_LEVEL="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: bareos-fd [options]"
            echo "  -c, --config FILE    Use configuration file"
            echo "  -t, --test          Test configuration"
            echo "  -d, --debug LEVEL   Set debug level"
            echo "  -h, --help          Show this help"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ "${TEST_CONFIG:-0}" = "1" ]; then
    echo "Configuration test: OK"
    exit 0
fi

# In production, this would start the actual daemon
echo "Starting Bareos File Daemon..."
echo "Configuration: ${CONFIG_FILE:-/var/packages/bareos-fd/target/etc/bareos/bareos-fd.conf}"
echo "Debug level: ${DEBUG_LEVEL:-100}"

# Simulate daemon startup
echo $$ > /var/run/bareos-fd.pid
echo "Bareos File Daemon started with PID $$"

# Keep running (in production, this would be the main daemon loop)
trap 'echo "Received shutdown signal"; rm -f /var/run/bareos-fd.pid; exit 0' TERM INT
while true; do
    sleep 1
done
EOF

chmod +x target/lib/bareos/bareos-fd

# Make scripts executable
log "Setting script permissions..."
chmod +x scripts/*
chmod +x target/bin/*

# Copy package files to build directory
log "Copying package files..."
cp -r INFO WIZARD_UIFILES conf scripts target "$BUILD_DIR/"

# Create package icons (placeholder files)
log "Creating package icons..."
# In production, you would create proper PNG icons
echo "PNG placeholder for 72x72 icon" > "$BUILD_DIR/PACKAGE_ICON.PNG"
echo "PNG placeholder for 256x256 icon" > "$BUILD_DIR/PACKAGE_ICON_256.PNG"

# Create the SPK package
log "Creating SPK package..."
cd "$BUILD_DIR"

# Create package archive
tar -czf package.tgz target/

# Create info and scripts archive  
tar -czf INFO.tgz INFO PACKAGE_ICON*.PNG WIZARD_UIFILES/ conf/

# Create the final SPK
tar -cf "../$SPK_NAME" package.tgz INFO.tgz scripts/

cd ..

# Verify the package
log "Verifying SPK package..."
if [ -f "$SPK_NAME" ]; then
    SIZE=$(du -h "$SPK_NAME" | cut -f1)
    log "Successfully created $SPK_NAME (Size: $SIZE)"
    
    # Display package contents
    echo
    echo "Package contents:"
    tar -tvf "$SPK_NAME"
    
    echo
    echo "Package structure verification:"
    tar -tf "$SPK_NAME" | head -20
    
    echo
    echo "To install this package on your Synology NAS:"
    echo "1. Upload $SPK_NAME to your NAS"
    echo "2. Open Package Center"
    echo "3. Click 'Manual Install'"
    echo "4. Select the SPK file"
    echo "5. Follow the installation wizard"
    echo
    echo "Or install via SSH:"
    echo "sudo synopkg install $SPK_NAME"
    
else
    log "Failed to create SPK package"
    exit 1
fi

log "Build completed successfully!"