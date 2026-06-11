# AWS & DevOps Interview Questions and Answers (5+ Years Experience)

## Q1. A Linux server suddenly becomes slow. How would you troubleshoot it?

### Answer

### Check CPU

```bash
top
htop
mpstat -P ALL 1
sar -u 1 5
```

Verify:

* CPU utilization
* Load average
* CPU steal time
* Top CPU-consuming processes

### Check Memory

```bash
free -h
vmstat 1
sar -r 1 5
```

Verify:

* Available memory
* Swap usage
* OOM events

```bash
dmesg | grep -i oom
```

### Check Disk I/O

```bash
iostat -xz 1
iotop
df -h
```

Verify:

* Disk utilization
* Await time
* Filesystem usage

### Check Network

```bash
ss -tulpn
sar -n DEV 1 5
iftop
```

### Check Processes

```bash
ps aux --sort=-%cpu | head
ps aux --sort=-%mem | head
```

### Check Logs

```bash
journalctl -xe
dmesg
```

---

## Q2. CPU Usage = 20%, Load Average = 25 on a 4-Core Server. What does it indicate?

### Answer

A load average of 25 on a 4-core server is abnormal.

Load average includes:

* Running processes
* Processes waiting for CPU
* Processes stuck in uninterruptible I/O wait

Possible causes:

* Disk I/O bottleneck
* NFS delays
* Storage latency

Commands:

```bash
iostat -xz 1
vmstat 1
top
```

Look for:

* High %wa
* High await
* Processes in D state

---

## Q3. Difference Between Process, Thread, Daemon, and Service

### Process

A running instance of a program.

Example:

```bash
firefox
```

### Thread

A lightweight execution unit inside a process.

Threads share memory.

Example:

```bash
ps -eLf
```

### Daemon

A background process that continuously provides a service.

Examples:

* sshd
* crond
* kubelet

### Service

A system-managed application.

Example:

```bash
systemctl status nginx
```

---

## Q4. What happens when executing:

```bash
curl https://google.com
```

### DNS Resolution

Checks:

1. Local Cache
2. /etc/hosts
3. DNS Resolver
4. Root Server
5. TLD Server
6. Authoritative DNS

Returns IP Address.

### TCP 3-Way Handshake

```text
Client -> SYN
Server -> SYN ACK
Client -> ACK
```

### TLS Handshake

* Exchange certificates
* Verify certificate
* Negotiate encryption keys

### HTTP Request

```http
GET /
Host: google.com
```

### HTTP Response

```http
HTTP/1.1 200 OK
```

Returns content to client.

---

## Q5. How do you troubleshoot a slow curl response?

### Command

```bash
curl -w "\nDNS: %{time_namelookup}\nTCP: %{time_connect}\nTLS: %{time_appconnect}\nTTFB: %{time_starttransfer}\nTotal: %{time_total}\n" -o /dev/null -s https://google.com
```

### Metrics

| Metric             | Meaning             |
| ------------------ | ------------------- |
| time_namelookup    | DNS Time            |
| time_connect       | TCP Connection Time |
| time_appconnect    | TLS Handshake Time  |
| time_starttransfer | Time To First Byte  |
| time_total         | Total Request Time  |

---

# AWS

## Q6. EC2 CPU reaches 90%. How does Auto Scaling work?

### Flow

```text
CloudWatch
    ↓
Alarm Triggered
    ↓
Auto Scaling Policy
    ↓
ASG Updates Desired Capacity
    ↓
Launch New EC2
    ↓
Register in Target Group
    ↓
ALB Health Checks
    ↓
Traffic Distribution
```

### Example Policy

```text
CPU > 80%
For 5 minutes
Add 2 instances
```

---

## Q7. Difference Between Security Group and NACL

| Feature        | Security Group | NACL                  |
| -------------- | -------------- | --------------------- |
| Type           | Stateful       | Stateless             |
| Level          | Instance/ENI   | Subnet                |
| Rules          | Allow Only     | Allow + Deny          |
| Return Traffic | Automatic      | Must Allow Explicitly |

### Security Group

Acts as an instance-level firewall.

### NACL

Acts as a subnet-level firewall.

---

## Q8. EKS Pods Need S3 Access Without NAT Gateway

### Solution

Use:

```text
S3 Gateway VPC Endpoint
```

### Architecture

```text
Pod
 ↓
Private Subnet
 ↓
S3 Gateway Endpoint
 ↓
S3 Bucket
```

### Authentication

Use:

```text
IRSA
```

### IRSA Flow

```text
Pod
 ↓
Service Account
 ↓
IAM Role
 ↓
S3 Access
```

Benefits:

* No static credentials
* Better security
* Least privilege

---

# Kubernetes

## Q9. What happens when running:

```bash
kubectl apply -f deployment.yaml
```

### Flow

kubectl apply -f deployment.yaml
        ↓
API Server receives request
        ↓
Authentication + Authorization + Validation
        ↓
Deployment object stored in etcd
        ↓
Deployment Controller detects new Deployment
        ↓
Creates ReplicaSet
        ↓
ReplicaSet creates Pod objects
        ↓
Pods remain Pending
        ↓
Scheduler watches unscheduled Pods
        ↓
Scheduler selects best node based on resources, taints, tolerations, affinity, etc.
        ↓
Scheduler updates Pod object
        ↓
Kubelet on selected node notices Pod assignment
        ↓
Kubelet asks containerd to pull image
        ↓
Container starts
        ↓
Pod becomes Running

### Scheduler Checks

* Resources
* Taints
* Tolerations
* Affinity
* Anti-Affinity
* Node Selector

### Container Runtime

Examples:

* containerd
* CRI-O

---

## Q10. Pod is stuck in Pending state. How do you troubleshoot?

### Step 1

Check Pod Status

```bash
kubectl get pod
```

### Step 2

Describe Pod

```bash
kubectl describe pod <pod-name>
```

Look for Events section.

### Step 3

Check Node Status

```bash
kubectl get nodes
kubectl describe node <node-name>
```

### Step 4

Check Resources

```bash
kubectl top nodes
kubectl top pods
```

### Step 5

Check Scheduler Events

Common causes:

* Insufficient CPU
* Insufficient Memory
* Taints
* Node Selector mismatch
* Affinity mismatch

### Step 6

Check PVC

```bash
kubectl get pvc
kubectl describe pvc
```

### Step 7

Check Taints

```bash
kubectl describe nodes
```

### Step 8

Check Scheduler Logs

```bash
kubectl logs -n kube-system <scheduler-pod>
```

---

# Common Commands

## CPU

```bash
top
htop
mpstat
sar -u
```

## Memory

```bash
free -h
vmstat
sar -r
```

## Disk

```bash
iostat
iotop
df -h
```

## Network

```bash
ss -tulpn
iftop
sar -n DEV
```

## Kubernetes

```bash
kubectl get pods
kubectl describe pod
kubectl get nodes
kubectl top nodes
kubectl top pods
kubectl logs
```

## AWS

```bash
aws ec2 describe-instances
aws eks describe-cluster
aws autoscaling describe-auto-scaling-groups
aws cloudwatch describe-alarms
```
