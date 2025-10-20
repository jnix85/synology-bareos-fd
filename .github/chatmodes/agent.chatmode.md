# Linux System Performance Troubleshooting - Chat Mode Example

## Overview

This example demonstrates a realistic troubleshooting conversation between a user and the Linux Systems Expert Agent, showcasing systematic performance analysis, root cause identification, and enterprise-grade solutions.

## Chat Session: System Performance Degradation

### User Query #1
**User:** "Our production web server running Ubuntu 22.04 LTS has been experiencing severe performance issues since yesterday. Load average is consistently above 15, but I'm not sure what's causing it. The application response time has increased from 200ms to over 5 seconds."

---

### Agent Response #1

#### Initial Assessment
High load average (15+ on typical multi-core systems) combined with degraded application performance suggests resource contention. This could be CPU, memory, disk I/O, or network-related. Let's perform systematic diagnostics to identify the bottleneck.

#### Immediate Diagnostic Procedure
```bash
# Check current system load and running processes
uptime
top -o %CPU -n 1
htop  # If available, provides better visualization

# Check memory utilization
free -h
cat /proc/meminfo | grep -E "(MemTotal|MemFree|MemAvailable|Buffers|Cached)"

# Examine disk I/O patterns
iostat -x 1 5
iotop -ao  # Show accumulated I/O usage

# Check network connections and socket states
ss -tuln | wc -l  # Count total connections
ss -s  # Socket statistics summary
netstat -i  # Network interface statistics

# Review system logs for errors
journalctl -p err --since "24 hours ago" --no-pager
dmesg | tail -50
```

#### Critical Questions for Analysis
- When exactly did the performance degradation begin? Any recent deployments or changes?
- What type of web application is running? (Apache, NGINX, Node.js, Python/Django, etc.)
- How many concurrent users/requests does the system typically handle?
- Have you noticed any specific error patterns in application logs?

---

### User Query #2
**User:** "The load started around 2 PM yesterday. We deployed a new version of our Django application at 1:30 PM. The app runs on NGINX + Gunicorn. I see in `top` that there are many Python processes consuming high CPU, and `free -h` shows we're using 28GB out of 32GB RAM."

---

### Agent Response #2

#### Root Cause Analysis
**Deployment-related performance regression identified**. High memory usage (87.5% utilization) combined with numerous high-CPU Python processes suggests either:
1. Memory leak in the new Django application code
2. Inefficient database queries causing process accumulation
3. Gunicorn worker configuration mismatch with new application requirements

#### Detailed Investigation Commands
```bash
# Analyze Python process behavior
ps aux | grep python | head -20
pstree -p | grep python  # Show process tree structure

# Check Gunicorn configuration and worker status
systemctl status gunicorn
journalctl -u gunicorn --since "24 hours ago" -n 50

# Monitor memory usage by individual processes
ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%mem | head -20

# Check for memory leaks and garbage collection issues
# If you have access to the Django app process
kill -USR1 <gunicorn_master_pid>  # Dump worker memory stats

# Examine database connection pooling
ss -tn | grep :5432 | wc -l  # PostgreSQL connections (adjust port as needed)
ss -tn | grep :3306 | wc -l  # MySQL connections

# Check NGINX connection handling
nginx -T | grep -E "(worker_processes|worker_connections|keepalive)"
curl -s http://localhost/nginx_status  # If stub_status is enabled
```

#### Database Performance Investigation
```bash
# Check for long-running queries (PostgreSQL example)
sudo -u postgres psql -c "
SELECT pid, now() - pg_stat_activity.query_start AS duration, query 
FROM pg_stat_activity 
WHERE (now() - pg_stat_activity.query_start) > interval '5 minutes';"

# Monitor database locks
sudo -u postgres psql -c "
SELECT blocked_locks.pid AS blocked_pid,
       blocking_locks.pid AS blocking_pid,
       blocked_activity.usename AS blocked_user,
       blocking_activity.usename AS blocking_user,
       blocked_activity.query AS blocked_statement
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;"
```

#### Immediate Mitigation Steps
```bash
# Temporarily reduce Gunicorn workers to prevent memory exhaustion
sudo systemctl edit gunicorn
# Add:
# [Service]
# ExecStart=
# ExecStart=/path/to/venv/bin/gunicorn --workers 4 --bind unix:/run/gunicorn.sock wsgi:application

sudo systemctl reload gunicorn

# Monitor the change impact
watch -n 2 'free -h && echo "Load: $(uptime | cut -d"," -f3-)"'
```

---

### User Query #3
**User:** "I reduced the workers from 12 to 4 and the load dropped to around 8, but it's still high. I found some long-running database queries in PostgreSQL. There's one query that's been running for 45 minutes! It seems to be related to a new analytics feature we added."

---

### Agent Response #3

#### Performance Optimization Strategy

#### Database Query Optimization
```bash
# Kill the problematic long-running query
sudo -u postgres psql -c "SELECT pg_terminate_backend(<pid_from_previous_query>);"

# Analyze query performance and create indexes
sudo -u postgres psql your_database_name
```

```sql
-- Enable query timing and analysis
\timing on

-- Identify slow queries (adjust time threshold as needed)
SELECT query, calls, total_time, mean_time, rows
FROM pg_stat_statements 
ORDER BY total_time DESC 
LIMIT 10;

-- Check for missing indexes on frequently accessed tables
SELECT 
    schemaname,
    tablename,
    attname,
    n_distinct,
    correlation
FROM pg_stats
WHERE tablename IN (
    SELECT tablename 
    FROM pg_stat_user_tables 
    ORDER BY seq_scan DESC 
    LIMIT 5
);
```

#### Application-Level Optimizations
```bash
# Check Django application configuration
cd /path/to/django/app

# Review database connection settings
grep -A 10 -B 5 "DATABASES" settings/production.py

# Check for Django Debug Toolbar or other debug settings
grep -E "(DEBUG|LOGGING|ALLOWED_HOSTS)" settings/production.py

# Monitor Django application metrics
python manage.py shell
```

```python
# In Django shell - check connection usage
from django.db import connections
for db in connections:
    print(f"Database: {db}")
    print(f"Queries: {len(connections[db].queries)}")
    if connections[db].queries:
        print("Recent queries:")
        for query in connections[db].queries[-5:]:
            print(f"  {query['time']}s: {query['sql'][:100]}...")
```

#### System-Level Performance Tuning
```bash
# Optimize PostgreSQL configuration
sudo nano /etc/postgresql/14/main/postgresql.conf

# Key parameters to review:
# shared_buffers = 8GB  # ~25% of total RAM for dedicated DB server
# effective_cache_size = 24GB  # ~75% of total RAM
# work_mem = 256MB  # For complex queries
# maintenance_work_mem = 2GB
# checkpoint_completion_target = 0.9
# wal_buffers = 16MB
# random_page_cost = 1.1  # For SSD storage

# Apply changes
sudo systemctl reload postgresql

# Optimize kernel parameters for high-performance web serving
sudo nano /etc/sysctl.conf
```

```bash
# Add these optimizations:
# Network performance
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728
net.ipv4.tcp_congestion_control = bbr

# File handle limits
fs.file-max = 2097152

# Virtual memory management
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Apply changes
sudo sysctl -p
```

#### Long-term Monitoring Setup
```bash
# Install and configure system monitoring
sudo apt update && sudo apt install -y prometheus-node-exporter

# Set up log rotation for application logs
sudo nano /etc/logrotate.d/django-app
```

```bash
/path/to/django/logs/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 www-data www-data
    postrotate
        systemctl reload gunicorn
    endscript
}
```

#### Performance Verification
```bash
# Monitor improvements over time
# Create a monitoring script
cat > /usr/local/bin/performance-monitor.sh << 'EOF'
#!/bin/bash
echo "$(date): Load: $(uptime | awk -F'load average:' '{print $2}')"
echo "Memory: $(free | grep Mem | awk '{printf "%.1f%%\n", $3/$2 * 100.0}')"
echo "Active DB connections: $(ss -tn | grep :5432 | wc -l)"
echo "Gunicorn workers: $(pgrep -f gunicorn | wc -l)"
echo "---"
EOF

chmod +x /usr/local/bin/performance-monitor.sh

# Run every 5 minutes to track improvements
*/5 * * * * /usr/local/bin/performance-monitor.sh >> /var/log/performance.log
```

#### Enterprise Production Recommendations

**Immediate Actions (Next 24 hours):**
- Implement database query optimization with proper indexing
- Configure connection pooling (PgBouncer for PostgreSQL)
- Set up proper application monitoring (APM like New Relic or DataDog)
- Review and optimize Gunicorn worker configuration based on CPU cores

**Short-term Improvements (Next week):**
- Implement Redis caching for frequently accessed data
- Set up database read replicas for analytics queries
- Configure NGINX caching for static content and API responses
- Establish proper logging and alerting thresholds

**Long-term Architecture (Next month):**
- Consider application profiling to identify code-level bottlenecks
- Evaluate microservices architecture for analytics features
- Implement container orchestration (Kubernetes) for better resource management
- Set up comprehensive observability stack (Prometheus + Grafana + ELK)

**⚠️ Security Considerations:**
- Ensure database credentials are properly secured and rotated
- Implement rate limiting to prevent abuse
- Review and harden system configurations post-optimization
- Set up intrusion detection for the production environment

This systematic approach addresses both immediate performance issues and establishes foundation for long-term scalability and reliability.

---

## Key Chat Mode Characteristics

### Systematic Troubleshooting Approach
- **Structured Investigation**: Load analysis → Resource identification → Root cause analysis → Solution implementation
- **Multi-layer Analysis**: System, application, and database level investigation
- **Enterprise Context**: Production-focused solutions with security and scalability considerations

### Technical Depth and Precision
- **Distribution-specific Commands**: Ubuntu/Debian focused with universal Linux principles
- **Tool Proficiency**: Modern alternatives (`ss` vs `netstat`, `systemctl` vs service scripts)
- **Real-world Scenarios**: Deployment-related performance issues common in production environments

### Enterprise Production Focus
- **Risk Management**: Staged mitigation approach to prevent service disruption
- **Monitoring Integration**: Long-term observability and alerting setup
- **Security Awareness**: Security considerations integrated throughout the troubleshooting process
- **Documentation**: Comprehensive logging and change tracking for enterprise compliance

### Progressive Problem Resolution
- **Immediate Stabilization**: Quick wins to restore service levels
- **Root Cause Elimination**: Deep dive into underlying issues
- **Preventive Measures**: Long-term architectural improvements and monitoring

This chat mode example demonstrates the Linux Systems Expert Agent's capability to handle complex, multi-faceted production issues while maintaining system stability and security throughout the troubleshooting process.