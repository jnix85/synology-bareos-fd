# Bareos File Daemon Documentation

## Overview

This Synology SPK package provides the Bareos File Daemon (bareos-fd), which is the client component of the Bareos backup system. The File Daemon runs on the machine to be backed up and is responsible for providing file attributes and data when requested by the Director and Storage services.

## Features

- Enterprise-grade backup client functionality
- Compression and encryption support
- SSL/TLS communication
- Multi-volume backup support
- Plugin architecture for specialized backups
- Integration with Synology DSM

## Installation

The File Daemon will be configured during installation through the DSM Package Center wizard.

## Configuration Files

- `/var/packages/bareos-fd/target/etc/bareos/bareos-fd.conf` - Main configuration
- `/var/packages/bareos-fd/target/etc/bareos/bareos-fd.d/` - Additional configurations

## Log Files

- `/var/log/bareos/bareos-fd.log` - Main log file
- `/var/log/bareos-install.log` - Installation log

## Service Management

- Start: `sudo synopkg start bareos-fd`
- Stop: `sudo synopkg stop bareos-fd`
- Status: `sudo synopkg status bareos-fd`
- Restart: `sudo synopkg restart bareos-fd`

## Verification

Use the built-in verification script:
```bash
/var/packages/bareos-fd/target/bin/bareos-verify
```

## Support

- Documentation: https://docs.bareos.org/
- Community Support: https://www.bareos.org/support/
- GitHub: https://github.com/bareos/bareos