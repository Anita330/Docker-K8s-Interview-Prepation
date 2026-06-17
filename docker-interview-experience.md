# Docker Interview Questions and Answers (5+ Years DevOps Engineer)

## 1. What happens when you run `docker run nginx`?

### Answer

When `docker run nginx` is executed:

1. Docker CLI sends the request to `dockerd`.
2. Docker daemon checks whether the image exists locally.
3. If not found, Docker pulls the image from Docker Hub or a configured registry.
4. Docker creates a writable container layer on top of image layers.
5. `dockerd` communicates with `containerd`.
6. `containerd` invokes `runc`.
7. `runc` creates namespaces and cgroups.
8. Container networking is configured.
9. ENTRYPOINT/CMD process starts.
10. Container enters Running state.

Architecture:

```text
Docker CLI
    |
dockerd
    |
containerd
    |
runc
    |
Linux Kernel
    |
Container
```

---

# 2. What is the difference between Docker Image and Container?

### Image

* Read-only template
* Contains application code and dependencies
* Used to create containers

### Container

* Running instance of an image
* Has a writable layer
* Executes application processes

Example:

```bash
docker pull nginx
docker run nginx
```

---

# 3. What are Docker Layers?

Docker images are built from multiple read-only layers.

Example:

```dockerfile
FROM ubuntu:22.04
RUN apt-get update
RUN apt-get install -y nginx
COPY app.py /app/
```

Layers:

```text
Layer 1 -> Ubuntu Base
Layer 2 -> apt-get update
Layer 3 -> nginx installation
Layer 4 -> COPY app.py
```

Benefits:

* Faster builds
* Layer reuse
* Reduced storage
* Faster image pulls

---

# 4. What is Union Filesystem?

UnionFS combines multiple image layers into a single filesystem view.

Container view:

```text
Writable Layer
Layer 4
Layer 3
Layer 2
Layer 1
```

Docker commonly uses OverlayFS (overlay2).

---

# 5. What is Copy-On-Write?

When a file from a read-only layer is modified:

1. Docker copies the file into the writable layer.
2. Changes are made in writable layer.
3. Original image remains unchanged.

---

# 6. What is the difference between ENTRYPOINT and CMD?

### ENTRYPOINT

Defines the executable.

```dockerfile
ENTRYPOINT ["nginx"]
```

### CMD

Defines default arguments.

```dockerfile
CMD ["-g","daemon off;"]
```

Execution:

```text
nginx -g "daemon off;"
```

---

# 7. What is containerd?

containerd is a high-level container runtime.

Responsibilities:

* Pull images
* Manage containers
* Lifecycle management
* Snapshot management

Architecture:

```text
dockerd
   |
containerd
```

---

# 8. What is runc?

runc is a low-level OCI runtime.

Responsibilities:

* Create containers
* Create namespaces
* Apply cgroups
* Start container process

Architecture:

```text
containerd
   |
runc
```

---

# 9. Difference Between containerd and runc

| containerd           | runc               |
| -------------------- | ------------------ |
| High-level runtime   | Low-level runtime  |
| Lifecycle management | Container creation |
| Pull images          | Create namespaces  |
| Manage containers    | Start process      |

---

# 10. What are Linux Namespaces?

Namespaces provide isolation.

Types:

| Namespace | Purpose              |
| --------- | -------------------- |
| PID       | Process isolation    |
| NET       | Network isolation    |
| MNT       | Filesystem isolation |
| IPC       | IPC isolation        |
| UTS       | Hostname isolation   |
| USER      | User isolation       |

Example:

Two containers can both have PID 1.

---

# 11. What are Cgroups?

Cgroups provide resource control.

Example:

```bash
docker run \
--memory=512m \
--cpus=1 nginx
```

Controls:

* CPU
* Memory
* I/O
* Network resources

---

# 12. Difference Between Namespace and Cgroups

### Namespace

Provides isolation.

Example:

```text
Container A cannot see Container B processes
```

### Cgroup

Provides resource limits.

Example:

```text
Container A = 512 MB RAM
Container B = 2 GB RAM
```

---

# 13. What is Docker Volume?

Docker-managed persistent storage.

Example:

```bash
docker volume create mysql-data

docker run \
-v mysql-data:/var/lib/mysql \
mysql
```

Benefits:

* Persistent data
* Docker managed
* Production friendly

---

# 14. What is Bind Mount?

Maps host directory into container.

Example:

```bash
docker run \
-v /data/mysql:/var/lib/mysql \
mysql
```

Use Cases:

* Development
* Configuration files
* Log collection

---

# 15. Volume vs Bind Mount

| Volume               | Bind Mount            |
| -------------------- | --------------------- |
| Managed by Docker    | Managed by OS         |
| Production preferred | Development preferred |
| Portable             | Host dependent        |
| Better isolation     | Direct host access    |

---

# 16. What is Docker Bridge Network?

Default Docker network.

Features:

* Creates docker0 interface
* Provides private IPs
* Enables container communication

Check:

```bash
docker network inspect bridge
```

---

# 17. What does `-p 8080:80` do?

```bash
docker run -p 8080:80 nginx
```

Maps:

```text
Host Port 8080
       |
Container Port 80
```

Traffic flow:

```text
Browser
   |
Host:8080
   |
iptables NAT
   |
docker0 bridge
   |
Container:80
```

---

# 18. What is Docker Swarm?

Docker's native orchestration platform.

Features:

* Clustering
* Scaling
* Service Discovery
* Load Balancing
* High Availability

---

# 19. Manager vs Worker Node

### Manager

* Scheduling
* Cluster state
* Service management

### Worker

* Runs containers
* Executes assigned tasks

---

# 20. What is Overlay Network?

Allows containers on different hosts to communicate securely.

Used by:

```text
Docker Swarm
```

---

# 21. What is Raft Consensus?

Used by Docker Swarm managers.

Purpose:

* Maintain cluster state
* Leader election
* High availability

---

# 22. What happens when PID 1 exits?

PID 1 is the main process of the container.

If PID 1 exits:

```text
Container stops
```

Example:

```bash
docker run nginx
```

If nginx process exits:

```text
Container exits
```

---

# 23. What does `docker exec -it nginx bash` do?

It creates a new process inside an existing container.

Example:

```bash
docker exec -it nginx bash
```

Docker does not create a new container.

---

# 24. Docker Troubleshooting Commands

### Logs

```bash
docker logs container
```

Shows application logs.

---

### Inspect

```bash
docker inspect container
```

Shows:

* Network
* Mounts
* Exit code
* Environment variables

---

### Stats

```bash
docker stats
```

Shows:

* CPU
* Memory
* Network I/O

---

### Events

```bash
docker events
```

Shows:

* Start
* Stop
* Restart
* OOM events

---

# 25. Common Production Troubleshooting Flow

### Step 1

Check logs

```bash
docker logs container
```

### Step 2

Inspect container

```bash
docker inspect container
```

### Step 3

Check resources

```bash
docker stats
```

### Step 4

Check networking

```bash
docker network inspect bridge
```

### Step 5

Check storage

```bash
docker volume ls
```

---

# Senior Interview Summary

Docker uses:

* Namespaces for isolation
* Cgroups for resource control
* OverlayFS for layered filesystem
* containerd for lifecycle management
* runc for container creation
* Volumes for persistence
* Bridge/Overlay networking for communication

A container is simply:

```text
Image
 + Writable Layer
 + Namespaces
 + Cgroups
 = Running Container
```
