# Monitoring and Logging Toolset

## Overview
Comprehensive monitoring, logging, and observability tools for Linux environments. Covers system monitoring, application performance monitoring (APM), log aggregation, metrics collection, and alerting systems.

## System Monitoring and Performance

### System Resource Monitoring
```bash
# CPU monitoring
top                             # Real-time process viewer
htop                            # Enhanced interactive process viewer
atop                            # Advanced system monitor
iotop                           # I/O monitoring by process
iftop                           # Network bandwidth monitoring

# CPU detailed analysis
mpstat 1 10                     # CPU usage statistics every 1 second for 10 times
iostat -x 1 10                  # I/O statistics with extended details
vmstat 1 10                     # Virtual memory statistics
sar -u 1 10                     # CPU utilization report
pidstat -u 1 10                 # Per-process CPU usage

# Memory monitoring
free -h                         # Memory usage in human-readable format
cat /proc/meminfo               # Detailed memory information
ps aux --sort=-%mem | head      # Top memory-consuming processes
smem -t                         # Memory usage with totals
pmap -x PID                     # Memory map of specific process

# Disk monitoring
df -h                           # Disk space usage
du -sh /path/*                  # Directory sizes
lsof +D /path                   # Files open in directory
fuser -v /path                  # Processes using files/directories
ncdu /                          # Interactive disk usage analyzer

# Network monitoring
ss -tuln                        # Socket statistics
netstat -i                      # Network interface statistics
nload                           # Network load monitor
nethogs                         # Network usage by process
tcpdump -i eth0                 # Packet capture
wireshark                       # GUI packet analyzer
```

### Performance Analysis Tools
```bash
# System call tracing
strace -c command               # Count system calls
strace -p PID                   # Trace running process
ltrace command                  # Library call tracer

# Performance profiling
perf top                        # Real-time performance counter profile
perf record -g command          # Record performance data with call graphs
perf report                     # Analyze recorded performance data
perf stat command               # Performance counter statistics

# I/O analysis
iotop -a                        # I/O monitoring with accumulated stats
blktrace /dev/sda               # Block layer I/O tracing
btrace /dev/sda                 # Block trace parsing

# System activity reporting
sar -A                          # All system activity data
sadc 1 60 /tmp/sardata          # Collect system activity data
sar -f /tmp/sardata             # Display collected data

# Process monitoring
pstree                          # Process tree
ps auxf                         # Process list with tree format
lsof -i                         # Network connections
lsof -p PID                     # Files opened by process
```

## Prometheus Monitoring Stack

### Prometheus Installation and Configuration
```bash
# Download and install Prometheus
wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
tar xvfz prometheus-*.tar.gz
cd prometheus-*
./prometheus --config.file=prometheus.yml

# Prometheus configuration
# prometheus.yml
global:
  scrape_interval: 15s
  evaluation_interval: 15s
  external_labels:
    cluster: 'production'
    region: 'us-west-2'

rule_files:
  - "alert_rules.yml"
  - "recording_rules.yml"

alerting:
  alertmanagers:
    - static_configs:
        - targets:
          - alertmanager:9093

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'node-exporter'
    static_configs:
      - targets: 
        - 'server1:9100'
        - 'server2:9100'
        - 'server3:9100'
    scrape_interval: 30s
    metrics_path: /metrics

  - job_name: 'application'
    kubernetes_sd_configs:
      - role: pod
    relabel_configs:
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)

  - job_name: 'blackbox'
    metrics_path: /probe
    params:
      module: [http_2xx]
    static_configs:
      - targets:
        - https://example.com
        - https://api.example.com
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115
```

### Node Exporter for System Metrics
```bash
# Install Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v1.6.0/node_exporter-1.6.0.linux-amd64.tar.gz
tar xvfz node_exporter-*.tar.gz
cd node_exporter-*

# Run Node Exporter
./node_exporter --collector.systemd --collector.processes

# Systemd service for Node Exporter
# /etc/systemd/system/node_exporter.service
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
User=node_exporter
Group=node_exporter
Type=simple
ExecStart=/usr/local/bin/node_exporter \
    --collector.systemd \
    --collector.processes \
    --collector.cpu.info \
    --collector.meminfo_numa \
    --web.listen-address=:9100

[Install]
WantedBy=multi-user.target

# Enable and start service
systemctl daemon-reload
systemctl enable node_exporter
systemctl start node_exporter
```

### Application Metrics with Custom Exporters
```python
# Python application metrics example
from prometheus_client import Counter, Histogram, Gauge, start_http_server
import time
import random

# Define metrics
REQUEST_COUNT = Counter('app_requests_total', 'Total HTTP requests', ['method', 'endpoint'])
REQUEST_LATENCY = Histogram('app_request_duration_seconds', 'HTTP request latency')
ACTIVE_CONNECTIONS = Gauge('app_active_connections', 'Active connections')
ERROR_COUNT = Counter('app_errors_total', 'Total errors', ['error_type'])

class MetricsMiddleware:
    def __init__(self, app):
        self.app = app
    
    def __call__(self, environ, start_response):
        start_time = time.time()
        method = environ['REQUEST_METHOD']
        path = environ['PATH_INFO']
        
        # Increment request counter
        REQUEST_COUNT.labels(method=method, endpoint=path).inc()
        
        # Track active connections
        ACTIVE_CONNECTIONS.inc()
        
        try:
            response = self.app(environ, start_response)
            return response
        except Exception as e:
            ERROR_COUNT.labels(error_type=type(e).__name__).inc()
            raise
        finally:
            # Record request duration
            REQUEST_LATENCY.observe(time.time() - start_time)
            ACTIVE_CONNECTIONS.dec()

# Start metrics server
if __name__ == '__main__':
    start_http_server(8000)  # Metrics available at http://localhost:8000/metrics
```

### Alerting Rules and Alertmanager
```yaml
# alert_rules.yml
groups:
- name: system.rules
  rules:
  - alert: HighCPUUsage
    expr: 100 - (avg by(instance) (irate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 80
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High CPU usage detected"
      description: "CPU usage is above 80% for more than 5 minutes on {{ $labels.instance }}"

  - alert: HighMemoryUsage
    expr: (node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100 > 90
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "High memory usage detected"
      description: "Memory usage is above 90% on {{ $labels.instance }}"

  - alert: DiskSpaceUsage
    expr: (node_filesystem_size_bytes - node_filesystem_avail_bytes) / node_filesystem_size_bytes * 100 > 85
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "Disk space usage high"
      description: "Disk usage is above 85% on {{ $labels.instance }} mount {{ $labels.mountpoint }}"

  - alert: ServiceDown
    expr: up == 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Service is down"
      description: "{{ $labels.job }} service is down on {{ $labels.instance }}"

- name: application.rules
  rules:
  - alert: HighErrorRate
    expr: rate(app_errors_total[5m]) > 0.1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High error rate detected"
      description: "Error rate is {{ $value }} errors per second"

  - alert: HighRequestLatency
    expr: histogram_quantile(0.95, rate(app_request_duration_seconds_bucket[5m])) > 0.5
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "High request latency"
      description: "95th percentile latency is {{ $value }} seconds"

# alertmanager.yml
global:
  smtp_smarthost: 'smtp.gmail.com:587'
  smtp_from: 'alerts@example.com'
  smtp_auth_username: 'alerts@example.com'
  smtp_auth_password: 'app_password'

route:
  group_by: ['alertname', 'cluster', 'service']
  group_wait: 10s
  group_interval: 10s
  repeat_interval: 1h
  receiver: 'default'
  routes:
  - match:
      severity: critical
    receiver: 'critical-alerts'
  - match:
      severity: warning
    receiver: 'warning-alerts'

receivers:
- name: 'default'
  email_configs:
  - to: 'team@example.com'
    subject: 'Alert: {{ .GroupLabels.alertname }}'
    body: |
      {{ range .Alerts }}
      Alert: {{ .Annotations.summary }}
      Description: {{ .Annotations.description }}
      Labels: {{ .Labels }}
      {{ end }}

- name: 'critical-alerts'
  email_configs:
  - to: 'oncall@example.com'
    subject: 'CRITICAL: {{ .GroupLabels.alertname }}'
  slack_configs:
  - api_url: 'https://hooks.slack.com/services/...'
    channel: '#alerts'
    title: 'Critical Alert'
    text: '{{ range .Alerts }}{{ .Annotations.summary }}{{ end }}'

- name: 'warning-alerts'
  email_configs:
  - to: 'team@example.com'
    subject: 'WARNING: {{ .GroupLabels.alertname }}'
```

## ELK Stack (Elasticsearch, Logstash, Kibana)

### Elasticsearch Installation and Configuration
```bash
# Install Elasticsearch
wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-8.8.0-linux-x86_64.tar.gz
tar -xzf elasticsearch-8.8.0-linux-x86_64.tar.gz
cd elasticsearch-8.8.0/

# Configuration
# config/elasticsearch.yml
cluster.name: production-cluster
node.name: node-1
path.data: /var/lib/elasticsearch
path.logs: /var/log/elasticsearch
network.host: 0.0.0.0
http.port: 9200
discovery.seed_hosts: ["node-1", "node-2", "node-3"]
cluster.initial_master_nodes: ["node-1", "node-2", "node-3"]

# Security configuration
xpack.security.enabled: true
xpack.security.transport.ssl.enabled: true
xpack.security.transport.ssl.verification_mode: certificate
xpack.security.transport.ssl.keystore.path: elastic-certificates.p12
xpack.security.transport.ssl.truststore.path: elastic-certificates.p12

# JVM settings
# config/jvm.options
-Xms4g
-Xmx4g
-XX:+UseG1GC
-XX:MaxGCPauseMillis=200

# Start Elasticsearch
./bin/elasticsearch -d

# Index management
curl -X PUT "localhost:9200/logs-2023.06" -H 'Content-Type: application/json' -d'
{
  "settings": {
    "number_of_shards": 3,
    "number_of_replicas": 1,
    "index.refresh_interval": "30s"
  },
  "mappings": {
    "properties": {
      "@timestamp": {"type": "date"},
      "level": {"type": "keyword"},
      "message": {"type": "text"},
      "host": {"type": "keyword"},
      "application": {"type": "keyword"}
    }
  }
}'
```

### Logstash Configuration
```bash
# Install Logstash
wget https://artifacts.elastic.co/downloads/logstash/logstash-8.8.0-linux-x86_64.tar.gz
tar -xzf logstash-8.8.0-linux-x86_64.tar.gz
cd logstash-8.8.0/

# Configuration
# config/logstash.yml
node.name: logstash-1
path.data: /var/lib/logstash
pipeline.workers: 4
pipeline.batch.size: 125
pipeline.batch.delay: 50
path.config: /etc/logstash/conf.d/*.conf
path.logs: /var/log/logstash

# Pipeline configuration
# /etc/logstash/conf.d/syslog.conf
input {
  beats {
    port => 5044
  }
  
  syslog {
    port => 514
    type => "syslog"
  }
  
  file {
    path => ["/var/log/nginx/access.log"]
    start_position => "beginning"
    type => "nginx-access"
  }
  
  file {
    path => ["/var/log/nginx/error.log"]
    start_position => "beginning"
    type => "nginx-error"
  }
}

filter {
  if [type] == "nginx-access" {
    grok {
      match => { 
        "message" => '%{IPORHOST:clientip} - %{USER:ident} \[%{HTTPDATE:timestamp}\] "%{WORD:verb} %{DATA:request} HTTP/%{NUMBER:httpversion}" %{NUMBER:response:int} (?:-|%{NUMBER:bytes:int}) %{QS:referrer} %{QS:agent}'
      }
    }
    
    date {
      match => [ "timestamp", "dd/MMM/yyyy:HH:mm:ss Z" ]
    }
    
    mutate {
      convert => ["response", "integer"]
      convert => ["bytes", "integer"]
    }
    
    if [response] >= 400 {
      mutate {
        add_tag => ["error"]
      }
    }
  }
  
  if [type] == "syslog" {
    grok {
      match => { 
        "message" => "%{SYSLOGTIMESTAMP:timestamp} %{IPORHOST:host} %{DATA:program}(?:\[%{POSINT:pid}\])?: %{GREEDYDATA:message}"
      }
      overwrite => ["message"]
    }
    
    date {
      match => [ "timestamp", "MMM  d HH:mm:ss", "MMM dd HH:mm:ss" ]
    }
  }
  
  # Add geolocation for IP addresses
  if [clientip] {
    geoip {
      source => "clientip"
      target => "geoip"
    }
  }
  
  # Parse JSON logs
  if [message] =~ /^\{.*\}$/ {
    json {
      source => "message"
    }
  }
}

output {
  elasticsearch {
    hosts => ["elasticsearch-1:9200", "elasticsearch-2:9200", "elasticsearch-3:9200"]
    index => "logs-%{+YYYY.MM.dd}"
    template_name => "logs"
    template_pattern => "logs-*"
    template => "/etc/logstash/templates/logs.json"
  }
  
  if "error" in [tags] {
    email {
      to => "admin@example.com"
      subject => "Error in logs: %{host}"
      body => "Error message: %{message}"
    }
  }
  
  stdout {
    codec => rubydebug
  }
}

# Start Logstash
./bin/logstash -f /etc/logstash/conf.d/
```

### Filebeat Log Shipping
```bash
# Install Filebeat
wget https://artifacts.elastic.co/downloads/beats/filebeat/filebeat-8.8.0-linux-x86_64.tar.gz
tar -xzf filebeat-8.8.0-linux-x86_64.tar.gz
cd filebeat-8.8.0-linux-x86_64/

# Configuration
# filebeat.yml
filebeat.inputs:
- type: log
  enabled: true
  paths:
    - /var/log/*.log
    - /var/log/messages
    - /var/log/syslog
  fields:
    environment: production
    datacenter: us-west-2
  fields_under_root: true
  
- type: log
  enabled: true
  paths:
    - /var/log/nginx/*.log
  fields:
    service: nginx
  multiline.pattern: '^\d{4}-\d{2}-\d{2}'
  multiline.negate: true
  multiline.match: after

- type: container
  enabled: true
  paths:
    - '/var/lib/docker/containers/*/*.log'
  processors:
    - add_docker_metadata:
        host: "unix:///var/run/docker.sock"

filebeat.config.modules:
  path: ${path.config}/modules.d/*.yml
  reload.enabled: true
  reload.period: 10s

setup.template.settings:
  index.number_of_shards: 3
  index.codec: best_compression

setup.kibana:
  host: "kibana:5601"

output.logstash:
  hosts: ["logstash-1:5044", "logstash-2:5044", "logstash-3:5044"]
  loadbalance: true

output.elasticsearch:
  hosts: ["elasticsearch-1:9200", "elasticsearch-2:9200", "elasticsearch-3:9200"]
  index: "filebeat-%{+yyyy.MM.dd}"
  template.name: "filebeat"
  template.pattern: "filebeat-*"

processors:
  - add_host_metadata:
      when.not.contains.tags: forwarded
  - add_docker_metadata: ~
  - add_kubernetes_metadata: ~

logging.level: info
logging.to_files: true
logging.files:
  path: /var/log/filebeat
  name: filebeat
  keepfiles: 7
  permissions: 0644

# Enable and start Filebeat
systemctl enable filebeat
systemctl start filebeat
```

### Kibana Dashboard Configuration
```bash
# Install Kibana
wget https://artifacts.elastic.co/downloads/kibana/kibana-8.8.0-linux-x86_64.tar.gz
tar -xzf kibana-8.8.0-linux-x86_64.tar.gz
cd kibana-8.8.0-linux-x86_64/

# Configuration
# config/kibana.yml
server.port: 5601
server.host: "0.0.0.0"
server.name: "kibana-production"
elasticsearch.hosts: ["http://elasticsearch-1:9200", "http://elasticsearch-2:9200"]
elasticsearch.username: "kibana_system"
elasticsearch.password: "password"

# Security
server.ssl.enabled: true
server.ssl.certificate: /path/to/certificate.crt
server.ssl.key: /path/to/private.key

# Start Kibana
./bin/kibana

# Kibana saved objects export/import
# Export dashboards
curl -X POST "kibana:5601/api/saved_objects/_export" -H 'kbn-xsrf: true' -H 'Content-Type: application/json' -d'
{
  "type": ["dashboard", "visualization", "search"],
  "includeReferencesDeep": true
}' > kibana-export.ndjson

# Import dashboards
curl -X POST "kibana:5601/api/saved_objects/_import" -H 'kbn-xsrf: true' -F file=@kibana-export.ndjson
```

## Grafana Visualization and Dashboards

### Grafana Installation and Configuration
```bash
# Install Grafana
wget https://dl.grafana.com/enterprise/release/grafana-enterprise-10.0.0.linux-amd64.tar.gz
tar -xzf grafana-enterprise-10.0.0.linux-amd64.tar.gz
cd grafana-10.0.0/

# Configuration
# conf/defaults.ini
[server]
protocol = https
http_port = 3000
domain = grafana.example.com
root_url = https://grafana.example.com/

[database]
type = postgres
host = postgres.example.com:5432
name = grafana
user = grafana
password = password

[security]
admin_user = admin
admin_password = secure_password
secret_key = your_secret_key
disable_gravatar = true

[auth.ldap]
enabled = true
config_file = /etc/grafana/ldap.toml

[smtp]
enabled = true
host = smtp.gmail.com:587
user = grafana@example.com
password = app_password
from_address = grafana@example.com

[alerting]
enabled = true
execute_alerts = true

# Start Grafana
./bin/grafana-server
```

### Grafana Dashboard JSON
```json
{
  "dashboard": {
    "id": null,
    "title": "System Monitoring Dashboard",
    "tags": ["linux", "monitoring"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "CPU Usage",
        "type": "stat",
        "targets": [
          {
            "expr": "100 - (avg by(instance) (irate(node_cpu_seconds_total{mode=\"idle\"}[5m])) * 100)",
            "legendFormat": "{{instance}}"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {
              "mode": "thresholds"
            },
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "yellow", "value": 70},
                {"color": "red", "value": 90}
              ]
            },
            "unit": "percent"
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Memory Usage",
        "type": "timeseries",
        "targets": [
          {
            "expr": "(node_memory_MemTotal_bytes - node_memory_MemAvailable_bytes) / node_memory_MemTotal_bytes * 100",
            "legendFormat": "Memory Usage %"
          }
        ],
        "fieldConfig": {
          "defaults": {
            "color": {"mode": "palette-classic"},
            "custom": {
              "axisLabel": "",
              "axisPlacement": "auto",
              "barAlignment": 0,
              "drawStyle": "line",
              "fillOpacity": 10,
              "gradientMode": "none",
              "hideFrom": {"legend": false, "tooltip": false, "vis": false},
              "lineInterpolation": "linear",
              "lineWidth": 1,
              "pointSize": 5,
              "scaleDistribution": {"type": "linear"},
              "showPoints": "never",
              "spanNulls": false,
              "stacking": {"group": "A", "mode": "none"},
              "thresholdsStyle": {"mode": "off"}
            },
            "thresholds": {
              "steps": [
                {"color": "green", "value": null},
                {"color": "red", "value": 80}
              ]
            },
            "unit": "percent"
          }
        },
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "30s"
  }
}
```

This monitoring and logging toolset provides comprehensive coverage for system monitoring, metrics collection, log aggregation, and observability in enterprise Linux environments.