# Linux Systems Expert Agent - Copilot Instructions

## Project Overview

This repository contains specialized AI agent prompts for Linux systems administration and enterprise infrastructure. The primary artifact is a comprehensive prompt template that creates expert-level AI agents capable of handling complex Linux environments across multiple distributions and enterprise scenarios.

## Architecture & Domain Focus

### Core Expertise Areas
- **Enterprise Linux Infrastructure**: RHEL, CentOS, Ubuntu Server, SUSE, container orchestration
- **System Administration**: Service management (systemd), package management, user/group administration
- **Security & Compliance**: SELinux/AppArmor, firewall management, audit frameworks, compliance automation
- **Network & Storage**: Network configuration, LVM, filesystems, NFS, iSCSI, storage management
- **Automation & Configuration Management**: Bash/shell scripting, Ansible, Puppet, Chef, Terraform

### Repository Structure
```
.github/
  prompts/
    linux-guru.prompt.md         # Main agent prompt template
  chatmodes/
    agent.chatmode.md            # Chat interaction examples
  toolsets/
    system-administration.md     # Core system admin tools
    security-compliance.md       # Security and audit tools
    automation-orchestration.md # Automation frameworks
    containerization.md         # Docker/Kubernetes tools
    monitoring-logging.md       # Observability stack
```

## Development Patterns

### Prompt Engineering Approach
- **Distribution-Agnostic Expertise**: Knowledge across RHEL/CentOS, Ubuntu/Debian, SUSE families
- **Structured Response Format**: Assessment → Procedure → Verification → Security Best Practices
- **Command Proficiency**: Native Linux commands, modern alternatives (exa, ripgrep, bat), and enterprise tools
- **Security-First Mindset**: Zero-trust principles, least privilege, defense in depth

### Content Guidelines
When modifying prompts or adding new agent templates:

1. **Command Mastery**: Include both traditional (`ps`, `netstat`) and modern (`ss`, `htop`, `systemctl`) alternatives
2. **Distribution Awareness**: Provide examples for different package managers (`yum`/`dnf`, `apt`, `zypper`)
3. **Enterprise Focus**: Address production scenarios with high availability, scalability, and security requirements
4. **Troubleshooting Structure**: Symptom → Investigation → Root Cause → Resolution → Prevention

### Example Pattern from Linux Agent
```markdown
## **Sample Tasks You Should Handle**
- "Why is my systemd service failing to start?"
- "How do I configure NGINX as a reverse proxy with SSL termination?"
- "What's the best practice for container security in production?"
```

## Key Implementation Considerations

### Security Standards
- Reference CIS Benchmarks for Linux distributions
- Emphasize SELinux/AppArmor configuration and troubleshooting
- Include secure configuration templates and hardening guides
- Highlight container security, network segmentation, and access controls

### Operational Excellence
- Provide commands for multiple distributions when relevant
- Include verification steps and monitoring setup
- Format command examples with explanatory comments
- Present solutions prioritizing stability, security, and maintainability

## Development Workflow

### File Naming Convention
- Use descriptive names: `{domain}-{focus}.md`
- Place specialized content in appropriate `.github/` subdirectories
- Maintain `.md` or `.prompt.md` extensions for clarity

### Content Updates
When updating the Linux agent prompt:
1. Preserve the structured format (Role → Communication Style → Response Structure)
2. Update distribution-specific examples for current LTS versions
3. Add new troubleshooting scenarios based on emerging technologies
4. Validate command syntax across different Linux distributions

### Testing Approach
- Validate commands across RHEL 8/9, Ubuntu 20.04/22.04 LTS, and recent SUSE versions
- Test automation scripts in representative environments
- Review for enterprise production readiness
- Ensure examples follow security best practices

## Integration Points

This agent template is designed for integration with:
- **Configuration Management**: Ansible, Puppet, Chef, SaltStack
- **Container Platforms**: Docker, Podman, Kubernetes, OpenShift
- **Monitoring Stack**: Prometheus, Grafana, ELK Stack, Nagios/Zabbix
- **Cloud Platforms**: AWS, Azure, GCP native services and hybrid architectures
- **Security Frameworks**: NIST, CIS Controls, DISA STIGs, compliance automation

## Linux-Specific Considerations

### Distribution Expertise
- **Red Hat Family**: RHEL, CentOS Stream, Rocky Linux, AlmaLinux
- **Debian Family**: Ubuntu Server, Debian, derivatives
- **SUSE Family**: SLES, openSUSE Leap/Tumbleweed
- **Container-Optimized**: CoreOS, Flatcar Linux, Amazon Linux

### Enterprise Integration
- **Identity Management**: LDAP, Active Directory integration, Kerberos
- **High Availability**: Pacemaker/Corosync, DRBD, load balancing
- **Virtualization**: KVM/QEMU, Xen, VMware integration
- **Storage Solutions**: LVM, ZFS, Ceph, GlusterFS, enterprise SAN/NAS

### Modern Toolchain
- **System Monitoring**: `systemctl`, `journalctl`, `htop`, `iotop`, `ss`
- **File Operations**: `find`, `grep`/`ripgrep`, `awk`, `sed`, `jq`
- **Network Tools**: `ip`, `ss`, `nmap`, `tcpdump`, `wireshark-cli`
- **Container Tools**: `docker`, `podman`, `kubectl`, `helm`, `skopeo`