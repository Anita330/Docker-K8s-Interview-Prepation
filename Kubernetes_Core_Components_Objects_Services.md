# Kubernetes Core Components, Objects, and Services

## Table of Contents
1. Kubernetes Architecture Overview
2. Control Plane Components
3. Worker Node Components
4. Kubernetes Request Flow
5. Kubernetes Objects
6. Kubernetes Services
7. Storage Components
8. Networking Components
9. Real-World EKS Architecture
10. Interview Questions

---

# 1. Kubernetes Architecture Overview

Kubernetes consists of:

- Control Plane
- Worker Nodes

```text
+-----------------------+
|     Control Plane     |
| API Server            |
| ETCD                  |
| Scheduler             |
| Controller Manager    |
+-----------------------+
           |
           |
+----------+-----------+
|                      |
v                      v

+------------+   +------------+
| Worker 1   |   | Worker 2   |
| Kubelet    |   | Kubelet    |
| Kube Proxy |   | Kube Proxy |
| Container  |   | Container  |
| Runtime    |   | Runtime    |
+------------+   +------------+
```

---

# 2. Control Plane Components

## kube-apiserver

- Entry point for Kubernetes.
- Receives requests from kubectl, UI, CI/CD tools.
- Authenticates and authorizes requests.
- Updates cluster state in ETCD.

### Example

```bash
kubectl get pods
```

Request Flow:

```text
kubectl -> API Server -> ETCD
```

---

## ETCD

Distributed key-value database.

Stores:

- Pods
- Deployments
- Nodes
- Secrets
- ConfigMaps
- Services

Important:

- Source of truth for Kubernetes.
- Always back up ETCD.

---

## kube-scheduler

Responsible for selecting nodes for Pods.

Checks:

- CPU
- Memory
- Affinity
- Anti-affinity
- Taints/Tolerations
- Resource Requests

---

## kube-controller-manager

Runs controllers continuously.

Controllers:

- Deployment Controller
- ReplicaSet Controller
- Job Controller
- Namespace Controller
- Node Controller

Example:

Desired Pods = 3

Actual Pods = 2

Controller creates one additional Pod.

---

## Cloud Controller Manager

Integrates Kubernetes with cloud providers.

Examples:

- AWS
- Azure
- GCP

Manages:

- Load Balancers
- Routes
- Storage Volumes
- Nodes

---

# 3. Worker Node Components

## Kubelet

Node agent.

Responsibilities:

- Registers node
- Creates Pods
- Monitors Pods
- Reports node health

---

## Container Runtime

Responsible for running containers.

Examples:

- containerd
- CRI-O

Functions:

- Pull images
- Start containers
- Stop containers

---

## kube-proxy

Handles networking.

Functions:

- Service routing
- Load balancing
- IPTables/IPVS rules

---

# 4. Kubernetes Request Flow

```text
kubectl apply deployment.yaml
          |
          v
      API Server
          |
          v
         ETCD
          |
          v
 Controller Manager
          |
          v
      Scheduler
          |
          v
      Worker Node
          |
          v
       Kubelet
          |
          v
 Container Runtime
          |
          v
         Pod
```

---

# 5. Kubernetes Objects

## Pod

Smallest deployable unit.

Contains:

- One or more containers
- Shared network
- Shared storage

---

## ReplicaSet

Maintains desired number of Pods.

```yaml
replicas: 3
```

Ensures three Pods remain running.

---

## Deployment

Most common object.

Features:

- Rolling Updates
- Rollbacks
- Scaling

Commands:

```bash
kubectl rollout history deployment nginx
kubectl rollout undo deployment nginx
```

---

## StatefulSet

Used for stateful workloads.

Examples:

- MongoDB
- PostgreSQL
- MySQL

Features:

- Stable hostname
- Stable storage
- Ordered deployment

---

## DaemonSet

Runs one Pod on every node.

Examples:

- Fluent Bit
- Node Exporter
- Security Agents

---

## Job

Runs once and exits.

Examples:

- Database backup
- Data migration

---

## CronJob

Scheduled Job.

Example:

```yaml
schedule: "0 2 * * *"
```

Runs daily at 2 AM.

---

## Namespace

Provides logical isolation.

Examples:

```text
default
kube-system
dev
prod
```

---

## ConfigMap

Stores non-sensitive configuration.

Examples:

- URLs
- Hostnames
- Environment variables

---

## Secret

Stores sensitive information.

Examples:

- Passwords
- Tokens
- Certificates

---

## ServiceAccount

Identity for Pods.

Used with:

- RBAC
- IAM Roles for Service Accounts (IRSA)

---

## ResourceQuota

Limits namespace resources.

Example:

```yaml
pods: 50
cpu: 20
memory: 50Gi
```

---

## LimitRange

Defines default resource requests and limits.

---

# 6. Kubernetes Services

Services provide stable networking for Pods.

## ClusterIP

Default service type.

Internal communication only.

```yaml
type: ClusterIP
```

---

## NodePort

Exposes service on node IP.

```yaml
type: NodePort
```

Port Range:

```text
30000-32767
```

---

## LoadBalancer

Creates cloud load balancer.

```yaml
type: LoadBalancer
```

Commonly used in EKS production workloads.

---

## ExternalName

Maps Kubernetes service to external DNS.

Example:

```yaml
externalName: database.company.com
```

---

## Headless Service

```yaml
clusterIP: None
```

Used mainly with StatefulSets.

Provides individual Pod DNS records.

---

# 7. Storage Components

## PersistentVolume (PV)

Actual storage resource.

Examples:

- AWS EBS
- EFS
- NFS

---

## PersistentVolumeClaim (PVC)

Request for storage.

Example:

```yaml
storage: 10Gi
```

---

## StorageClass

Dynamic provisioning of storage.

Example:

```yaml
provisioner: ebs.csi.aws.com
```

---

# 8. Networking Components

## Ingress

Provides HTTP/HTTPS routing.

Example:

```text
app.company.com -> App Service
api.company.com -> API Service
```

---

## Ingress Controller

Examples:

- NGINX Ingress
- AWS Load Balancer Controller
- Traefik

---

## Network Policy

Controls Pod-to-Pod communication.

Example:

Allow:

```text
Frontend -> Backend
```

Deny:

```text
Frontend -> Database
```

---

# 9. Real-World EKS Architecture

```text
Internet
   |
AWS Load Balancer
   |
Ingress
   |
Service (ClusterIP)
   |
Deployment
   |
ReplicaSet
   |
Pods
   |
PVC
   |
EBS Volume
```

Observability Stack:

```text
Application
   |
OpenTelemetry
   |
Prometheus
   |
Grafana
```

Logging Stack:

```text
Application
   |
Fluent Bit
   |
CloudWatch
```

---

# 10. Important Interview Questions

1. Difference between Deployment and StatefulSet?
2. Difference between ClusterIP and NodePort?
3. What happens when a Pod crashes?
4. How does Scheduler select a node?
5. What is ETCD?
6. Difference between ConfigMap and Secret?
7. What is a DaemonSet?
8. Difference between PV and PVC?
9. What is Ingress?
10. What is kube-proxy?
11. Difference between HPA, VPA, and Cluster Autoscaler?
12. How does IRSA work in EKS?
13. What are taints and tolerations?
14. What are affinity and anti-affinity rules?
15. How does rolling update work?

---

# Quick Revision Table

| Component | Purpose |
|------------|----------|
| API Server | Entry point |
| ETCD | Cluster database |
| Scheduler | Selects node |
| Controller Manager | Maintains desired state |
| Kubelet | Node agent |
| Kube Proxy | Networking |
| Pod | Smallest deployment unit |
| ReplicaSet | Maintains pod count |
| Deployment | Stateless apps |
| StatefulSet | Stateful apps |
| DaemonSet | One pod per node |
| Job | Run once |
| CronJob | Scheduled execution |
| Service | Stable networking |
| Ingress | HTTP/HTTPS routing |
| ConfigMap | Non-sensitive configuration |
| Secret | Sensitive configuration |
| PV | Physical storage |
| PVC | Storage request |
| StorageClass | Dynamic storage provisioning |
