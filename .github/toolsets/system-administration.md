# System Administration Toolset

## Overview
Core Linux system administration tools and utilities for enterprise environments, covering system management, user administration, process control, and service management.

## Essential System Administration Commands

### System Information and Monitoring
```bash
# System overview and hardware information
uname -a                    # Kernel and system information
hostnamectl                 # System hostname and details
lscpu                      # CPU architecture information
lsmem                      # Memory layout information
lsblk                      # Block device information
lsusb                      # USB device information
lspci                      # PCI device information

# System performance monitoring
top                        # Real-time process viewer
htop                       # Enhanced interactive process viewer
atop                       # Advanced system and process monitor
iotop                      # I/O usage by processes
nethogs                    # Network usage by process
iftop                      # Network bandwidth usage
```

### Process and Service Management
```bash
# Process management
ps aux                     # List all running processes
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem  # Processes sorted by memory usage
pgrep -f pattern          # Find processes by pattern
pkill -f pattern          # Kill processes by pattern
killall process_name      # Kill all instances of a process
pstree                    # Display process tree

# Service management (systemd)
systemctl status service_name     # Check service status
systemctl start service_name      # Start a service
systemctl stop service_name       # Stop a service
systemctl restart service_name    # Restart a service
systemctl reload service_name     # Reload service configuration
systemctl enable service_name     # Enable service at boot
systemctl disable service_name    # Disable service at boot
systemctl list-units --type=service  # List all services

# Service logs and troubleshooting
journalctl -u service_name        # View service logs
journalctl -f                     # Follow system logs in real-time
journalctl -p err                 # Show only error-level logs
journalctl --since "1 hour ago"   # Logs from last hour
systemctl cat service_name        # Show service configuration
systemctl edit service_name       # Edit service override
```

### User and Group Management
```bash
# User management
useradd -m -s /bin/bash username   # Create user with home directory
usermod -aG groupname username     # Add user to group
userdel -r username               # Delete user and home directory
passwd username                   # Change user password
chage -l username                 # View password aging information
id username                       # Show user ID and group memberships

# Group management
groupadd groupname                # Create new group
groupdel groupname                # Delete group
gpasswd -a username groupname     # Add user to group
gpasswd -d username groupname     # Remove user from group
groups username                   # Show user's groups

# Permission and ownership
chmod 755 /path/to/file           # Change file permissions
chown user:group /path/to/file    # Change file ownership
chgrp groupname /path/to/file     # Change group ownership
umask 022                         # Set default permissions mask
```

### File System Management
```bash
# Disk usage and management
df -h                             # Show disk usage (human readable)
du -sh /path/to/directory         # Show directory size
du -h --max-depth=1 /path         # Show subdirectory sizes
lsof                             # List open files
lsof /path/to/file               # Show processes using specific file
fuser -v /path/to/file           # Show processes using file

# File operations
find /path -name "pattern"        # Find files by name
find /path -type f -mtime +7      # Find files modified more than 7 days ago
locate filename                  # Quickly find files (uses database)
which command                    # Show command location
whereis command                  # Show command, source, and manual locations

# Archive and compression
tar -czvf archive.tar.gz /path/   # Create compressed archive
tar -xzvf archive.tar.gz          # Extract compressed archive
tar -tzvf archive.tar.gz          # List archive contents
rsync -avz source/ destination/   # Sync directories efficiently
```

### Network Configuration and Monitoring
```bash
# Network interface management
ip addr show                      # Show IP addresses
ip route show                     # Show routing table
ip link set eth0 up              # Bring interface up
ip link set eth0 down            # Bring interface down
nmcli device status              # NetworkManager device status
nmcli connection show            # Show network connections

# Network connectivity and troubleshooting
ping -c 4 hostname               # Test connectivity
traceroute hostname              # Trace network path
ss -tuln                         # Show listening ports (modern netstat)
ss -tp                          # Show TCP connections with processes
nmap -sT -O hostname            # Port scan and OS detection
tcpdump -i eth0 port 80         # Capture network traffic
```

### Package Management

#### Red Hat/CentOS/Rocky Linux (DNF/YUM)
```bash
# Package operations
dnf update                       # Update all packages
dnf install package_name         # Install package
dnf remove package_name          # Remove package
dnf search keyword               # Search for packages
dnf info package_name            # Show package information
dnf list installed               # List installed packages
dnf history                      # Show transaction history

# Repository management
dnf repolist                     # List enabled repositories
dnf config-manager --add-repo URL  # Add repository
dnf config-manager --enable repo   # Enable repository
```

#### Ubuntu/Debian (APT)
```bash
# Package operations
apt update                       # Update package database
apt upgrade                      # Upgrade all packages
apt install package_name         # Install package
apt remove package_name          # Remove package
apt purge package_name           # Remove package and configuration
apt search keyword               # Search for packages
apt show package_name            # Show package information
apt list --installed            # List installed packages

# Repository management
add-apt-repository ppa:name      # Add PPA repository
apt-key add keyfile              # Add repository key
```

#### SUSE (Zypper)
```bash
# Package operations
zypper refresh                   # Refresh repositories
zypper update                    # Update packages
zypper install package_name      # Install package
zypper remove package_name       # Remove package
zypper search keyword            # Search packages
zypper info package_name         # Package information
```

### Security and System Hardening
```bash
# Firewall management (UFW - Ubuntu)
ufw status                       # Check firewall status
ufw enable                       # Enable firewall
ufw disable                      # Disable firewall
ufw allow 22/tcp                 # Allow SSH
ufw deny 80/tcp                  # Deny HTTP
ufw delete allow 80/tcp          # Remove rule

# Firewall management (firewalld - RHEL/CentOS)
firewall-cmd --state             # Check firewall state
firewall-cmd --list-all          # List all rules
firewall-cmd --add-service=ssh   # Allow SSH service
firewall-cmd --remove-service=http  # Remove HTTP service
firewall-cmd --reload            # Reload firewall rules

# SELinux management (RHEL/CentOS)
getenforce                       # Check SELinux status
setenforce 1                     # Enable SELinux
getsebool -a                     # List all SELinux booleans
setsebool boolean_name on        # Set SELinux boolean
restorecon -R /path              # Restore SELinux contexts
```

### System Monitoring and Logs
```bash
# Log file monitoring
tail -f /var/log/syslog          # Follow system log
tail -f /var/log/messages        # Follow messages log
less /var/log/auth.log           # View authentication log
grep "error" /var/log/syslog     # Search for errors in log

# System resource monitoring
vmstat 1                         # Virtual memory statistics
iostat -x 1                     # I/O statistics
sar -u 1 10                     # CPU usage statistics
sar -r 1 10                     # Memory usage statistics
mpstat -P ALL 1                 # Per-CPU statistics

# Process monitoring
watch -n 1 'ps aux | head -20'  # Monitor top processes
strace -p PID                    # Trace system calls for process
ltrace -p PID                    # Trace library calls for process
```

### Cron and Scheduled Tasks
```bash
# Cron job management
crontab -l                       # List current user's cron jobs
crontab -e                       # Edit current user's cron jobs
crontab -r                       # Remove all cron jobs
crontab -l -u username           # List another user's cron jobs

# System-wide cron
ls -la /etc/cron.*               # List system cron directories
cat /etc/crontab                 # View system crontab

# Cron job examples
# 0 2 * * * /path/to/backup.sh   # Daily at 2 AM
# */15 * * * * /path/to/check.sh # Every 15 minutes
# 0 0 1 * * /path/to/monthly.sh  # Monthly on 1st day
```

### Environment and Configuration
```bash
# Environment variables
env                              # Show all environment variables
echo $PATH                       # Show PATH variable
export VAR=value                 # Set environment variable
unset VAR                        # Unset environment variable

# System configuration files
/etc/passwd                      # User account information
/etc/group                       # Group information
/etc/shadow                      # Password hashes
/etc/hosts                       # Host name resolution
/etc/fstab                       # File system mount points
/etc/crontab                     # System cron jobs
/etc/ssh/sshd_config            # SSH daemon configuration
```

## Advanced System Administration

### LVM (Logical Volume Management)
```bash
# Physical volume management
pvcreate /dev/sdb                # Create physical volume
pvdisplay                       # Display physical volumes
pvs                             # Show physical volume summary

# Volume group management
vgcreate vg_name /dev/sdb        # Create volume group
vgextend vg_name /dev/sdc        # Extend volume group
vgdisplay                       # Display volume groups
vgs                             # Show volume group summary

# Logical volume management
lvcreate -L 10G -n lv_name vg_name  # Create logical volume
lvextend -L +5G /dev/vg_name/lv_name # Extend logical volume
lvdisplay                       # Display logical volumes
lvs                             # Show logical volume summary
```

### System Backup and Recovery
```bash
# File system backup
rsync -avz --delete /source/ /backup/  # Incremental backup
tar -czf backup.tar.gz /path/to/backup # Create backup archive
dd if=/dev/sda of=/backup/disk.img     # Disk image backup

# Database backup examples
mysqldump -u user -p database > backup.sql     # MySQL backup
pg_dump -U user database > backup.sql          # PostgreSQL backup
```

This toolset provides comprehensive coverage of essential Linux system administration tasks for enterprise environments.