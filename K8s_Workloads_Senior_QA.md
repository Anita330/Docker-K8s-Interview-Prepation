# Kubernetes Workloads – Senior Engineer Q&A
**Day 6 | Phase 3: EKS Core | Section 8 (1–4)**
**Date: 11-May-2026**

---

## Table of Contents

1. [Section 08-01: Kubernetes Pods](#section-08-01-kubernetes-pods)
2. [Section 08-02: Kubernetes Deployments](#section-08-02-kubernetes-deployments)
3. [Section 08-03: Kubernetes Services](#section-08-03-kubernetes-services)
4. [Section 08-04: Kubernetes ConfigMap](#section-08-04-kubernetes-configmap)
5. [Cross-Section / Architectural Scenarios](#cross-section--architectural-scenarios)

---

## Section 08-01: Kubernetes Pods

---

### Q1. A Pod is the smallest deployable unit. But internally, every Pod actually runs a hidden container before your app container. What is it, and what role does it play?

**Answer:**

Every Pod runs a **pause container** (also called the "infra container" or `k8s.gcr.io/pause`).

It is started first and its sole job is to:
- **Hold the network namespace** for the Pod (the Linux `netns`).
- Assign the Pod's IP address.
- Keep the namespace alive even if application containers restart.

All other containers in the Pod **join** this pause container's network namespace, which is why they share the same IP and `localhost`. If the pause container dies, the entire Pod is torn down and rescheduled.

---

### Q2. Explain Pod QoS classes. How does Kubernetes assign them and what are the eviction implications?

**Answer:**

Kubernetes assigns one of three QoS classes based on resource declarations:

| QoS Class | Condition | Eviction Priority |
|-----------|-----------|-------------------|
| **Guaranteed** | Every container has `requests == limits` for both CPU and memory | Last to be evicted |
| **Burstable** | At least one container has `requests < limits` or only one is set | Evicted after BestEffort |
| **BestEffort** | No `requests` or `limits` defined on any container | First to be evicted |

**In the course manifest:**
```yaml
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "250m"
    memory: "256Mi"
```
This is **Burstable** because `requests != limits`.

**Eviction:** Under memory pressure, the kubelet evicts BestEffort first, then Burstable (ordered by how much they exceed their requests), and Guaranteed last. This directly impacts production reliability — always use Guaranteed QoS for critical workloads.

---

### Q3. What are the Pod lifecycle phases? What does `Running` actually guarantee?

**Answer:**

| Phase | Meaning |
|-------|---------|
| `Pending` | Pod accepted by the API server; scheduler hasn't assigned a node yet, or images are being pulled |
| `Running` | Pod bound to a node; at least one container is running, starting, or restarting |
| `Succeeded` | All containers exited with code 0 (Jobs/batch workloads) |
| `Failed` | All containers have stopped; at least one exited with non-zero code |
| `Unknown` | Node communication lost; kubelet can't report state |

**Critical nuance:** `Running` does **not** mean the app is healthy. A Pod can be in `Running` phase while its Readiness Probe is failing (meaning it is excluded from Service endpoints). Always check `READY` column (`1/1`) not just `STATUS`.

---

### Q4. What is the difference between `readinessProbe`, `livenessProbe`, and `startupProbe`? When would you use each?

**Answer:**

| Probe | Question It Answers | Failure Action | Use Case |
|-------|---------------------|----------------|----------|
| **readinessProbe** | "Is the container ready to serve traffic?" | Remove Pod from Service endpoints | App has a warm-up period; DB connections need to establish |
| **livenessProbe** | "Is the container still alive?" | Restart the container | Detect deadlocks, hung threads, memory leaks that freeze the app |
| **startupProbe** | "Has the container finished starting?" | Restart the container (until `failureThreshold` exceeded) | Slow-starting legacy apps; prevents liveness from killing app before it boots |

**Key interaction:** `startupProbe` disables `livenessProbe` and `readinessProbe` until it succeeds. This prevents premature restarts during slow startup.

**From the course manifest:** Only `readinessProbe` is defined on the Pod. Adding `livenessProbe` (done in 08-02) adds self-healing behavior.

---

### Q5. What happens at the OS/kernel level when `kubectl exec -it catalog-pod -- sh` is executed?

**Answer:**

1. `kubectl` sends a `POST` request to the API server: `POST /api/v1/namespaces/default/pods/catalog-pod/exec`.
2. The API server upgrades the connection to a **WebSocket or SPDY** stream.
3. The API server communicates with the **kubelet** on the target node via its HTTPS endpoint.
4. The kubelet calls the **Container Runtime Interface (CRI)** (e.g., containerd).
5. containerd uses the `exec` syscall to run `sh` inside the container's existing **Linux namespaces** (PID, mount, network, UTS, IPC).
6. A new process is created that **joins** the existing container namespaces — it is not a new container.
7. Stdin/stdout are streamed back through the kubelet → API server → `kubectl`.

**Security implication:** This requires RBAC verb `exec` on `pods`. In production, restrict this — it grants essentially root-level access to the container.

---

### Q6. What are Init Containers? How do they differ from sidecar containers, and when would you use them in production?

**Answer:**

**Init Containers** run to completion **before** any app container starts. They run sequentially, one after another.

**Differences from app/sidecar containers:**

| Aspect | Init Container | App/Sidecar Container |
|--------|---------------|----------------------|
| Lifecycle | Runs once, must complete successfully | Runs for the life of the Pod |
| Restart | Restarts until success (per `restartPolicy`) | Restarts per container restart policy |
| Resource accounting | Counted separately for scheduling | Added to total Pod resource request |
| Probes | No readiness/liveness probes | Supports all probes |

**Production use cases:**
- Wait for a database to be available before starting the app (`nslookup db-service`)
- Pre-populate a shared `emptyDir` volume with config files
- Run DB schema migrations before the app container starts
- Clone a git repo into a shared volume

```yaml
initContainers:
  - name: wait-for-db
    image: busybox
    command: ['sh', '-c', 'until nslookup mysql-service; do sleep 2; done']
```

---

## Section 08-02: Kubernetes Deployments

---

### Q7. A Deployment creates a ReplicaSet, which creates Pods. Why does Kubernetes use this two-level hierarchy instead of Deployments directly managing Pods?

**Answer:**

The separation enables **versioned rollouts and rollbacks**:

- Each time you update a Deployment (e.g., change image), Kubernetes creates a **new ReplicaSet** for the new version while scaling down the old one.
- Old ReplicaSets are retained (controlled by `revisionHistoryLimit`, default: 10) to enable rollback.
- Rolling back simply means **scaling up the old ReplicaSet** and scaling down the new one.

```
Deployment (desired state owner)
  ├── ReplicaSet v1 (replicas: 0) ← kept for rollback
  └── ReplicaSet v2 (replicas: 3) ← current
```

If Deployments managed Pods directly, there would be no clean "snapshot" to roll back to — you'd have to reconstruct the old Pod template manually.

---

### Q8. Explain `maxUnavailable` and `maxSurge` in RollingUpdate. What is the trade-off between them?

**Answer:**

Both control **how aggressively** the rolling update proceeds:

| Parameter | Definition | Default |
|-----------|-----------|---------|
| `maxUnavailable` | Max Pods that can be **unavailable** during rollout (absolute or %) | 25% |
| `maxSurge` | Max **extra** Pods that can be created above `replicas` during rollout | 25% |

**Trade-offs:**

| Strategy | Config | Behavior | Cost |
|----------|--------|----------|------|
| Minimize downtime | High `maxSurge`, low `maxUnavailable` | New Pods start first, old ones terminate after | More compute cost (extra Pods running simultaneously) |
| Minimize cost | Low `maxSurge`, high `maxUnavailable` | Old Pods terminate first, then new ones start | Brief reduced capacity |
| Zero downtime, zero extra cost (impossible simultaneously) | `maxUnavailable: 0, maxSurge: 0` | **Invalid** — Kubernetes rejects this | — |

**Course manifest uses:** `maxUnavailable: 1, maxSurge` not set (defaults to 25%). For a single replica Deployment, this means the old Pod is killed before the new one starts — brief downtime acceptable for dev, not for production.

---

### Q9. What does `kubectl rollout undo` actually do under the hood? How is rollback different from re-deploying the old image?

**Answer:**

`kubectl rollout undo deployment/catalog` does the following:

1. Reads the **revision history** stored in old ReplicaSet annotations (`deployment.kubernetes.io/revision`).
2. Takes the `spec.template` from the previous ReplicaSet.
3. **Patches the current Deployment** with the previous Pod template (image, env vars, volumes, etc.).
4. This triggers a new rolling update — **scaling up the old RS** and **scaling down the current RS**.
5. The "previous" RS becomes the current one, and what was current is now revision N-1.

**Key difference from re-deploying:** `rollout undo` uses the **exact stored spec** from the previous ReplicaSet, including all fields (not just image). A manual `kubectl set image` only changes the image field — any other config changes made in that revision are preserved in the undo.

**Check revision before undo:**
```bash
kubectl rollout history deployment/catalog --revision=2
```

---

### Q10. What is the `Recreate` deployment strategy? When would you use it over `RollingUpdate`?

**Answer:**

`Recreate` strategy:
1. Terminates **all existing Pods** first.
2. Then creates new Pods.
3. This results in **downtime** equal to the time between old Pods terminating and new Pods becoming ready.

**When to use Recreate over RollingUpdate:**

| Scenario | Reason |
|----------|--------|
| App cannot run two versions simultaneously | Database schema migrations that are backward-incompatible |
| Singleton processes that lock files or ports | Only one instance should ever run |
| Major breaking changes in shared state | Two versions reading/writing different formats would corrupt data |
| Cost-constrained environments | Avoids running double the Pods during transition |

```yaml
strategy:
  type: Recreate
```

**In EKS production:** Almost always prefer `RollingUpdate` unless you have a specific reason. Use `PreStop` hooks and `terminationGracePeriodSeconds` to ensure graceful draining.

---

### Q11. What is a Pod Disruption Budget (PDB)? How does it interact with Deployments during node maintenance?

**Answer:**

A **PodDisruptionBudget** limits the number of Pods of a replicated application that can be voluntarily disrupted at any given time.

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: catalog-pdb
spec:
  minAvailable: 2        # OR maxUnavailable: 1
  selector:
    matchLabels:
      app.kubernetes.io/name: catalog
```

**Interaction with Deployments:**
- PDB applies to **voluntary disruptions** (node drain, cluster upgrades, evictions).
- During `kubectl drain <node>`, the eviction API checks PDB before evicting Pods.
- If evicting a Pod would violate the PDB, the drain **blocks** until the Deployment brings up a replacement Pod elsewhere.

**Involuntary disruptions** (node crash, kernel panic) are NOT governed by PDB.

**EKS relevance:** Managed node group upgrades and Karpenter node consolidation respect PDBs. Without a PDB, a cluster upgrade could evict all replicas simultaneously.

---

### Q12. The `securityContext` in the course manifest drops ALL Linux capabilities. Name 5 capabilities and why dropping them improves security.

**Answer:**

```yaml
securityContext:
  capabilities:
    drop:
      - ALL
```

Linux capabilities that are dropped (and why removing them matters):

| Capability | What it allows | Why dropping it matters |
|-----------|---------------|------------------------|
| `CAP_NET_RAW` | Create raw network sockets (ping, packet sniffing) | Prevents network-level attacks, ARP spoofing inside the cluster |
| `CAP_SYS_ADMIN` | Mount filesystems, change namespaces, load kernel modules | The most dangerous capability — essentially root. Dropping it prevents container escape |
| `CAP_CHOWN` | Change file ownership arbitrarily | Prevents privilege escalation via file ownership manipulation |
| `CAP_SETUID` / `CAP_SETGID` | Change process UID/GID | Prevents switching to root or another privileged user inside the container |
| `CAP_DAC_OVERRIDE` | Bypass file read/write/execute permission checks | Prevents reading files the process shouldn't have access to |

**Combined with:** `runAsNonRoot: true` and `readOnlyRootFilesystem: true`, this follows the **principle of least privilege** and is required for CIS Kubernetes Benchmark compliance.

---

## Section 08-03: Kubernetes Services

---

### Q13. How does `kube-proxy` implement a ClusterIP Service? Walk through what happens at the network layer when a Pod calls `catalog-service:8080`.

**Answer:**

**Default mode: iptables** (most common in EKS)

1. **DNS resolution:** The app calls `catalog-service:8080`. CoreDNS resolves `catalog-service.default.svc.cluster.local` → ClusterIP (e.g., `10.100.45.12`).
2. **Packet leaves the Pod:** The packet's destination is `10.100.45.12:8080`.
3. **iptables intercepts:** `kube-proxy` has programmed iptables `DNAT` rules in the `KUBE-SERVICES` chain. The ClusterIP is a **virtual IP** — it doesn't exist on any interface.
4. **DNAT rewrite:** iptables randomly selects one of the backing Pod IPs (EndpointSlice) and rewrites the destination: `10.100.45.12:8080` → `10.0.11.45:8080` (a real Pod IP).
5. **Packet routed to target Pod:** The node's routing table or overlay network (VPC CNI in EKS) routes the packet to the actual Pod.
6. **Connection tracked:** `conntrack` ensures reply packets are rewritten back.

**IPVS mode** (better performance at scale): Uses kernel-level IPVS hash tables instead of linear iptables chain traversal. Scales to tens of thousands of Services without iptables rule explosion.

---

### Q14. What is the difference between ClusterIP, NodePort, LoadBalancer, and ExternalName Services? When would you use each on EKS?

**Answer:**

| Type | Accessibility | EKS Use Case |
|------|-------------|--------------|
| **ClusterIP** | Only within the cluster | Internal microservice-to-microservice communication (default, most secure) |
| **NodePort** | Via `<NodeIP>:<NodePort>` (30000–32767) on every node | Rarely used directly; mostly as a building block for LoadBalancer. Useful for debugging |
| **LoadBalancer** | Via AWS ELB/ALB public or private DNS | Expose a service to external traffic. Creates an NLB (Network Load Balancer) by default on EKS |
| **ExternalName** | CNAME to external DNS | Route in-cluster traffic to an external service (e.g., RDS endpoint) using a Kubernetes-native name |
| **Headless** (ClusterIP: None) | Returns individual Pod IPs directly via DNS | StatefulSets, databases — clients need to know individual Pod IPs (e.g., MySQL Galera, Kafka) |

**EKS best practice:** Use `ClusterIP` for internal services + an **Ingress controller** (AWS Load Balancer Controller with ALB) for external access. Avoid creating a `LoadBalancer` Service per microservice — each one provisions a separate ELB.

---

### Q15. How does Kubernetes DNS work internally? What is the full DNS name for `catalog-service` and how does CoreDNS serve it?

**Answer:**

**Full DNS FQDN structure:**
```
<service-name>.<namespace>.svc.<cluster-domain>
catalog-service.default.svc.cluster.local
```

**How CoreDNS serves it:**

1. Each Pod's `/etc/resolv.conf` is configured by kubelet:
   ```
   nameserver 10.96.0.10      # CoreDNS ClusterIP
   search default.svc.cluster.local svc.cluster.local cluster.local
   options ndots:5
   ```
2. When a Pod queries `catalog-service`, the DNS client appends search domains.
3. `catalog-service.default.svc.cluster.local` is tried first and resolves.
4. CoreDNS reads from the **Kubernetes API** (via the `kubernetes` plugin) to return the Service's ClusterIP.
5. For **headless services** (`ClusterIP: None`), CoreDNS returns the individual **Pod IPs** instead of a single ClusterIP.

**`ndots:5` implication:** Any name with fewer than 5 dots triggers a search domain lookup before trying as an absolute name. This means `catalog-service` first tries `catalog-service.default.svc.cluster.local` — efficient for in-cluster calls. However, FQDN lookups like `google.com` go through 4 search domain attempts before resolving — adds latency. Mitigate with trailing dot: `curl http://google.com./`.

---

### Q16. What are EndpointSlices and how do they improve upon the old Endpoints object?

**Answer:**

**Old Endpoints object (problem):**
- A single `Endpoints` object stored **all** Pod IPs for a Service.
- Every update (Pod restart, scaling) caused the entire object to be re-synced to all nodes.
- At 5000+ endpoints, this caused significant etcd and kube-proxy CPU overhead.

**EndpointSlices (solution — GA in k8s 1.21):**
- Endpoints are sharded into multiple `EndpointSlice` objects, each holding up to **100 endpoints** by default.
- Only the **changed slice** is updated and propagated on Pod changes.
- Supports **multiple address types**: IPv4, IPv6, FQDN.
- Supports **topology hints** for zone-aware routing (Traffic Distribution to local zone).

```bash
kubectl get endpointslices -l kubernetes.io/service-name=catalog-service
```

**EKS relevance:** EKS uses EndpointSlices by default. The AWS VPC CNI and `kube-proxy` use EndpointSlices to program iptables/IPVS rules efficiently at scale.

---

### Q17. What is Service topology / Traffic Distribution and why does it matter in a multi-AZ EKS cluster?

**Answer:**

In EKS with nodes spread across 3 AZs, by default a ClusterIP Service load-balances requests across **all healthy Pods regardless of AZ**.

**Problem:** A Pod in `us-east-1a` calling `catalog-service` might hit a Pod in `us-east-1c` — this is **cross-AZ traffic**, which incurs:
- Additional latency (~1ms per cross-AZ hop)
- **AWS data transfer costs** (~$0.01/GB between AZs)

**Solution — `trafficDistribution: PreferClose` (k8s 1.31 stable):**
```yaml
spec:
  trafficDistribution: PreferClose
```

kube-proxy and EndpointSlice topology hints will **prefer routing to Pods in the same zone** as the caller, falling back to other zones only if no local Pods are available.

**Older approach:** `topologyKeys` (deprecated) or AWS Load Balancer Controller's `target-type: ip` with `enableZonalShift`.

---

## Section 08-04: Kubernetes ConfigMap

---

### Q18. What are the three ways to consume a ConfigMap in a Pod, and what are the trade-offs of each?

**Answer:**

| Method | YAML | Behavior | Best For |
|--------|------|----------|---------|
| **`envFrom`** | `envFrom: [{configMapRef: {name: catalog}}]` | All keys injected as env vars | Bulk injection of many env vars |
| **`env.valueFrom`** | `valueFrom: {configMapKeyRef: {name: catalog, key: DB_NAME}}` | Individual key injected as named env var | Selective injection, renaming keys |
| **Volume mount** | `volumes: [{configMap: {name: catalog}}]` | ConfigMap keys become **files** in a directory | Config files (nginx.conf, app.yaml), supports hot reload |

**Critical difference — Hot Reload:**
- **Env vars (`envFrom` / `valueFrom`):** ConfigMap changes are **NOT reflected** in running Pods. You must restart the Pod.
- **Volume mounts:** Kubernetes updates the mounted files **automatically** (with ~1 minute kubelet sync delay). Apps that watch their config files (e.g., nginx with `-s reload`) can pick up changes without restart.

**From course manifest:** `envFrom` is used — any ConfigMap change requires a Pod rollout.

---

### Q19. What is the difference between a ConfigMap and a Secret? When should you use one over the other?

**Answer:**

| Aspect | ConfigMap | Secret |
|--------|-----------|--------|
| **Purpose** | Non-sensitive config (URLs, feature flags, timeouts) | Sensitive data (passwords, tokens, TLS certs) |
| **Storage** | Stored in etcd in **plaintext** | Stored in etcd **base64-encoded** (NOT encrypted by default) |
| **Encryption at rest** | Not encrypted | Only encrypted if `EncryptionConfiguration` is enabled (enabled by default in EKS) |
| **RBAC** | Standard RBAC | Tighter RBAC recommended (`get` on secrets should be restricted) |
| **Size limit** | 1 MiB | 1 MiB |
| **Env var exposure** | Visible in `kubectl exec -- env` | Also visible — but can use `secretKeyRef` |

**In the course manifest:** `RETAIL_CATALOG_PERSISTENCE_PASSWORD: ""` is in the ConfigMap — even an empty password should be in a Secret for production.

**EKS best practice:** Use **AWS Secrets Manager + External Secrets Operator** or **AWS SSM Parameter Store** instead of native Kubernetes Secrets for production credentials.

---

### Q20. What is an Immutable ConfigMap? What problem does it solve at scale?

**Answer:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: catalog-config-v2
immutable: true
data:
  APP_VERSION: "2.0"
```

**Benefits of immutable ConfigMaps:**
1. **Protects against accidental changes** — once created, data cannot be modified (only deleted and recreated).
2. **Performance at scale:** For clusters with tens of thousands of Pods watching the same ConfigMap, the kubelet normally polls the API server for changes. Marking it immutable tells kubelets to **stop watching** — drastically reducing API server load.
3. **Forces versioned config:** Encourages treating config as immutable artifacts (e.g., `catalog-config-v1`, `catalog-config-v2`) — same principle as immutable container images.

**Tradeoff:** To change config, you must create a new ConfigMap and update the Deployment to reference it (triggering a rollout) — which is actually desirable for auditability.

---

### Q21. Can you hot-reload environment variables in a running Pod when a ConfigMap changes? If not, what patterns exist to handle dynamic configuration?

**Answer:**

**Short answer:** No. Environment variables are set at container start time. A ConfigMap change does **not** update env vars in running containers.

**Patterns for dynamic configuration:**

| Pattern | How It Works | Complexity |
|---------|-------------|------------|
| **Volume-mounted config + app file watcher** | ConfigMap as file volume; app watches for file changes | Low (if app supports it) |
| **Reloader sidecar** | Tools like `stakater/Reloader` watch ConfigMap/Secret changes and trigger rolling restarts automatically | Low (operator pattern) |
| **External config server** | App polls AWS AppConfig, Consul, or etcd directly at runtime | Medium |
| **Feature flags service** | AWS AppConfig, LaunchDarkly — runtime flag evaluation without restarts | Medium-High |
| **Immutable config + GitOps rollout** | Config changes create new ConfigMap versions; ArgoCD/Flux triggers Deployment rollout | High (but most production-grade) |

**Reloader example annotation:**
```yaml
metadata:
  annotations:
    reloader.stakater.com/auto: "true"
```

---

## Cross-Section / Architectural Scenarios

---

### Q22. You have a Deployment with 3 replicas. During a rolling update, one new Pod is stuck in `0/1 READY`. What is your troubleshooting process?

**Answer:**

**Step 1: Check rollout status**
```bash
kubectl rollout status deployment/catalog
# Will show: Waiting for rollout to finish: 1 out of 3 new replicas have been updated...
```

**Step 2: Identify the stuck Pod**
```bash
kubectl get pods -l app.kubernetes.io/name=catalog
# Look for READY 0/1 with STATUS Running
```

**Step 3: Check Readiness Probe**
```bash
kubectl describe pod <stuck-pod-name>
# Look for: Readiness probe failed: ...
# Check Events section at the bottom
```

**Step 4: Check logs**
```bash
kubectl logs <stuck-pod-name>
kubectl logs <stuck-pod-name> --previous   # if container restarted
```

**Step 5: Check liveness/readiness probe endpoint manually**
```bash
kubectl exec -it <stuck-pod-name> -- curl localhost:8080/health
```

**Common root causes:**
- New image has a bug — app crashes or health endpoint returns non-200
- New image needs env var or config that isn't present
- Resource limits too low — OOMKilled
- Readiness probe `path` or `port` changed in new image
- `initialDelaySeconds` too short for slow-starting app

**Recovery options:**
- Rollback immediately: `kubectl rollout undo deployment/catalog`
- The rolling update is paused by the failed probe — old Pods are still serving traffic

---

### Q23. A microservice team says "our Service is routing traffic but some requests are failing intermittently." How would you diagnose load balancing issues at the Service level?

**Answer:**

**Step 1: Verify all backend Pods are READY**
```bash
kubectl get pods -l app.kubernetes.io/name=catalog
# Ensure all show 1/1 READY. A 0/1 Pod is still in EndpointSlice
# and will receive traffic — this is the most common cause of intermittent failures.
```

**Step 2: Check EndpointSlice**
```bash
kubectl get endpointslices -l kubernetes.io/service-name=catalog-service -o yaml
# Verify all endpoints have `conditions.ready: true`
```

**Step 3: Isolate which Pod is failing**
```bash
# Add logging or use a debug sidecar
# Check per-Pod metrics in CloudWatch Container Insights
```

**Step 4: Test each Pod IP directly**
```bash
kubectl run debug --image=curlimages/curl -it --rm -- sh
# curl http://<pod-ip>:8080/health for each Pod IP
```

**Step 5: Check for resource exhaustion**
```bash
kubectl top pods -l app.kubernetes.io/name=catalog
# A Pod near memory limit may be slow to respond and fail intermittently
```

**Step 6: Session affinity**
```bash
kubectl get svc catalog-service -o yaml | grep sessionAffinity
# Default: None (round-robin). If app has in-memory session state,
# you may need sessionAffinity: ClientIP
```

---

### Q24. How would you design the Kubernetes manifests for the Catalog service to be fully production-ready on EKS? What is missing from the course demos?

**Answer:**

The course demos cover fundamentals. A production-ready setup would add:

| Category | Missing Element | Why Needed |
|----------|----------------|------------|
| **Availability** | `PodDisruptionBudget` | Prevent all replicas from being evicted during node upgrades |
| **Availability** | `topologySpreadConstraints` | Spread Pods across AZs to prevent single-AZ failures |
| **Availability** | `minReadySeconds` on Deployment | Ensure new Pods are stable before proceeding with rolling update |
| **Security** | `NetworkPolicy` | Restrict which Pods can call `catalog-service` (zero-trust networking) |
| **Security** | `ServiceAccount` with IRSA | Grant AWS permissions (S3, DynamoDB) via IAM Role for Service Account instead of node role |
| **Security** | Move passwords to `Secret` + AWS Secrets Manager | ConfigMap stores password in plaintext |
| **Observability** | `Prometheus` annotations or `ServiceMonitor` | Enable metrics scraping |
| **Reliability** | `HorizontalPodAutoscaler` | Auto-scale based on CPU/memory/custom metrics |
| **Config** | Immutable ConfigMap with versioning | Prevent accidental config drift |
| **Lifecycle** | `preStop` hook + `terminationGracePeriodSeconds` | Graceful shutdown — drain in-flight requests before Pod terminates |

**Example `topologySpreadConstraints`:**
```yaml
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app.kubernetes.io/name: catalog
```

---

### Q25. Explain the full lifecycle of a `kubectl apply -f 01_catalog_deployment.yaml` command — from your terminal to a running Pod on an EKS worker node.

**Answer:**

1. **kubectl** reads the YAML, serializes it to JSON, sends `PATCH` (or `PUT`) to the API server: `PATCH /apis/apps/v1/namespaces/default/deployments/catalog`.

2. **API Server** authenticates (via kubeconfig token/cert), authorizes (RBAC), then runs **admission controllers**:
   - `MutatingAdmissionWebhook` may inject sidecars (Istio, Datadog)
   - `ValidatingAdmissionWebhook` validates the manifest (OPA Gatekeeper policies)
   - Built-in admission: `LimitRanger` (apply default limits), `ResourceQuota` (check namespace quota)

3. **API server persists** the desired state to **etcd**.

4. **Deployment Controller** (in `kube-controller-manager`) watches for Deployment changes via `list/watch`. It computes the diff and creates or updates a **ReplicaSet**.

5. **ReplicaSet Controller** sees `replicas: 1` but 0 Pods exist. Creates a **Pod object** in etcd (Status: `Pending`).

6. **Scheduler** watches for unscheduled Pods. Runs filtering (taints, node selectors, resource fit) and scoring (spread, affinity). Assigns the Pod to a node by writing `spec.nodeName` to the Pod object.

7. **kubelet** on the target node watches for Pods assigned to it. Calls **containerd** (via CRI) to:
   - Pull image from ECR (`public.ecr.aws/...`)
   - Create the **pause container** (network namespace setup)
   - Create the **app container**, applying cgroups (CPU/memory limits) and seccomp profiles

8. **CNI plugin** (AWS VPC CNI): Allocates a **VPC IP** from the node's ENI secondary IP pool and configures the Pod's network namespace.

9. **kubelet** starts the **readiness probe**. When `/health` returns 200, it sets `conditions.ready: true`.

10. **Endpoints controller** / **EndpointSlice controller** detects the ready Pod and adds its IP to the `catalog-service` EndpointSlice.

11. **kube-proxy** on all nodes picks up the EndpointSlice update and adds iptables DNAT rules so the Service ClusterIP routes to the new Pod.

**Pod is now live and receiving traffic.**

---

*Document prepared for Day 6 – Phase 3: EKS Core*
*Senior Engineer Knowledge Validation*

---

---

# Kubernetes Workloads – Senior Engineer Q&A
**Day 7 | Phase 3: EKS Core | Section 8 (5)**
**Date: 12-May-2026**

---

## Table of Contents

1. [StatefulSet vs Deployment — Core Differences](#q26-what-fundamentally-distinguishes-a-statefulset-from-a-deployment-at-the-kubernetes-controller-level)
2. [Stable Network Identity & Headless Service DNS](#q27-explain-how-a-statefulset-provides-stable-network-identity-walk-through-the-dns-resolution-for-pod-1-of-a-statefulset-named-mysql)
3. [VolumeClaimTemplates & PVC Lifecycle](#q28-what-is-a-volumeclaimtemplate-how-does-it-differ-from-a-pod-level-volume-and-what-happens-to-pvcs-when-a-statefulset-pod-is-deleted)
4. [Ordered Deployment, Scaling & Termination](#q29-walk-through-the-exact-order-kubernetes-follows-when-scaling-a-statefulset-from-1-to-3-replicas-and-then-back-to-1)
5. [Pod Management Policy](#q30-what-is-podmanagementpolicy-and-when-would-you-use-parallel-over-orderedready)
6. [Update Strategies & Partitioned Rollout](#q31-how-does-a-statefulset-rollingupdate-differ-from-a-deployment-rolling-update-what-is-the-partition-field-and-when-is-it-used)
7. [Headless Service — Why Required](#q32-why-does-a-statefulset-require-a-headless-service-what-breaks-if-you-use-a-regular-clusterip-service-instead)
8. [PVC Retain Policy & Data Safety](#q33-what-is-the-persistentvolumeclaimretentionpolicy-in-statefulsets-and-why-was-it-added)
9. [StatefulSet on EKS — Multi-AZ EBS Problem](#q34-you-deploy-a-statefulset-with-3-replicas-using-ebs-volumes-on-a-multi-az-eks-cluster-what-critical-problem-arises-and-how-do-you-solve-it)
10. [Init Containers for Cluster Bootstrap](#q35-how-would-you-use-init-containers-to-bootstrap-a-clustered-database-statefulset-eg-mysql-group-replication)
11. [Anti-Affinity for StatefulSets](#q36-why-is-pod-anti-affinity-especially-important-for-statefulsets-write-the-manifest-snippet-and-explain-the-tradeoff-between-requiredduringscheduling-and-preferredduringscheduling)
12. [Production Readiness Checklist](#q37-a-team-wants-to-run-a-3-node-kafka-cluster-as-a-statefulset-on-eks-what-is-your-complete-production-readiness-checklist)
13. [Scenario — Stuck Pod in StatefulSet Rollout](#q38-during-a-statefulset-rolling-update-pod-1-is-stuck-in-pending-the-rollout-is-blocked-walk-through-your-diagnosis-and-remediation)

---

## Section 08-05: Kubernetes StatefulSet

---

### Q26. What fundamentally distinguishes a StatefulSet from a Deployment at the Kubernetes controller level?

**Answer:**

A **Deployment** manages a group of **interchangeable** Pods — each Pod is fungible, has a random name, and gets a random IP on restart.

A **StatefulSet** manages a group of **individually identifiable** Pods. Three guarantees that no other workload type provides:

| Guarantee | Detail |
|-----------|--------|
| **Stable, unique Pod names** | Pods are named `<statefulset-name>-<ordinal>` (e.g., `mysql-0`, `mysql-1`). The name is **retained** across restarts and rescheduling. |
| **Stable network identity** | Each Pod gets a stable DNS hostname via a **Headless Service**: `mysql-0.mysql-svc.default.svc.cluster.local`. The hostname resolves even after Pod restart on a different node. |
| **Stable, dedicated storage** | Each Pod gets its own `PersistentVolumeClaim` created from a `volumeClaimTemplate`. The PVC is **not deleted** when the Pod is deleted — the new Pod reattaches the same PVC. |

**Controller behavior difference:**

- Deployment controller replaces a dead Pod with a new Pod using the same template but a **different name and PVC**.
- StatefulSet controller replaces Pod `mysql-1` with a new Pod **also named** `mysql-1` that reattaches **the same PVC** (`data-mysql-1`).

This is why StatefulSets are used for **databases, message queues, and clustered applications** where each instance has unique identity that other peers reference by name.

---

### Q27. Explain how a StatefulSet provides stable network identity. Walk through the DNS resolution for Pod-1 of a StatefulSet named `mysql`.

**Answer:**

**Prerequisites:**
1. StatefulSet references a **Headless Service** via `spec.serviceName: "mysql-svc"`.
2. The Headless Service has `clusterIP: None`.

**DNS names created by CoreDNS:**

| DNS Name | Resolves To |
|----------|------------|
| `mysql-svc.default.svc.cluster.local` | All ready Pod IPs (round-robin A records) |
| `mysql-0.mysql-svc.default.svc.cluster.local` | IP of `mysql-0` specifically |
| `mysql-1.mysql-svc.default.svc.cluster.local` | IP of `mysql-1` specifically |
| `mysql-2.mysql-svc.default.svc.cluster.local` | IP of `mysql-2` specifically |

**DNS resolution walkthrough for Pod-1:**

1. A replica calls `mysql-1.mysql-svc` (search domains expand to full FQDN).
2. CoreDNS uses the `kubernetes` plugin to look up the **Pod object** for `mysql-1` in the `default` namespace.
3. It returns the current Pod IP — even if `mysql-1` was rescheduled to a different node with a new VPC IP.
4. The caller always reaches the **same logical replica**, not a random Pod.

**Why this matters:** MySQL replication, Kafka leader election, Zookeeper quorum — all require peers to address each other by stable identifiers. `mysql-1.mysql-svc` is that stable identifier.

**If the Pod is not ready:** CoreDNS still returns the A record by default (unlike a regular ClusterIP Service which only routes to ready endpoints). You can change this with `publishNotReadyAddresses: true` on the Service — useful during cluster bootstrap when Pods need to discover each other before they are ready.

---

### Q28. What is a `volumeClaimTemplate`? How does it differ from a Pod-level volume, and what happens to PVCs when a StatefulSet Pod is deleted?

**Answer:**

**Pod-level volume (in Deployment):**
```yaml
volumes:
  - name: data
    emptyDir: {}       # or a named PVC
```
Every Pod in the Deployment shares or gets a **new ephemeral volume** — data is lost on Pod restart unless you manually pre-create a PVC.

**`volumeClaimTemplates` (in StatefulSet):**
```yaml
volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: gp3
      resources:
        requests:
          storage: 20Gi
```

**What Kubernetes does:**
- When Pod `mysql-0` is first created, Kubernetes automatically creates PVC `data-mysql-0`.
- When Pod `mysql-1` is created, PVC `data-mysql-1` is created.
- Each PVC is **bound to a unique PV** (EBS volume in EKS).

**What happens on Pod deletion:**

| Action | PVC behavior |
|--------|-------------|
| `kubectl delete pod mysql-1` | PVC `data-mysql-1` is **retained**. When StatefulSet recreates `mysql-1`, the same PVC is reattached. |
| `kubectl delete statefulset mysql` | By default, PVCs are **also retained** (orphaned). Data survives. You must delete PVCs manually. |
| `kubectl delete statefulset mysql --cascade=orphan` | Pods deleted, PVCs and PVs remain. |

**Key production implication:** Scaling down from 3 to 2 replicas deletes Pod `mysql-2` but **not** PVC `data-mysql-2`. If you scale back to 3, the same data is reattached. This is intentional — prevents accidental data loss.

---

### Q29. Walk through the exact order Kubernetes follows when scaling a StatefulSet from 1 to 3 replicas, and then back to 1.

**Answer:**

**Scaling UP (1 → 3), with `podManagementPolicy: OrderedReady` (default):**

```
Pod mysql-0 already exists and is Running/Ready
→ Create mysql-1, wait until Running AND Ready
→ Create mysql-2, wait until Running AND Ready
```

Rules:
- Pod `N` is not created until Pod `N-1` is **Running and Ready**.
- This ensures that by the time `mysql-2` starts, `mysql-0` and `mysql-1` are already available — critical for clustered apps that bootstrap by joining existing nodes.

**Scaling DOWN (3 → 1):**

```
Delete mysql-2, wait until fully Terminated
→ Delete mysql-1, wait until fully Terminated
→ mysql-0 remains
```

Rules:
- Deletion is in **reverse ordinal order** (highest first).
- Pod `N` is not deleted until Pod `N+1` is **fully terminated**.
- This prevents quorum loss in distributed systems (e.g., a 3-node Raft cluster always retains the majority until the very end of scale-down).

**Why ordered scale-down matters — example:**
In a 3-node etcd cluster, if you deleted `etcd-0` and `etcd-1` simultaneously, you'd lose quorum. Ordered deletion ensures only one node is offline at a time.

---

### Q30. What is `podManagementPolicy` and when would you use `Parallel` over `OrderedReady`?

**Answer:**

`podManagementPolicy` controls how Pods are created and deleted during scale operations.

| Policy | Behavior | Default |
|--------|----------|---------|
| `OrderedReady` | Create/delete Pods one at a time, in order, waiting for each to be Ready/Terminated before proceeding | Yes |
| `Parallel` | Create or delete **all Pods simultaneously** without waiting | No |

**`Parallel` use cases:**

1. **Stateless-ish workloads that need stable names** — e.g., a service that needs predictable hostnames but doesn't actually need sequential startup.
2. **Large-scale clusters where ordered startup is too slow** — 50-node Kafka cluster would take 50× pod-startup-time to scale up sequentially.
3. **Applications that self-coordinate startup** — Zookeeper with `publishNotReadyAddresses: true` where nodes discover each other via DNS even before ready.

```yaml
spec:
  podManagementPolicy: Parallel
```

**Important:** `Parallel` only applies to **scale operations**. Rolling updates still respect `maxUnavailable` per the `updateStrategy`, not `podManagementPolicy`.

---

### Q31. How does a StatefulSet `RollingUpdate` differ from a Deployment rolling update? What is the `partition` field and when is it used?

**Answer:**

**Deployment RollingUpdate:**
- Uses `maxUnavailable` and `maxSurge`.
- Pods are replaced in **no guaranteed order** — multiple Pods can be updated simultaneously.
- Old and new ReplicaSets coexist.

**StatefulSet RollingUpdate:**
- Always updates Pods in **reverse ordinal order** (highest ordinal first): `mysql-2` → `mysql-1` → `mysql-0`.
- Only moves to the next Pod after the current one is **Running and Ready**.
- No concept of surge — one Pod is replaced at a time.
- No separate ReplicaSet — the StatefulSet directly owns Pods.

**The `partition` field — Canary rollout for StatefulSets:**

```yaml
updateStrategy:
  type: RollingUpdate
  rollingUpdate:
    partition: 2
```

With `partition: 2` and 3 replicas (`mysql-0`, `mysql-1`, `mysql-2`):
- Only Pods with **ordinal ≥ partition** are updated: `mysql-2` gets the new image.
- `mysql-0` and `mysql-1` **keep the old image** even if the StatefulSet spec is updated.

**Use case — staged canary for databases:**
1. Set `partition: 2` → update only `mysql-2` (secondary/read replica). Validate.
2. Set `partition: 1` → update `mysql-1`. Validate.
3. Set `partition: 0` → update `mysql-0` (primary). Complete rollout.

This is especially valuable when rolling back a primary database is dangerous — you validate on replicas first.

---

### Q32. Why does a StatefulSet require a Headless Service? What breaks if you use a regular ClusterIP Service instead?

**Answer:**

**Headless Service (`clusterIP: None`)** is required because:

1. **Per-Pod DNS records:** CoreDNS creates an A record for each Pod: `<pod-name>.<service-name>.<namespace>.svc.cluster.local`. This requires the Service to be headless — a regular ClusterIP Service only creates a record for the Service VIP, not individual Pods.

2. **Client-side load balancing:** Applications like Kafka clients, Cassandra drivers, and MySQL replication use DNS to **discover all cluster members** and connect to specific ones. A ClusterIP would return a single VIP and hide the individual Pods behind it.

3. **No accidental load balancing:** If `mysql-0` is the primary (read-write) and `mysql-1`/`mysql-2` are replicas (read-only), you **must not** send write traffic to replicas. A ClusterIP Service would randomly load-balance writes to any Pod — causing data corruption.

**What breaks with a regular ClusterIP Service:**

| Scenario | Problem |
|----------|---------|
| Peer-to-peer discovery | `mysql-1.mysql-svc` DNS name does not exist — peers cannot address each other |
| Primary election | Leader needs to advertise its specific hostname — impossible without per-Pod DNS |
| Client topology-aware routing | Clients cannot distinguish primary vs replica |

**The Headless Service must also set `publishNotReadyAddresses: true`** for StatefulSets during bootstrap, so unready Pods are still discoverable by their peers during cluster formation.

---

### Q33. What is the `persistentVolumeClaimRetentionPolicy` in StatefulSets, and why was it added?

**Answer:**

Added in Kubernetes 1.27 (stable), this field controls what happens to PVCs when the StatefulSet is deleted or scaled down.

```yaml
spec:
  persistentVolumeClaimRetentionPolicy:
    whenDeleted: Retain   # or Delete
    whenScaled: Retain    # or Delete
```

| Field | Value | Behavior |
|-------|-------|----------|
| `whenDeleted: Retain` | Default | PVCs survive when the StatefulSet is deleted. Manual cleanup required. |
| `whenDeleted: Delete` | New option | PVCs are automatically deleted when the StatefulSet is deleted. |
| `whenScaled: Retain` | Default | PVCs for scaled-down Pods persist (e.g., scale 3→1 leaves `data-mysql-1` and `data-mysql-2`). |
| `whenScaled: Delete` | New option | PVCs for scaled-down Pods are automatically deleted. |

**Why it was added:**

Before 1.27, there was no way to automatically clean up PVCs. Operators would:
- Scale down a StatefulSet and forget orphaned PVCs → accumulating EBS volumes → AWS cost leak.
- Delete a StatefulSet for cleanup and find the storage lingering for months.

**EKS production guidance:**
- **Databases (MySQL, Postgres):** `whenDeleted: Retain, whenScaled: Retain` — never auto-delete database storage.
- **Ephemeral caches (Redis, Memcached as StatefulSet):** `whenDeleted: Delete, whenScaled: Delete` — storage is disposable.
- **Dev/Test environments:** `whenDeleted: Delete` — auto-cleanup prevents cost leak.

---

### Q34. You deploy a StatefulSet with 3 replicas using EBS volumes on a multi-AZ EKS cluster. What critical problem arises, and how do you solve it?

**Answer:**

**The Problem — EBS is AZ-local:**

EBS volumes are **bound to a specific Availability Zone**. An EBS volume in `us-east-1a` cannot be attached to an EC2 node in `us-east-1b`.

When a StatefulSet Pod is rescheduled (node failure, maintenance), the new Pod **must land in the same AZ as its EBS volume**. If the scheduler picks a node in a different AZ, the Pod gets stuck in `Pending` with:
```
AttachVolume.Attach failed: ... volume is already exclusively attached to one node
# or:
multi-attach error: volume is already attached to node in a different AZ
```

**Solutions:**

**Option 1: Node affinity via Storage Class `volumeBindingMode: WaitForFirstConsumer`**
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
parameters:
  type: gp3
volumeBindingMode: WaitForFirstConsumer  # critical
```
The PV is not provisioned until a Pod is scheduled. The scheduler picks the node first, then EBS provisions the volume in the same AZ. On rescheduling, the node affinity annotation on the PV ensures the Pod returns to the same AZ.

**Option 2: Explicit topology spread constraints (defense-in-depth)**
```yaml
topologySpreadConstraints:
  - maxSkew: 1
    topologyKey: topology.kubernetes.io/zone
    whenUnsatisfiable: DoNotSchedule
    labelSelector:
      matchLabels:
        app: mysql
```
Spreads Pods across AZs, reducing the chance of all Pods landing in one AZ (single point of failure).

**Option 3: Use EFS instead of EBS**
AWS EFS is a multi-AZ NFS-based storage. `ReadWriteMany` — any Pod in any AZ can mount it. However, EFS is slower and costs more. Appropriate for shared config or log storage, not high-IOPS databases.

**Option 4: Use a distributed storage layer**
For truly AZ-resilient stateful apps, use **Amazon Aurora** (managed, multi-AZ), **Portworx**, or **Rook/Ceph** in-cluster — these replicate data across AZs independently of the underlying block storage.

---

### Q35. How would you use Init Containers to bootstrap a clustered database StatefulSet (e.g., MySQL Group Replication)?

**Answer:**

In a MySQL Group Replication StatefulSet, each Pod needs to:
1. Know its own ordinal index (to generate a unique `server-id`).
2. Copy the correct config template based on whether it's the primary (`mysql-0`) or a secondary.

**Pattern using Init Containers:**

```yaml
initContainers:
  - name: init-mysql
    image: mysql:8.0
    command:
      - bash
      - "-c"
      - |
        set -ex
        # Derive server-id from Pod ordinal (hostname suffix)
        [[ $(hostname) =~ -([0-9]+)$ ]] && ordinal=${BASH_REMATCH[1]}
        echo [mysqld]              > /mnt/conf.d/server-id.cnf
        echo server-id=$((100 + ordinal)) >> /mnt/conf.d/server-id.cnf
        # Primary gets read-write config, replicas get read-only
        if [[ $ordinal -eq 0 ]]; then
          cp /mnt/config-map/primary.cnf /mnt/conf.d/
        else
          cp /mnt/config-map/replica.cnf /mnt/conf.d/
        fi
    volumeMounts:
      - name: conf
        mountPath: /mnt/conf.d
      - name: config-map
        mountPath: /mnt/config-map
  - name: clone-mysql
    image: gcr.io/google-samples/xtrabackup:1.0
    command:
      - bash
      - "-c"
      - |
        set -ex
        [[ $(hostname) =~ -([0-9]+)$ ]] && ordinal=${BASH_REMATCH[1]}
        # Skip if primary (no data to clone) or data already exists
        [[ $ordinal -eq 0 ]] && exit 0
        [[ -d /var/lib/mysql/mysql ]] && exit 0
        # Clone from previous peer (N-1)
        ncat --recv-only mysql-$(($ordinal - 1)).mysql-svc 3307 | xbstream -x -C /var/lib/mysql
        xtrabackup --prepare --target-dir=/var/lib/mysql
    volumeMounts:
      - name: data
        mountPath: /var/lib/mysql
```

**Key patterns:**
- **`hostname` parsing** to get the ordinal: `mysql-2` → ordinal `2`.
- **Clone from `N-1` peer** using `ncat` — Pod `mysql-1` clones from `mysql-0`, Pod `mysql-2` clones from `mysql-1`. This avoids putting all clone load on the primary.
- **Guard clause `[[ -d /var/lib/mysql/mysql ]]`** — skip cloning if data already exists (Pod restart after first init).
- Init containers run **before** the MySQL container starts, guaranteeing config and data are ready.

---

### Q36. Why is Pod anti-affinity especially important for StatefulSets? Write the manifest snippet and explain the trade-off between `requiredDuringScheduling` and `preferredDuringScheduling`.

**Answer:**

**Why it matters for StatefulSets more than Deployments:**

StatefulSets are used for clustered databases (MySQL, Kafka, etcd). If two replicas land on the same node and that node fails, you lose multiple cluster members simultaneously — potentially losing quorum.

For a 3-node etcd cluster, losing 2 nodes simultaneously means **loss of quorum and cluster unavailability**, not just reduced capacity.

**Anti-affinity manifest:**

```yaml
affinity:
  podAntiAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      - labelSelector:
          matchLabels:
            app: mysql
        topologyKey: kubernetes.io/hostname   # enforce: no two Pods on same node
    preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchLabels:
              app: mysql
          topologyKey: topology.kubernetes.io/zone  # prefer: spread across AZs
```

**Trade-off:**

| Policy | Behavior on Violation | Use When |
|--------|----------------------|----------|
| `requiredDuringScheduling` | Pod stays `Pending` indefinitely if constraint cannot be met | **Node-level anti-affinity** — never share a node. Cluster correctness depends on it. |
| `preferredDuringScheduling` | Scheduler tries to respect it but will violate if needed | **AZ-level spread** — best effort. Don't block scheduling if only 2 AZs have capacity. |

**Why not `required` for AZ-level too?**
If you require 3 separate AZs but only have 2 available (AZ capacity issues, spot interruptions), all Pods stay `Pending`. Prefer `preferred` at the AZ level to maintain availability at the cost of suboptimal placement.

---

### Q37. A team wants to run a 3-node Kafka cluster as a StatefulSet on EKS. What is your complete production readiness checklist?

**Answer:**

**Storage:**
- [ ] StorageClass with `volumeBindingMode: WaitForFirstConsumer` and `reclaimPolicy: Retain`
- [ ] EBS `gp3` volumes with provisioned IOPS (`iops: 3000`) for log segments
- [ ] `persistentVolumeClaimRetentionPolicy: whenDeleted: Retain, whenScaled: Retain`
- [ ] Separate PVC for data and logs if log volume is high

**Networking:**
- [ ] Headless Service (`clusterIP: None`) with `publishNotReadyAddresses: true`
- [ ] `KAFKA_ADVERTISED_LISTENERS` set to Pod's stable DNS name (`broker-0.kafka-svc.kafka.svc.cluster.local:9092`)
- [ ] Separate internal ClusterIP Service for client access (round-robin to all brokers)

**Scheduling:**
- [ ] `podAntiAffinity: required` on `kubernetes.io/hostname` (no two brokers on same node)
- [ ] `podAntiAffinity: preferred` on `topology.kubernetes.io/zone` (spread across AZs)
- [ ] Node selector or `nodeAffinity` to target storage-optimized instance family (e.g., `r6i`, `i3en`)

**Availability:**
- [ ] `PodDisruptionBudget` with `maxUnavailable: 1`
- [ ] `podManagementPolicy: Parallel` (Kafka brokers can start in any order)
- [ ] `terminationGracePeriodSeconds: 300` for graceful leader re-election before shutdown

**Update Strategy:**
- [ ] `updateStrategy.rollingUpdate.partition` set to `2` for staged rollout validation

**Security:**
- [ ] Dedicated ServiceAccount with IRSA for AWS MSK credential-less auth or S3 tiered storage
- [ ] `securityContext: runAsNonRoot: true`, `readOnlyRootFilesystem: false` (Kafka writes to disk)
- [ ] `NetworkPolicy` allowing only authorized clients to port 9092

**Observability:**
- [ ] JMX exporter sidecar or Prometheus JMX agent for broker metrics
- [ ] `ServiceMonitor` for Prometheus scraping
- [ ] CloudWatch Container Insights for node-level disk I/O metrics
- [ ] Alert on `UnderReplicatedPartitions > 0` and `ActiveControllerCount != 1`

**Resource:**
- [ ] `resources.requests == limits` (Guaranteed QoS) for broker Pods
- [ ] JVM heap set to ~50% of container memory limit via `KAFKA_HEAP_OPTS`

---

### Q38. During a StatefulSet rolling update, `Pod-1` is stuck in `Pending`. The rollout is blocked. Walk through your diagnosis and remediation.

**Answer:**

**Why a stuck Pod blocks a StatefulSet rollout:**
StatefulSet updates in reverse ordinal order and waits for each Pod to be `Running and Ready` before proceeding. A `Pending` Pod is an infinite wait — the update does not time out automatically.

**Step 1: Identify the state**
```bash
kubectl rollout status statefulset/mysql
# Waiting for 1 pods to be ready...

kubectl get pods -l app=mysql
# NAME      READY   STATUS    RESTARTS
# mysql-0   1/1     Running   0
# mysql-1   0/1     Pending   0         ← stuck here
# mysql-2   1/1     Running   0         ← already updated
```

**Step 2: Describe the Pending Pod**
```bash
kubectl describe pod mysql-1
# Look for Events section:
# Warning  FailedScheduling  ... 0/3 nodes available:
#   1 node had untolerated taint, 2 had insufficient memory
```

**Common Pending causes and fixes:**

| Root Cause | Evidence in `describe` | Fix |
|------------|------------------------|-----|
| **Insufficient node resources** | `Insufficient cpu/memory` | Add nodes, reduce requests, or add Cluster Autoscaler capacity |
| **EBS volume in wrong AZ** | `AttachVolume.Attach failed` | Check PV's `nodeAffinity` AZ vs available nodes in that AZ |
| **PVC not bound** | `pod has unbound PVCs` | Check StorageClass exists; check EBS CSI driver is installed |
| **Anti-affinity violation** | `node(s) didn't match pod anti-affinity rules` | A required anti-affinity rule has no satisfying nodes — relax to `preferred` or add nodes |
| **Taint/toleration mismatch** | `node had untolerated taint` | Add matching `tolerations` to the StatefulSet Pod spec |
| **ImagePullBackOff** (not Pending but blocks) | `Failed to pull image` | Check ECR permissions via IRSA, check image tag exists |

**Step 3: Immediate remediation if update must be aborted**

Use the `partition` field to freeze the update:
```bash
kubectl patch statefulset mysql -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":2}}}}'
# Now only mysql-2 (ordinal ≥ 2) is in the new version
# mysql-0 and mysql-1 are protected from further update attempts
```

This stops the rollout from progressing while you fix the underlying issue.

**Step 4: Fix the root cause, then resume**
```bash
# After fix (e.g., added nodes, fixed StorageClass):
kubectl patch statefulset mysql -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'
# Rollout resumes from mysql-1 downward
```

---

*Document prepared for Day 7 – Phase 3: EKS Core*
*Senior Engineer Knowledge Validation*

---

---

# Kubernetes Secrets Management – Senior Engineer Q&A
**Day 8 | Phase 3: EKS Core | Section 9 (1–4)**
**Date: 13-May-2026**

---

## Table of Contents

1. [Section 09-01: Kubernetes Secrets — Internals & Types](#section-09-01-kubernetes-secrets)
2. [Section 09-02: Consuming Secrets in Pods](#section-09-02-consuming-secrets-in-pods)
3. [Section 09-03: AWS Secrets Manager Integration (ESO & ASCP)](#section-09-03-aws-secrets-manager-integration)
4. [Section 09-04: IRSA — IAM Roles for Service Accounts](#section-09-04-irsa--iam-roles-for-service-accounts)
5. [Cross-Section / Architectural Scenarios](#cross-section--architectural-scenarios-1)

---

## Section 09-01: Kubernetes Secrets

---

### Q39. A Kubernetes Secret stores data as base64. How is that different from encryption, and what does EKS actually do to protect Secret data at rest?

**Answer:**

**Base64 is NOT encryption.** It is a reversible encoding — anyone who can read the etcd entry can decode it in one command:
```bash
echo "cGFzc3dvcmQ=" | base64 -d   # → password
```

**Three layers to understand:**

| Layer | What It Is | EKS Behavior |
|-------|-----------|--------------|
| **etcd storage** | Raw bytes stored in etcd | EKS **encrypts etcd at rest** using AES-256 via AWS KMS (envelope encryption). This is enabled by default — you can specify your own CMK during cluster creation. |
| **API server in-flight** | Secrets transmitted between etcd and API server | TLS-encrypted (always). |
| **In memory on nodes** | Secret data mounted into `tmpfs` (RAM) volumes | kubelet mounts secrets into an in-memory `tmpfs` volume per Pod — data is never written to the node's disk. |

**Practical implication:** EKS etcd encryption protects against a raw etcd dump (e.g., compromised backup). It does **not** protect against:
- A user/process with `kubectl get secret` permission — RBAC is your control here.
- A compromised container that reads `/run/secrets/` — use `readOnlyRootFilesystem` and limit Secret RBAC.

**Production baseline:** etcd encryption + RBAC `get`/`list` on Secrets restricted to only the Pods/SAs that need them + audit logging for Secret access.

---

### Q40. What are the built-in Secret types in Kubernetes? When would you create each one?

**Answer:**

| Type | `type:` field | Purpose | When to Use |
|------|--------------|---------|-------------|
| **Opaque** | `Opaque` | Arbitrary user-defined key-value data | Default — use for passwords, API keys, connection strings |
| **Service Account Token** | `kubernetes.io/service-account-token` | Token bound to a SA (legacy, pre-1.22) | Avoid — use projected SA tokens (`automountServiceAccountToken`) instead |
| **Docker Registry** | `kubernetes.io/dockerconfigjson` | Pull credentials for a private registry | Pulling images from a private ECR registry without IRSA |
| **TLS** | `kubernetes.io/tls` | TLS certificate and private key (`tls.crt`, `tls.key`) | Ingress TLS termination, cert-manager managed certs |
| **Basic Auth** | `kubernetes.io/basic-auth` | `username` and `password` fields | Legacy systems requiring HTTP Basic Auth |
| **SSH Auth** | `kubernetes.io/ssh-auth` | `ssh-privatekey` field | Git operations over SSH from within a Pod |
| **Bootstrap Token** | `bootstrap.kubernetes.io/token` | Node bootstrap tokens | Cluster bootstrapping; managed by kubeadm |

**EKS + ECR pattern:** Instead of `dockerconfigjson` Secrets (which expire every 12 hours for ECR), attach an IAM policy to the node IAM role allowing `ecr:GetAuthorizationToken`. The kubelet handles credential refresh automatically. Even better: use IRSA on a dedicated `imagepuller` ServiceAccount.

---

### Q41. What is the 1 MiB size limit on Secrets and what architectural consequence does it have?

**Answer:**

Kubernetes enforces a **1 MiB (1,048,576 byte)** limit per Secret object — the same limit as ConfigMaps. This applies to the total size of all key-value data combined.

**Why the limit exists:** All Secrets flow through etcd. etcd has a default 1.5 MiB max object size, and large objects stress the etcd watch API (every kube-proxy and kubelet subscribing to changes). Kubernetes conservatively caps at 1 MiB to protect etcd performance.

**Architectural consequences:**

| Scenario | Problem |
|----------|---------|
| TLS certificate chains with intermediate CAs | A full cert bundle can approach 10–50 KB — still fine, but large CA bundles can accumulate |
| Storing a large JSON config blob as a Secret | Can hit limits; move to ConfigMap (non-sensitive) or external store |
| Storing entire Terraform state or database dumps | Wrong tool — use S3 |
| Many microservices' secrets in a single Secret | Anti-pattern — use one Secret per service for RBAC isolation |

**Best practice:** One Secret per service, scoped tightly. Large binary blobs (keystores, PKCS12) should live in AWS Secrets Manager and be fetched at runtime, not stored as K8s Secrets.

---

### Q42. How does Kubernetes RBAC control access to Secrets, and why are Secrets riskier than ConfigMaps from an RBAC perspective?

**Answer:**

Secrets use standard RBAC verbs: `get`, `list`, `watch`, `create`, `update`, `patch`, `delete`.

**The critical risk with `list` and `watch`:**

```yaml
# DANGEROUS — grants access to ALL Secrets in the namespace
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: ["list", "watch"]
```

`list` on Secrets returns the **full data** of every Secret in the namespace — not just names. A single over-permissive ClusterRole can leak every credential in the cluster.

**ConfigMaps are different:** `list` on ConfigMaps is often granted broadly (e.g., for service discovery). That's acceptable because ConfigMaps hold non-sensitive data. Applying the same permissiveness to Secrets is dangerous.

**Least-privilege pattern for Secrets:**

```yaml
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    resourceNames: ["catalog-db-credentials"]   # specific Secret name
    verbs: ["get"]                               # only get, not list
```

`resourceNames` restricts to a specific Secret. This prevents a compromised ServiceAccount from enumerating all Secrets in the namespace.

**EKS audit logging:** Enable CloudTrail + EKS audit logs and alert on `list` verb against `secrets` resource from unexpected principals — this is a common indicator of credential harvesting.

---

## Section 09-02: Consuming Secrets in Pods

---

### Q43. What are the two ways to consume a Secret in a Pod, and what are the security trade-offs of each?

**Answer:**

| Method | Mechanism | Security Risk | Best For |
|--------|-----------|--------------|---------|
| **Environment variable** (`env.valueFrom.secretKeyRef` or `envFrom`) | Secret injected as an env var at container start | Visible in `kubectl exec -- env`, `/proc/<pid>/environ`, crash dumps, debug tools. Child processes inherit all env vars. | Legacy apps that only read config from env |
| **Volume mount** | Secret keys become files in a `tmpfs` volume | Only readable by processes with access to the mounted path. Not in env. Not inherited by child processes. Supports file permissions (`defaultMode`). | Modern apps, database passwords, TLS certs, SSH keys |

**Volume mount example with restricted permissions:**
```yaml
volumes:
  - name: db-creds
    secret:
      secretName: catalog-db-credentials
      defaultMode: 0400   # owner read-only (octal)
volumeMounts:
  - name: db-creds
    mountPath: /run/secrets/db
    readOnly: true
```

**Hot reload with volume mounts:** Unlike ConfigMaps, Secret volume mounts are **also updated automatically** by the kubelet when the Secret changes (~1 minute sync delay). Apps that watch the file can pick up rotated credentials without restart.

**Never use `envFrom` for Secrets** — it dumps all keys into env, including any future keys added to the Secret. Volume mounts with `defaultMode: 0400` are the secure default.

---

### Q44. What is `imagePullSecrets`? When is it needed on EKS, and when can you skip it?

**Answer:**

`imagePullSecrets` references a `kubernetes.io/dockerconfigjson` Secret that the kubelet uses to authenticate to a private container registry when pulling images.

```yaml
spec:
  imagePullSecrets:
    - name: ecr-pull-secret
  containers:
    - name: app
      image: 123456789.dkr.ecr.us-east-1.amazonaws.com/catalog:v1.0
```

**When you need it on EKS:**
- Pulling from a **cross-account ECR registry** (your node's IAM role doesn't have permissions to the other account's ECR).
- Pulling from a **non-AWS registry** (Docker Hub, GitHub Container Registry, JFrog Artifactory).
- Using a **public ECR image with rate-limit concerns** via authenticated pull.

**When you can skip it on EKS:**
- Pulling from **ECR in the same AWS account** — the node IAM role (created by EKS managed node groups) has `ecr:GetAuthorizationToken` and `ecr:BatchGetImage` permissions by default. kubelet uses the node role to authenticate transparently.

**ECR token expiry problem:** ECR tokens are valid for 12 hours. A `dockerconfigjson` Secret with a hardcoded ECR token will expire. Solutions:
1. **Node IAM role** (recommended for same-account ECR) — no expiry issue.
2. **`amazon-ecr-credential-helper`** — refreshes tokens automatically on the node.
3. **External Secrets Operator** to rotate the `imagePullSecret` from AWS Secrets Manager.

---

### Q45. A Secret's data changes (password rotated). How does a running Pod pick up the new value? What are the gaps?

**Answer:**

**Volume-mounted Secrets — automatic update:**
- The kubelet **syncs mounted Secret volumes periodically** (default: every 1 minute, configurable via `--sync-frequency`).
- The file in `/run/secrets/db/password` is **atomically replaced** (symlink swap via a `.data` temp directory).
- Apps watching the file with `inotify` or polling pick up the new value.
- **Gap:** ~1 minute lag between Secret update and file update in the Pod.

**Environment variable Secrets — NO automatic update:**
- Env vars are set at container start from the Secret value at that moment.
- A Secret update does **not** update env vars in a running container.
- **Only fix:** Rolling restart (`kubectl rollout restart deployment/catalog`).

**The deeper production gap — connection pools:**
Even if the file updates, the app must actually re-read and use the new credential. Most database drivers hold a connection pool with the old credentials until connections are recycled. Options:
- App implements a file-watch loop that reloads the credential and reconnects.
- Use `stakater/Reloader` to trigger a rolling restart automatically on Secret change.
- Use a **connection proxy** (e.g., AWS RDS Proxy) that handles credential rotation transparently — the app always authenticates to the proxy with a static token.

**AWS Secrets Manager rotation best practice:**
1. Rotate secret in AWS Secrets Manager.
2. External Secrets Operator syncs the new value to the K8s Secret.
3. `stakater/Reloader` detects the K8s Secret change and triggers a Deployment rollout.
4. New Pods start with the new credential.

---

## Section 09-03: AWS Secrets Manager Integration

---

### Q46. What is the External Secrets Operator (ESO)? How does it differ from the AWS Secrets and Config Provider (ASCP)?

**Answer:**

Both tools bridge AWS Secrets Manager / SSM Parameter Store to Kubernetes Pods, but via different mechanisms:

| Aspect | External Secrets Operator (ESO) | AWS Secrets and Config Provider (ASCP) |
|--------|--------------------------------|---------------------------------------|
| **How it works** | Runs as a controller. Syncs AWS secrets → Kubernetes `Secret` objects on a schedule | CSI driver sidecar. Mounts secrets directly as files into Pod volumes — no K8s Secret object created |
| **K8s Secret object created?** | Yes — creates/updates a standard `Secret` | No (by default) — bypasses the K8s Secret entirely |
| **RBAC surface** | K8s Secret exists and can be `get`-ted via kubectl | No K8s Secret object — harder to accidentally expose via misconfigured RBAC |
| **Rotation handling** | Polls on a configurable `refreshInterval` (e.g., `1h`). Updates the K8s Secret. | Pod must be restarted OR use `autoRotation: true` which remounts the file on change. |
| **Multi-provider support** | Yes — AWS, GCP, Azure, Vault, HashiCorp | AWS-only |
| **Complexity** | Higher (CRDs: `SecretStore`, `ExternalSecret`) | Lower (annotation-based) |
| **EKS best practice** | Preferred for teams wanting GitOps-friendly `ExternalSecret` CRDs | Preferred for max security (no K8s Secret object) or when operator overhead is unwanted |

**ESO `ExternalSecret` CRD:**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: catalog-db-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: catalog-db-credentials     # K8s Secret name to create
  data:
    - secretKey: DB_PASSWORD         # key in K8s Secret
      remoteRef:
        key: prod/catalog/db         # AWS Secrets Manager secret name
        property: password           # JSON field within the secret
```

---

### Q47. Walk through how the AWS Secrets and Config Provider (ASCP) mounts a secret from AWS Secrets Manager into a Pod without creating a Kubernetes Secret object.

**Answer:**

**Components:**
1. **Secrets Store CSI Driver** — a DaemonSet on every node that handles `SecretProviderClass` volume requests.
2. **AWS Provider plugin** — runs alongside the CSI driver, makes AWS API calls.
3. **`SecretProviderClass`** — CRD defining which secrets to fetch and from where.
4. **IRSA** — the Pod's ServiceAccount must have an IAM role with `secretsmanager:GetSecretValue` permission.

**Step-by-step flow:**

1. Pod is created with a CSI volume referencing a `SecretProviderClass`.
2. kubelet calls the **Secrets Store CSI Driver** on the node to mount the volume.
3. The CSI driver reads the `SecretProviderClass` spec and calls the **AWS Provider**.
4. The AWS Provider calls `secretsmanager:GetSecretValue` using the **Pod's IRSA token** (projected from the SA token volume).
5. The secret value is written to a `tmpfs` (in-memory) directory on the node.
6. The CSI driver bind-mounts that `tmpfs` path into the Pod at the specified `mountPath`.
7. The file is now readable inside the Pod at e.g. `/mnt/secrets/db-password`.

**Manifest:**
```yaml
# SecretProviderClass
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: catalog-aws-secrets
spec:
  provider: aws
  parameters:
    objects: |
      - objectName: "prod/catalog/db"
        objectType: "secretsmanager"
        jmesPath:
          - path: password
            objectAlias: db-password

---
# Pod volume spec
volumes:
  - name: secrets-store
    csi:
      driver: secrets-store.csi.k8s.io
      readOnly: true
      volumeAttributes:
        secretProviderClass: catalog-aws-secrets
volumeMounts:
  - name: secrets-store
    mountPath: /mnt/secrets
    readOnly: true
```

**Security advantage:** No K8s Secret object is ever created. The secret exists only in AWS Secrets Manager and in-memory on the node/Pod. A `kubectl get secrets` shows nothing.

---

### Q48. How does AWS Secrets Manager secret rotation interact with ASCP and ESO? What is the risk window during rotation?

**Answer:**

**AWS Secrets Manager rotation** invokes a Lambda function to:
1. Create a new secret version (`AWSPENDING`).
2. Update the resource (e.g., change the DB password).
3. Promote the new version to `AWSCURRENT`.
4. (Optionally) deprecate the old version.

**ASCP rotation handling:**
- ASCP can be configured with `autoRotation: true` in the `SecretProviderClass` and `rotationPollIntervalInSeconds`.
- The CSI driver re-fetches the secret and atomically replaces the mounted file.
- The Pod does **not restart** — but the app must re-read the file.
- **Risk window:** From the moment AWS rotates the DB password (`AWSCURRENT` changes) to the moment ASCP remounts the file, any new DB connection attempt with the old cached credential fails.

**ESO rotation handling:**
- ESO polls on `refreshInterval` (e.g., `1h`). It updates the K8s Secret with the new value.
- A `stakater/Reloader` annotation triggers a Deployment rollout.
- The rolling restart replaces Pods using the new credential.
- **Risk window:** Up to `refreshInterval` + time for rollout. During this window, the K8s Secret holds the old value.

**Mitigation — dual-active window:**
AWS Secrets Manager supports a rotation **overlap window** where both old and new credentials are simultaneously valid at the database level. This is configured in the rotation Lambda:
- The DB user's password is updated in the new version.
- The old version remains `AWSPREVIOUS` and is still accepted by the DB for a grace period.
- This eliminates the risk window — old and new credentials both work during rotation.

**RDS Proxy removes the problem entirely:** RDS Proxy handles credential rotation transparently. The app always connects to the proxy using IAM authentication (no password at all), and the proxy manages the actual DB credentials.

---

## Section 09-04: IRSA — IAM Roles for Service Accounts

---

### Q49. What is IRSA (IAM Roles for Service Accounts) and why is it fundamentally more secure than using the node IAM role for AWS API access?

**Answer:**

**Node IAM role (old approach):**
- Every Pod on a node inherits the EC2 instance's IAM role.
- Credentials are fetched from the instance metadata endpoint: `http://169.254.169.254/latest/meta-data/iam/security-credentials/`.
- **Problem:** All Pods on the node share the same IAM permissions — if `catalog` needs S3 access, every Pod on that node (including compromised ones) also has S3 access.

**IRSA (IAM Roles for Service Accounts):**
- A Kubernetes ServiceAccount is annotated with an AWS IAM role ARN.
- EKS's OIDC provider issues a **projected ServiceAccount token** (JWT) to the Pod.
- The Pod exchanges this JWT with AWS STS (`sts:AssumeRoleWithWebIdentity`) to get temporary credentials scoped to **only that IAM role**.
- Credentials are **Pod-scoped**, not node-scoped.

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: catalog-sa
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/catalog-secrets-role
```

**Security comparison:**

| Aspect | Node IAM Role | IRSA |
|--------|-------------|------|
| Scope | All Pods on node | Single ServiceAccount (and its Pods) |
| Blast radius if compromised | All workloads on node | Only that SA's Pods |
| Least privilege | Hard to achieve | Per-service IAM roles |
| Credential rotation | EC2 rotates every few hours | STS tokens expire in 1 hour (configurable) |
| Audit trail | CloudTrail shows node role | CloudTrail shows specific SA name in session name |

**EKS requirement:** The cluster must have an OIDC provider configured (`eksctl utils associate-iam-oidc-provider`).

---

### Q50. Walk through the full token exchange flow when a Pod with IRSA calls AWS Secrets Manager. What prevents a malicious Pod from stealing another Pod's IRSA credentials?

**Answer:**

**Full flow:**

1. **Pod starts:** kubelet projects a **ServiceAccount token** into the Pod at `/var/run/secrets/eks.amazonaws.com/serviceaccount/token`.
   - This is a **short-lived JWT** (expires in 1 hour by default) signed by the EKS OIDC provider.
   - The JWT contains claims: `sub: system:serviceaccount:default:catalog-sa`, `aud: sts.amazonaws.com`.

2. **AWS SDK reads the token:** The AWS SDK automatically reads `AWS_WEB_IDENTITY_TOKEN_FILE` and `AWS_ROLE_ARN` env vars (injected by the EKS pod identity webhook).

3. **STS AssumeRoleWithWebIdentity:** The SDK calls:
   ```
   sts:AssumeRoleWithWebIdentity
     WebIdentityToken: <JWT from file>
     RoleArn: arn:aws:iam::123456789:role/catalog-secrets-role
   ```

4. **STS validates the JWT:** AWS STS calls the EKS OIDC endpoint (`oidc.eks.<region>.amazonaws.com/id/<cluster-id>`) to verify the JWT signature and claims.

5. **IAM role trust policy is evaluated:**
   ```json
   {
     "Condition": {
       "StringEquals": {
         "oidc.eks.us-east-1.amazonaws.com/id/CLUSTER_ID:sub":
           "system:serviceaccount:default:catalog-sa"
       }
     }
   }
   ```
   This condition ensures **only** the `catalog-sa` ServiceAccount in the `default` namespace can assume this role.

6. **STS returns temporary credentials** (AccessKeyId, SecretAccessKey, SessionToken) valid for 1 hour.

7. **SDK calls `secretsmanager:GetSecretValue`** with these temporary credentials.

**What prevents a malicious Pod from stealing credentials:**

- The JWT is **Pod-specific** — it encodes the ServiceAccount name. A Pod using a different ServiceAccount gets a different JWT.
- The **IAM trust policy `Condition`** enforces the ServiceAccount constraint. Even if a malicious Pod somehow obtained the JWT, it would have to assume the same role — which STS only grants to the matching `sub` claim.
- JWTs are **short-lived** (1 hour) — captured tokens expire quickly.
- The **OIDC provider URL is unique per cluster** — a JWT from one EKS cluster cannot be used against a trust policy configured for a different cluster.
- IMDSv2 is recommended to **block access to the instance metadata endpoint from Pods** (prevents node role credential theft via `169.254.169.254`):
  ```
  eks.amazonaws.com/compute-type: ec2
  # + enforce IMDSv2 hop limit of 1 on the node
  ```

---

### Q51. How do you create an IRSA-enabled ServiceAccount for the Catalog service that can read a specific secret from AWS Secrets Manager? Show the complete setup.

**Answer:**

**Step 1: Create the IAM policy**
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"],
    "Resource": "arn:aws:iam::123456789:secret:prod/catalog/db-*"
  }]
}
```
`*` at the end matches version suffixes AWS Secrets Manager appends (e.g., `-AbCdEf`).

**Step 2: Create the IAM role with OIDC trust policy**
```bash
eksctl create iamserviceaccount \
  --cluster=my-eks-cluster \
  --namespace=default \
  --name=catalog-sa \
  --attach-policy-arn=arn:aws:iam::123456789:policy/CatalogSecretsPolicy \
  --approve
```
`eksctl` creates the IAM role, configures the OIDC trust policy, and creates the annotated ServiceAccount in one step.

**Step 3: Verify the ServiceAccount annotation**
```bash
kubectl get serviceaccount catalog-sa -o yaml
# metadata.annotations:
#   eks.amazonaws.com/role-arn: arn:aws:iam::123456789:role/eksctl-my-eks-cluster-addon-iamserviceaccount-default-catalog-sa-Role1-...
```

**Step 4: Reference the ServiceAccount in the Deployment**
```yaml
spec:
  serviceAccountName: catalog-sa
  containers:
    - name: catalog
      env:
        - name: AWS_REGION
          value: us-east-1
```
The EKS pod identity webhook automatically injects `AWS_WEB_IDENTITY_TOKEN_FILE` and `AWS_ROLE_ARN` when it sees a ServiceAccount with the IRSA annotation.

**Step 5: Verify in the Pod**
```bash
kubectl exec -it catalog-pod -- env | grep AWS
# AWS_ROLE_ARN=arn:aws:iam::123456789:role/...
# AWS_WEB_IDENTITY_TOKEN_FILE=/var/run/secrets/eks.amazonaws.com/serviceaccount/token

# Test the actual secret access:
kubectl exec -it catalog-pod -- \
  aws secretsmanager get-secret-value --secret-id prod/catalog/db --region us-east-1
```

---

## Cross-Section / Architectural Scenarios

---

### Q52. A developer accidentally committed a database password into a Kubernetes Secret as plaintext in a YAML file in Git. The Secret has been applied to production. What is your incident response process?

**Answer:**

**Immediate actions (within minutes):**

1. **Rotate the credential** — change the database password immediately. This is the highest priority; RBAC/audit are secondary.
   ```bash
   # For RDS:
   aws rds modify-db-instance --db-instance-identifier catalog-db \
     --master-user-password "$(openssl rand -base64 32)"
   ```

2. **Update the K8s Secret** with the new password:
   ```bash
   kubectl create secret generic catalog-db-credentials \
     --from-literal=password="<new-password>" \
     --dry-run=client -o yaml | kubectl apply -f -
   ```

3. **Rolling restart** the Deployment to pick up the new Secret:
   ```bash
   kubectl rollout restart deployment/catalog
   ```

**Git remediation (do not just delete the file — history must be cleaned):**

4. **Remove from Git history** using BFG Repo Cleaner or `git filter-repo`:
   ```bash
   git filter-repo --path path/to/secret.yaml --invert-paths
   # Force-push (coordinate with team):
   git push origin --force --all
   git push origin --force --tags
   ```

5. **Invalidate all clones** — notify all team members to re-clone. Cached copies of the old history must be destroyed.

6. **Revoke any GitHub/GitLab tokens** if the secret was also in a pipeline secret exposed in logs.

**Root cause prevention:**

| Control | Tool |
|---------|------|
| Pre-commit hook to detect secrets | `detect-secrets`, `gitleaks`, `trufflehog` |
| Seal secrets before committing | `Sealed Secrets` (Bitnami) — encrypts Secret YAML with cluster public key so committed YAML is safe |
| Migrate to AWS Secrets Manager | Eliminate K8s Secret YAML files entirely; use `ExternalSecret` CRDs referencing AWS |
| SAST in CI | `git-secrets`, `talisman` in the PR pipeline |

---

### Q53. Compare Sealed Secrets vs External Secrets Operator vs ASCP. When would you recommend each to a team?

**Answer:**

| | Sealed Secrets | External Secrets Operator | ASCP |
|--|--------------|--------------------------|------|
| **What it solves** | Allows encrypted Secret YAML to be safely committed to Git | Syncs secrets from AWS/GCP/Azure/Vault into K8s Secrets | Mounts AWS secrets directly into Pod volumes (no K8s Secret) |
| **Where secrets live** | Encrypted in Git, decrypted by the `SealedSecret` controller in-cluster | AWS Secrets Manager / SSM Parameter Store | AWS Secrets Manager / SSM Parameter Store |
| **K8s Secret created?** | Yes | Yes | No (by default) |
| **GitOps compatibility** | Excellent — SealedSecret YAML is safe to commit | Excellent — `ExternalSecret` CRD is safe to commit (no actual secret data) | Good — `SecretProviderClass` CRD is safe to commit |
| **AWS dependency** | No — works on any K8s cluster | Yes — needs AWS (or other provider) | Yes — AWS-only |
| **Rotation handling** | Manual — re-seal and re-apply | Automatic via `refreshInterval` | Automatic via `rotationPollIntervalInSeconds` |
| **When to choose** | Air-gapped clusters, no external secret store, team wants secrets-as-code in Git | Multi-cloud, or want secrets visible/auditable as K8s Secret objects, or using GitOps | Maximum security (no K8s Secret API surface), AWS-native teams |

**Decision tree:**
```
Need secrets in Git?
  └─ Yes → Sealed Secrets (or use ESO with no secret values in Git)
Need multi-cloud?
  └─ Yes → ESO
AWS-only + maximum security (no K8s Secret object)?
  └─ Yes → ASCP
AWS-only + GitOps + want K8s Secret for app compatibility?
  └─ Yes → ESO
```

---

### Q54. Design a complete production secrets architecture for the Catalog service on EKS — from developer workflow to running Pod — using AWS-native tooling.

**Answer:**

**Architecture overview:**

```
Developer → AWS Secrets Manager → ESO / ASCP → Pod
               (source of truth)    (sync)     (consumption)
```

**1. Secret Creation (operator workflow):**
```bash
# One-time: create secret in AWS Secrets Manager
aws secretsmanager create-secret \
  --name prod/catalog/db \
  --secret-string '{"host":"catalog-db.cluster.us-east-1.rds.amazonaws.com","username":"catalog","password":"InitialPass123!"}'

# Enable automatic rotation (30-day cycle)
aws secretsmanager rotate-secret \
  --secret-id prod/catalog/db \
  --rotation-lambda-arn arn:aws:lambda:us-east-1:123456789:function:SecretsManagerRDSRotation \
  --rotation-rules AutomaticallyAfterDays=30
```

**2. IRSA Setup:**
```bash
eksctl create iamserviceaccount \
  --cluster=prod-eks \
  --namespace=catalog \
  --name=catalog-sa \
  --attach-policy-arn=arn:aws:iam::123456789:policy/CatalogSecretsReadPolicy \
  --approve
```

**3. External Secrets Operator sync (GitOps-safe CRD):**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: catalog-db-secret
  namespace: catalog
  annotations:
    reloader.stakater.com/match: "true"    # triggers rolling restart on Secret change
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager-store
    kind: ClusterSecretStore
  target:
    name: catalog-db-credentials
    creationPolicy: Owner
  data:
    - secretKey: DB_HOST
      remoteRef:
        key: prod/catalog/db
        property: host
    - secretKey: DB_PASSWORD
      remoteRef:
        key: prod/catalog/db
        property: password
```

**4. Deployment consumption (volume mount, not env var):**
```yaml
spec:
  serviceAccountName: catalog-sa
  volumes:
    - name: db-secrets
      secret:
        secretName: catalog-db-credentials
        defaultMode: 0400
  containers:
    - name: catalog
      volumeMounts:
        - name: db-secrets
          mountPath: /run/secrets/db
          readOnly: true
```

**5. Automatic rotation flow:**
```
AWS Secrets Manager rotates secret (every 30 days)
  → ESO picks up new value within refreshInterval (1h)
  → ESO updates K8s Secret `catalog-db-credentials`
  → stakater/Reloader detects Secret change
  → Triggers rolling restart of `catalog` Deployment
  → New Pods mount the new credential
```

**Security controls in place:**
- Secrets never in Git (only `ExternalSecret` CRD with no values)
- etcd encryption via KMS (EKS default)
- IRSA: Pod-scoped IAM permissions (not node-level)
- Secret mounted as file (`0400`) not env var
- Rotation automated — no manual credential management
- CloudTrail audit on `secretsmanager:GetSecretValue` calls

---

*Document prepared for Day 8 – Phase 3: EKS Core*
*Senior Engineer Knowledge Validation*

---

---

# Kubernetes Persistent Storage – Senior Engineer Q&A
**Day 9 | Phase 3: EKS Core | Section 10 (1–3)**
**Date: 14-May-2026**

---

## Table of Contents

1. [Section 10-01: Kubernetes Volumes](#section-10-01-kubernetes-volumes)
2. [Section 10-02: PersistentVolumes and PersistentVolumeClaims](#section-10-02-persistentvolumes-and-persistentvolumeclaims)
3. [Section 10-03: StorageClass and Dynamic Provisioning](#section-10-03-storageclass-and-dynamic-provisioning)
4. [Cross-Section / Architectural Scenarios](#cross-section--architectural-scenarios-2)

---

## Section 10-01: Kubernetes Volumes

---

### Q55. What is the fundamental difference between an ephemeral volume and a persistent volume in Kubernetes? Name all ephemeral volume types and their primary use cases.

**Answer:**

**Ephemeral volumes** are tied to the Pod's lifetime — they are created when the Pod starts and destroyed when the Pod is deleted (regardless of why). No data survives Pod deletion.

**Persistent volumes** exist independently of any Pod. A Pod can be deleted, rescheduled, or restarted and the data remains intact on the underlying storage.

**Ephemeral volume types:**

| Type | Storage Backend | Lifetime | Primary Use Case |
|------|---------------|---------|-----------------|
| `emptyDir` | Node disk (or RAM) | Pod lifetime | Scratch space, inter-container file sharing within a Pod |
| `hostPath` | Node filesystem | Pod lifetime (data survives Pod deletion on same node) | Node-level logging agents, DaemonSets needing host access |
| `configMap` | etcd → kubelet | Pod lifetime | Inject config files into Pods |
| `secret` | etcd → kubelet (tmpfs) | Pod lifetime | Inject credentials as files |
| `downwardAPI` | Generated by kubelet | Pod lifetime | Expose Pod metadata (labels, annotations, resource limits) as files |
| `projected` | Combined sources | Pod lifetime | Merge multiple sources (SA token + secret + configMap) into one mount |
| `ephemeral` (generic CSI) | CSI driver | Pod lifetime | Inline CSI volumes without PVC overhead — scratch space backed by any CSI driver |

**Key distinction from persistent volumes:** None of the above types survive Pod deletion on their own. Even `hostPath` data survives on that specific node but is unreachable if the Pod is rescheduled elsewhere.

---

### Q56. Explain `emptyDir` in depth — its lifecycle, storage backend options, and when to choose `medium: Memory` over the default disk backend.

**Answer:**

**Lifecycle:**
- Created when the Pod is assigned to a node (before any container starts).
- Shared across **all containers in the Pod** — any container can read/write to it.
- Destroyed when the Pod is deleted from the node (not just restarted — restarts keep the data).
- Each container in the Pod can mount it at different paths.

**Storage backend options:**

```yaml
volumes:
  - name: scratch
    emptyDir: {}           # default: node's disk (the kubelet root filesystem)

  - name: ramdisk
    emptyDir:
      medium: Memory       # backed by tmpfs (RAM)
      sizeLimit: 256Mi     # cap RAM usage; enforced by kubelet
```

| Backend | Persistence on container restart | Performance | Node resource used | When to use |
|---------|----------------------------------|-------------|-------------------|-------------|
| Default (disk) | Yes | Disk I/O speed | Disk space | Large scratch files, build caches, log buffers |
| `Memory` (tmpfs) | Yes (until Pod deleted) | Memory speed (much faster) | RAM | Sensitive data (not written to disk), high-throughput temp data, small fast scratch buffers |

**`medium: Memory` key behaviors:**
- Data is never written to the node's disk — good for secrets or data that must not be persisted.
- Counts against the container's memory limit. If the container writes 200 MiB to the tmpfs and its limit is 256 MiB, it can OOM.
- Always set `sizeLimit` — without it, a runaway process can fill node RAM.

**Production use cases for `emptyDir`:**
- **Sidecar log collection:** App writes to `emptyDir`, log-shipper sidecar reads and forwards to CloudWatch.
- **Init container handoff:** Init container clones a git repo or renders templates into `emptyDir`; app container reads the output.
- **Cache warming:** App downloads a dataset once into `emptyDir` and uses it across restarts within the same Pod scheduling.

---

### Q57. What is a `hostPath` volume? Why is it dangerous in production, and when is it a legitimate choice?

**Answer:**

A `hostPath` volume mounts a file or directory from the **host node's filesystem** directly into the Pod.

```yaml
volumes:
  - name: docker-sock
    hostPath:
      path: /var/run/docker.sock
      type: Socket
```

**`hostPath` type options:**

| `type` | Behavior |
|--------|---------|
| `""` (empty) | No check — mount whatever exists at the path |
| `DirectoryOrCreate` | Create directory if it doesn't exist |
| `Directory` | Must already exist as a directory |
| `FileOrCreate` | Create file if it doesn't exist |
| `File` | Must already exist as a file |
| `Socket` | Must exist as a Unix socket |
| `BlockDevice` | Must exist as a block device |

**Why it's dangerous:**

| Risk | Explanation |
|------|-------------|
| **Container escape** | A compromised container with `hostPath: /` mounted has access to the entire node filesystem, including `kubelet` credentials and container runtime sockets |
| **Node coupling** | Pod is tied to a specific node (data only exists on that node) — breaks rescheduling |
| **Privilege escalation** | Mounting `/etc` allows reading `/etc/shadow`; mounting `/proc` allows kernel-level attacks |
| **No portability** | Assumes the path exists on every node the Pod might land on |
| **OPA Gatekeeper / Kyverno** | Most cluster policies (CIS Benchmark) deny `hostPath` unless specifically allowlisted |

**Legitimate production use cases:**

| Use Case | What is mounted | Why acceptable |
|----------|----------------|---------------|
| **DaemonSet log collectors** (Fluentd, Fluent Bit) | `/var/log/pods`, `/var/lib/docker/containers` | Node-scoped agents intentionally need node logs |
| **Prometheus Node Exporter** | `/proc`, `/sys` | Intentionally needs kernel metrics — runs as DaemonSet with known risk |
| **CNI plugins** | `/etc/cni/net.d`, `/opt/cni/bin` | Must install binaries onto node filesystem |
| **CSI drivers** (DaemonSet) | `/var/lib/kubelet/plugins` | Must register CSI sockets with kubelet |

**EKS practice:** Deny unrestricted `hostPath` via OPA Gatekeeper. Allowlist only specific safe paths for DaemonSets via policy exceptions.

---

### Q58. What is a `projected` volume? What sources can it combine, and why is this pattern useful in production?

**Answer:**

A `projected` volume maps multiple volume sources into a **single directory** inside a container — eliminating the need for multiple mounts.

**Supported sources:**

| Source | What it provides |
|--------|----------------|
| `secret` | Secret keys as files |
| `configMap` | ConfigMap keys as files |
| `serviceAccountToken` | A projected short-lived SA token (audience + expiry configurable) |
| `downwardAPI` | Pod metadata fields (labels, annotations, resource limits) as files |
| `clusterTrustBundle` | CA certificates from ClusterTrustBundle objects (k8s 1.27+) |

**Example — mount SA token + CA bundle for AWS API calls:**
```yaml
volumes:
  - name: aws-iam-token
    projected:
      sources:
        - serviceAccountToken:
            audience: sts.amazonaws.com
            expirationSeconds: 86400
            path: token
        - configMap:
            name: aws-ca-bundle
            items:
              - key: ca.crt
                path: ca.crt
        - downwardAPI:
            items:
              - path: namespace
                fieldRef:
                  fieldPath: metadata.namespace
```

**Why this is useful:**

1. **IRSA token injection:** The EKS pod identity webhook uses a projected `serviceAccountToken` volume to give Pods a short-lived JWT for `sts:AssumeRoleWithWebIdentity`. This is how IRSA works under the hood.
2. **Reduced mount proliferation:** Instead of 4 separate `volumeMounts` for 4 sources, you get one clean mount point with a logical directory structure.
3. **Token audience scoping:** `serviceAccountToken` in a projected volume lets you request a token for a specific audience (e.g., `sts.amazonaws.com`) rather than the default kube-apiserver audience. This is critical for IRSA security.
4. **Short-lived tokens:** Projected SA tokens rotate automatically before `expirationSeconds` expires — no manual secret rotation needed.

---

### Q59. What does the `downwardAPI` volume expose, and how does it differ from environment variables set via `fieldRef`?

**Answer:**

Both the `downwardAPI` volume and `env.fieldRef` expose **Pod metadata to the container** — but they differ in what they can expose and how.

**What can be exposed:**

| Field | Volume (`downwardAPI`) | Env var (`fieldRef`) |
|-------|----------------------|-------------------|
| Pod name | Yes | Yes |
| Pod namespace | Yes | Yes |
| Pod IP | Yes | Yes |
| Node name | Yes | Yes |
| Pod UID | Yes | Yes |
| Pod labels | **Yes (only via volume)** | No |
| Pod annotations | **Yes (only via volume)** | No |
| Container resource limits/requests | Yes (`resourceFieldRef`) | Yes (`resourceFieldRef`) |

**Key difference — labels and annotations:**

Labels and annotations can change at runtime (via `kubectl label` or `kubectl annotate`). Since env vars are set at container start and never updated, they cannot reliably expose mutable metadata. The **volume approach atomically updates the file** when the annotation or label changes — the app can read the new value without restarting.

**Example — expose annotations as a file:**
```yaml
volumes:
  - name: podinfo
    downwardAPI:
      items:
        - path: annotations
          fieldRef:
            fieldPath: metadata.annotations
        - path: cpu-limit
          resourceFieldRef:
            containerName: catalog
            resource: limits.cpu
volumeMounts:
  - name: podinfo
    mountPath: /etc/podinfo
```

The container reads `/etc/podinfo/annotations` to discover its own annotations — useful for feature flags injected as Pod annotations by operators, or for sidecar containers that need to know the app container's resource limits.

---

## Section 10-02: PersistentVolumes and PersistentVolumeClaims

---

### Q60. Walk through the full PersistentVolume lifecycle — all phases and what triggers each transition.

**Answer:**

A PV passes through five phases:

```
Available → Bound → Released → (Retained | Deleted | Recycled)
                  ↑
               (Failed)
```

| Phase | Meaning | What triggers entry |
|-------|---------|-------------------|
| **Available** | PV exists and has no PVC bound to it | PV is created (static) or dynamically provisioned. No PVC yet matched. |
| **Bound** | PV is exclusively bound to a specific PVC | The PVC controller matches this PV to a PVC's requirements and writes `spec.volumeName` on the PVC and `spec.claimRef` on the PV. |
| **Released** | The PVC was deleted but the PV's reclaim policy prevents immediate deletion | `kubectl delete pvc` completes. The PV retains a `claimRef` to the deleted PVC. |
| **Failed** | Automatic reclamation failed | Only relevant for `Recycle` policy — the scrub job failed. Rarely seen with modern storage classes. |
| **Deleted** | The PV object and underlying storage are gone | Triggered by `Delete` reclaim policy when PVC is deleted, or by manual `kubectl delete pv`. |

**Important nuance — Released ≠ Available:**

A PV in `Released` state **cannot be rebound** to a new PVC automatically. It still holds the `claimRef` of the old deleted PVC. To make it available again:

```bash
kubectl patch pv <pv-name> -p '{"spec":{"claimRef": null}}'
```

This resets it to `Available`. This is intentional — prevents a new PVC from accidentally binding to a PV that still has data from the previous owner.

**Dynamic provisioning** lifecycle difference:
- PV is created only when a PVC is created → goes directly from non-existent to `Bound`.
- When the PVC is deleted with `reclaimPolicy: Delete`, the PV and the underlying EBS volume are **both deleted automatically** — no manual cleanup needed.

---

### Q61. What are the four PV access modes? Which AWS storage types on EKS support each, and what are the practical implications?

**Answer:**

| Access Mode | Short | Meaning | Who can mount |
|-------------|-------|---------|---------------|
| `ReadWriteOnce` | `RWO` | Read and write by **one node** at a time | Single node (multiple Pods on that node can share it) |
| `ReadOnlyMany` | `ROX` | Read-only by **multiple nodes** simultaneously | Many nodes, read-only |
| `ReadWriteMany` | `RWX` | Read and write by **multiple nodes** simultaneously | Many nodes, read-write |
| `ReadWriteOncePod` | `RWOP` | Read and write by **exactly one Pod** | Single Pod (stricter than RWO) |

**AWS storage support on EKS:**

| Storage | RWO | ROX | RWX | RWOP | Notes |
|---------|-----|-----|-----|------|-------|
| **EBS (gp2/gp3/io1/io2)** | Yes | No | **No** | Yes (k8s 1.22+) | EBS is block storage — attached to one EC2 instance at a time |
| **EFS (elastic file system)** | Yes | Yes | **Yes** | No | NFS-based — multiple AZs, supports RWX |
| **FSx for Lustre** | Yes | No | **Yes** (clients on same VPC) | No | High-performance parallel filesystem |
| **FSx for NetApp ONTAP** | Yes | Yes | **Yes** | No | Enterprise NFS/SMB |

**Critical implication — EBS and StatefulSets:**

EBS is `RWO` only. Each StatefulSet Pod gets its own dedicated EBS volume. You **cannot** have two Pods on different nodes mount the same EBS volume simultaneously. This is why StatefulSet `volumeClaimTemplates` creates **separate PVCs per Pod** — each bound to a different EBS volume.

**`ReadWriteOncePod` use case:**

Stricter than `RWO`. Even if two Pods are on the same node, only one can mount the volume. Critical for database scenarios where split-brain (two processes writing to the same disk) would corrupt data. EBS CSI driver supports RWOP since Kubernetes 1.22.

---

### Q62. What are the three PV reclaim policies? Walk through what happens at the AWS storage layer for each when a PVC is deleted on EKS.

**Answer:**

The `persistentVolumeReclaimPolicy` on a PV (or the `reclaimPolicy` on a StorageClass) controls what happens to the underlying storage when the PVC is deleted.

| Policy | PV object after PVC deletion | Underlying EBS volume | Data |
|--------|----------------------------|----------------------|------|
| **Retain** | Moves to `Released` phase; not deleted | **Kept** — volume exists in AWS Console | **Preserved** — manual cleanup required |
| **Delete** | PV object is deleted automatically | **Deleted** — EBS volume is deleted by the CSI driver | **Lost** — data is gone |
| **Recycle** (deprecated) | PV re-set to `Available` after scrub | Kept | Wiped (`rm -rf /volume/*`) then reused |

**Recycle is deprecated** since Kubernetes 1.11 — StorageClasses with dynamic provisioning replaced it. Never use Recycle.

**When to use which on EKS:**

| Scenario | Recommended Policy |
|----------|--------------------|
| Production database (Postgres, MySQL) | `Retain` — never auto-delete production data |
| StatefulSet with `volumeClaimTemplates` | `Retain` (default) for databases; `Delete` for ephemeral caches |
| CI/CD build agents | `Delete` — discard volumes after each build run |
| Dev/test environments | `Delete` — automatic cleanup prevents cost accumulation |
| PVs created by StorageClass (dynamic) | Set at StorageClass level; EKS default `gp2`/`gp3` use `Delete` |

**Changing reclaim policy after PV creation:**
```bash
kubectl patch pv <pv-name> -p '{"spec":{"persistentVolumeReclaimPolicy":"Retain"}}'
```

You can change this at any time — it takes effect on the **next** PVC deletion event.

---

### Q63. How does PV/PVC binding work? What rules does the Kubernetes control plane use to match a PVC to an available PV?

**Answer:**

The **PersistentVolume controller** (part of `kube-controller-manager`) continuously reconciles unbound PVCs against available PVs. Binding is a **best-fit matching** algorithm.

**Matching rules (all must be satisfied):**

| Rule | Detail |
|------|--------|
| **StorageClass** | PVC's `storageClassName` must match the PV's `storageClassName`. If the PVC has `storageClassName: ""`, it matches PVs with no StorageClass. |
| **Access modes** | PVC's `accessModes` must be a **subset** of the PV's `accessModes`. A PVC requesting `RWO` can bind to a PV with `[RWO, ROX]`. |
| **Capacity** | PV's capacity must be **≥** PVC's request. The controller prefers the smallest PV that satisfies the request (best-fit). |
| **Volume mode** | `volumeMode: Filesystem` matches `Filesystem` PVs; `volumeMode: Block` matches `Block` PVs. |
| **Label selectors** | If the PVC has a `selector`, the PV must have matching labels. |
| **Claim ref** | If the PV has a `claimRef`, it is pre-reserved for that specific PVC (static binding). |

**The binding process:**
1. PVC is created in `Pending` state.
2. PV controller finds a matching PV and sets `pvc.spec.volumeName = <pv-name>` and `pv.spec.claimRef = <pvc-ref>`.
3. Both objects move to `Bound` state atomically.

**Pre-binding (static provisioning pattern):**
```yaml
# PV pre-reserved for a specific PVC
apiVersion: v1
kind: PersistentVolume
metadata:
  name: ebs-prod-db-pv
spec:
  claimRef:
    name: data-mysql-0          # specific PVC name
    namespace: default
  capacity:
    storage: 100Gi
  accessModes: [ReadWriteOnce]
  storageClassName: gp3
  csi:
    driver: ebs.csi.aws.com
    volumeHandle: vol-0a1b2c3d4e5f
```

**Why best-fit matters:** If you have PVs of 10 Gi, 50 Gi, and 100 Gi, and a PVC requests 10 Gi, the controller binds to the 10 Gi PV — not the 100 Gi one. This preserves larger PVs for requests that actually need them.

---

### Q64. What is the difference between static provisioning and dynamic provisioning of PersistentVolumes? When would you choose static provisioning on EKS?

**Answer:**

**Static provisioning:**
- A cluster administrator **manually creates** the PV object and the underlying storage (e.g., pre-creates an EBS volume in AWS Console or CLI).
- A user creates a PVC; Kubernetes binds it to the pre-created PV.
- The PVC consumer has no control over the actual storage type or AZ.

**Dynamic provisioning:**
- No pre-created PV. User creates only a PVC referencing a `StorageClass`.
- The StorageClass **provisioner** (e.g., the EBS CSI driver) automatically creates the EBS volume and the PV object.
- PV is created **on-demand** when the PVC is created.

**Comparison:**

| Aspect | Static | Dynamic |
|--------|--------|---------|
| PV creation | Manual (admin) | Automatic (provisioner) |
| Flexibility | Admin controls everything | User specifies size; provisioner handles rest |
| Speed | Slow (admin bottleneck) | Fast (seconds) |
| EBS volume lifecycle | Admin manages the EBS lifecycle | CSI driver manages it |
| Use in production | Narrow use cases | Default for all modern workloads |

**When to use static provisioning on EKS:**

| Scenario | Reason |
|----------|--------|
| **Pre-existing EBS volumes** — migrating a workload from EC2 to EKS | You have data on an existing volume that must be reused |
| **Specific EBS volume configuration** — custom KMS key, specific IOPS tier not expressible in StorageClass | The provisioner's defaults don't match the requirement |
| **Cross-account EBS volumes** | Volume is in a different AWS account; CSI driver can't create it |
| **Compliance requires pre-approved storage** | Storage must be provisioned through a change management process before the workload deploys |
| **Cost control in restricted environments** | No dynamic provisioning allowed; ops team controls all storage allocation |

```bash
# Static provisioning: bring existing EBS volume vol-0a1b2c3d4e5f into Kubernetes
aws ec2 describe-volumes --volume-ids vol-0a1b2c3d4e5f  # verify it exists in the right AZ
kubectl apply -f pv-static.yaml    # PV referencing the existing volume handle
kubectl apply -f pvc-static.yaml   # PVC referencing the PV by storageClassName + size
```

---

## Section 10-03: StorageClass and Dynamic Provisioning

---

### Q65. What is a StorageClass? Walk through its key fields and explain how it bridges a PVC request to an actual EBS volume on EKS.

**Answer:**

A `StorageClass` is a Kubernetes object that defines a **class of storage** — the provisioner to use, the storage parameters, and the reclaim and binding behavior. It is the template from which PVs are dynamically created.

**Key fields:**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"   # default SC for PVCs with no storageClassName
provisioner: ebs.csi.aws.com              # which CSI driver handles provisioning
parameters:
  type: gp3                               # EBS volume type
  iops: "3000"                            # provisioned IOPS (gp3 only)
  throughput: "125"                       # MB/s throughput (gp3 only)
  encrypted: "true"                       # KMS encryption
  kmsKeyId: "arn:aws:kms:..."             # specific KMS CMK
reclaimPolicy: Delete                     # what to do with the PV when PVC is deleted
allowVolumeExpansion: true                # allow PVC resize without Pod restart
volumeBindingMode: WaitForFirstConsumer   # delay PV creation until Pod is scheduled
mountOptions:
  - noatime                               # mount options applied to the filesystem
```

**How it bridges PVC → EBS volume:**

1. User creates a PVC referencing `storageClassName: gp3`.
2. Kubernetes marks the PVC as `Pending` and emits a provision event.
3. The **EBS CSI driver** (watching for new PVCs with `provisioner: ebs.csi.aws.com`) reads the `parameters` from the StorageClass.
4. The driver calls `ec2:CreateVolume` via the AWS SDK (using its IRSA IAM role).
5. AWS creates the EBS volume with the specified type, IOPS, and encryption.
6. The driver creates a `PersistentVolume` object in Kubernetes with `volumeHandle: vol-<id>`.
7. Kubernetes binds the PVC to this PV — both move to `Bound`.

**Default StorageClass behavior:**
If a PVC does not specify `storageClassName`, it uses the StorageClass annotated `storageclass.kubernetes.io/is-default-class: "true"`. EKS clusters have `gp2` as default; upgrading to `gp3` requires patching or creating a new default.

---

### Q66. What is `volumeBindingMode`? Explain `Immediate` vs `WaitForFirstConsumer` and why the latter is critical for EKS multi-AZ clusters.

**Answer:**

`volumeBindingMode` controls **when** the PV is provisioned and bound relative to Pod scheduling.

**`Immediate` (default before EKS best-practice guidance):**
- PV is provisioned as soon as the PVC is created.
- The EBS CSI driver must pick an AZ before knowing where the Pod will run.
- It picks the AZ based on `allowedTopologies` or a round-robin/random default.
- **Problem:** If the EBS volume lands in `us-east-1a` but the scheduler places the Pod on a node in `us-east-1b`, the Pod gets stuck:
  ```
  Warning  FailedAttachVolume  AttachVolume.Attach failed for volume "pvc-...":
  rpc error: code = Internal desc = Could not attach volume "vol-..." to node "i-...":
  RequestError: ... InvalidParameterValue: Invalid value ... for parameter availabilityZone
  ```

**`WaitForFirstConsumer` (recommended for EKS):**
- PV provisioning is **delayed** until a Pod using the PVC is scheduled to a node.
- The scheduler selects the node first (considering anti-affinity, resource fit, taints, etc.).
- The provisioner receives a `SelectedNode` annotation on the PVC: `volume.kubernetes.io/selected-node: ip-10-0-1-5.us-east-1.compute.internal`.
- The EBS volume is provisioned **in the same AZ as the selected node**.
- The PV gets a `nodeAffinity` annotation that ensures future Pod rescheduling returns to the same AZ.

```
PVC created
  → PVC stays Pending (no PV provisioned yet)
  → Pod created referencing the PVC
  → Scheduler finds best node (e.g., in us-east-1b)
  → PVC gets annotation: selected-node = node-in-us-east-1b
  → EBS CSI driver provisions volume in us-east-1b
  → PV created with nodeAffinity for us-east-1b
  → PVC → Bound; Pod starts on the correct node
```

**Node affinity written to the PV:**
```yaml
nodeAffinity:
  required:
    nodeSelectorTerms:
      - matchExpressions:
          - key: topology.kubernetes.io/zone
            operator: In
            values: [us-east-1b]
```

This ensures that if the Pod is evicted and rescheduled, the scheduler knows it must land in `us-east-1b` — the only AZ where the EBS volume exists.

---

### Q67. Walk through the end-to-end EBS dynamic provisioning flow on EKS — from `kubectl apply` of a PVC to the volume being mounted inside a Pod.

**Answer:**

**Components involved:** EBS CSI Driver (controller + node DaemonSet), API server, scheduler, kubelet, EC2 API.

```
kubectl apply -f pvc.yaml
```

**Step 1: PVC created in etcd**
- API server validates and persists the PVC object (status: `Pending`).
- `volumeBindingMode: WaitForFirstConsumer` — no provisioning yet.

**Step 2: Pod created referencing the PVC**
- API server persists the Pod object (status: `Pending`).

**Step 3: Scheduler selects a node**
- Scheduler runs filter plugins: PVC topology constraints, resource fit, taints, affinity rules.
- Selects node `ip-10-0-1-5.us-east-1b.compute.internal` (AZ: `us-east-1b`).
- Writes `spec.nodeName` to the Pod and adds annotation `volume.kubernetes.io/selected-node` to the PVC.

**Step 4: EBS CSI Controller provisions the volume**
- The **EBS CSI Controller** (Deployment, runs on any node) watches for PVCs with `selected-node` annotation.
- Calls `ec2:CreateVolume` with `AvailabilityZone: us-east-1b` and parameters from the StorageClass (`type: gp3, iops: 3000, encrypted: true`).
- AWS creates the EBS volume: `vol-0a1b2c3d4e5f6789a`.
- CSI Controller creates the PV object with `volumeHandle: vol-0a1b2c3d4e5f6789a` and `nodeAffinity` for `us-east-1b`.
- PVC moves to `Bound`.

**Step 5: kubelet on the target node sees the Pod**
- kubelet calls the **EBS CSI Node plugin** (DaemonSet on each node) via gRPC.
- `NodeStageVolume`: CSI node plugin calls `ec2:AttachVolume` to attach `vol-0a1b2c3d4e5f6789a` to EC2 instance `i-0abc123`. The volume appears as `/dev/nvme1n1`.
- `NodePublishVolume`: The volume is formatted (if new) and bind-mounted into the Pod's mount namespace at the specified `mountPath`.

**Step 6: Container starts**
- kubelet starts the container with the volume mounted.
- The app can read/write to `/data` (or whatever `mountPath` was specified).

**Total time:** ~15–30 seconds for a new EBS volume (CreateVolume + AttachVolume).

---

### Q68. What is the EBS CSI driver? How does it differ from the legacy in-tree EBS plugin, and how do you verify it is installed and functioning on your EKS cluster?

**Answer:**

**Legacy in-tree EBS plugin (`kubernetes.io/aws-ebs`):**
- Code lived inside the Kubernetes core binary (`kube-controller-manager`, `kubelet`).
- To add features or fix bugs, a Kubernetes release was required.
- Tightly coupled — AWS-specific code in the upstream K8s repo.
- **Deprecated** since Kubernetes 1.17; removed in 1.27.

**EBS CSI Driver (`ebs.csi.aws.com`):**
- Implements the **Container Storage Interface (CSI)** standard — a vendor-neutral plugin API.
- Runs as a Deployment (controller) + DaemonSet (node plugin) — independent of the Kubernetes version.
- Released and updated independently of Kubernetes — AWS can ship new EBS features (e.g., gp3, io2 Block Express) without waiting for a K8s release.
- Supports features the in-tree plugin never had: `WaitForFirstConsumer`, volume snapshots, resizing, `ReadWriteOncePod`.

**Architecture:**

```
┌─────────────────────────────────────────┐
│  CSI Controller (Deployment, 1 replica) │
│  - ebs-plugin: CreateVolume/DeleteVolume │
│  - external-provisioner: watches PVCs   │
│  - external-attacher: watches VolumeAttachments │
│  - external-snapshotter: VolumeSnapshots │
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│  CSI Node Plugin (DaemonSet, each node) │
│  - ebs-plugin: NodeStageVolume/NodePublishVolume │
│  - node-driver-registrar: registers with kubelet │
└─────────────────────────────────────────┘
```

**Verify installation on EKS:**

```bash
# Check if the EBS CSI driver addon is installed
aws eks describe-addon --cluster-name <cluster> --addon-name aws-ebs-csi-driver

# Check pods are running
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver

# Verify CSINode objects (node plugin registered with kubelet)
kubectl get csinodes
kubectl get csinodes <node-name> -o yaml | grep ebs.csi.aws.com

# Verify StorageClass uses the CSI provisioner
kubectl get storageclass gp3 -o yaml | grep provisioner
# Should show: provisioner: ebs.csi.aws.com (NOT kubernetes.io/aws-ebs)

# End-to-end test: create a PVC and check it binds
kubectl apply -f - <<EOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-csi-test
spec:
  accessModes: [ReadWriteOnce]
  storageClassName: gp3
  resources:
    requests:
      storage: 1Gi
EOF
kubectl get pvc ebs-csi-test   # should reach Bound within ~30s
```

**IRSA for EBS CSI driver:**
The CSI controller calls AWS EC2 APIs. It needs an IAM role — provision via the managed addon:
```bash
aws eks create-addon \
  --cluster-name my-eks \
  --addon-name aws-ebs-csi-driver \
  --service-account-role-arn arn:aws:iam::123456789:role/AmazonEKS_EBS_CSI_DriverRole
```

---

### Q69. What is `volumeMode: Block` vs `volumeMode: Filesystem`? When would you use raw block volumes on EKS?

**Answer:**

`volumeMode` controls whether the volume is presented to the container as a **formatted filesystem** or as a **raw block device**.

**`Filesystem` (default):**
- The CSI driver formats the EBS volume with `ext4` or `xfs` (configurable via `csi.storage.k8s.io/fstype` parameter).
- Mounted as a directory in the container: `/data`.
- The container reads/writes files and directories via normal POSIX filesystem calls.

**`Block`:**
- The volume is presented as a **raw block device** inside the container (e.g., `/dev/xvda`).
- No filesystem — the container manages the block device directly.
- The container can format it, use it as a database raw device, or pass it to an application that manages its own I/O.

```yaml
# PVC requesting raw block
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: raw-block-pvc
spec:
  accessModes: [ReadWriteOnce]
  volumeMode: Block              # raw block
  storageClassName: gp3
  resources:
    requests:
      storage: 100Gi

---
# Pod consuming raw block
volumeDevices:                   # NOT volumeMounts
  - name: raw-block
    devicePath: /dev/xvda        # appears as a block device, not a directory
```

**When to use raw block volumes:**

| Use Case | Reason |
|----------|--------|
| **High-performance databases (Oracle, SAP HANA)** | These databases have their own I/O scheduler and buffer management — a filesystem adds overhead and conflicts with database's own buffer cache |
| **Storage virtualization / Ceph / Portworx** | These storage systems manage raw block devices directly to implement their own replication and erasure coding |
| **Benchmark testing** | Raw I/O measurement without filesystem overhead |
| **Custom filesystems (SPDK, DPDK-based I/O)** | Userspace I/O libraries that bypass the kernel VFS entirely |

**EKS consideration:** Raw block volumes require EBS CSI driver and `ReadWriteOnce` or `ReadWriteOncePod` access mode. EBS does not support `ReadWriteMany` for block volumes.

---

## Cross-Section / Architectural Scenarios

---

### Q70. A Pod is stuck in `ContainerCreating` with event `AttachVolume.Attach failed`. Walk through your complete diagnosis and remediation process.

**Answer:**

**Step 1: Identify the Pod and event**
```bash
kubectl describe pod <pod-name>
# Look in Events:
# Warning  FailedAttachVolume  ... AttachVolume.Attach failed for volume "pvc-abc":
#   rpc error: code = Internal desc = Could not attach volume "vol-0a1b2c3d4e5f":
#   ... Invalid value 'us-east-1b' for availabilityZone
```

**Step 2: Find the PVC and PV**
```bash
kubectl get pvc <pvc-name>
kubectl get pv <pv-name> -o yaml | grep -A10 nodeAffinity
# nodeAffinity will show which AZ the EBS volume is in
```

**Step 3: Find which AZ the Pod's target node is in**
```bash
kubectl get node <node-name> -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'
```

**Step 4: Diagnose the root cause**

| Symptom | Root Cause | Fix |
|---------|-----------|-----|
| AZ in `nodeAffinity` ≠ AZ of node | StorageClass used `Immediate` binding — PV provisioned before Pod was scheduled | Change StorageClass to `volumeBindingMode: WaitForFirstConsumer` for new PVCs |
| `Multi-Attach error: volume is already attached` | Previous Pod termination did not release the EBS attach gracefully | Wait for the previous node to release (can take 6–10 minutes after node failure); force-detach if node is dead: `aws ec2 detach-volume --volume-id vol-0... --force` |
| `VolumeNotFound` | EBS volume was deleted manually from AWS Console | Restore from EBS snapshot or recreate the PV/PVC |
| `NodeNotFound` or `InvalidInstance` | EBS CSI driver IRSA permissions missing `ec2:AttachVolume` | Check CSI driver pod logs and IAM role |
| PVC still `Pending` | StorageClass not found, or EBS CSI driver not installed | `kubectl get sc`, `kubectl get pods -n kube-system -l app=ebs-csi-controller` |

**Step 5: Check EBS CSI driver logs**
```bash
kubectl logs -n kube-system -l app=ebs-csi-controller -c ebs-plugin --tail=50
kubectl logs -n kube-system -l app=ebs-csi-node -c ebs-plugin --field-selector spec.nodeName=<node> --tail=50
```

**Step 6: AZ mismatch remediation (most common)**
```bash
# Option A: Move the Pod to the correct AZ (add nodeAffinity)
kubectl patch deployment/catalog --patch '
{"spec":{"template":{"spec":{"affinity":{"nodeAffinity":{"requiredDuringSchedulingIgnoredDuringExecution":
{"nodeSelectorTerms":[{"matchExpressions":[{"key":"topology.kubernetes.io/zone",
"operator":"In","values":["us-east-1b"]}]}]}}}}}}}'

# Option B: If data migration is acceptable — create snapshot, new volume in correct AZ
aws ec2 create-snapshot --volume-id vol-0abc --description "migration"
aws ec2 create-volume --snapshot-id snap-0abc --availability-zone us-east-1c --volume-type gp3
# Update PV to point to new volume, delete old PV/PVC
```

---

### Q71. Multiple read-only Pods across different nodes need to share a large dataset (200 GiB). EBS cannot be used. What storage options does EKS provide and what are the trade-offs?

**Answer:**

EBS only supports `ReadWriteOnce` — it cannot be mounted by Pods on multiple nodes simultaneously. The options for `ReadWriteMany` on EKS:

**Option 1: Amazon EFS (Elastic File System)**

```yaml
storageClassName: efs-sc
accessModes: [ReadWriteMany]   # multiple nodes, read-write (or ReadOnlyMany)
```

| | |
|--|--|
| **Protocol** | NFSv4.1 — any Pod in any AZ can mount |
| **Performance** | Throughput scales with stored data or provisioned throughput mode. Latency ~1–2ms (higher than EBS) |
| **Cost** | $0.30/GB/month (Standard) — expensive for 200 GiB = $60/month |
| **Best for** | Shared config files, shared ML model weights, web assets, home directories |
| **EKS setup** | Install EFS CSI driver; create EFS filesystem and access points; create StorageClass with `provisioner: efs.csi.aws.com` |

**Option 2: Amazon S3 (via Mountpoint for S3 CSI)**

```yaml
storageClassName: s3-sc
# S3 mount — read-only or read-write via Mountpoint
```

| | |
|--|--|
| **Protocol** | FUSE-based S3 API (not POSIX compliant — no rename, no locking) |
| **Performance** | High aggregate throughput for sequential reads; poor for random small I/O |
| **Cost** | $0.023/GB/month — cheapest option for large datasets |
| **Best for** | Large ML training datasets, large read-only data files, log ingestion |
| **Limitation** | Not a full POSIX filesystem — applications that require `rename`, `mmap`, or file locking will fail |

**Option 3: FSx for Lustre**

| | |
|--|--|
| **Protocol** | Lustre parallel filesystem |
| **Performance** | Sub-millisecond latency, hundreds of GB/s aggregate throughput — best performance |
| **Cost** | High (~$0.14–$0.28/GB/month) |
| **Best for** | HPC, large-scale ML training, genomics pipelines where I/O is the bottleneck |
| **EKS setup** | FSx for Lustre CSI driver; filesystem created per workload |

**Option 4: Self-managed distributed storage (Rook/Ceph)**

| | |
|--|--|
| **Protocol** | CephFS (POSIX-compliant, RWX) or object storage (S3-compatible) |
| **Cost** | Uses existing node disk capacity; no additional AWS storage cost |
| **Operational overhead** | Very high — you operate Ceph |
| **Best for** | Clusters where EFS/FSx cost is prohibitive and team has Ceph expertise |

**Decision matrix for the 200 GiB dataset scenario:**

| Requirement | Choose |
|-------------|--------|
| Pods only read (no writes) | S3 Mountpoint (cheapest) |
| Pods need to write occasionally too | EFS |
| Sub-millisecond latency required | FSx for Lustre |
| POSIX compliance required with multi-writer | EFS or FSx for NetApp ONTAP |

---

### Q72. Design a complete persistent storage architecture on EKS for a 3-tier application: stateless web tier, stateful API tier writing temp files, and a PostgreSQL database. What storage class and volume configuration does each tier need?

**Answer:**

**Architecture overview:**

```
Internet → ALB → Web Tier (stateless) → API Tier (stateful) → PostgreSQL
                 No PVC needed        emptyDir              EBS PVC via StatefulSet
```

---

**Tier 1: Web Tier (Nginx / React SPA)**

- Serves static assets — completely stateless.
- No PVC needed. Use `emptyDir` (tmpfs) for Nginx temp files.

```yaml
volumes:
  - name: nginx-tmp
    emptyDir:
      medium: Memory
      sizeLimit: 64Mi
```

---

**Tier 2: API Tier (Node.js / Spring Boot writing temp files)**

- Needs scratch space for file uploads (before forwarding to S3), temp files, local caches.
- Files are transient — do not need to survive Pod restarts.
- Use `emptyDir` with a size limit, NOT a PVC. A PVC would provision an EBS volume per replica — wasteful for scratch data.

```yaml
volumes:
  - name: api-scratch
    emptyDir:
      sizeLimit: 5Gi          # limits how much node disk the API can consume
```

- If shared temp storage between API replicas is needed (rare), use EFS with `ReadWriteMany`.
- If temp files must survive Pod restarts (e.g., resumable uploads), then use a PVC with `gp3` StorageClass.

---

**Tier 3: PostgreSQL Database (StatefulSet)**

This is the critical tier — data must survive Pod deletion, rescheduling, and node failure.

**StorageClass:**
```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: postgres-gp3
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "6000"              # high IOPS for PostgreSQL WAL + data
  throughput: "250"         # MB/s
  encrypted: "true"
  kmsKeyId: "arn:aws:kms:us-east-1:123456789:key/abc"
reclaimPolicy: Retain       # never auto-delete DB storage
volumeBindingMode: WaitForFirstConsumer
allowVolumeExpansion: true
```

**StatefulSet storage:**
```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  replicas: 3                      # primary + 2 read replicas
  serviceName: postgres-headless
  podManagementPolicy: OrderedReady
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 2                 # canary: update replica before primary
  template:
    spec:
      securityContext:
        fsGroup: 999               # postgres user GID — needed for volume ownership
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            - topologyKey: kubernetes.io/hostname   # no two Postgres Pods on same node
          preferredDuringSchedulingIgnoredDuringExecution:
            - weight: 100
              podAffinityTerm:
                topologyKey: topology.kubernetes.io/zone  # prefer different AZs
  persistentVolumeClaimRetentionPolicy:
    whenDeleted: Retain            # never auto-delete when StatefulSet is deleted
    whenScaled: Retain             # never auto-delete when scaling down
  volumeClaimTemplates:
    - metadata:
        name: pgdata
      spec:
        accessModes: [ReadWriteOnce]
        storageClassName: postgres-gp3
        resources:
          requests:
            storage: 200Gi
    - metadata:
        name: pgwal                # separate WAL volume — prevents WAL from filling data volume
      spec:
        accessModes: [ReadWriteOnce]
        storageClassName: postgres-gp3
        resources:
          requests:
            storage: 50Gi
```

**PodDisruptionBudget:**
```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: postgres-pdb
spec:
  maxUnavailable: 1
  selector:
    matchLabels:
      app: postgres
```

**Summary table:**

| Tier | Storage type | Kubernetes object | Reclaim | AZ considerations |
|------|-------------|------------------|---------|------------------|
| Web (Nginx) | tmpfs (RAM) | `emptyDir: {medium: Memory}` | N/A | None — stateless |
| API (temp files) | Node disk | `emptyDir: {sizeLimit: 5Gi}` | N/A | None — scratch |
| PostgreSQL | EBS gp3, 6000 IOPS | `volumeClaimTemplates` in StatefulSet | `Retain` | `WaitForFirstConsumer` ensures AZ alignment |

---

*Document prepared for Day 9 – Phase 3: EKS Core*
*Senior Engineer Knowledge Validation*


---

# EKS Ingress & AWS Load Balancer Controller – Senior Engineer Q&A
**Day 10 | Phase 4: EKS Core | Section 11 (1–3)**
**Date: 15-May-2026**

---

## Table of Contents

1. [Section 11-01: AWS Load Balancer Controller Install](#section-11-01-aws-load-balancer-controller-install)
2. [Section 11-02: Kubernetes Ingress – HTTP](#section-11-02-kubernetes-ingress--http)
3. [Section 11-03: Kubernetes Ingress – HTTPS](#section-11-03-kubernetes-ingress--https)
4. [Cross-Section / Architectural Scenarios](#cross-section--architectural-scenarios)

---

## Section 11-01: AWS Load Balancer Controller Install

---

### Q1. What is the AWS Load Balancer Controller, and why does EKS need it if Kubernetes already has a Service of type LoadBalancer?

**Answer:**

Kubernetes' built-in cloud-controller-manager creates a **Classic Load Balancer (CLB)** for every `Service type: LoadBalancer` — one CLB per Service. This is expensive, slow, and cannot perform L7 routing.

The **AWS Load Balancer Controller (LBC)** is a Kubernetes controller that watches `Ingress` and `Service` resources and instead provisions:

| Resource | What LBC Creates |
|---|---|
| `Ingress` (class `alb`) | Application Load Balancer (ALB) — L7, path/host routing, TLS |
| `Service type: LoadBalancer` with NLB annotations | Network Load Balancer (NLB) — L4, ultra-low latency |

**Key advantages:**
- One ALB can front many Services via path rules — far cheaper.
- Native ALB features: ACM TLS termination, WAF, authentication (Cognito/OIDC), access logs, IP/instance target modes.
- Integrates with **EKS Pod Identity** or **IRSA** for least-privilege IAM access.

Without the LBC installed, creating an `Ingress` with `ingressClassName: alb` results in the Ingress staying permanently unaddressed — no controller reconciles it.

---

### Q2. The trust policy for the LBC IAM role uses `"Service": "pods.eks.amazonaws.com"` instead of an OIDC issuer. What authentication mechanism is this, and how is it fundamentally different from IRSA?

**Answer:**

This is **EKS Pod Identity** (GA since late 2023), not IRSA (IAM Roles for Service Accounts).

| Aspect | IRSA | EKS Pod Identity |
|---|---|---|
| **Trust principal** | `sts:AssumeRoleWithWebIdentity` via OIDC issuer URL | `sts:AssumeRole` + `sts:TagSession` via `pods.eks.amazonaws.com` |
| **Binding location** | Annotation on ServiceAccount (`eks.amazonaws.com/role-arn`) | `aws eks create-pod-identity-association` (API/console) |
| **OIDC provider** | Must exist on the cluster | Not needed |
| **IAM trust update** | Must update trust policy per-cluster (OIDC URL is unique per cluster) | One universal trust policy reusable across all clusters |
| **Credential delivery** | Projected ServiceAccount token mounted into Pod | EKS Pod Identity Agent (DaemonSet) delivers temp credentials via IMDS-like endpoint `169.254.170.23` |

**In this course**, the trust policy allows `pods.eks.amazonaws.com` to call `sts:AssumeRole` and `sts:TagSession`. The binding is created with:

```bash
aws eks create-pod-identity-association \
  --cluster-name ${EKS_CLUSTER_NAME} \
  --namespace kube-system \
  --service-account aws-load-balancer-controller \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_ID}:role/AmazonEKS_LBC_Role_${EKS_CLUSTER_NAME}
```

This associates the `aws-load-balancer-controller` ServiceAccount in `kube-system` with the IAM role — any pod running under that ServiceAccount gets temporary credentials scoped to that role.

---

### Q3. When installing LBC with Helm, the course explicitly sets `--set vpcId=$VPC_ID` and `--set region=$AWS_REGION`. Why can't the controller auto-detect these values?

**Answer:**

By default, the LBC tries to auto-detect `vpcId` and `region` via **EC2 Instance Metadata Service (IMDS)** — the `http://169.254.169.254/latest/meta-data/` endpoint that EC2 instances expose.

In modern EKS clusters, especially with **IMDSv2 enforced** or **hop limit set to 1**, Pods running on nodes **cannot reach IMDS**. The hop limit of 1 means the metadata response never travels beyond the node itself — a container's additional network hop causes IMDS calls to time out.

Without explicit values, the LBC Pod startup fails or falls into an error loop trying to discover cluster context.

**The fix:**
```bash
VPC_ID=$(aws eks describe-cluster --name ${EKS_CLUSTER_NAME} \
  --query "cluster.resourcesVpcConfig.vpcId" --output text)

helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=${EKS_CLUSTER_NAME} \
  --set region=${AWS_REGION} \
  --set vpcId=${VPC_ID} \
  ...
```

This provides the values out-of-band, bypassing IMDS entirely. Production-grade installs always pass these explicitly.

---

### Q4. The Helm install uses `serviceAccount.create=true` and `serviceAccount.name=aws-load-balancer-controller`. What is the relationship between this ServiceAccount and the Pod Identity Association you created earlier?

**Answer:**

The sequence matters:

1. **Pod Identity Association** (created first) declares: *"If a Pod runs as ServiceAccount `aws-load-balancer-controller` in namespace `kube-system`, inject credentials for IAM Role `AmazonEKS_LBC_Role_*`"*.

2. **Helm install** (`serviceAccount.create=true`) creates the actual Kubernetes `ServiceAccount` object named `aws-load-balancer-controller` in `kube-system`.

3. The LBC `Deployment` spec sets `serviceAccountName: aws-load-balancer-controller`. When the Pod is scheduled, the **EKS Pod Identity Agent** (a DaemonSet on each node) intercepts the Pod startup and injects AWS credentials matching the association.

**Critical nuance:** The names must match exactly. The Pod Identity Association links by `(namespace, serviceAccountName)` pair. If the Helm-created ServiceAccount uses a different name, the association misses — the LBC Pod will see `403 Access Denied` on AWS API calls.

You can verify the binding:
```bash
aws eks list-pod-identity-associations --cluster-name ${EKS_CLUSTER_NAME}
kubectl get serviceaccount aws-load-balancer-controller -n kube-system -o yaml
```

---

### Q5. What happens inside the EKS cluster after `helm install aws-load-balancer-controller` completes? Walk through the reconciliation loop.

**Answer:**

The LBC runs as a **Kubernetes controller** with a control loop:

1. **Watch:** LBC registers informers on `Ingress` (and `Service` with NLB annotations) across all namespaces.

2. **Event:** When you apply an `Ingress` manifest with `ingressClassName: alb`, the API server stores the object and fires a watch event.

3. **Reconcile:** LBC's reconciler receives the event and:
   - Reads all annotations on the Ingress (scheme, target-type, health checks, certificate ARN, etc.).
   - Calls AWS ALB APIs to provision: an ALB, listeners (HTTP 80 / HTTPS 443), target groups, and routing rules.
   - Registers EC2 instances (instance mode) or Pod IPs (IP mode) as ALB targets.

4. **Status update:** LBC patches `ingress.status.loadBalancer.ingress[0].hostname` with the ALB DNS name — this is what `kubectl get ingress` shows in the `ADDRESS` column.

5. **Ongoing sync:** LBC watches for Pod scaling events and updates target group registrations accordingly — no manual intervention needed.

```bash
# Observe the reconciliation in action
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller -f
```

---

## Section 11-02: Kubernetes Ingress – HTTP

---

### Q6. What is `ingressClassName: alb` and how does Kubernetes know which controller should reconcile this Ingress?

**Answer:**

`ingressClassName` references an `IngressClass` resource — a cluster-level object that maps a class name to a controller.

When the LBC is installed, it creates (or you reference) an `IngressClass` named `alb`:

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: alb
spec:
  controller: ingress.k8s.aws/alb
```

The LBC's reconciler is registered to handle `controller: ingress.k8s.aws/alb`. When it sees an `Ingress` with `ingressClassName: alb`, it takes ownership. Any other controller (nginx-ingress, traefik, etc.) ignores it.

**From the course manifests:**
```yaml
spec:
  ingressClassName: alb
```

This single line is what directs the Ingress object to the AWS Load Balancer Controller instead of any other installed ingress controller.

---

### Q7. The course deploys two HTTP ingress manifests — `01_ingress_http_instance_mode.yaml` and `02_ingress_http_ip_mode.yaml`. What is the fundamental difference between `target-type: instance` and `target-type: ip`, and when would you use each?

**Answer:**

The `alb.ingress.kubernetes.io/target-type` annotation controls **where the ALB sends traffic after routing**:

| | Instance Mode | IP Mode |
|---|---|---|
| **Targets registered** | EC2 Node IPs + NodePort | Pod IPs directly |
| **Traffic path** | ALB → Node (NodePort) → kube-proxy → Pod | ALB → Pod IP (bypasses kube-proxy) |
| **Service type required** | `NodePort` or `ClusterIP` (LBC uses NodePort implicitly) | `ClusterIP` |
| **Hop count** | 2 hops | 1 hop |
| **Cross-AZ traffic** | Possible (NodePort may forward to pod on different AZ node) | Direct, avoids unnecessary hop |
| **Pod churn** | Target group updates when nodes scale | Target group updates when pods scale |

**From the course:**
- Instance mode backend: `name: ui-np` — a `NodePort` service.
- IP mode backend: `name: ui` — a `ClusterIP` service.

**When to use IP mode:** Fargate (no nodes), when minimizing latency, or when you want Pod-level health checks. Most production EKS deployments use IP mode for efficiency.

---

### Q8. Explain every ALB health check annotation in the course manifests and what breaks if each is misconfigured.

**Answer:**

From the manifest:

```yaml
alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
alb.ingress.kubernetes.io/healthcheck-port: traffic-port
alb.ingress.kubernetes.io/healthcheck-path: /actuator/health/readiness
alb.ingress.kubernetes.io/healthcheck-interval-seconds: '15'
alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
alb.ingress.kubernetes.io/success-codes: '200'
alb.ingress.kubernetes.io/healthy-threshold-count: '2'
alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'
```

| Annotation | Purpose | Misconfiguration Impact |
|---|---|---|
| `healthcheck-protocol: HTTP` | ALB probes using HTTP (not HTTPS) | Wrong protocol → SSL handshake error, all targets unhealthy |
| `healthcheck-port: traffic-port` | Uses the same port the target serves traffic on | Wrong port → connection refused, all targets unhealthy |
| `healthcheck-path: /actuator/health/readiness` | Spring Boot readiness endpoint — returns 200 when app is ready | Wrong path (404) → all targets unhealthy, ALB serves 503 |
| `healthcheck-interval-seconds: 15` | ALB probes every 15s | Too high → slow detection of failures; too low → excessive load |
| `healthcheck-timeout-seconds: 5` | Probe must respond within 5s | Must be < interval; slow apps will time out |
| `success-codes: 200` | Only HTTP 200 counts as healthy | If app returns 204 or redirects, targets marked unhealthy |
| `healthy-threshold-count: 2` | 2 consecutive successes to mark target healthy | High value → slow recovery after restart |
| `unhealthy-threshold-count: 2` | 2 consecutive failures to mark target unhealthy | Low value → flapping on transient errors |

**Why `/actuator/health/readiness`?** This Spring Boot endpoint only returns 200 when the application is fully ready to serve traffic — DB connections established, caches warm. Using `/` would return 200 even during startup before the app is ready.

---

### Q9. The HTTP ingress uses `defaultBackend` with no `rules` section. What does this mean architecturally, and when would you add path-based rules?

**Answer:**

```yaml
spec:
  ingressClassName: alb
  defaultBackend:
    service:
      name: ui-np
      port:
        number: 80
```

`defaultBackend` is a catch-all: **every request that doesn't match any explicit path rule is forwarded here**. With no `rules:` section defined, 100% of traffic goes to `ui-np:80`.

This is correct for a single-service application where the UI service proxies all internal microservice calls (catalog, cart, orders, checkout) — external clients only reach the UI, which internally routes via ClusterIP services.

**When to add path-based rules** (multi-service external exposure):

```yaml
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /api/catalog
            pathType: Prefix
            backend:
              service:
                name: catalog
                port:
                  number: 8080
          - path: /api/cart
            pathType: Prefix
            backend:
              service:
                name: cart
                port:
                  number: 8080
  defaultBackend:
    service:
      name: ui
      port:
        number: 80
```

In production, you'd use path routing to expose different microservices through one ALB — reducing cost and centralizing SSL termination.

---

## Section 11-03: Kubernetes Ingress – HTTPS

---

### Q10. What changes between the HTTP and HTTPS ingress manifests? Walk through every new annotation added.

**Answer:**

The HTTPS manifests add three annotations on top of the HTTP base:

```yaml
alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:180789647333:certificate/60a5bccd-...
alb.ingress.kubernetes.io/ssl-redirect: '443'
```

**`listen-ports`**
- Tells the ALB to open two listeners: port 80 (HTTP) and port 443 (HTTPS).
- Without this, ALB only listens on 80 by default for HTTP Ingress.
- Value is JSON — note the string format (single-quoted outer, JSON inside).

**`certificate-arn`**
- Points to an ACM certificate that the ALB presents during TLS handshake.
- The certificate must be in the **same AWS region** as the ALB.
- ACM manages private key storage and certificate renewal — the key never leaves AWS.
- Multiple certificates can be listed for SNI-based multi-domain hosting.

**`ssl-redirect: '443'`**
- Configures an ALB listener rule: any HTTP (port 80) request gets a **301 redirect** to HTTPS (port 443).
- This is an ALB-native redirect — no application code handles it.
- Without this, HTTP and HTTPS both work independently — leaving HTTP open as a security gap.

---

### Q11. How does ACM certificate validation work, and why must you create a CNAME record in Route53?

**Answer:**

ACM offers two validation methods: **DNS validation** and email validation. The course uses DNS validation:

**Flow:**
1. You request a public certificate for `retailstore.stacksimplify.com` in ACM.
2. ACM generates a unique CNAME record (e.g., `_acme-challenge.retailstore.stacksimplify.com → _xyz.acm-validations.aws`).
3. You create this CNAME in the Route53 hosted zone for `stacksimplify.com`.
4. ACM's validation service polls for this CNAME. When found, it issues the certificate — status changes to **Issued**.
5. ACM **automatically renews** the certificate before expiry as long as the CNAME remains in DNS.

**Why it must be in the same region as ALB:**
- ACM certificates are regional for ALB.
- A certificate in `us-east-2` cannot be attached to an ALB in `us-east-1`.
- Exception: CloudFront requires certificates in `us-east-1` only (global CDN).

**After deployment**, a second Route53 record is needed:
```
Name: retailstore.stacksimplify.com
Type: CNAME
Value: <ALB-DNS-NAME>
TTL:   60
```
This routes end-user DNS lookups to the ALB. In production, use an **Alias record** (not CNAME) pointing to the ALB DNS — Alias is free, supports zone apex, and has health checking.

---

### Q12. Where does TLS termination happen in this architecture? What are the security implications of that choice?

**Answer:**

TLS terminates at the **ALB** (frontend listener on port 443). After termination, traffic flows from ALB to targets (EC2 nodes or Pod IPs) **over plain HTTP within the VPC**.

```
Client ──HTTPS──► ALB (TLS terminates here) ──HTTP──► Node/Pod
```

**Security analysis:**

| Concern | Impact in this architecture |
|---|---|
| **In-transit encryption** | Client ↔ ALB is encrypted (ACM cert, TLS 1.2/1.3). ALB ↔ Pod is unencrypted HTTP inside the VPC. |
| **VPC trust model** | AWS VPCs use private address space; inter-node traffic doesn't leave the VPC. Network ACLs and Security Groups restrict lateral access. |
| **Compliance requirements** | PCI-DSS, HIPAA, or FedRAMP may require end-to-end encryption. In that case, use `target-type: ip` with `alb.ingress.kubernetes.io/backend-protocol: HTTPS` and Pod-level TLS. |
| **Certificate management** | Only one certificate to manage (at ALB via ACM). Pods need no TLS config. |

**For this course's use case** (dev/staging retail demo), terminating at ALB is standard and sufficient. The ALB ↔ Pod path is inside an AWS-managed private network with Security Group enforcement.

---

### Q13. The course shows a CNAME record pointing to the ALB DNS name. What is the difference between a CNAME and an Alias record in Route53, and which should you use in production?

**Answer:**

| | CNAME | Alias Record |
|---|---|---|
| **Works at zone apex** | No (`stacksimplify.com` cannot be a CNAME) | Yes |
| **Can point to AWS resource** | Yes (by DNS hostname) | Yes (native AWS integration) |
| **DNS TTL billing** | Charged as standard DNS query | Free (no extra query charge) |
| **Route53 health check** | Not natively integrated | Can tie to ALB health — removes unhealthy endpoints from DNS |
| **Returns** | CNAME record → resolver follows chain | A/AAAA record directly (Route53 resolves the alias) |

**Production recommendation:** Use an **Alias record** targeting the ALB. Reasons:
1. ALBs can change IPs without notice — Alias tracks the current IPs automatically.
2. No extra TTL/query costs.
3. Health check integration means DNS automatically removes a failed ALB from resolution.
4. Required if you want the domain apex (e.g., `stacksimplify.com`) to resolve — CNAMEs are invalid at zone apex per RFC 1034.

---

## Cross-Section / Architectural Scenarios

---

### Q14. A teammate applies the HTTP ingress manifest but `kubectl get ingress` shows `ADDRESS` is empty after 10 minutes. Walk through your complete troubleshooting process.

**Answer:**

The `ADDRESS` is populated only when the LBC successfully provisions an ALB. Empty means the LBC either hasn't reconciled or hit an error.

**Step 1 — Verify LBC is running:**
```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller
```
If Pods are not `Running` → fix the controller first (check Pod Identity, Helm values, RBAC).

**Step 2 — Check LBC logs for errors:**
```bash
kubectl logs -n kube-system -l app.kubernetes.io/name=aws-load-balancer-controller --tail=100
```
Common errors:
- `AccessDenied` → IAM policy missing a permission or Pod Identity association is wrong.
- `VPC not found` → `vpcId` Helm value is wrong or empty.
- `subnet not tagged` → Subnets missing `kubernetes.io/role/elb: 1` tag (required for ALB to discover public subnets).

**Step 3 — Check Ingress events:**
```bash
kubectl describe ingress retail-store-http-instance-mode
```
Look at `Events:` section — LBC posts error events here.

**Step 4 — Verify `ingressClassName`:**
```bash
kubectl get ingressclass
```
Confirm `alb` IngressClass exists. Without it, no controller claims the Ingress.

**Step 5 — Check subnet tags:**
Public subnets must be tagged: 
```
kubernetes.io/cluster/<cluster-name>: shared
kubernetes.io/role/elb: 1
```
Private subnets for internal ALB: `kubernetes.io/role/internal-elb: 1`.

**Step 6 — Security Group check:**
The LBC creates Security Groups automatically, but your cluster node Security Group must allow traffic from the ALB SG on the NodePort range (default 30000-32767) for instance mode.

---

### Q15. You need to expose 3 microservices (catalog, cart, ui) through a single ALB with path-based routing and HTTPS. Design the complete Ingress manifest using the annotations from this course.

**Answer:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: retail-store-multi-path-https
  annotations:
    alb.ingress.kubernetes.io/load-balancer-name: retail-store-multi-path-https
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    # Health Check
    alb.ingress.kubernetes.io/healthcheck-protocol: HTTP
    alb.ingress.kubernetes.io/healthcheck-port: traffic-port
    alb.ingress.kubernetes.io/healthcheck-path: /actuator/health/readiness
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: '15'
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: '5'
    alb.ingress.kubernetes.io/success-codes: '200'
    alb.ingress.kubernetes.io/healthy-threshold-count: '2'
    alb.ingress.kubernetes.io/unhealthy-threshold-count: '2'
    # HTTPS
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}, {"HTTP":80}]'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:us-east-1:ACCOUNT:certificate/CERT-ID
    alb.ingress.kubernetes.io/ssl-redirect: '443'
spec:
  ingressClassName: alb
  rules:
    - http:
        paths:
          - path: /catalog
            pathType: Prefix
            backend:
              service:
                name: catalog
                port:
                  number: 8080
          - path: /cart
            pathType: Prefix
            backend:
              service:
                name: cart
                port:
                  number: 8080
          - path: /
            pathType: Prefix
            backend:
              service:
                name: ui
                port:
                  number: 80
```

**Key design decisions:**
- `target-type: ip` — all backends are ClusterIP services, direct pod routing.
- Rules are evaluated **top to bottom** — specific paths (`/catalog`, `/cart`) before the catch-all `/`.
- `ssl-redirect: '443'` ensures HTTP requests are upgraded before any path matching matters.
- All services share one ALB → one public DNS name → one ACM certificate → reduced cost.

---

### Q16. What is the security blast radius if the LBC IAM role is compromised? What limits the damage?

**Answer:**

The `AWSLoadBalancerControllerIAMPolicy` grants permissions to manage ALBs, NLBs, Target Groups, Security Groups, and read EC2/EKS metadata. If the role is compromised:

**Attacker can:**
- Create or delete ALBs/NLBs in your account — disrupting traffic routing.
- Modify Target Group registrations — redirect traffic to attacker-controlled IPs.
- Read VPC/subnet/security group configurations — reconnaissance for further attacks.
- Modify Security Groups attached to ALBs — potentially open ports.

**Attacker cannot (by policy boundary):**
- Access S3 buckets, RDS, DynamoDB, or other data services.
- Create EC2 instances or modify IAM roles (no `iam:*` permissions).
- Exfiltrate application data — only network path metadata.

**Mitigations already in place:**
1. **Pod Identity scoping:** Credentials are only injected into the specific ServiceAccount Pod — not available to other Pods even on the same node.
2. **Least-privilege policy:** The policy is purpose-built for LBC operations only.
3. **Session tags:** `sts:TagSession` allows CloudTrail to trace actions back to specific Pods.

**Additional hardening:**
- Enable ALB access logs to S3 — detect unusual routing changes.
- Set up CloudTrail alerts on `elasticloadbalancing:ModifyListener` or `ec2:AuthorizeSecurityGroupIngress`.
- Rotate Pod Identity associations periodically and audit with `aws eks list-pod-identity-associations`.

---

