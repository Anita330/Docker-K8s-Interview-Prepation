# Kubernetes Workloads, Objects, and Services - Complete Guide

This guide covers Pod, Deployment, ReplicaSet, StatefulSet, DaemonSet, Job, CronJob, Service, Ingress, ConfigMap, Secret, PV, PVC, StorageClass, Namespace, and ServiceAccount.

## Kubernetes Resource Categories

### Workloads
- Pod
- ReplicaSet
- Deployment
- StatefulSet
- DaemonSet
- Job
- CronJob

### Networking
- Service
- Ingress
- NetworkPolicy

### Configuration
- ConfigMap
- Secret

### Storage
- PV
- PVC
- StorageClass

### Security
- ServiceAccount
- RBAC Resources

## Deployment
Used for stateless applications.
Features: Rolling updates, Rollbacks, Scaling, Self-healing.

## StatefulSet
Used for databases and stateful workloads.
Features: Stable hostname, Persistent storage, Ordered startup.

## DaemonSet
Runs one Pod on every node.
Examples: Fluent Bit, Node Exporter, OpenTelemetry Collector.

## Job
Runs once and exits.

## CronJob
Runs on a schedule.

## Service
Provides stable networking for Pods.
Types: ClusterIP, NodePort, LoadBalancer, ExternalName.

## Ingress
Provides HTTP/HTTPS routing.

## ConfigMap
Stores non-sensitive configuration.

## Secret
Stores sensitive information.

## PV/PVC
PV = Actual Storage
PVC = Storage Request

## Resource Flow
Deployment -> ReplicaSet -> Pod -> Service -> Ingress

StatefulSet -> Pod -> PVC -> Storage

# Kubernetes Workload Resources: Complete Guide

## What Are These in Kubernetes?

In Kubernetes, **Deployment**, **DaemonSet**, **Service**, **StatefulSet**, and similar resources are called **Kubernetes API Objects** or **Kubernetes Resources**. More specifically:

- **Workload Resources**: Deployment, DaemonSet, StatefulSet, ReplicaSet, Job, CronJob
  - These manage **pods** (the actual running containers)
  
- **Networking Resources**: Service, Ingress
  - These manage **network access** to pods

- **Configuration Resources**: ConfigMap, Secret
  - These store **configuration data**

Collectively, they are **Kubernetes Objects** defined in YAML or JSON manifests that you apply to your cluster using `kubectl apply -f <file>.yaml`.

---

## 1. Deployment

### What is it?
A **Deployment** manages **stateless applications** by creating and managing **ReplicaSets**, which in turn manage pods. It provides declarative updates, rolling updates, and rollback capabilities.

### Use Cases
- Stateless web applications (nginx, API servers)
- Microservices without persistent storage
- Applications that can scale horizontally
- Applications needing rolling updates and rollbacks

### Key Features
- Automatic rolling updates
- Rollback to previous versions
- Scaling (manual or automatic with HPA)
- Self-healing (recreates failed pods)
- Canary/deployment strategies

### YAML Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.24.0
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: "500m"
            memory: "128Mi"
          requests:
            cpu: "250m"
            memory: "64Mi"
        livenessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

### Common Commands
```bash
kubectl apply -f deployment.yaml
kubectl scale deployment nginx-deployment --replicas=5
kubectl set image deployment/nginx-deployment nginx=nginx:1.25.0
kubectl rollout undo deployment/nginx-deployment
kubectl get deployment
kubectl describe deployment nginx-deployment
```

---

## 2. DaemonSet

### What is it?
A **DaemonSet** ensures that **all (or some) nodes** run a copy of a pod. When a node is added, a pod is automatically added; when a node is removed, the pod is garbage collected.

### Use Cases
- Cluster-wide utilities (logging agents like Fluentd, Filebeat)
- Monitoring agents (Prometheus Node Exporter, Datadog Agent)
- Storage daemons (glusterd, ceph)
- Network plugins (Calico, Flannel, Weave)
- Security agents (security scanners, intrusion detection)

### Key Features
- One pod per node (by default)
- Automatic pod placement on new nodes
- Ideal for node-level services
- Cannot be scaled manually (controlled by node count)

### YAML Example

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: node-exporter
  labels:
    app: node-exporter
spec:
  selector:
    matchLabels:
      app: node-exporter
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
  template:
    metadata:
      labels:
        app: node-exporter
    spec:
      hostPID: true
      hostNetwork: true
      containers:
      - name: node-exporter
        image: prom/node-exporter:v1.6.0
        ports:
        - containerPort: 9100
          hostPort: 9100
        resources:
          limits:
            cpu: "200m"
            memory: "128Mi"
          requests:
            cpu: "100m"
            memory: "64Mi"
        volumeMounts:
        - name: proc
          mountPath: /host/proc
          readOnly: true
        - name: sys
          mountPath: /host/sys
          readOnly: true
      volumes:
      - name: proc
        hostPath:
          path: /proc
      - name: sys
        hostPath:
          path: /sys
      tolerations:
      - effect: NoSchedule
        operator: Exists
```

### Common Commands
```bash
kubectl apply -f daemonset.yaml
kubectl get daemonset
kubectl describe daemonset node-exporter
kubectl get pods -o wide | grep node-exporter
```

---

## 3. Service

### What is it?
A **Service** is an **abstract layer** that provides a **stable network endpoint** (IP address and DNS name) to access a set of pods. It enables service discovery and load balancing.

### Service Types

| Type | Use Case | External Access |
|------|----------|-----------------|
| **ClusterIP** | Internal cluster communication | No (default) |
| **NodePort** | Expose on each node's IP | Yes (node IP:port) |
| **LoadBalancer** | Expose via cloud provider LB | Yes (external LB) |
| **ExternalName** | Map to external DNS | N/A (DNS CNAME) |

### YAML Examples

#### ClusterIP (Default - Internal Only)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  labels:
    app: nginx
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
```

#### NodePort (External via Node IP)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-nodeport
  labels:
    app: nginx
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    nodePort: 30080
    protocol: TCP
    name: http
```

#### LoadBalancer (Cloud Provider LB)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-loadbalancer
  labels:
    app: nginx
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
    protocol: TCP
    name: http
```

#### Headless Service (For StatefulSet)
```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
  labels:
    app: postgres
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
    protocol: TCP
    name: postgres
```

### Common Commands
```bash
kubectl apply -f service.yaml
kubectl get services
kubectl get svc
kubectl describe service nginx-service
```

---

## 4. StatefulSet

### What is it?
A **StatefulSet** manages **stateful applications** with **unique, persistent identities** and **stable network identifiers**. Unlike Deployments, pods have deterministic names (`app-name-0`, `app-name-1`, ...) and maintain order during scaling/upgrades.

### Use Cases
- Databases (MySQL, PostgreSQL, MongoDB, Cassandra)
- Distributed systems (Kafka, Elasticsearch, ZooKeeper)
- Applications requiring stable network IDs
- Applications with persistent storage per pod
- Applications needing ordered deployment/scaling

### Key Features
- Stable, unique pod names (`web-0`, `web-1`, `web-2`)
- Stable network identity (DNS: `web-0.service-name`)
- Ordered, graceful deployment and scaling
- Ordered, automated rolling updates
- Persistent storage per pod (PersistentVolumeClaim)

### YAML Example
```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-statefulset
  labels:
    app: postgres
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
    name: postgres
***
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-statefulset
  replicas: 3
  podManagementPolicy: OrderedReady
  updateStrategy:
    type: RollingUpdate
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      terminationGracePeriodSeconds: 10
      containers:
      - name: postgres
        image: postgres:15.3
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: POSTGRES_DB
          value: mydb
        - name: POSTGRES_USER
          value: postgres
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        volumeMounts:
        - name: postgres-data
          mountPath: /var/lib/postgresql/data
        resources:
          limits:
            cpu: "1000m"
            memory: "1Gi"
          requests:
            cpu: "500m"
            memory: "512Mi"
  volumeClaimTemplates:
  - metadata:
      name: postgres-data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: standard
      resources:
        requests:
          storage: 10Gi
```

### Pod Naming Pattern

# 8. Quick Comparison Table

| Resource | Stateful? | Pod Identity | Scaling | Best For |
|----------|-----------|--------------|---------|----------|
| **Deployment** | No | Random | Manual/HPA | Stateless apps |
| **DaemonSet** | No | One per node | Auto (by nodes) | Node-level agents |
| **StatefulSet** | Yes | Stable, ordered | Manual | Databases, distributed systems |
| **ReplicaSet** | No | Random | Manual | Managed by Deployment |
| **Job** | No | Random | Fixed completions | One-time batch tasks |
| **CronJob** | No | Random | Scheduled | Recurring batch tasks |
| **Service** | N/A | N/A | N/A | Network access to pods |

---