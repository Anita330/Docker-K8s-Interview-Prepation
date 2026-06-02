# Docker Interview Questions and Answers

## Core Concepts

### 1. What is Docker?
Docker is a containerization platform that packages an application and its dependencies into a lightweight, portable container so it can run consistently across environments.

### 2. How is a container different from a virtual machine?
A container shares the host OS kernel and isolates processes at the application level, while a virtual machine includes a full guest OS. Containers are typically lighter and start faster.

### 3. What is a Docker image?
A Docker image is a read-only template used to create containers. It contains the application code, runtime, libraries, and configuration.

### 4. What is a Docker container?
A container is a running instance of a Docker image. It is isolated, lightweight, and ephemeral by default.

### 5. What is a Dockerfile?
A Dockerfile is a text file that contains instructions to build a Docker image, such as `FROM`, `COPY`, `RUN`, `CMD`, and `ENTRYPOINT`.

### 6. What is the purpose of Docker Hub?
Docker Hub is a container image registry used to store and share Docker images.

### 7. What is `.dockerignore` used for?
`.dockerignore` excludes files and folders from the Docker build context, which reduces image size and improves build performance.

## Image Building

### 8. What is the difference between `COPY` and `ADD`?
`COPY` copies files from the build context into the image. `ADD` does the same but also supports remote URLs and tar archive extraction. In most cases, `COPY` is preferred.

### 9. What is the difference between `CMD` and `ENTRYPOINT`?
`CMD` provides default arguments or a default command and can be overridden easily. `ENTRYPOINT` defines the main executable for the container and is harder to override.

### 10. How do you reduce Docker image size?
Use minimal base images, remove unnecessary packages, combine `RUN` commands, use multi-stage builds, and copy only required files into the final image.

### 11. What are multi-stage builds?
Multi-stage builds let you use one stage to build the application and a later stage to create a smaller runtime image containing only the final artifacts.

### 12. How does layer caching work in Docker?
Each Dockerfile instruction creates a layer. Docker reuses cached layers when possible, which speeds up builds if instructions and files have not changed.

### 13. Why is order important in a Dockerfile?
Placing stable layers first improves cache reuse. For example, copying dependency files before application source can make rebuilds faster.

## Container Lifecycle and Commands

### 14. What is the difference between `docker run` and `docker start`?
`docker run` creates a new container from an image and starts it. `docker start` starts an existing stopped container.

### 15. How do you list containers?
Use `docker ps` to list running containers and `docker ps -a` to list all containers.

### 16. How do you stop and remove a container?
Use `docker stop <container>` to stop it and `docker rm <container>` to remove it.

### 17. How do you inspect a container?
Use `docker inspect <container>` to view detailed configuration and runtime information.

### 18. How do you see container logs?
Use `docker logs <container>` to view the logs of a container.

### 19. How do you execute a command inside a running container?
Use `docker exec -it <container> <command>`.

### 20. What is the lifecycle of a Docker container?
A container typically goes through created, running, paused, stopped, and removed states.

## Storage and Persistence

### 21. What are Docker volumes?
Volumes are Docker-managed storage used to persist data outside the container lifecycle.

### 22. What is the difference between bind mounts and volumes?
Bind mounts map a host directory into the container. Volumes are managed by Docker and are generally better for portability and production use.

### 23. How do you persist data in Docker?
Use volumes or bind mounts so data survives container recreation.

### 24. How can data be shared between containers?
Containers can share a volume or use another external storage mechanism.

## Networking

### 25. How does Docker networking work?
Docker networking allows containers to communicate with each other, the host, and external systems using isolated network namespaces and drivers.

### 26. What are the common Docker network types?
The common network types are bridge, host, none, and overlay.

### 27. What is a bridge network?
A bridge network is the default network type on a single host and allows containers to communicate through a virtual bridge.

### 28. What is an overlay network?
An overlay network is used for communication between containers running on different Docker hosts.

### 29. How do you expose a port from a container?
Use `-p hostPort:containerPort` with `docker run`.

## Docker Compose

### 30. What is Docker Compose?
Docker Compose is a tool for defining and running multi-container applications with a YAML file.

### 31. Why use Docker Compose?
It simplifies local development, testing, and service orchestration for multi-container apps.

### 32. How do you scale a service in Docker Compose?
You can run multiple replicas of a service, though production scaling is usually handled by an orchestrator like Kubernetes.

### 33. How do you define services in `docker-compose.yml`?
You define each service with its image or build context, ports, volumes, environment variables, and dependencies.

## Security

### 34. How do you handle secrets in Docker?
Do not bake secrets into images. Use environment variables, Docker secrets, mounted files, or an external secret manager.

### 35. What are best practices for securing Docker containers?
Run as a non-root user, use minimal base images, avoid privileged containers, scan images, and restrict capabilities.

### 36. How do you deal with image vulnerabilities?
Scan images in CI/CD, patch base images regularly, rebuild often, and block vulnerable images from production.

### 37. Why should containers not run as root?
Running as root increases the blast radius if a container is compromised.

## Advanced Topics

### 38. What are cgroups and namespaces?
Namespaces isolate container resources like processes and networking. Cgroups limit and account for resource usage such as CPU and memory.

### 39. How does Docker ensure isolation?
Docker uses Linux kernel features such as namespaces, cgroups, and layered filesystems to isolate containers.

### 40. What is the difference between Docker Swarm and Kubernetes?
Docker Swarm is Docker’s native orchestration system and is simpler. Kubernetes is a more powerful and widely adopted orchestration platform.

### 41. How do you monitor Docker containers in production?
Use metrics, logs, and tracing tools such as Prometheus, Grafana, ELK, or cloud observability stacks.

### 42. What are the performance implications of Docker?
Containers are lightweight compared to VMs, but performance can be affected by logging, storage drivers, networking, and resource limits.

### 43. How do you implement CI/CD with Docker?
Build the image in CI, run tests, scan for vulnerabilities, tag the image, push it to a registry, and deploy it in CD.

### 44. What is a Docker context?
A Docker context lets you switch between different Docker environments such as local and remote engines.

### 45. What is the difference between `--link`, user-defined bridge networks, and overlay networks?
`--link` is legacy. User-defined bridge networks are better for single-host communication, and overlay networks are used for multi-host communication.

### 46. How do you troubleshoot a container that does not start?
Check `docker logs`, inspect the container, verify the entrypoint and command, check environment variables, and confirm port mappings.

### 47. What is the difference between an image and a container?
An image is a static template. A container is a running instance of that image.

### 48. How do you update an application running in Docker?
Build a new image, tag it, deploy a new container from the updated image, and replace the old one.

### 49. What is the best practice for tagging images?
Use versioned tags such as `1.0.0` or commit-based tags instead of relying only on `latest`.

### 50. Why is Docker useful in DevOps?
Docker makes applications portable, repeatable, and easier to build, test, and deploy across environments.