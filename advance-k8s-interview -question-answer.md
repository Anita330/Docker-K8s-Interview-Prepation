1. How does Kubernetes control plane ensure consistency across etcd, API
Server, and controllers?  
Ans:- The API Server acts as the central hub and the only component that talks directly to etcd. Consistency
is maintained through the **List and Watch** mechanism. Controllers (like the ReplicationManager)
watch the API Server for changes to the desired state. When a change occurs (e.g., a user updates a
Deployment), the API Server persists this to etcd (which uses the **RAFT consensus algorithm** to
ensure strong consistency). The controller is notified via the watch stream, compares the desired state
with the current state, and reconciles them. This level-triggered logic ensures that even if a signal is
missed, the next reconciliation loop corrects the state.

2. Explain Kubernetes scheduler workflow step-by-step.  
The scheduling process moves a Pod from 'Pending' to 'Running' on a node:
1. **Informer:** The scheduler watches for Pods with no `nodeName` set.
2. **Scheduling Queue:** These pods are placed in an internal queue.
3. **Filtering (Predicates):** The scheduler filters out nodes that don't meet hard requirements (e.g.,
insufficient CPU/RAM, taints, node selector mismatches).
4. **Scoring (Priorities):** Remaining nodes are ranked based on 'soft' rules (e.g., spreading pods
across zones, affinity preferences, image locality).
5. **Binding:** The scheduler selects the node with the highest score and sends a `Bind` object to the
API server, setting the Pod's `nodeName`. The Kubelet on that node then sees the assignment and
starts the pod.

3. How does kube-proxy work internally in iptables vs IPVS mode?  
Ans:- **iptables mode:** Kube-proxy watches for Service and Endpoint updates and creates individual
iptables rules for each service backend. Traffic is load-balanced using a random probability model.
*Drawback:* Rule updates are O(N) (linear). With thousands of services, updating rules becomes CPU
intensive and slow.
**IPVS mode:** Uses the Linux kernel's IP Virtual Server (Netfilter). It uses a hash table structure,
making rule lookups and updates O(1) (constant time). It supports more sophisticated load balancing
algorithms (e.g., Least Connection, Round Robin, Weighted) and performs significantly better at scale.


4. How does Kubernetes implement self-healing at pod and node level?
Ans:-
**Pod Level:** Self-healing is handled by the **Kubelet** (via Liveness/Readiness probes) and
**Controllers** (ReplicaSet). If a container crashes, the Kubelet restarts it based on the `restartPolicy`.
If a probe fails, the Kubelet kills and restarts the container.
**Node Level:** The **Node Controller** in the Control Plane monitors node heartbeats. If a node stops
sending heartbeats (status `Unknown`), the controller waits for a `pod-eviction-timeout` (default 5m). If
the node doesn't return, the controller marks the pods on that node for deletion, prompting the
ReplicaSet/Deployment to reschedule new replicas on healthy nodes.

5. What happens internally when a pod is deleted?
Ans:- 
1. User sends delete command.
2. API Server marks the pod as `Terminating` and sets a `deletionTimestamp`.
3. **Kubelet** starts the graceful shutdown: Executes `preStop` hook (if defined) and sends
**SIGTERM** to the container process (PID 1).
4. Simultaneously, the **Endpoint Controller** removes the Pod's IP from the Service's Endpoints list to
stop new traffic.
5. After the `terminationGracePeriodSeconds` (default 30s) expires, Kubelet sends **SIGKILL** to
forcefully stop the process.
6. The Pod is removed from etcd.


6. How does HPA calculate metrics and make scaling decisions?
Ans:- The Horizontal Pod Autoscaler controller runs a control loop (default 15s). It queries the Metrics Server
(or custom metrics API) for resource usage. The scaling formula is:
TargetReplicas = ceil[ CurrentReplicas * ( CurrentMetricValue / DesiredMetricValue ) ]
For example, if you have 2 pods with 50% CPU usage and the target is 25%, the calculation is `ceil[ 2 *
(50 / 25) ] = 4` pods.


7. Difference between HPA, VPA, and Cluster Autoscaler — when to use each?
Ans:-
**HPA (Horizontal Pod Autoscaler):** Scales the *number* of replicas. Use for stateless applications
with fluctuating traffic patterns (e.g., web servers).
**VPA (Vertical Pod Autoscaler):** Adjusts the *resource requests/limits* (CPU/RAM) of existing pods.
Use for stateful apps or monoliths where adding replicas is difficult, or to right-size workloads. *Note:
VPA usually restarts pods to apply changes.*
**Cluster Autoscaler (CA):** Scales the *number of nodes* in the cluster. It triggers when pods are in a
'Pending' state due to insufficient cluster resources. Use in cloud environments to optimize costs.

8. How does Kubernetes networking work across nodes (CNI flow)?
Ans:-
Kubernetes requires a flat network where every pod can talk to every other pod without NAT. This is
implemented by a **CNI (Container Network Interface)** plugin (e.g., Calico, Flannel).
1. When a pod starts, Kubelet calls the CNI plugin.
2. The plugin creates a virtual ethernet (veth) pair. One end is inside the pod's network namespace, the
other on the host.
3. The plugin assigns an IP via an IPAM (IP Address Management) module.
4. For cross-node communication, the plugin uses either an **Overlay Network** (encapsulating
packets in VXLAN/IP-in-IP) or **Direct Routing** (BGP) to route packets between nodes.

9. Explain Pod networking vs Service networking.
Ans:-**Pod Networking:** Every pod gets a unique, ephemeral IP address. Pods communicate directly via
these IPs. However, because pods are volatile (they die and change IPs), this is unreliable for
long-term communication.
**Service Networking:** A Service provides a stable Virtual IP (ClusterIP) and DNS name. It acts as an
abstraction over a set of Pods. The ClusterIP does not exist on any network interface; it is a virtual rule
defined in **iptables/IPVS** on every node. When traffic hits the ClusterIP, the node's kernel NATs the
request to one of the backend Pod IPs.

10. How does Ingress differ from Service LoadBalancer internally?
Ans:- **Service LoadBalancer (L4):** Asks the Cloud Provider (AWS/GCP/Azure) to provision a
physical/virtual Load Balancer (ELB/NLB). It operates at Layer 4 (TCP/UDP), forwarding traffic directly
to NodePorts. It is expensive (one LB per service) and unaware of HTTP paths.
**Ingress (L7):** An Ingress is a Kubernetes resource that configures an **Ingress Controller** (like
Nginx or Traefik). The controller is essentially a reverse proxy running inside the cluster. It operates at
Layer 7 (HTTP/HTTPS), allowing host-based (`foo.com`) and path-based (`/api`, `/web`) routing to
multiple internal Services using a single external IP.

11. What is etcd quorum and how does it impact cluster availability?
Ans:-
Etcd is a distributed key-value store that uses the **Raft** consensus algorithm. Quorum is the majority
of nodes required to agree on updates (`(N/2) + 1`).
If you have 3 nodes, quorum is 2. You can tolerate 1 failure. If you lose quorum (e.g., 2 nodes fail in a
3-node cluster), the cluster becomes **Read-Only**. No new pods can be scheduled, and no resource
changes can be made until quorum is restored.


12. How does Kubernetes handle leader election?
Ans:-
Kubernetes components (Scheduler, Controller Manager) use **Leader Election** to ensure high
availability without conflict. They use a **Lease** object (in the `coordination.k8s.io` API group) as a
distributed lock.
Candidates attempt to acquire the lease by updating the object with their identity and a timestamp. The
active leader periodically renews the lease. If the leader fails to renew within the `leaseDuration`,
another candidate acquires the lock and becomes the new leader. This relies on Optimistic Locking
(ResourceVersions) in the API Server.

13. How do rolling updates work internally in Deployments?
Ans:- A Deployment manages updates by creating a new **ReplicaSet** while scaling down the old one. This
is controlled by two parameters:
**maxSurge:** How many pods can be created *above* the desired count (e.g., creating new versions
before deleting old ones).
**maxUnavailable:** How many pods can be unavailable during the update.
The Deployment Controller iteratively scales up the new ReplicaSet and scales down the old
ReplicaSet until the new version reaches the desired count and the old one reaches 0.

14. What are PodDisruptionBudgets and real-world use cases?
Ans:- 
A **PodDisruptionBudget (PDB)** limits the number of pods that can be down simultaneously due to
*voluntary* disruptions (e.g., node draining for maintenance, cluster upgrades).
**Use Case:** If you have a Cassandra database cluster with 3 replicas and quorum requires 2, you set
a PDB with `minAvailable: 2`. If an admin tries to drain a node containing one of these pods,
Kubernetes will block the drain action if it would violate the PDB (i.e., if another replica is already
down).

15. How does Kubernetes handle node failures and rescheduling?
Ans:- 
1. The **Node Controller** stops receiving heartbeats from a node.
2. It changes the node `Condition` to `Unknown` or `NotReady`.
3. It waits for the `pod-eviction-timeout` (default 5 minutes) to avoid thrashing due to temporary network
blips.
4. Once the timeout expires, the controller deletes the Pod objects assigned to that node from the API
Server.
5. The **ReplicaSet Controller** notices the running replicas count has dropped and creates new Pods.
6. The **Scheduler** assigns these new Pods to healthy nodes.


16. What are admission controllers and why are they critical for security?
Ans:-
Admission Controllers are plugins that intercept API requests *after* authentication/authorization but
*before* the object is persisted to etcd.
**Types:**
1. **Mutating:** Modifies the request (e.g., injecting a sidecar proxy like Istio, setting default resource
limits).
2. **Validating:** Rejects the request if it violates policies (e.g., preventing pods from running as root,
enforcing unique ingress hosts).
They are critical for enforcing security policies (Pod Security Standards) and governance across the
cluster.

17. How does RBAC evaluation happen during API requests?
Ans:- When a request hits the API Server, the RBAC Authorizer checks:
**Subject:** Who is making the request? (User, Group, ServiceAccount)
**Verb:** What action? (get, list, watch, create, update, delete)
**Resource:** On what object? (pods, secrets, deployments)
**Namespace:** Where?
It evaluates all **RoleBindings** and **ClusterRoleBindings** associated with the subject. If *any*
binding allows the action, the request is approved. RBAC is 'deny-by-default'—if no rule explicitly allows
it, it is denied.

18. What is the difference between Secrets encryption at rest vs in transit?
Ans:- **In Transit:** Kubernetes uses **TLS** (HTTPS) for all communication between the User (kubectl), the
API Server, the Kubelet, and Etcd. This protects data as it travels over the network.
**At Rest:** By default, Secrets are stored as base64-encoded plain text in Etcd. To enable encryption
at rest, you must configure an **EncryptionConfiguration** in the API Server. This uses a provider (like
`aescbc` or a KMS plugin) to encrypt the secret data *before* writing it to Etcd, ensuring that even if the
etcd disk is stolen, the secrets are unreadable.


19. How do taints & tolerations differ from node affinity?
Ans:- 
**Taints/Tolerations:** Used to *repel* pods from nodes. A node with a Taint will refuse to schedule any
pod that does not have a matching Toleration. (Use case: Dedicated nodes for GPU workloads,
preventing general pods from landing there).
**Node Affinity:** Used to *attract* pods to nodes. It allows you to specify that a pod *prefers* or
*requires* to run on nodes with specific labels. (Use case: Scheduling pods in a specific availability
zone).

20. How does Kubernetes DNS work internally?
Ans:-
Kubernetes runs a DNS server (usually **CoreDNS**) as a Deployment/Service. It watches the API
Server for new Services and Pods.
When a Service `my-service` is created in namespace `default`, CoreDNS adds an A record:
`my-service.default.svc.cluster.local` pointing to the Service's ClusterIP.
Kubelet configures every Pod's `/etc/resolv.conf` with the CoreDNS Service IP and search domains
(e.g., `default.svc.cluster.local`, `svc.cluster.local`). This allows pods to resolve services by short
names.

21. How does kubelet communicate with the container runtime (CRI)?
Ans:- The Kubelet does not speak directly to Docker or containerd. It uses the **CRI (Container Runtime
Interface)**.
CRI is a plugin interface based on **gRPC**. The Kubelet acts as a gRPC client and calls the Container
Runtime (the gRPC server) to perform operations like `CreateContainer`, `StartContainer`, or
`StopContainer`. The runtime (e.g., containerd via a CRI shim) then interacts with the kernel (via
runc/OCI) to manage the containers.

22. What are static pods and when are they used?
Ans:-Static Pods are managed directly by the **Kubelet** on a specific node, bypassing the API Server and
Scheduler. They are defined by placing YAML manifest files in a specific directory on the node (usually
`/etc/kubernetes/manifests`).
**Use Case:** Bootstrapping the Control Plane itself. The API Server, Controller Manager, and
Scheduler usually run as static pods on the Master nodes because they need to start *before* the
cluster control plane is functional.

23. How does Kubernetes garbage collection work?
Ans:-Kubernetes GC cleans up unused resources (like terminated pods, unused images, or orphaned
objects). It relies heavily on **OwnerReferences**.
**Cascading Deletion:** When you delete a parent object (like a Deployment), the GC sees that the
child objects (ReplicaSets) have an `ownerReference` to it. Depending on the deletion strategy
(`Foreground`, `Background`, or `Orphan`), the GC deletes the dependents automatically.

24. What happens when a container exceeds memory limits?
Ans:-If a container tries to consume more RAM than its defined `limit`, the Linux Kernel's **OOM (Out of
Memory) Killer** intervenes.

The kernel terminates the process causing the pressure. In Kubernetes, this results in the container
exiting with **Exit Code 137** (128 + 9 for SIGKILL). The Kubelet sees this termination and restarts the
container (if the `restartPolicy` allows), often leading to a `CrashLoopBackOff` if the memory issue
persists.

25. How do you design a highly available Kubernetes control plane?
Ans:-To achieve HA, you need to eliminate single points of failure:
1. **Multiple Control Plane Nodes:** Run at least 3 control plane nodes (distributed across Availability
Zones).
2. **Etcd Clustering:** Etcd must run as a cluster (usually stacked on control nodes) with an odd
number of members (3 or 5) to maintain quorum.
3. **API Server Load Balancer:** Put a Load Balancer (cloud or HAProxy/Keepalived) in front of the API
Servers (port 6443) so worker nodes can talk to a stable endpoint.
4. **Controller Manager/Scheduler:** These run on all control nodes, but use **Leader Election** so
only one instance is active at a time.