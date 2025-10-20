# Security and Compliance Toolset

## Overview
Comprehensive security tools and compliance frameworks for Linux environments, focusing on system hardening, vulnerability assessment, compliance automation, and security monitoring.

## Security Assessment and Auditing

### System Security Scanning
```bash
# Lynis - Security auditing tool
lynis audit system              # Comprehensive security audit
lynis show profiles             # Show available audit profiles
lynis show commands             # Show available commands
lynis update info               # Check for updates

# CIS-CAT (Center for Internet Security Configuration Assessment Tool)
# Download from CIS website and run:
./CIS-CAT.sh -a -r /path/to/results

# OpenSCAP (Security Content Automation Protocol)
oscap xccdf eval --profile xccdf_profile_id --results results.xml content.xml
oscap xccdf generate report results.xml > report.html

# Nessus command line (if installed)
/opt/nessus/bin/nessuscli scan --targets 192.168.1.1-254 --template basic

# Nikto web vulnerability scanner
nikto -h http://target-website.com -o nikto-report.html -Format htm
```

### Vulnerability Assessment
```bash
# Package vulnerability scanning
# Ubuntu/Debian
apt list --upgradable           # Show packages with security updates
unattended-upgrade --dry-run    # Preview automatic security updates

# RHEL/CentOS
dnf updateinfo list security    # List security updates
dnf updateinfo info RHSA-*      # Show details of security advisory
dnf upgrade --security          # Install only security updates

# Container vulnerability scanning (with Trivy)
trivy image nginx:latest        # Scan container image
trivy fs /path/to/project       # Scan filesystem
trivy repo https://github.com/user/repo  # Scan git repository

# Network vulnerability scanning
nmap -sV --script vuln target-ip        # Network vulnerability scan
nmap --script ssl-enum-ciphers -p 443 target  # SSL/TLS configuration scan
```

### Access Control and Authentication

#### PAM (Pluggable Authentication Modules) Configuration
```bash
# PAM configuration files
/etc/pam.d/common-auth          # Authentication settings
/etc/pam.d/common-password      # Password requirements
/etc/pam.d/common-session       # Session management
/etc/pam.d/sshd                 # SSH authentication

# Password policy enforcement
# Edit /etc/pam.d/common-password
# password requisite pam_pwquality.so retry=3 minlen=12 maxrepeat=3 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1

# Account lockout policy
# Edit /etc/pam.d/common-auth
# auth required pam_tally2.so deny=5 unlock_time=900

# Check locked accounts
pam_tally2 --user username      # Check failed login attempts
pam_tally2 --user username --reset  # Reset failed login counter
```

#### SUDO Configuration and Auditing
```bash
# SUDO configuration
visudo                          # Edit sudoers file safely
sudo -l                         # List current user's sudo privileges
sudo -l -U username             # List specific user's privileges

# SUDO logging
grep sudo /var/log/auth.log     # View sudo usage (Ubuntu/Debian)
grep sudo /var/log/secure       # View sudo usage (RHEL/CentOS)

# Sudoers file examples
# Allow user to run specific commands
username ALL=(ALL) /usr/bin/systemctl restart nginx, /usr/bin/systemctl status nginx

# Group-based permissions
%wheel ALL=(ALL) ALL            # All users in wheel group
%developers ALL=(www-data) NOPASSWD: /usr/bin/systemctl restart nginx
```

### SELinux Security (RHEL/CentOS/Fedora)
```bash
# SELinux status and mode
getenforce                      # Current SELinux mode
sestatus                        # Detailed SELinux status
setenforce 1                    # Set to enforcing mode
setenforce 0                    # Set to permissive mode

# SELinux contexts
ls -lZ /path/to/file           # View file SELinux context
ps auxZ                        # View process SELinux contexts
id -Z                          # View current user SELinux context

# SELinux context management
restorecon -R /path            # Restore default SELinux contexts
chcon -t httpd_exec_t /path/to/file  # Change SELinux context
semanage fcontext -a -t httpd_exec_t "/path/to/file"  # Add permanent context

# SELinux booleans
getsebool -a                   # List all SELinux booleans
getsebool httpd_can_network_connect  # Check specific boolean
setsebool -P httpd_can_network_connect on  # Set boolean permanently

# SELinux troubleshooting
ausearch -m avc -ts recent     # Search for recent SELinux denials
grep "avc: denied" /var/log/audit/audit.log  # Find SELinux denials
sealert -a /var/log/audit/audit.log  # Analyze SELinux alerts
```

### AppArmor Security (Ubuntu/SUSE)
```bash
# AppArmor status
apparmor_status                 # Show AppArmor status
aa-enabled                      # Check if AppArmor is enabled

# Profile management
aa-enforce /path/to/profile     # Set profile to enforce mode
aa-complain /path/to/profile    # Set profile to complain mode
aa-disable /path/to/profile     # Disable profile

# Profile development and debugging
aa-genprof /usr/bin/program     # Generate new profile
aa-logprof                      # Update profiles based on logs
aa-unconfined                   # Show unconfined processes

# AppArmor logs
grep apparmor /var/log/syslog   # View AppArmor messages
dmesg | grep -i apparmor        # Check kernel messages
```

### Firewall Management and Network Security

#### iptables Configuration
```bash
# View current rules
iptables -L -n -v               # List all rules with packet counts
iptables -t nat -L -n -v        # List NAT table rules
iptables -S                     # Show rules in save format

# Basic firewall rules
iptables -A INPUT -i lo -j ACCEPT  # Allow loopback
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT  # Allow established connections
iptables -A INPUT -p tcp --dport 22 -j ACCEPT  # Allow SSH
iptables -A INPUT -p tcp --dport 80 -j ACCEPT  # Allow HTTP
iptables -A INPUT -p tcp --dport 443 -j ACCEPT  # Allow HTTPS
iptables -A INPUT -j DROP       # Drop all other traffic

# Save and restore rules
iptables-save > /etc/iptables/rules.v4  # Save current rules
iptables-restore < /etc/iptables/rules.v4  # Restore saved rules

# Advanced rules
iptables -A INPUT -p tcp --dport 22 -m recent --set --name SSH  # Rate limiting SSH
iptables -A INPUT -p tcp --dport 22 -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP
```

#### firewalld Configuration (RHEL/CentOS)
```bash
# Basic firewalld operations
firewall-cmd --state            # Check firewall state
firewall-cmd --get-zones        # List available zones
firewall-cmd --get-active-zones # Show active zones
firewall-cmd --list-all         # List all configuration

# Zone management
firewall-cmd --zone=public --add-service=http  # Add service to zone
firewall-cmd --zone=public --add-port=8080/tcp  # Add port to zone
firewall-cmd --zone=public --remove-service=http  # Remove service
firewall-cmd --reload           # Reload configuration
firewall-cmd --runtime-to-permanent  # Make runtime config permanent

# Rich rules for advanced configuration
firewall-cmd --add-rich-rule='rule family="ipv4" source address="192.168.1.0/24" service name="ssh" accept'
firewall-cmd --add-rich-rule='rule family="ipv4" source address="0.0.0.0/0" port protocol="tcp" port="443" accept'
```

### File Integrity Monitoring

#### AIDE (Advanced Intrusion Detection Environment)
```bash
# Install and configure AIDE
apt install aide                # Ubuntu/Debian
dnf install aide                # RHEL/CentOS

# Initialize AIDE database
aideinit                        # Create initial database
mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Run integrity check
aide --check                    # Check for changes
aide --update                   # Update database with changes

# AIDE configuration (/etc/aide/aide.conf)
# /etc p+i+n+u+g+s+b+m+c+md5+sha1
# /bin p+i+n+u+g+s+b+m+c+md5+sha1
# /sbin p+i+n+u+g+s+b+m+c+md5+sha1
```

#### Tripwire (Commercial/Open Source)
```bash
# Initialize Tripwire
tripwire --init                 # Create initial database
tripwire --check                # Run integrity check
tripwire --update --twrfile report.twr  # Update database

# Tripwire configuration
/etc/tripwire/twcfg.txt        # Tripwire configuration
/etc/tripwire/twpol.txt        # Tripwire policy file
```

### Log Analysis and SIEM

#### rsyslog Configuration
```bash
# rsyslog configuration
/etc/rsyslog.conf              # Main configuration file
/etc/rsyslog.d/                # Additional configuration directory

# Remote logging setup
echo "*.* @@logserver:514" >> /etc/rsyslog.conf  # Send logs to remote server
systemctl restart rsyslog      # Restart rsyslog service

# Log rotation
/etc/logrotate.conf            # Main logrotate configuration
/etc/logrotate.d/              # Service-specific configurations
```

#### ELK Stack Integration
```bash
# Filebeat configuration for log shipping
# /etc/filebeat/filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log
    - /var/log/messages
    - /var/log/syslog

output.elasticsearch:
  hosts: ["elasticsearch-server:9200"]

# Start Filebeat
systemctl enable filebeat
systemctl start filebeat
```

### Compliance Automation

#### CIS Benchmarks Implementation
```bash
# CIS Ubuntu 20.04 LTS Benchmark examples

# 1.1.1.1 Ensure mounting of cramfs filesystems is disabled
echo "install cramfs /bin/true" >> /etc/modprobe.d/cramfs.conf

# 1.3.1 Ensure AIDE is installed
apt install aide
aideinit

# 1.4.1 Ensure permissions on bootloader config are configured
chmod og-rwx /boot/grub/grub.cfg

# 2.2.1.1 Ensure time synchronization is in use
systemctl enable systemd-timesyncd
systemctl start systemd-timesyncd

# 3.3.1 Ensure source routed packets are not accepted
echo "net.ipv4.conf.all.accept_source_route = 0" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.accept_source_route = 0" >> /etc/sysctl.conf
sysctl -p

# 4.1.1.1 Ensure auditd is installed
apt install auditd audispd-plugins

# 5.2.5 Ensure SSH LogLevel is appropriate
sed -i 's/.*LogLevel.*/LogLevel INFO/' /etc/ssh/sshd_config
systemctl restart sshd
```

#### NIST Cybersecurity Framework Compliance
```bash
# Asset identification and management script
#!/bin/bash
# Generate asset inventory
{
echo "Hostname: $(hostname)"
echo "OS: $(lsb_release -d | cut -f2)"
echo "Kernel: $(uname -r)"
echo "IP Addresses: $(ip addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}')"
echo "Network Interfaces: $(ip link show | grep -oP '(?<=\d:\s)\w+' | grep -v lo)"
echo "Installed Packages: $(dpkg -l | wc -l)"  # Ubuntu/Debian
echo "Running Services: $(systemctl list-units --type=service --state=running | wc -l)"
echo "Open Ports: $(ss -tuln | grep LISTEN | wc -l)"
echo "Users: $(cat /etc/passwd | wc -l)"
echo "Last Update: $(stat -c %y /var/log/dpkg.log | cut -d' ' -f1)"  # Ubuntu/Debian
} > /var/log/asset-inventory.txt
```

### Security Monitoring and Incident Response

#### Intrusion Detection with OSSEC
```bash
# OSSEC agent installation and configuration
wget -U ossec https://github.com/ossec/ossec-hids/archive/3.6.0.tar.gz
tar -xzf 3.6.0.tar.gz
cd ossec-hids-3.6.0/
./install.sh

# OSSEC configuration
/var/ossec/etc/ossec.conf      # Main configuration file

# Start OSSEC
/var/ossec/bin/ossec-control start

# OSSEC log analysis
tail -f /var/ossec/logs/alerts/alerts.log
```

#### Fail2Ban for Intrusion Prevention
```bash
# Install and configure Fail2Ban
apt install fail2ban           # Ubuntu/Debian
dnf install fail2ban           # RHEL/CentOS

# Configuration files
/etc/fail2ban/jail.conf        # Default configuration
/etc/fail2ban/jail.local       # Local overrides

# Common jail configurations
# SSH protection
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600

# Fail2Ban management
fail2ban-client status         # Show status
fail2ban-client status sshd    # Show specific jail status
fail2ban-client unban IP       # Unban IP address
```

### Automated Security Hardening Scripts

#### System Hardening Script
```bash
#!/bin/bash
# Linux System Hardening Script

# Update system
apt update && apt upgrade -y   # Ubuntu/Debian
# dnf update -y                # RHEL/CentOS

# Install security tools
apt install -y fail2ban ufw aide rkhunter chkrootkit

# Configure automatic updates
echo 'Unattended-Upgrade::Automatic-Reboot "false";' >> /etc/apt/apt.conf.d/50unattended-upgrades

# Disable unnecessary services
systemctl disable avahi-daemon
systemctl disable cups
systemctl disable bluetooth

# Secure shared memory
echo "tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0" >> /etc/fstab

# Kernel parameter hardening
cat >> /etc/sysctl.conf << EOF
# IP Spoofing protection
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.rp_filter = 1

# Ignore ICMP redirects
net.ipv4.conf.all.accept_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# Ignore send redirects
net.ipv4.conf.all.send_redirects = 0

# Disable source packet routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# Log Martians
net.ipv4.conf.all.log_martians = 1

# Ignore ping requests
net.ipv4.icmp_echo_ignore_all = 1
EOF

sysctl -p

# Set up basic firewall
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh

echo "System hardening completed. Please review configurations and reboot."
```

This security toolset provides comprehensive coverage for Linux security assessment, compliance, and hardening in enterprise environments.