# Automation and Orchestration Toolset

## Overview
Comprehensive automation, orchestration, and Infrastructure as Code (IaC) tools for Linux environments. Covers configuration management, CI/CD pipelines, infrastructure provisioning, and DevOps automation workflows.

## Configuration Management

### Ansible Automation
```bash
# Ansible installation
pip3 install ansible            # Install via pip
apt install ansible             # Ubuntu/Debian
dnf install ansible             # RHEL/CentOS

# Basic Ansible commands
ansible --version               # Check Ansible version
ansible-config dump             # Show current configuration
ansible-inventory --list        # List inventory hosts
ansible all -m ping             # Test connectivity to all hosts
ansible-doc -l                  # List available modules

# Inventory management
# /etc/ansible/hosts or inventory.ini
[webservers]
web1.example.com
web2.example.com

[databases]
db1.example.com ansible_user=admin ansible_ssh_private_key_file=~/.ssh/id_rsa

[production:children]
webservers
databases

# Ad-hoc commands
ansible webservers -m shell -a "uptime"                    # Run shell command
ansible all -m apt -a "name=htop state=present" --become   # Install package
ansible databases -m service -a "name=postgresql state=restarted" --become
ansible all -m setup                                       # Gather facts
```

#### Ansible Playbooks
```yaml
# site.yml - Main playbook
---
- hosts: webservers
  become: yes
  vars:
    nginx_port: 80
    app_user: webapp
  
  tasks:
    - name: Update package cache
      apt:
        update_cache: yes
        cache_valid_time: 3600
    
    - name: Install nginx
      apt:
        name: nginx
        state: present
    
    - name: Start and enable nginx
      systemd:
        name: nginx
        state: started
        enabled: yes
    
    - name: Create application user
      user:
        name: "{{ app_user }}"
        shell: /bin/bash
        home: /home/{{ app_user }}
        create_home: yes
    
    - name: Configure nginx
      template:
        src: nginx.conf.j2
        dest: /etc/nginx/sites-available/default
        backup: yes
      notify: restart nginx
  
  handlers:
    - name: restart nginx
      systemd:
        name: nginx
        state: restarted

# Database playbook
- hosts: databases
  become: yes
  vars:
    postgres_version: 13
    db_name: webapp_db
    db_user: webapp_user
    db_password: "{{ vault_db_password }}"
  
  tasks:
    - name: Install PostgreSQL
      apt:
        name:
          - postgresql-{{ postgres_version }}
          - postgresql-client-{{ postgres_version }}
          - python3-psycopg2
        state: present
    
    - name: Create database
      postgresql_db:
        name: "{{ db_name }}"
        state: present
      become_user: postgres
    
    - name: Create database user
      postgresql_user:
        name: "{{ db_user }}"
        password: "{{ db_password }}"
        priv: "{{ db_name }}:ALL"
        state: present
      become_user: postgres
```

#### Ansible Vault for Secrets Management
```bash
# Create encrypted file
ansible-vault create secrets.yml

# Edit encrypted file
ansible-vault edit secrets.yml

# Encrypt existing file
ansible-vault encrypt inventory.yml

# Decrypt file
ansible-vault decrypt inventory.yml

# Run playbook with vault
ansible-playbook site.yml --ask-vault-pass
ansible-playbook site.yml --vault-password-file vault_pass.txt

# Example secrets.yml
---
vault_db_password: "super_secure_password"
vault_api_key: "secret_api_key_12345"
vault_ssl_cert: |
  -----BEGIN CERTIFICATE-----
  MIIFyTCCA7GgAwIBAgIBADANBgkqhkiG9w0BAQsFADCBpTELMAkGA1UEBhMCVVMx
  ...
  -----END CERTIFICATE-----
```

#### Ansible Roles Structure
```bash
# Create role structure
ansible-galaxy init webserver

# Role directory structure
webserver/
├── defaults/main.yml          # Default variables
├── files/                     # Static files
├── handlers/main.yml          # Handlers
├── meta/main.yml              # Role metadata
├── tasks/main.yml             # Main tasks
├── templates/                 # Jinja2 templates
├── tests/                     # Test files
└── vars/main.yml              # Role variables

# Use roles in playbook
---
- hosts: webservers
  roles:
    - webserver
    - { role: database, db_name: webapp_db }
```

### Terraform Infrastructure as Code
```bash
# Terraform installation
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Basic Terraform commands
terraform version              # Check version
terraform init                 # Initialize working directory
terraform plan                 # Show execution plan
terraform apply                # Apply changes
terraform destroy              # Destroy infrastructure
terraform validate             # Validate configuration
terraform fmt                  # Format configuration files
terraform state list           # List resources in state
terraform state show resource_name  # Show resource details
```

#### Terraform Configuration Examples
```hcl
# main.tf - AWS infrastructure
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  
  backend "s3" {
    bucket = "terraform-state-bucket"
    key    = "prod/terraform.tfstate"
    region = "us-west-2"
  }
}

provider "aws" {
  region = var.aws_region
}

# Variables
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium"
}

# Data sources
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical
  
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-22.04-amd64-server-*"]
  }
  
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# VPC and networking
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

resource "aws_subnet" "public" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  map_public_ip_on_launch = true
  
  tags = {
    Name = "${var.environment}-public-subnet-${count.index + 1}"
  }
}

# Security group
resource "aws_security_group" "web" {
  name_prefix = "${var.environment}-web"
  vpc_id      = aws_vpc.main.id
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "${var.environment}-web-sg"
  }
}

# Launch template
resource "aws_launch_template" "web" {
  name_prefix   = "${var.environment}-web"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  
  vpc_security_group_ids = [aws_security_group.web.id]
  
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment = var.environment
  }))
  
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "${var.environment}-web-server"
      Environment = var.environment
    }
  }
}

# Auto Scaling Group
resource "aws_autoscaling_group" "web" {
  name                = "${var.environment}-web-asg"
  vpc_zone_identifier = aws_subnet.public[*].id
  target_group_arns   = [aws_lb_target_group.web.arn]
  health_check_type   = "ELB"
  
  min_size         = 2
  max_size         = 10
  desired_capacity = 3
  
  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "${var.environment}-web-asg"
    propagate_at_launch = false
  }
}
```

#### Terraform Modules
```hcl
# modules/vpc/main.tf
variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cidr_block" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/16"
}

resource "aws_vpc" "main" {
  cidr_block           = var.cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  
  tags = {
    Name        = "${var.environment}-vpc"
    Environment = var.environment
  }
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr_block" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

# Use module in main configuration
module "vpc" {
  source = "./modules/vpc"
  
  environment = var.environment
  cidr_block  = "10.0.0.0/16"
}
```

## CI/CD Pipelines

### GitLab CI/CD
```yaml
# .gitlab-ci.yml
stages:
  - test
  - build
  - security
  - deploy

variables:
  DOCKER_DRIVER: overlay2
  DOCKER_TLS_CERTDIR: "/certs"

before_script:
  - echo "Preparing environment..."
  - export TIMESTAMP=$(date +%Y%m%d-%H%M%S)

# Test stage
unit_tests:
  stage: test
  image: python:3.9
  script:
    - pip install -r requirements.txt
    - python -m pytest tests/ --cov=app/ --cov-report=xml
  coverage: '/(?i)total.*? (100(?:\.0+)?\%|[1-9]?\d(?:\.\d+)?\%)$/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
    expire_in: 1 week

lint_code:
  stage: test
  image: python:3.9
  script:
    - pip install flake8 black
    - flake8 app/
    - black --check app/

# Security scanning
sast_scan:
  stage: security
  image: securecodewarrior/docker-bandit
  script:
    - bandit -r app/ -f json -o bandit-report.json
  artifacts:
    reports:
      sast: bandit-report.json
    expire_in: 1 week
  allow_failure: true

container_scan:
  stage: security
  image: aquasec/trivy:latest
  script:
    - trivy image --format template --template "@contrib/sarif.tpl" -o trivy-report.sarif $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
  artifacts:
    reports:
      container_scanning: trivy-report.sarif
    expire_in: 1 week

# Build stage
build_image:
  stage: build
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
    - docker build -t $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA .
    - docker push $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA
    - docker tag $CI_REGISTRY_IMAGE:$CI_COMMIT_SHA $CI_REGISTRY_IMAGE:latest
    - docker push $CI_REGISTRY_IMAGE:latest
  only:
    - main

# Deploy to staging
deploy_staging:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl config use-context $KUBE_CONTEXT_STAGING
    - envsubst < k8s/deployment.yaml | kubectl apply -f -
    - kubectl rollout status deployment/myapp -n staging
  environment:
    name: staging
    url: https://staging.example.com
  only:
    - main

# Deploy to production
deploy_production:
  stage: deploy
  image: bitnami/kubectl:latest
  script:
    - kubectl config use-context $KUBE_CONTEXT_PROD
    - envsubst < k8s/deployment.yaml | kubectl apply -f -
    - kubectl rollout status deployment/myapp -n production
  environment:
    name: production
    url: https://example.com
  when: manual
  only:
    - main
```

### Jenkins Pipeline
```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'registry.example.com'
        IMAGE_NAME = 'myapp'
        KUBECONFIG = credentials('kubeconfig')
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }
            }
        }
        
        stage('Test') {
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh '''
                            python -m venv venv
                            source venv/bin/activate
                            pip install -r requirements.txt
                            python -m pytest tests/ --junitxml=test-results.xml
                        '''
                    }
                    post {
                        always {
                            junit 'test-results.xml'
                        }
                    }
                }
                
                stage('Lint') {
                    steps {
                        sh '''
                            source venv/bin/activate
                            flake8 app/ > flake8-report.txt || true
                            pylint app/ > pylint-report.txt || true
                        '''
                    }
                    post {
                        always {
                            archiveArtifacts artifacts: '*-report.txt', fingerprint: true
                        }
                    }
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                script {
                    sh '''
                        # Dependency vulnerability scanning
                        pip install safety
                        safety check --json > safety-report.json || true
                        
                        # Static analysis
                        bandit -r app/ -f json -o bandit-report.json || true
                    '''
                }
            }
            post {
                always {
                    archiveArtifacts artifacts: '*-report.json', fingerprint: true
                }
            }
        }
        
        stage('Build') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                }
            }
            steps {
                script {
                    def image = docker.build("${DOCKER_REGISTRY}/${IMAGE_NAME}:${env.GIT_COMMIT_SHORT}")
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-registry-credentials') {
                        image.push()
                        image.push('latest')
                    }
                }
            }
        }
        
        stage('Deploy to Staging') {
            when {
                branch 'develop'
            }
            steps {
                sh '''
                    helm upgrade --install myapp-staging ./helm/myapp \
                        --namespace staging \
                        --set image.tag=${GIT_COMMIT_SHORT} \
                        --set environment=staging \
                        --wait --timeout=300s
                '''
            }
        }
        
        stage('Deploy to Production') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def deploy = input(
                        id: 'deploy',
                        message: 'Deploy to production?',
                        parameters: [
                            choice(choices: ['deploy', 'abort'], description: 'Action', name: 'action')
                        ]
                    )
                    
                    if (deploy == 'deploy') {
                        sh '''
                            helm upgrade --install myapp-prod ./helm/myapp \
                                --namespace production \
                                --set image.tag=${GIT_COMMIT_SHORT} \
                                --set environment=production \
                                --wait --timeout=600s
                        '''
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        failure {
            emailext (
                subject: "Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "The build ${env.BUILD_URL} has failed.",
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
        }
        success {
            slackSend (
                channel: '#deployments',
                color: 'good',
                message: "✅ Deployment successful: ${env.JOB_NAME} - ${env.BUILD_NUMBER}"
            )
        }
    }
}
```

### GitHub Actions
```yaml
# .github/workflows/ci-cd.yml
name: CI/CD Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        python-version: [3.8, 3.9, '3.10']
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Set up Python ${{ matrix.python-version }}
      uses: actions/setup-python@v4
      with:
        python-version: ${{ matrix.python-version }}
    
    - name: Cache dependencies
      uses: actions/cache@v3
      with:
        path: ~/.cache/pip
        key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}
        restore-keys: |
          ${{ runner.os }}-pip-
    
    - name: Install dependencies
      run: |
        python -m pip install --upgrade pip
        pip install -r requirements.txt
        pip install pytest coverage flake8
    
    - name: Lint with flake8
      run: |
        flake8 . --count --select=E9,F63,F7,F82 --show-source --statistics
        flake8 . --count --exit-zero --max-complexity=10 --max-line-length=127 --statistics
    
    - name: Test with pytest
      run: |
        coverage run -m pytest
        coverage xml
    
    - name: Upload coverage to Codecov
      uses: codecov/codecov-action@v3
      with:
        file: ./coverage.xml

  security:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v4
    
    - name: Run Bandit
      uses: securecodewarrior/github-action-bandit@v1
      with:
        args: '-r . -f json -o bandit-report.json'
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        scan-type: 'fs'
        scan-ref: '.'
        format: 'sarif'
        output: 'trivy-results.sarif'
    
    - name: Upload Trivy scan results to GitHub Security tab
      uses: github/codeql-action/upload-sarif@v2
      with:
        sarif_file: 'trivy-results.sarif'

  build:
    needs: [test, security]
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main' || github.ref == 'refs/heads/develop'
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Log in to Container Registry
      uses: docker/login-action@v3
      with:
        registry: ${{ env.REGISTRY }}
        username: ${{ github.actor }}
        password: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Extract metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
        tags: |
          type=ref,event=branch
          type=ref,event=pr
          type=sha
    
    - name: Build and push Docker image
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        labels: ${{ steps.meta.outputs.labels }}

  deploy:
    needs: build
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    environment: production
    
    steps:
    - uses: actions/checkout@v4
    
    - name: Configure kubectl
      uses: azure/k8s-set-context@v1
      with:
        method: kubeconfig
        kubeconfig: ${{ secrets.KUBE_CONFIG }}
    
    - name: Deploy to Kubernetes
      run: |
        envsubst < k8s/deployment.yaml | kubectl apply -f -
        kubectl rollout status deployment/myapp -n production
      env:
        IMAGE_TAG: ${{ github.sha }}
```

## Container Orchestration and Automation

### Docker Automation Scripts
```bash
#!/bin/bash
# Docker deployment automation script

set -euo pipefail

# Configuration
APP_NAME="myapp"
REGISTRY="registry.example.com"
ENVIRONMENT="${1:-staging}"
VERSION="${2:-latest}"

# Functions
log() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" >&2
}

check_dependencies() {
    for cmd in docker docker-compose curl; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            log "ERROR: $cmd is required but not installed"
            exit 1
        fi
    done
}

pull_images() {
    log "Pulling images for $APP_NAME:$VERSION"
    docker pull "$REGISTRY/$APP_NAME:$VERSION"
    docker pull "$REGISTRY/$APP_NAME-nginx:$VERSION"
}

health_check() {
    local url="$1"
    local max_attempts=30
    local attempt=1
    
    log "Performing health check on $url"
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s "$url/health" >/dev/null; then
            log "Health check passed"
            return 0
        fi
        
        log "Health check attempt $attempt/$max_attempts failed, retrying..."
        sleep 10
        ((attempt++))
    done
    
    log "ERROR: Health check failed after $max_attempts attempts"
    return 1
}

deploy() {
    log "Deploying $APP_NAME to $ENVIRONMENT"
    
    # Create deployment directory
    DEPLOY_DIR="/opt/deployments/$APP_NAME/$ENVIRONMENT"
    sudo mkdir -p "$DEPLOY_DIR"
    cd "$DEPLOY_DIR"
    
    # Generate docker-compose file
    cat > docker-compose.yml << EOF
version: '3.8'

services:
  app:
    image: $REGISTRY/$APP_NAME:$VERSION
    container_name: ${APP_NAME}_app
    restart: unless-stopped
    environment:
      - ENVIRONMENT=$ENVIRONMENT
      - DATABASE_URL=\${DATABASE_URL}
      - REDIS_URL=\${REDIS_URL}
    networks:
      - app-network
    volumes:
      - app-data:/app/data
      - ./logs:/app/logs
    depends_on:
      - redis
      - database

  nginx:
    image: $REGISTRY/$APP_NAME-nginx:$VERSION
    container_name: ${APP_NAME}_nginx
    ports:
      - "80:80"
      - "443:443"
    restart: unless-stopped
    networks:
      - app-network
    volumes:
      - ./ssl:/etc/nginx/ssl:ro
    depends_on:
      - app

  redis:
    image: redis:7-alpine
    container_name: ${APP_NAME}_redis
    restart: unless-stopped
    networks:
      - app-network
    volumes:
      - redis-data:/data

  database:
    image: postgres:15
    container_name: ${APP_NAME}_db
    restart: unless-stopped
    environment:
      - POSTGRES_DB=\${DB_NAME}
      - POSTGRES_USER=\${DB_USER}
      - POSTGRES_PASSWORD=\${DB_PASSWORD}
    networks:
      - app-network
    volumes:
      - db-data:/var/lib/postgresql/data

networks:
  app-network:
    driver: bridge

volumes:
  app-data:
  redis-data:
  db-data:
EOF

    # Load environment variables
    if [ -f ".env.$ENVIRONMENT" ]; then
        source ".env.$ENVIRONMENT"
    fi
    
    # Pull images
    pull_images
    
    # Stop existing containers
    docker-compose down --remove-orphans
    
    # Start new deployment
    docker-compose up -d
    
    # Wait for services to be ready
    sleep 30
    
    # Health check
    health_check "http://localhost"
    
    log "Deployment completed successfully"
}

rollback() {
    log "Rolling back $APP_NAME in $ENVIRONMENT"
    
    cd "/opt/deployments/$APP_NAME/$ENVIRONMENT"
    
    # Get previous version from backup
    if [ -f "docker-compose.yml.backup" ]; then
        mv docker-compose.yml docker-compose.yml.failed
        mv docker-compose.yml.backup docker-compose.yml
        
        docker-compose down --remove-orphans
        docker-compose up -d
        
        sleep 30
        health_check "http://localhost"
        
        log "Rollback completed successfully"
    else
        log "ERROR: No backup found for rollback"
        exit 1
    fi
}

# Main execution
case "${3:-deploy}" in
    deploy)
        check_dependencies
        deploy
        ;;
    rollback)
        rollback
        ;;
    *)
        echo "Usage: $0 <environment> <version> [deploy|rollback]"
        exit 1
        ;;
esac
```

This automation toolset provides comprehensive coverage for configuration management, infrastructure provisioning, CI/CD pipelines, and container orchestration in modern DevOps environments.