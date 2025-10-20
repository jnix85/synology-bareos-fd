# Containerization and Cloud-Native Toolset

## Overview
Comprehensive tools for containerization, Kubernetes orchestration, cloud-native development, and container security. Covers Docker, Kubernetes, OpenShift, service mesh, and cloud-native patterns.

## Docker Container Management

### Docker Core Commands
```bash
# Image management
docker images                         # List local images
docker pull nginx:latest             # Pull image from registry
docker build -t myapp:latest .       # Build image from Dockerfile
docker tag myapp:latest registry.com/myapp:v1.0  # Tag image
docker push registry.com/myapp:v1.0   # Push image to registry
docker rmi image_id                   # Remove image
docker image prune                    # Remove unused images

# Container lifecycle
docker run -d --name webapp -p 8080:80 nginx  # Run container detached
docker start container_name           # Start stopped container
docker stop container_name            # Stop running container
docker restart container_name         # Restart container
docker rm container_name              # Remove container
docker container prune               # Remove stopped containers

# Container inspection and debugging
docker ps                            # List running containers
docker ps -a                         # List all containers
docker logs container_name           # View container logs
docker logs -f container_name        # Follow log output
docker exec -it container_name bash  # Interactive shell
docker inspect container_name        # Detailed container info
docker stats                         # Real-time resource usage
docker top container_name            # Running processes in container
```

### Advanced Docker Operations
```bash
# Volume management
docker volume create myvolume        # Create named volume
docker volume ls                     # List volumes
docker volume inspect myvolume      # Inspect volume
docker run -v myvolume:/data nginx   # Mount named volume
docker run -v /host/path:/container/path nginx  # Bind mount

# Network management
docker network create mynetwork     # Create custom network
docker network ls                   # List networks
docker network inspect bridge       # Inspect network
docker run --network mynetwork nginx  # Connect container to network

# Multi-stage builds
# Dockerfile example
FROM node:16 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:16-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY . .
EXPOSE 3000
CMD ["npm", "start"]

# Docker Compose
# docker-compose.yml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "8080:80"
    environment:
      - NODE_ENV=production
    volumes:
      - ./logs:/var/log/app
    depends_on:
      - database
      - redis
    networks:
      - app-network
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  database:
    image: postgres:15
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: ${DB_USER:-postgres}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - db_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - app-network

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    networks:
      - app-network

volumes:
  db_data:
  redis_data:

networks:
  app-network:
    driver: bridge
```

## Kubernetes Container Orchestration

### Kubernetes Core Commands
```bash
# Cluster information
kubectl cluster-info             # Display cluster info
kubectl version                  # Show client and server versions
kubectl get nodes               # List cluster nodes
kubectl describe node node-name # Detailed node information
kubectl top nodes               # Node resource usage
kubectl get namespaces          # List namespaces

# Pod management
kubectl get pods                 # List pods in current namespace
kubectl get pods -A              # List pods in all namespaces
kubectl get pods -o wide         # Detailed pod information
kubectl describe pod pod-name    # Detailed pod description
kubectl logs pod-name            # View pod logs
kubectl logs -f pod-name         # Follow pod logs
kubectl exec -it pod-name -- bash  # Interactive shell in pod
kubectl port-forward pod-name 8080:80  # Port forwarding

# Deployment management
kubectl create deployment nginx --image=nginx:latest  # Create deployment
kubectl get deployments         # List deployments
kubectl describe deployment nginx  # Describe deployment
kubectl scale deployment nginx --replicas=3  # Scale deployment
kubectl rollout status deployment/nginx  # Check rollout status
kubectl rollout history deployment/nginx  # View rollout history
kubectl rollout undo deployment/nginx  # Rollback to previous version

# Service management
kubectl expose deployment nginx --port=80 --type=ClusterIP  # Create service
kubectl get services             # List services
kubectl describe service nginx   # Describe service
kubectl get endpoints           # List service endpoints
```

### Kubernetes YAML Manifests
```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: myapp
  labels:
    name: myapp
    environment: production

---
# deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp-deployment
  namespace: myapp
  labels:
    app: myapp
    version: v1.0
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: v1.0
    spec:
      containers:
      - name: myapp
        image: registry.com/myapp:v1.0
        ports:
        - containerPort: 8080
          name: http
        env:
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: myapp-secrets
              key: database-url
        - name: REDIS_URL
          valueFrom:
            configMapKeyRef:
              name: myapp-config
              key: redis-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
        volumeMounts:
        - name: app-storage
          mountPath: /app/data
        - name: config-volume
          mountPath: /app/config
      volumes:
      - name: app-storage
        persistentVolumeClaim:
          claimName: myapp-pvc
      - name: config-volume
        configMap:
          name: myapp-config
      imagePullSecrets:
      - name: registry-secret

---
# service.yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-service
  namespace: myapp
  labels:
    app: myapp
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 8080
    protocol: TCP
    name: http
  selector:
    app: myapp

---
# ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: myapp-ingress
  namespace: myapp
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: letsencrypt-prod
    nginx.ingress.kubernetes.io/rewrite-target: /
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: myapp-service
            port:
              number: 80

---
# configmap.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-config
  namespace: myapp
data:
  redis-url: "redis://redis-service:6379"
  log-level: "info"
  app.properties: |
    debug=false
    database.pool.size=10
    cache.ttl=3600

---
# secret.yaml
apiVersion: v1
kind: Secret
metadata:
  name: myapp-secrets
  namespace: myapp
type: Opaque
data:
  database-url: cG9zdGdyZXNxbDovL3VzZXI6cGFzc0BkYi5leGFtcGxlLmNvbS9teWFwcA==  # base64 encoded
  api-key: YWJjZGVmZ2hpams=  # base64 encoded

---
# pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: myapp-pvc
  namespace: myapp
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: fast-ssd

---
# hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
  namespace: myapp
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp-deployment
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

### Helm Package Management
```bash
# Helm installation and setup
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
helm version                     # Check Helm version

# Repository management
helm repo add stable https://charts.helm.sh/stable
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update                 # Update repository cache
helm repo list                   # List repositories
helm search repo nginx          # Search for charts

# Chart management
helm create myapp                # Create new chart
helm lint myapp/                 # Validate chart
helm template myapp myapp/       # Render templates locally
helm package myapp/              # Package chart

# Release management
helm install myapp-prod myapp/ --namespace production
helm list                        # List releases
helm status myapp-prod           # Check release status
helm upgrade myapp-prod myapp/ --set image.tag=v2.0
helm rollback myapp-prod 1       # Rollback to revision 1
helm uninstall myapp-prod        # Delete release

# Helm chart structure
# myapp/
# ├── Chart.yaml
# ├── values.yaml
# ├── charts/
# └── templates/
#     ├── deployment.yaml
#     ├── service.yaml
#     ├── ingress.yaml
#     ├── configmap.yaml
#     ├── secret.yaml
#     └── _helpers.tpl

# values.yaml
image:
  repository: myapp
  tag: latest
  pullPolicy: IfNotPresent

service:
  type: ClusterIP
  port: 80

ingress:
  enabled: true
  hostname: myapp.example.com
  tls: true

resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"

autoscaling:
  enabled: true
  minReplicas: 3
  maxReplicas: 10
  targetCPUUtilizationPercentage: 70
```

## OpenShift Container Platform

### OpenShift CLI (oc) Commands
```bash
# Login and project management
oc login https://api.openshift.example.com:6443  # Login to cluster
oc whoami                       # Current user
oc projects                     # List projects
oc project myproject            # Switch to project
oc new-project myapp            # Create new project

# Application deployment
oc new-app https://github.com/user/myapp.git  # Deploy from Git
oc new-app --docker-image=nginx:latest  # Deploy from image
oc new-app -f deployment.yaml   # Deploy from template

# Build management
oc get builds                   # List builds
oc logs build/myapp-1           # View build logs
oc start-build myapp            # Trigger new build
oc cancel-build myapp-1         # Cancel build

# Route management (OpenShift-specific)
oc create route edge --service=myapp-service --hostname=myapp.apps.example.com
oc get routes                   # List routes
oc describe route myapp         # Describe route

# Source-to-Image (S2I) builds
oc new-build --strategy=source --binary --name=myapp
oc start-build myapp --from-dir=. --follow  # Build from local directory

# DeploymentConfig (OpenShift-specific)
oc rollout latest dc/myapp      # Trigger new deployment
oc rollout history dc/myapp     # View deployment history
oc rollout undo dc/myapp        # Rollback deployment
```

### OpenShift Templates
```yaml
# openshift-template.yaml
apiVersion: template.openshift.io/v1
kind: Template
metadata:
  name: myapp-template
  annotations:
    description: "Template for deploying MyApp"
    tags: "web,nodejs"
objects:
- apiVersion: apps.openshift.io/v1
  kind: DeploymentConfig
  metadata:
    name: ${APP_NAME}
    labels:
      app: ${APP_NAME}
  spec:
    replicas: ${{REPLICA_COUNT}}
    selector:
      app: ${APP_NAME}
    template:
      metadata:
        labels:
          app: ${APP_NAME}
      spec:
        containers:
        - name: ${APP_NAME}
          image: ${IMAGE_NAME}:${IMAGE_TAG}
          ports:
          - containerPort: 8080
          env:
          - name: NODE_ENV
            value: ${NODE_ENV}
          resources:
            requests:
              memory: ${MEMORY_REQUEST}
              cpu: ${CPU_REQUEST}
            limits:
              memory: ${MEMORY_LIMIT}
              cpu: ${CPU_LIMIT}
    triggers:
    - type: ConfigChange
    - type: ImageChange
      imageChangeParams:
        automatic: true
        containerNames:
        - ${APP_NAME}
        from:
          kind: ImageStreamTag
          name: ${APP_NAME}:latest

- apiVersion: v1
  kind: Service
  metadata:
    name: ${APP_NAME}-service
    labels:
      app: ${APP_NAME}
  spec:
    ports:
    - port: 80
      targetPort: 8080
    selector:
      app: ${APP_NAME}

- apiVersion: route.openshift.io/v1
  kind: Route
  metadata:
    name: ${APP_NAME}-route
    labels:
      app: ${APP_NAME}
  spec:
    host: ${APP_HOSTNAME}
    to:
      kind: Service
      name: ${APP_NAME}-service
    tls:
      termination: edge
      insecureEdgeTerminationPolicy: Redirect

parameters:
- name: APP_NAME
  description: "Name of the application"
  value: "myapp"
  required: true
- name: IMAGE_NAME
  description: "Container image name"
  value: "myapp"
  required: true
- name: IMAGE_TAG
  description: "Container image tag"
  value: "latest"
  required: true
- name: REPLICA_COUNT
  description: "Number of replicas"
  value: "3"
  required: true
- name: NODE_ENV
  description: "Node.js environment"
  value: "production"
  required: true
- name: APP_HOSTNAME
  description: "Application hostname"
  required: true
- name: MEMORY_REQUEST
  description: "Memory request"
  value: "256Mi"
- name: MEMORY_LIMIT
  description: "Memory limit"
  value: "512Mi"
- name: CPU_REQUEST
  description: "CPU request"
  value: "250m"
- name: CPU_LIMIT
  description: "CPU limit"
  value: "500m"
```

## Service Mesh with Istio

### Istio Installation and Management
```bash
# Download and install Istio
curl -L https://istio.io/downloadIstio | sh -
export PATH=$PWD/istio-1.19.0/bin:$PATH

# Install Istio on Kubernetes
istioctl install --set values.defaultRevision=default
kubectl label namespace default istio-injection=enabled

# Verify installation
istioctl verify-install
kubectl get pods -n istio-system

# Istio configuration
istioctl proxy-config cluster productpage-v1-123456789-abcde.default
istioctl proxy-status          # Check proxy status
istioctl analyze              # Analyze configuration issues
```

### Istio Service Mesh Configuration
```yaml
# gateway.yaml
apiVersion: networking.istio.io/v1beta1
kind: Gateway
metadata:
  name: myapp-gateway
  namespace: myapp
spec:
  selector:
    istio: ingressgateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - myapp.example.com
    tls:
      httpsRedirect: true
  - port:
      number: 443
      name: https
      protocol: HTTPS
    tls:
      mode: SIMPLE
      credentialName: myapp-tls
    hosts:
    - myapp.example.com

---
# virtualservice.yaml
apiVersion: networking.istio.io/v1beta1
kind: VirtualService
metadata:
  name: myapp-vs
  namespace: myapp
spec:
  hosts:
  - myapp.example.com
  gateways:
  - myapp-gateway
  http:
  - match:
    - uri:
        prefix: /api/v2
    route:
    - destination:
        host: myapp-service
        subset: v2
      weight: 10
    - destination:
        host: myapp-service
        subset: v1
      weight: 90
    fault:
      delay:
        percentage:
          value: 0.1
        fixedDelay: 5s
  - match:
    - uri:
        prefix: /
    route:
    - destination:
        host: myapp-service
        subset: v1

---
# destinationrule.yaml
apiVersion: networking.istio.io/v1beta1
kind: DestinationRule
metadata:
  name: myapp-dr
  namespace: myapp
spec:
  host: myapp-service
  trafficPolicy:
    connectionPool:
      tcp:
        maxConnections: 100
      http:
        http1MaxPendingRequests: 50
        maxRequestsPerConnection: 2
    loadBalancer:
      simple: LEAST_CONN
    outlierDetection:
      consecutiveErrors: 3
      interval: 30s
      baseEjectionTime: 30s
  subsets:
  - name: v1
    labels:
      version: v1
    trafficPolicy:
      circuitBreaker:
        consecutiveErrors: 3
        interval: 30s
        baseEjectionTime: 30s
  - name: v2
    labels:
      version: v2

---
# peerauthentication.yaml
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: myapp
spec:
  mtls:
    mode: STRICT

---
# authorizationpolicy.yaml
apiVersion: security.istio.io/v1beta1
kind: AuthorizationPolicy
metadata:
  name: myapp-authz
  namespace: myapp
spec:
  selector:
    matchLabels:
      app: myapp
  rules:
  - from:
    - source:
        principals: ["cluster.local/ns/istio-system/sa/istio-ingressgateway-service-account"]
    to:
    - operation:
        methods: ["GET", "POST"]
  - from:
    - source:
        namespaces: ["myapp"]
    to:
    - operation:
        methods: ["GET", "POST", "PUT", "DELETE"]
```

## Container Security and Compliance

### Container Image Security Scanning
```bash
# Trivy - Vulnerability scanner
trivy image nginx:latest                    # Scan image for vulnerabilities
trivy image --severity HIGH,CRITICAL nginx  # Scan for high/critical only
trivy image --format json nginx > scan.json  # Output in JSON format
trivy fs .                                  # Scan filesystem
trivy k8s --report summary cluster         # Scan Kubernetes cluster

# Clair vulnerability scanner (with clairctl)
clairctl analyze nginx:latest
clairctl report nginx:latest

# Anchore Engine
anchore-cli image add nginx:latest
anchore-cli image wait nginx:latest
anchore-cli image vuln nginx:latest all
anchore-cli evaluate check nginx:latest

# Docker Bench Security
docker run --rm --net host --pid host --userns host --cap-add audit_control \
    -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
    -v /etc:/etc:ro \
    -v /usr/bin/containerd:/usr/bin/containerd:ro \
    -v /usr/bin/runc:/usr/bin/runc:ro \
    -v /usr/lib/systemd:/usr/lib/systemd:ro \
    -v /var/lib:/var/lib:ro \
    -v /var/run/docker.sock:/var/run/docker.sock:ro \
    docker/docker-bench-security
```

### Kubernetes Security Best Practices
```yaml
# pod-security-policy.yaml (deprecated in K8s 1.25+)
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
    - ALL
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    - 'persistentVolumeClaim'
  runAsUser:
    rule: 'MustRunAsNonRoot'
  seLinux:
    rule: 'RunAsAny'
  fsGroup:
    rule: 'RunAsAny'

---
# network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: myapp-netpol
  namespace: myapp
spec:
  podSelector:
    matchLabels:
      app: myapp
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: istio-system
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
  - to: []
    ports:
    - protocol: TCP
      port: 53
    - protocol: UDP
      port: 53

---
# security-context.yaml
apiVersion: v1
kind: Pod
metadata:
  name: security-context-demo
spec:
  securityContext:
    runAsUser: 1000
    runAsGroup: 3000
    fsGroup: 2000
    seccompProfile:
      type: RuntimeDefault
  containers:
  - name: app
    image: myapp:latest
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: var-log
      mountPath: /var/log
  volumes:
  - name: tmp
    emptyDir: {}
  - name: var-log
    emptyDir: {}
```

This containerization toolset provides comprehensive coverage for Docker, Kubernetes, OpenShift, service mesh, and container security in cloud-native environments.