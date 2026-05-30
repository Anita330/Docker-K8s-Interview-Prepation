# Docker Commands Cheat Sheet

## Docker Version and Information

### Check Docker Version

```bash
docker version
```

Displays Docker Client and Server versions.

### View Docker System Information

```bash
docker info
```

Displays detailed information about Docker.

### Check Docker Disk Usage

```bash
docker system df
```

Shows space used by images, containers, and volumes.

---

# Docker Images

### List Images

```bash
docker images
```

or

```bash
docker image ls
```

Displays all local Docker images.

### Pull an Image

```bash
docker pull nginx
```

Downloads an image from a registry.

### Search Images

```bash
docker search nginx
```

Searches Docker Hub for images.

### Remove an Image

```bash
docker rmi nginx
```

Deletes an image from the local system.

### Remove Multiple Images

```bash
docker rmi image1 image2 image3
```

Deletes multiple images.

---

# Docker Containers

### Run a Container

```bash
docker run nginx
```

Creates and starts a container.

### Run a Container in Detached Mode

```bash
docker run -d nginx
```

Runs a container in the background.

### Run with Port Mapping

```bash
docker run -d -p 80:80 nginx
```

Maps host port 80 to container port 80.

### Run with Custom Name

```bash
docker run -d --name webserver nginx
```

Assigns a custom name to the container.

### Run with Environment Variables

```bash
docker run -e ENV=prod nginx
```

Sets environment variables.

### Run with Volume Mount

```bash
docker run -v myvolume:/data nginx
```

Mounts a Docker volume.

### List Running Containers

```bash
docker ps
```

Shows running containers.

### List All Containers

```bash
docker ps -a
```

Shows all containers including stopped ones.

### Stop a Container

```bash
docker stop webserver
```

Stops a running container.

### Start a Container

```bash
docker start webserver
```

Starts a stopped container.

### Restart a Container

```bash
docker restart webserver
```

Restarts a container.

### Pause a Container

```bash
docker pause webserver
```

Pauses all processes inside the container.

### Unpause a Container

```bash
docker unpause webserver
```

Resumes a paused container.

### Remove a Container

```bash
docker rm webserver
```

Deletes a stopped container.

### Force Remove a Running Container

```bash
docker rm -f webserver
```

Stops and deletes a running container.

---

# Container Logs

### View Logs

```bash
docker logs webserver
```

Displays container logs.

### Follow Logs

```bash
docker logs -f webserver
```

Streams logs in real time.

### Show Last 100 Log Lines

```bash
docker logs --tail 100 webserver
```

Displays recent log entries.

---

# Execute Commands Inside Containers

### Execute a Command

```bash
docker exec webserver ls
```

Runs a command inside a running container.

### Open Interactive Bash Shell

```bash
docker exec -it webserver bash
```

Accesses the container terminal.

### Open Interactive Shell

```bash
docker exec -it webserver sh
```

Used when bash is not installed.

---

# Container Inspection and Monitoring

### Inspect Container

```bash
docker inspect webserver
```

Displays detailed JSON configuration.

### View Running Processes

```bash
docker top webserver
```

Shows processes running inside the container.

### View Resource Usage

```bash
docker stats
```

Monitors CPU, memory, network, and disk usage.

---

# Docker Build Commands

### Build an Image

```bash
docker build -t myapp:v1 .
```

Builds an image from a Dockerfile.

### Build Without Cache

```bash
docker build --no-cache -t myapp:v1 .
```

Forces Docker to rebuild all layers.

### Build Using Specific Dockerfile

```bash
docker build -f Dockerfile.dev -t myapp:v1 .
```

Uses a custom Dockerfile.

---

# Docker Registry Commands

### Login to Registry

```bash
docker login
```

Authenticates to Docker Hub or another registry.

### Logout

```bash
docker logout
```

Removes stored credentials.

### Push Image

```bash
docker push myrepo/myapp:v1
```

Uploads an image to a registry.

### Pull Image

```bash
docker pull myrepo/myapp:v1
```

Downloads an image from a registry.

### Tag an Image

```bash
docker tag myapp:v1 myrepo/myapp:v1
```

Creates a new tag for an image.

---

# Docker Volumes

### Create Volume

```bash
docker volume create myvolume
```

Creates a persistent storage volume.

### List Volumes

```bash
docker volume ls
```

Displays available volumes.

### Inspect Volume

```bash
docker volume inspect myvolume
```

Displays volume details.

### Remove Volume

```bash
docker volume rm myvolume
```

Deletes a volume.

### Remove Unused Volumes

```bash
docker volume prune
```

Deletes all unused volumes.

---

# Docker Networks

### List Networks

```bash
docker network ls
```

Displays Docker networks.

### Create Network

```bash
docker network create mynetwork
```

Creates a custom network.

### Inspect Network

```bash
docker network inspect mynetwork
```

Displays network details.

### Connect Container to Network

```bash
docker network connect mynetwork webserver
```

Attaches a container to a network.

### Disconnect Container from Network

```bash
docker network disconnect mynetwork webserver
```

Removes a container from a network.

### Remove Network

```bash
docker network rm mynetwork
```

Deletes a network.

---

# Docker Save and Load

### Save Image to File

```bash
docker save -o nginx.tar nginx
```

Exports an image.

### Load Image from File

```bash
docker load -i nginx.tar
```

Imports an image.

---

# Docker Cleanup Commands

### Remove Stopped Containers

```bash
docker container prune
```

Deletes stopped containers.

### Remove Dangling Images

```bash
docker image prune
```

Deletes unused image layers.

### Remove Unused Networks

```bash
docker network prune
```

Deletes unused networks.

### Remove Unused Volumes

```bash
docker volume prune
```

Deletes unused volumes.

### Full Cleanup

```bash
docker system prune -a
```

Removes all unused containers, images, networks, and cache.

---

# Useful Troubleshooting Commands

### Check Docker Service Status

```bash
systemctl status docker
```

Checks Docker daemon status.

### View Docker Service Logs

```bash
journalctl -u docker -f
```

Streams Docker daemon logs.

### Check Docker Socket

```bash
ls -l /var/run/docker.sock
```

Displays Docker Unix socket permissions.

### Test Docker API

```bash
curl --unix-socket /var/run/docker.sock http://localhost/version
```

Queries Docker API directly.

---

# Most Frequently Used Commands

```bash
docker images
docker ps -a
docker pull nginx
docker run -d -p 80:80 nginx
docker logs -f nginx
docker exec -it nginx bash
docker stop nginx
docker rm nginx
docker build -t myapp:v1 .
docker push myapp:v1
docker system prune -a
```

These commands are commonly used in Docker administration, DevOps workflows, CI/CD pipelines, Kubernetes troubleshooting, and Amazon EKS environments.
