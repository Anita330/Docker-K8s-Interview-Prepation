# Kubernetes (k8s) Complete Cheatsheet

## 📋 Table of Contents
1. [Core Concepts](#core-concepts)
2. [kubectl Commands](#kubectl-commands)
3. [Pod Management](#pod-management)
4. [Deployment & Scaling](#deployment--scaling)
5. [Service & Networking](#service--networking)
6. [ConfigMaps & Secrets](#configmaps--secrets)
7. [StatefulSet & DaemonSet](#statefulset--daemonset)
8. [Jobs & CronJobs](#jobs--cronjobs)
9. [Storage (PVC/PV)](#storage-pvcpv)
10. [Namespaces](#namespaces)
11. [Labels & Selectors](#labels--selectors)
12. [Troubleshooting](#troubleshooting)
13. [YAML Templates](#yaml-templates)
14. [Pod Lifecycle](#pod-lifecycle)

---

## Core Concepts

### K8s Architecture Components
| Component | Role |
|-----------|------|
| **API Server** | Frontend for cluster, validates REST requests |
| **etcd** | Key-value store for cluster state |
| **Scheduler** | Assigns pods to nodes based on resources |
| **Controller Manager** | Manages replicas, endpoints, nodes |
| **kubelet** | Agent on each node, manages containers |
| **kube-proxy** | Network proxy, manages iptables |
| **Container Runtime** | Docker, containerd, CRI-O |

### Resource Hierarchy


---

## kubectl Commands

### Basic Syntax
```bash
kubectl <verb> <resource> <name> [flags]
```

### Common Verbs
| Verb | Action |
|------|--------|
| `get` | List resources |
| `describe` | Detailed info |
| `create` | Create from file |
| `apply` | Apply config (declarative) |
| `delete` | Delete resource |
| `edit` | Edit resource |
| `scale` | Change replicas |
| `explain` | Get API resource docs |
| `logs` | View container logs |
| `exec` | Execute command in pod |
| `port-forward` | Forward local port to pod |
| `top` | View resource usage |

### Shortcuts
```bash
kubectl get pods           # Same as kubectl get pod
kubectl get po             # Short for pod
kubectl get svc            # Service
kubectl get deploy         # Deployment
kubectl get ds             # DaemonSet
kubectl get sts            # StatefulSet
kubectl get job            # Job
kubectl get cj             # CronJob
kubectl get cm             # ConfigMap
kubectl get secret         # Secret
kubectl get pv             # PersistentVolume
kubectl get pvc            # PersistentVolumeClaim
kubectl get ns             # Namespace
kubectl get no             # Node
kubectl get all            # All resources in namespace
```

---

## Pod Management

### Create & Delete
```bash
# Create pod from file
kubectl apply -f pod.yaml

# Create pod directly (quick test)
kubectl run nginx-pod --image=nginx:1.24 --restart=Always

# Create pod with command
kubectl run debug-pod --image=busybox --rm -it --restart=Never -- sh

# Delete pod
kubectl delete pod nginx-pod
kubectl delete pod nginx-pod --grace-period=0 --force
```

### View & Inspect
```bash
# List all pods
kubectl get pods
kubectl get pods -A              # All namespaces
kubectl get pods -n kube-system  # Specific namespace

# View detailed status
kubectl describe pod <pod-name>

# Watch pods in real-time
kubectl get pods -w

# Get pods with node info
kubectl get pods -o wide

# Get pods with labels
kubectl get pods -l app=nginx
kubectl get pods --selector app=nginx

# Get JSON/YAML output
kubectl get pod <name> -o json
kubectl get pod <name> -o yaml
```

### Logs
```bash
# View logs
kubectl logs <pod-name>

# View logs of specific container
kubectl logs <pod-name> -c <container-name>

# Follow logs (like tail -f)
kubectl logs -f <pod-name>

# Previous container logs (after crash)
kubectl logs <pod-name> -p

# Logs with timestamp
kubectl logs <pod-name> --timestamps

# Last N lines
kubectl logs <pod-name> --tail=100
```

### Execute Commands
```bash
# Execute command
kubectl exec <pod-name> -- ls /

# Interactive shell
kubectl exec -it <pod-name> -- sh
kubectl exec -it <pod-name> -- bash

# Run command in specific container
kubectl exec -it <pod-name> -c <container> -- sh
```

### Port Forwarding
```bash
# Forward local port to pod
kubectl port-forward pod/nginx-pod 8080:80

# Access via localhost:8080
curl http://localhost:8080
```

---

## Deployment & Scaling

### Create & Update
```bash
# Create deployment
kubectl create deployment nginx --image=nginx:1.24

# Apply deployment from file
kubectl apply -f deployment.yaml

# View deployment
kubectl get deploy
kubectl get deploy -o wide
kubectl describe deploy <name>

# Update image
kubectl set image deployment/nginx nginx=nginx:1.25

# Update image (short form)
kubectl set image deploy/nginx nginx=nginx:v2

# View rollout history
kubectl rollout history deployment/nginx

# Rollback to previous version
kubectl rollout undo deployment/nginx

# Rollback to specific revision
kubectl rollout undo deployment/nginx --to-revision=2

# Check rollout status
kubectl rollout status deployment/nginx
```

### Scaling
```bash
# Scale deployment
kubectl scale deployment/nginx --replicas=5

# Scale to 0 (pause)
kubectl scale deployment/nginx --replicas=0

# Autoscale (create HPA)
kubectl autoscale deployment/nginx --min=2 --max=10 --cpu-percent=80

# View HPA
kubectl get hpa
kubectl describe hpa nginx
```

---

## Service & Networking

### Create Services
```bash
# Create ClusterIP service
kubectl expose deployment/nginx --port=80 --target-port=80 --name=nginx-svc

# Create NodePort service
kubectl expose deployment/nginx --port=80 --target-port=80 --type=NodePort --name=nginx-nodeport

# Create LoadBalancer service
kubectl expose deployment/nginx --port=80 --target-port=80 --type=LoadBalancer --name=nginx-lb

# Create service from file
kubectl apply -f service.yaml
```

### View Services
```bash
# List services
kubectl get svc
kubectl get svc -o wide

# Describe service
kubectl describe svc <name>

# Check endpoints
kubectl get endpoints <svc-name>
```

### Service Types
| Type | Description | Use Case |
|------|-------------|----------|
| **ClusterIP** | Internal IP only | Internal communication (default) |
| **NodePort** | Expose on node IP:port | Development/testing |
| **LoadBalancer** | Cloud provider LB | Production external access |
| **ExternalName** | CNAME to external DNS | Map to external service |

### Network Commands
```bash
# Get nodes
kubectl get nodes
kubectl describe node <node-name>

# Get node taints
kubectl get nodes -o jsonpath='{.items[*].spec.taints}'

# Get node labels
kubectl get nodes --show-labels

# Add label to node
kubectl label nodes <node-name> disktype=ssd

# Remove label from node
kubectl label nodes <node-name> disktype-

# Add taint to node
kubectl taint nodes <node-name> key=value:NoSchedule

# Remove taint from node
kubectl taint nodes <node-name> key=value:NoSchedule-
```

---

## ConfigMaps & Secrets

### ConfigMap
```bash
# Create ConfigMap from literal
kubectl create configmap my-config --from-literal=KEY1=value1 --from-literal=KEY2=value2

# Create ConfigMap from file
kubectl create configmap my-config --from-file=config.properties

# View ConfigMap
kubectl get cm
kubectl get cm my-config -o yaml
kubectl describe cm my-config

# Use in Pod
envFrom:
- configMapRef:
    name: my-config

# Or as individual env
env:
- name: KEY1
  valueFrom:
    configMapKeyRef:
      name: my-config
      key: KEY1
```

### Secret
```bash
# Create Secret (opaque)
kubectl create secret generic my-secret --from-literal=username=admin --from-literal=password=secret123

# View Secret (decoded)
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 -d
```

---

## StatefulSet & DaemonSet

### StatefulSet
```bash
# Create StatefulSet
kubectl apply -f statefulset.yaml

# View StatefulSet
kubectl get sts
kubectl describe sts <name>

# Scale StatefulSet
kubectl scale sts web --replicas=5
```

### DaemonSet
```bash
# Create DaemonSet
kubectl apply -f daemonset.yaml

# View DaemonSet
kubectl get ds
kubectl describe ds <name>
```

---

## Jobs & CronJobs

### Job
```bash
# Create Job
kubectl create job my-job --image=busybox -- sh -c 'echo "Hello"; sleep 5'

# View Job
kubectl get jobs
kubectl describe job <name>
```

### CronJob
```bash
# Create CronJob
kubectl create cronjob daily-backup --image=busybox --schedule="0 2 * * *" -- sh -c 'echo "Backup"'

# View CronJob
kubectl get cj
kubectl describe cj <name>

# Suspend CronJob
kubectl patch cronjob <name> -p '{"spec":{"suspend":true}}'
```

### Cron Schedule Format

Examples:
- `0 * * * *` → Every hour
- `0 0 * * *` → Every day at midnight
- `*/5 * * * *` → Every 5 minutes

---

## Storage (PVC/PV)

```bash
# List PVs and PVCs
kubectl get pv
kubectl get pvc
kubectl get pvc -n <namespace>

# Describe storage
kubectl describe pv <name>
kubectl describe pvc <name>
kubectl describe storageclass <name>

# List StorageClasses
kubectl get storageclass
```

---

## Namespaces

```bash
# List namespaces
kubectl get ns

# Create namespace
kubectl create namespace production

# Set namespace context
kubectl config set-context --current --namespace=production

# Run in namespace
kubectl get pods -n production
kubectl apply -f deployment.yaml -n staging
kubectl delete ns production
```

---

## Labels & Selectors

```bash
# Add label
kubectl label pod nginx-pod app=web tier=frontend

# Update label
kubectl label pod nginx-pod app=web-new --overwrite

# Remove label
kubectl label pod nginx-pod app-

# List by label
kubectl get pods -l app=web
kubectl get pods -l 'app in (web, api)'
kubectl get pods -l 'app!=web'

# Show labels
kubectl get pods --show-labels
```

---

## Troubleshooting

### Check Pod Status
```bash
# CrashLoopBackOff
kubectl get pods
kubectl describe pod <name>  # Check Events
kubectl logs <name> -p       # Previous logs
kubectl logs <name>          # Current logs

# Pending
kubectl describe pod <name>  # Check Events
kubectl get nodes            # Check resources
kubectl describe node <node> # Check taints

# ImagePullBackOff
kubectl describe pod <name>  # Check image name
```

### Node Issues
```bash
# Check node status
kubectl get nodes
kubectl describe node <node-name>

# Check node resources
kubectl top nodes
```

### Service Issues
```bash
# Check endpoints
kubectl get endpoints <svc-name>

# Check selector matches
kubectl get pods -l <selector>

# Test DNS
kubectl run test --image=busybox --rm -it --restart=Never -- nslookup <svc-name>
```

### Debug Commands
```bash
# Get events
kubectl get events --sort-by='.lastTimestamp'

# Check cluster components
kubectl get pods -n kube-system

# Describe all
kubectl describe all --all-namespaces
```

---

## YAML Templates

### Pod Template
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
  labels:
    app: myapp
spec:
  containers:
  - name: my-container
    image: nginx:1.24
    ports:
    - containerPort: 80
    resources:
      requests:
        cpu: "100m"
        memory: "128Mi"
      limits:
        cpu: "200m"
        memory: "256Mi"
```

### Deployment Template
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-deployment
  labels:
    app: myapp
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: my-container
        image: nginx:1.24
        ports:
        - containerPort: 80
```

### Service Template
```yaml
apiVersion: v1
kind: Service
metadata:
  name: my-service
spec:
  selector:
    app: myapp
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

---

## Pod Lifecycle

### Phases
| Phase | Description |
|-------|-------------|
| **Pending** | Pod accepted, not running yet |
| **Running** | At least one container running |
| **Succeeded** | All containers completed successfully |
| **Failed** | At least one container failed |
| **Unknown** | Status couldn't be obtained |

### Common Issues
| Issue | Action |
|-------|--------|
| `CrashLoopBackOff` | `kubectl logs <pod> -p` |
| `ImagePullBackOff` | Check image name |
| `Pending` | Check node resources, taints |

---

## apiVersion Reference

| Kind | apiVersion |
|------|------------|
| Pod, Service, ConfigMap, Secret | `v1` |
| Deployment, StatefulSet, DaemonSet | `apps/v1` |
| Job | `batch/v1` |
| CronJob | `batch/v1` |
| Ingress | `networking.k8s.io/v1` |
| RBAC | `rbac.authorization.k8s.io/v1` |

---

## Quick One-Liners

```bash
# Delete all pods
kubectl delete pods --all -n <namespace>

# Get pod IP
kubectl get pod <name> -o jsonpath='{.status.podIP}'

# Pause deployment
kubectl rollout pause deployment/<name>

# Resume deployment
kubectl rollout resume deployment/<name>

# Pod restart count
kubectl get pods -o custom-columns=NAME:.metadata.name,RESTARTS:.status.containerStatuses.restartCount

# Top pods by CPU
kubectl top pods -n <namespace> --sort-by=cpu

# Top pods by memory
kubectl top pods -n <namespace> --sort-by=memory
```

---

## kubectl Config

```bash
# List contexts
kubectl config get-contexts

# Current context
kubectl config current-context

# Switch context
kubectl config use-context <context-name>

# Set namespace
kubectl config set-context --current --namespace=production

# Autocomplete
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
```

---

## Resources

- [Official Kubernetes Docs](https://kubernetes.io/docs/)
- [kubectl Reference](https://kubernetes.io/docs/reference/kubectl/)
- [Kubernetes API](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.28/)

---

