# Bareos File Daemon for Synology DSM

A complete Synology SPK package for installing and managing Bareos File Daemon on Synology NAS devices.

## Overview

This package provides the Bareos File Daemon (bareos-fd), which is the client component of the Bareos backup system. It runs on your Synology NAS and communicates with a Bareos Director to perform backup and restore operations.

## Features

- **Full DSM Integration**: Native Synology DSM Package Center support
- **Configuration Wizard**: Easy setup through DSM interface
- **SSL/TLS Support**: Optional encryption with auto-generated certificates
- **Multi-Volume Support**: Configurable backup locations across Synology volumes
- **Service Management**: Start/stop/restart through DSM
- **Log Management**: Automated log rotation and monitoring
- **Health Monitoring**: Built-in verification and status checking
- **Security**: Dedicated user, proper file permissions, and ACL support

## Requirements

- Synology DSM 7.0 or higher
- Minimum 100MB free disk space
- Python 3.8 or higher (automatically installed)
- SSH service enabled (for advanced configuration)

## Installation

### Method 1: Package Center (Recommended)

1. Download the `bareos-fd-23.0.0-1-noarch.spk` file
2. Open **Package Center** on your Synology NAS
3. Click **Manual Install**
4. Browse and select the SPK file
5. Follow the installation wizard:
   - Enter your Bareos Director hostname/IP
   - Set the File Daemon name (defaults to hostname-fd)
   - Create a secure password
   - Configure the listening port (default: 9102)
   - Select backup locations (volumes to backup)
   - Choose advanced options (SSL, compression, autostart)
6. Click **Apply** to complete installation

### Method 2: SSH Command Line

```bash
# Upload the SPK file to your NAS, then:
sudo synopkg install bareos-fd-23.0.0-1-noarch.spk

# Start the service
sudo synopkg start bareos-fd
```

## Configuration

### Wizard Configuration

During installation, the wizard will collect:

- **Director Address**: Hostname or IP of your Bareos Director
- **Client Name**: Unique identifier for this File Daemon
- **Password**: Authentication password (store this securely)
- **Port**: Network port for File Daemon (default: 9102)
- **Backup Locations**: Comma-separated list of paths to backup
- **SSL/TLS**: Enable encrypted communication
- **Compression**: Enable backup compression
- **Autostart**: Start automatically on boot

### Manual Configuration

Configuration files are located at:
```
/var/packages/bareos-fd/target/etc/bareos/
├── bareos-fd.conf              # Main configuration
└── bareos-fd.d/               # Additional configurations
    ├── client/
    ├── director/
    └── messages/
```

## Service Management

### DSM Package Center
- Start/Stop: Use the Package Center interface
- View logs: Package Center → Bareos File Daemon → View Logs

### Command Line
```bash
# Service control
sudo synopkg start bareos-fd
sudo synopkg stop bareos-fd
sudo synopkg restart bareos-fd
sudo synopkg status bareos-fd

# Direct script control
/var/packages/bareos-fd/scripts/start-stop-status {start|stop|status|reload}

# Configuration test
/var/packages/bareos-fd/target/bin/bareos-fd -t -c /var/packages/bareos-fd/target/etc/bareos/bareos-fd.conf
```

## Monitoring and Logs

### Status Check
```bash
/var/packages/bareos-fd/target/bin/bareos-verify
```

### Log Files
- **Service logs**: `/var/log/bareos/bareos-fd.log`
- **Installation logs**: `/var/log/bareos-install.log`
- **DSM logs**: DSM → Log Center → Package Center

### Log Rotation
Logs are automatically rotated weekly, keeping 4 weeks of history.

## Firewall Configuration

Ensure the File Daemon port (default: 9102) is accessible:

1. **DSM Firewall**: Control Panel → Security → Firewall
2. **Router**: Forward port 9102 to your NAS (if external access needed)
3. **Director**: Configure Director to connect to NAS_IP:9102

## Directory Structure

```
/var/packages/bareos-fd/
├── target/                    # Package files
│   ├── bin/                  # Executables
│   │   ├── bareos-fd         # File Daemon wrapper
│   │   └── bareos-verify     # Status verification
│   ├── etc/                  # Configuration templates
│   ├── lib/                  # Bareos libraries and plugins
│   └── share/               # Documentation
├── scripts/                  # Installation scripts
└── conf/                    # Package configuration

/var/lib/bareos/             # Working directory
/var/log/bareos/             # Log files
/var/run/bareos/             # Runtime files
```

## Building from Source

### Prerequisites
```bash
# Install development tools
sudo apt-get update
sudo apt-get install build-essential cmake git

# Clone Bareos source
git clone https://github.com/bareos/bareos.git
cd bareos
```

### Build SPK Package
```bash
# Make build script executable
chmod +x build_spk.sh

# Build the package
./build_spk.sh

# Result: bareos-fd-23.0.0-1-noarch.spk
```

### Customization

To customize the package:

1. **Modify configuration**: Edit `target/etc/bareos/bareos-fd.conf.template`
2. **Update scripts**: Modify files in `scripts/` directory
3. **Change metadata**: Edit `INFO` file
4. **Update wizard**: Modify `WIZARD_UIFILES/install_uifile`
5. **Rebuild**: Run `./build_spk.sh`

## Troubleshooting

### Common Issues

**Service won't start**
```bash
# Check configuration
/var/packages/bareos-fd/target/bin/bareos-fd -t

# Check logs
tail -f /var/log/bareos/bareos-fd.log

# Check permissions
ls -la /var/lib/bareos/
```

**Network connectivity issues**
```bash
# Test port accessibility
netstat -ln | grep 9102

# Test from Director
telnet NAS_IP 9102
```

**SSL/TLS problems**
```bash
# Check certificates
ls -la /var/packages/bareos-fd/target/etc/bareos/*.pem

# Regenerate certificates
openssl x509 -in bareos-fd.pem -text -noout
```

### Advanced Configuration

**Custom backup locations**
```bash
# Edit configuration
vi /var/packages/bareos-fd/target/etc/bareos/bareos-fd.conf

# Test configuration
/var/packages/bareos-fd/target/bin/bareos-fd -t

# Restart service
sudo synopkg restart bareos-fd
```

**Plugin configuration**
```bash
# Add plugins to
/var/packages/bareos-fd/target/lib/bareos/plugins/

# Update configuration to load plugins
```

## Security Considerations

1. **User Permissions**: Service runs as dedicated `bareos` user
2. **File Access**: Uses ACLs for backup access permissions
3. **Network Security**: SSL/TLS encryption recommended
4. **Password Security**: Use strong authentication passwords
5. **Firewall**: Restrict network access to trusted Directors

## Integration with Bareos Director

### Director Configuration
Add this client to your Bareos Director configuration:

```
Client {
  Name = "synology-nas-fd"
  Address = "NAS_IP_ADDRESS"
  FDPort = 9102
  Catalog = "MyCatalog"
  Password = "YOUR_PASSWORD"
  File Retention = 60 days
  Job Retention = 6 months
  AutoPrune = yes
}
```

### Job Configuration
```
Job {
  Name = "synology-backup"
  Type = Backup
  Level = Incremental
  Client = "synology-nas-fd"
  FileSet = "synology-fileset"
  Schedule = "daily-backup"
  Storage = "backup-storage"
  Messages = Standard
  Pool = "incremental-pool"
}

FileSet {
  Name = "synology-fileset"
  Include {
    Options {
      signature = MD5
      compression = GZIP
    }
    File = /volume1
    File = /volume2
  }
  Exclude {
    File = /volume1/@tmp
    File = /volume2/@eaDir
  }
}
```

## Support and Documentation

- **Bareos Documentation**: https://docs.bareos.org/
- **Community Forum**: https://www.bareos.org/support/
- **GitHub Repository**: https://github.com/bareos/bareos
- **Issue Tracking**: Report SPK-specific issues on the package repository

## License

This SPK package is distributed under the same license as Bareos (AGPL v3).

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test the SPK package
5. Submit a pull request

---

*Created for Synology DSM 7.0+ with enterprise-grade backup requirements in mind.*