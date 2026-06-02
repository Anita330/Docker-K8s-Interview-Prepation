# Kubernetes Interview Questions and Answers

## Core Concepts

### 1. What is Kubernetes?
Kubernetes is an open-source container orchestration platform used to deploy, scale, and manage containerized applications across clusters.

### 2. Why is Kubernetes used?
Kubernetes automates scheduling, scaling, self-healing, service discovery, and rolling updates for containerized workloads.

### 3. What is the difference between a container and a pod?
A container runs one application process, while a pod is the smallest deployable unit in Kubernetes and can contain one or more tightly coupled containers.

### 4. What is the role of the control plane?
The control plane makes global decisions about the cluster, such as scheduling, maintaining desired state, and responding to events.

### 5. What is the scheduler?
The scheduler assigns pending pods to nodes based on resource availability, constraints, affinity, taints, and other policies.

### 6. What is etcd?
etcd is the distributed key-value store that stores cluster state and configuration data.

### 7. What is kubelet?
The kubelet runs on each node, ensures containers described in pod specs are running, and reports status back to the control plane.

### 8. What is kube-proxy?
kube-proxy handles networking rules and service traffic routing on nodes.

## Pods and Workloads

### 9. What is a Deployment?
A Deployment manages stateless applications and provides declarative updates, scaling, and rollbacks through ReplicaSets.

### 10. What is a StatefulSet?
A StatefulSet manages stateful applications that need stable network identities, stable storage, and ordered deployment.

### 11. What is a DaemonSet?
A DaemonSet ensures a copy of a pod runs on all or selected nodes, often used for logging or monitoring agents.

### 12. What is a Job?
A Job runs a task to completion and is suitable for batch or one-time work.

### 13. What is a CronJob?
A CronJob runs Jobs on a scheduled basis using a cron expression.

### 14. What is a ReplicaSet?
A ReplicaSet ensures a desired number of pod replicas are running at all times.

## Networking

### 15. What is a Service in Kubernetes?
A Service provides a stable IP, DNS name, and load balancing for a group of pods.

### 16. What are the types of Kubernetes Services?
Common service types are ClusterIP, NodePort, LoadBalancer, and ExternalName.

### 17. What is an Ingress?
Ingress manages external HTTP/HTTPS access to services in a cluster, typically through an Ingress Controller.

### 18. What is a NetworkPolicy?
A NetworkPolicy controls traffic flow between pods and namespaces.

### 19. How does Kubernetes provide service discovery?
Services are discoverable through DNS and environment variables injected into pods.

## Configuration and Storage

### 20. What is a ConfigMap?
A ConfigMap stores non-sensitive configuration data separately from container images.

### 21. What is a Secret?
A Secret stores sensitive data such as passwords, tokens, or certificates.

### 22. What is a PersistentVolume?
A PersistentVolume is cluster-level storage provisioned by an admin or storage class.

### 23. What is a PersistentVolumeClaim?
A PersistentVolumeClaim requests storage for a pod.

### 24. What is a StorageClass?
A StorageClass defines how persistent storage should be provisioned dynamically.

### 25. What is `emptyDir`?
`emptyDir` is a temporary volume that is created when a pod is assigned to a node and removed when the pod is deleted.

## Scheduling and Placement

### 26. What are labels and selectors?
Labels are key-value pairs used to organize objects. Selectors filter and match resources based on labels.

### 27. What are taints and tolerations?
Taints repel pods from nodes, and tolerations allow pods to be scheduled onto tainted nodes.

### 28. What is node affinity?
Node affinity lets you schedule pods onto nodes that match specific labels or conditions.

### 29. What is pod affinity and anti-affinity?
Pod affinity places pods near certain pods, while anti-affinity spreads pods apart to improve resilience.

### 30. What is a PodDisruptionBudget?
A PodDisruptionBudget limits voluntary disruptions so a minimum number of pods stay available.

### 31. What is ResourceQuota?
A ResourceQuota limits total resource consumption in a namespace.

### 32. What is LimitRange?
LimitRange sets default and maximum resource requests and limits for containers in a namespace.

## Health and Reliability

### 33. What is the difference between readiness and liveness probes?
Readiness probes determine whether a pod can receive traffic. Liveness probes determine whether a container should be restarted.

### 34. What is a startup probe?
A startup probe gives a slow-starting application extra time before liveness checks begin.

### 35. What happens when a node fails?
The node becomes NotReady, pods are rescheduled by controllers, and replacement capacity may be created depending on the platform.

### 36. How does Kubernetes perform rolling updates?
Kubernetes gradually replaces old pods with new ones based on the Deployment strategy and availability settings.

### 37. How do you roll back a failed deployment?
Use `kubectl rollout undo deployment <name>` to revert to a previous ReplicaSet revision.

### 38. What is `terminationGracePeriodSeconds`?
It defines how long Kubernetes waits for a pod to shut down gracefully before forcefully killing it.

## Security

### 39. What is RBAC?
Role-Based Access Control controls what users and service accounts can do in the cluster.

### 40. What is a ServiceAccount?
A ServiceAccount provides an identity for processes running in pods.

### 41. How do you secure secrets in Kubernetes?
Use encryption at rest, RBAC, external secret managers, and avoid storing plaintext secrets in manifests.

### 42. What is Pod Security?
Pod security defines policies to restrict risky pod behavior such as running as root or using privileged containers.

### 43. What are admission controllers?
Admission controllers intercept API requests and can validate or mutate resources before they are persisted.

### 44. What are mutating and validating webhooks?
Mutating webhooks modify objects before creation or update. Validating webhooks check whether objects comply with policies.

## Troubleshooting

### 45. How do you debug a CrashLoopBackOff pod?
Check logs, describe the pod, inspect events, verify probes, and look for OOMKilled or configuration issues.

### 46. How do you debug a pod stuck in Pending?
Check resource availability, node selectors, taints, PVC binding, affinity rules, and scheduler events.

### 47. How do you debug image pull errors?
Verify the image name, tag, registry access, image pull secrets, and network connectivity.

### 48. How do you inspect logs for a completed Job?
Use `kubectl logs` on the pod created by the Job, or inspect previous container logs if the pod restarted.

### 49. What does `kubectl drain` do?
It safely evicts pods from a node so the node can be maintained or upgraded.

### 50. What is the purpose of `kubectl cordon`?
It marks a node as unschedulable so no new pods are placed on it.

## Advanced Topics

### 51. What is the difference between Deployment, ReplicaSet, and ReplicationController?
ReplicationController is legacy. ReplicaSet is its newer replacement. Deployment manages ReplicaSets and adds rollout and rollback features.

### 52. What are finalizers?
Finalizers are metadata keys that block deletion until cleanup logic completes.

### 53. Why do resources sometimes stay in Terminating state?
A finalizer may be preventing deletion, or a dependent resource cleanup may not have completed.

### 54. What is a CSI driver?
A CSI driver enables Kubernetes to work with external storage systems using a standard interface.

### 55. What are CSI snapshots useful for?
They provide volume-level backups that help with disaster recovery and data protection.

### 56. What is a sidecar container?
A sidecar is a helper container in the same pod that provides supporting functionality such as logging, proxying, or config sync.

### 57. What is an init container?
An init container runs before the main containers start and performs initialization tasks.

### 58. How do you implement canary deployments in Kubernetes?
Use progressive delivery tools such as Argo Rollouts or service mesh traffic splitting to gradually shift traffic to the new version.

### 59. How do you secure communication within a namespace?
Use NetworkPolicies with a default-deny model and allow only required ingress and egress paths.

### 60. How do you design multi-tenant Kubernetes clusters?
Use namespaces, RBAC, resource quotas, network policies, separate node pools, and strong admission controls.

## Observability and Operations

### 61. How do you monitor Kubernetes?
Use metrics, logs, and traces through tools like Prometheus, Grafana, EFK, or cloud-native observability stacks.

### 62. What are the pros and cons of centralized logging?
It improves search and troubleshooting, but can add storage cost, ingestion overhead, and operational complexity.

### 63. What is audit logging?
Audit logging records Kubernetes API activity for compliance and security tracking.

### 64. How do you inspect cluster health?
Check node status, pod status, events, controller health, metrics, and API server availability.

### 65. What are common anti-patterns in Kubernetes?
Common anti-patterns include using `latest` tags, missing requests and limits, running as root, and putting too much logic in a single container image.

## Scenario-Based Questions

### 66. A pod keeps restarting. How do you investigate?
Check pod logs, describe the pod, verify probes, inspect environment variables, and look for memory or CPU issues.

### 67. A service is not reachable from another pod. What do you check?
Verify the service selector, pod labels, endpoints, NetworkPolicies, DNS resolution, and target port configuration.

### 68. A deployment is not rolling out. What do you check?
Inspect events, probe failures, image availability, resource constraints, and rollout history.

### 69. A node is under high pressure. What do you do?
Check CPU, memory, disk pressure, evict unnecessary workloads, and move critical pods to healthier nodes.

### 70. How do you safely upgrade a Kubernetes node?
Cordon the node, drain it, upgrade it, validate workloads, and then uncordon it.

### 71. How do you manage scheduled workloads?
Use CronJobs for recurring tasks and Jobs for one-time batch processing.

### 72. How do you expose multiple services through one Ingress?
Define multiple rules or paths in a single Ingress resource and route each path to the correct backend service.

### 73. How do you handle manifest differences across environments?
Use Helm values, Kustomize overlays, or GitOps directory structures to keep environment-specific changes manageable.

### 74. How do you minimize container startup time?
Use smaller images, reduce initialization work, optimize dependencies, and avoid unnecessary startup steps.

### 75. Why is Kubernetes widely used in production?
It provides portability, automation, scaling, self-healing, and a strong ecosystem for cloud-native applications.