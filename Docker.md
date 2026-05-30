# Docker Architecture and How It Works

## Overview

Docker is a containerization platform that allows developers to package applications and their dependencies into lightweight, portable containers. Docker follows a client-server architecture.

---

## Docker Architecture

### 1. Docker Client

The Docker Client is the interface through which users interact with Docker.

Common commands:

```bash
docker build
docker run
docker pull
docker push
docker ps
```

The client sends commands to the Docker Daemon.

---

### 2. Docker Daemon (dockerd)

The Docker Daemon runs as a background service on the host machine.

Responsibilities:
- Building images
- Running containers
- Managing networks
- Managing volumes
- Pulling images from registries
- Pushing images to registries

---

### 3. Docker Registry

A Docker Registry stores Docker images.

Examples:
- Docker Hub
- Amazon ECR
- Harbor
- JFrog Artifactory

Common commands:

```bash
docker pull nginx
docker push myrepo/myapp:v1
```

---

### 4. Docker Images

A Docker Image is a read-only template used to create containers.

An image contains:
- Application code
- Runtime environment
- Libraries
- Dependencies
- Configuration files

Example:

```bash
docker pull nginx
```

---

### 5. Docker Containers

A container is a running instance of a Docker image.

Characteristics:
- Lightweight
- Portable
- Isolated
- Fast startup

Example:

```bash
docker run -d nginx
```

---

### 6. Docker Volumes

Volumes provide persistent storage for containers.

Benefits:
- Data survives container deletion
- Data can be shared among containers

Example:

```bash
docker volume create mydata
```

---

### 7. Docker Networks

Docker Networks enable communication between containers.

Network Types:

| Network Type | Description |
|-------------|-------------|
| Bridge | Default network for containers |
| Host | Shares host network |
| None | No networking |
| Overlay | Multi-host networking (Docker Swarm) |

---

# Docker Architecture Diagram

```text
+----------------+
| Docker Client  |
+----------------+
        |
        v
+----------------+
| Docker Daemon  |
|   (dockerd)    |
+----------------+
    |      |
    |      |
    v      v
Images   Containers
    |
    v
Docker Registry
```

---

# How Docker Works

## Step 1: Create a Dockerfile

Example:

```dockerfile
FROM nginx
COPY index.html /usr/share/nginx/html
```

---

## Step 2: Build an Image

```bash
docker build -t myapp:v1 .
```

Flow:

```text
Dockerfile
     |
     v
Docker Image
```

---

## Step 3: Push Image to Registry

```bash
docker push myapp:v1
```

Flow:

```text
Local Image
     |
     v
Docker Registry
```

---

## Step 4: Pull Image from Registry

```bash
docker pull myapp:v1
```

Flow:

```text
Docker Registry
     |
     v
Local Host
```

---

## Step 5: Run Container

```bash
docker run -d -p 80:80 myapp:v1
```

Flow:

```text
Docker Image
     |
     v
Docker Container
```

---

# End-to-End Workflow

```text
Developer
    |
    | docker build
    v
Docker Image
    |
    | docker push
    v
Docker Registry
    |
    | docker pull
    v
Docker Host
    |
    | docker run
    v
Docker Container
```

---

# What Happens Internally During docker run?

Command:

```bash
docker run nginx
```

Docker performs the following actions:

1. Docker Client sends request to Docker Daemon.
2. Docker Daemon checks local image cache.
3. If image is not available locally, Docker pulls it from a registry.
4. Docker creates a writable container layer.
5. Docker configures networking.
6. Docker mounts required volumes.
7. Docker allocates CPU and memory resources.
8. Docker starts the container process.
9. Application becomes available.

Internal Flow:

```text
docker run nginx
        |
        v
Docker Client
        |
        v
Docker Daemon
        |
        +--> Pull Image
        +--> Create Container
        +--> Configure Network
        +--> Mount Volumes
        +--> Allocate Resources
        +--> Start Process
        |
        v
Running Container
```

---

# Docker vs Virtual Machine

| Feature | Docker Container | Virtual Machine |
|----------|-----------------|----------------|
| Kernel | Shared Host Kernel | Own Kernel |
| Startup Time | Seconds | Minutes |
| Size | MBs | GBs |
| Performance | Near Native | More Overhead |
| Resource Usage | Low | High |
| Portability | High | Medium |

---

# Docker in Kubernetes (EKS)

Example Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  containers:
  - name: nginx
    image: nginx:latest
```

When Kubernetes creates a Pod:

1. Scheduler selects a node.
2. Container runtime pulls the image.
3. Container is created.
4. Network is attached.
5. Application process starts.
6. Pod becomes Ready.

> Note: Modern Amazon EKS uses **containerd** as the container runtime instead of Docker Engine, but Docker images are still used.

---

# Key Interview Questions

### What is Docker?

Docker is a containerization platform used to package applications and their dependencies into portable containers.

### What is the difference between Image and Container?

- Image = Blueprint or Template
- Container = Running instance of an Image

### What is Docker Daemon?

Docker Daemon (dockerd) is the background service responsible for managing images, containers, networks, and volumes.

### What is Docker Registry?

A centralized repository used to store and distribute Docker images.

### What is the purpose of Docker Volumes?

Volumes provide persistent storage independent of the container lifecycle.

### What happens when you run `docker run nginx`?

Docker checks for the image, pulls it if necessary, creates a container, configures networking, and starts the Nginx process.

---

# Summary

Docker Architecture consists of:

- Docker Client
- Docker Daemon
- Docker Registry
- Docker Images
- Docker Containers
- Docker Volumes
- Docker Networks

The workflow is:

```text
Dockerfile
   ↓
Image
   ↓
Registry
   ↓
Container
   ↓
Running Application
```

Docker provides lightweight, portable, and efficient application deployment compared to traditional virtual machines.