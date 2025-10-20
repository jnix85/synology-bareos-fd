# Quick Installation Guide

## Download and Install

1. **Build the SPK** (if not already built):
   ```bash
   chmod +x build_spk.sh
   ./build_spk.sh
   ```

2. **Upload to Synology**:
   - Copy `bareos-fd-23.0.0-1-noarch.spk` to your NAS
   - Or download directly to your NAS

3. **Install via Package Center**:
   - Open Package Center
   - Click "Manual Install"
   - Select the SPK file
   - Complete the wizard

4. **Or install via SSH**:
   ```bash
   sudo synopkg install bareos-fd-23.0.0-1-noarch.spk
   sudo synopkg start bareos-fd
   ```

## Configuration Wizard Settings

- **Director Address**: IP or hostname of your Bareos Director
- **Client Name**: Unique name (default: hostname-fd)
- **Password**: Strong password for authentication
- **Port**: 9102 (default) or custom port
- **Backup Locations**: /volume1,/volume2 (adjust as needed)
- **Enable SSL**: Yes (recommended)
- **Enable Compression**: Yes (recommended)
- **Autostart**: Yes (recommended)

## Verify Installation

```bash
# Check service status
sudo synopkg status bareos-fd

# Run verification script
/var/packages/bareos-fd/target/bin/bareos-verify

# View logs
tail -f /var/log/bareos/bareos-fd.log
```

## Next Steps

1. Configure your Bareos Director to include this client
2. Create backup jobs for your Synology volumes
3. Test backup and restore operations
4. Set up monitoring and alerting

For detailed configuration, see the main README.md file.