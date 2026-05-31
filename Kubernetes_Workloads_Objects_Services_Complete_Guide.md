# Kubernetes Workloads, Objects, and Services - Complete Guide

This guide covers Pod, Deployment, ReplicaSet, StatefulSet, DaemonSet, Job, CronJob, Service, Ingress, ConfigMap, Secret, PV, PVC, StorageClass, Namespace, and ServiceAccount.

## Kubernetes Resource Categories

### Workloads
- Pod
- ReplicaSet
- Deployment
- StatefulSet
- DaemonSet
- Job
- CronJob

### Networking
- Service
- Ingress
- NetworkPolicy

### Configuration
- ConfigMap
- Secret

### Storage
- PV
- PVC
- StorageClass

### Security
- ServiceAccount
- RBAC Resources

## Deployment
Used for stateless applications.
Features: Rolling updates, Rollbacks, Scaling, Self-healing.

## StatefulSet
Used for databases and stateful workloads.
Features: Stable hostname, Persistent storage, Ordered startup.

## DaemonSet
Runs one Pod on every node.
Examples: Fluent Bit, Node Exporter, OpenTelemetry Collector.

## Job
Runs once and exits.

## CronJob
Runs on a schedule.

## Service
Provides stable networking for Pods.
Types: ClusterIP, NodePort, LoadBalancer, ExternalName.

## Ingress
Provides HTTP/HTTPS routing.

## ConfigMap
Stores non-sensitive configuration.

## Secret
Stores sensitive information.

## PV/PVC
PV = Actual Storage
PVC = Storage Request

## Resource Flow
Deployment -> ReplicaSet -> Pod -> Service -> Ingress

StatefulSet -> Pod -> PVC -> Storage
