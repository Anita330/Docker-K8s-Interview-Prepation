1. Docker CLI sends request to dockerd via Unix socket.

2. dockerd checks local image cache.

3. If image is absent, it pulls image layers from Docker Hub.

4. containerd downloads and manages image layers.

5. overlay2 mounts read-only image layers and creates a writable container layer.

6. dockerd asks containerd to create the container.

7. containerd invokes runc.

8. runc creates:
   - PID namespace
   - Network namespace
   - Mount namespace
   - UTS namespace
   - IPC namespace
   - User namespace (if enabled)

9. runc creates cgroups for CPU and memory limits.

10. Docker networking creates a veth pair and connects it to docker0 bridge.

11. Container receives an IP address.

12. nginx process starts as PID 1 inside the container.

13. Logs are attached and container enters Running state.

What is the difference between:

docker exec -it <container> bash

and

docker attach <container>
Explain:
What happens internally?
Which one creates a new process?
Which one attaches to the existing PID 1 process?
Which is safer in production and why?

Answer as if you're in a real interview.
docker exec creates a new process inside an already running container while sharing the existing namespaces and cgroups. docker attach connects my terminal to the existing PID 1 process and does not create a new process. In production, I prefer docker exec because it is safer for troubleshooting and avoids accidentally impacting the main application process.

# how two container ping each other when they are in same network
When app1 pings app2, Docker DNS first resolves the container name to the container IP address. The packet leaves app1 through its eth0 interface, traverses the veth pair, reaches the docker0 bridge, and the bridge forwards the packet to app2's veth interface based on MAC address learning. Since both containers are on the same bridge network, communication happens entirely within the host through the Linux bridge. Network namespaces provide isolation, while the bridge provides connectivity. NAT is not required because traffic never leaves the bridge network.

# Explain the complete architecture of Docker Swarm:

Manager Node
Worker Node
Service
Task
Overlay Network
Routing Mesh
RAFT Consensus
Quorum

Also answer:

Why do we recommend 3 or 5 manager nodes instead of 2 manager nodes?

Docker Swarm consists of Manager and Worker nodes. Managers maintain cluster state, perform scheduling, and participate in leader election using the RAFT consensus algorithm. Workers execute tasks assigned by managers. A Service defines the desired state of an application, while Tasks are the individual container instances created by the service. Overlay networks provide communication across multiple nodes using VXLAN tunneling. Routing Mesh provides built-in load balancing by allowing traffic to enter through any node and reach the correct service task. We typically deploy 3 or 5 managers because RAFT requires a quorum. With 3 managers, the cluster can tolerate one manager failure and still maintain quorum.

# A production Docker host reports:

No space left on device

The server has:

100 GB Disk
95 GB Used

During a production incident, I would first verify disk usage with df -h and identify which filesystem is full. Then I would check Docker storage using docker system df -v and inspect /var/lib/docker, especially overlay2, containers, and volumes. I would investigate large container log files, dangling images, stopped containers, and unused volumes. After confirming dependencies, I would safely remove unused resources using Docker prune commands. If overlay2 growth is caused by application writes, I would investigate the specific container and move persistent data to managed volumes.
