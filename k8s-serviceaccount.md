# Kubernetes Service Account - Complete Guide

## Table of Contents

1. Introduction
2. What is a ServiceAccount?
3. Why ServiceAccount is Required?
4. How ServiceAccount Works Internally
5. Default ServiceAccount
6. ServiceAccount Authentication Flow
7. ServiceAccount vs User Account
8. Creating a ServiceAccount
9. Using ServiceAccount in Pods
10. ServiceAccount and RBAC
11. ServiceAccount in Amazon EKS
12. ServiceAccount with AWS Secrets Manager
13. ServiceAccount with EKS Pod Identity
14. Best Practices
15. Troubleshooting
16. Interview Questions

---

# 1. Introduction

A ServiceAccount provides an identity for applications running inside Kubernetes Pods.

Just as human users authenticate to Kubernetes using:

- Certificates
- IAM
- OIDC
- Tokens

Applications running inside Pods use ServiceAccounts.

---

# 2. What is a ServiceAccount?

A ServiceAccount is a Kubernetes resource that provides an identity to Pods.

Example:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
```

Create:

```bash
kubectl apply -f serviceaccount.yaml
```

Verify:

```bash
kubectl get sa
```

Output:

```text
NAME      SECRETS   AGE
app-sa    0         1m
```

---

# 3. Why ServiceAccount is Required?

A ServiceAccount is required when a Pod needs:

- Access to Kubernetes API
- RBAC permissions
- Access to AWS Services
- Access to Secrets Manager
- Access to S3
- Access to DynamoDB
- Access to SQS
- Access to Route53

Without ServiceAccount:

```text
Pod
 |
No Identity
 |
Access Denied
```

With ServiceAccount:

```text
Pod
 |
ServiceAccount
 |
Authenticated
 |
Authorized
```

---

# 4. How ServiceAccount Works Internally

When a Pod starts:

1. Kubernetes assigns a ServiceAccount.
2. A token is generated.
3. The token is mounted inside the Pod.
4. The Pod uses the token to authenticate.

Flow:

```text
Pod
 |
ServiceAccount
 |
Token
 |
API Server
 |
RBAC
 |
Response
```

---

# 5. Default ServiceAccount

Every namespace contains a ServiceAccount named:

```text
default
```

Check:

```bash
kubectl get sa
```

Output:

```text
NAME
default
```

If you do not specify a ServiceAccount:

```yaml
spec:
  containers:
  - name: nginx
    image: nginx
```

Kubernetes automatically uses:

```text
default ServiceAccount
```

---

# 6. ServiceAccount Authentication Flow

Authentication Process:

```text
Pod
 |
ServiceAccount Token
 |
API Server
 |
Authentication
 |
Authorization
 |
Response
```

The API Server verifies:

- Token validity
- ServiceAccount identity
- RBAC permissions

---

# 7. ServiceAccount vs User Account

| Feature | User | ServiceAccount |
|----------|----------|----------|
| Used By | Humans | Pods |
| Authentication | OIDC/Certificate/IAM | Token |
| Namespace Scoped | No | Yes |
| Used for Applications | No | Yes |
| RBAC Supported | Yes | Yes |

Example:

```text
Admin User
     |
kubectl
     |
API Server

Application
     |
ServiceAccount
     |
API Server
```

---

# 8. Creating a ServiceAccount

## serviceaccount.yaml

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
```

Apply:

```bash
kubectl apply -f serviceaccount.yaml
```

Verify:

```bash
kubectl get sa
```

Describe:

```bash
kubectl describe sa app-sa
```

---

# 9. Using ServiceAccount in Pods

## pod.yaml

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx
spec:
  serviceAccountName: app-sa

  containers:
  - name: nginx
    image: nginx
```

Apply:

```bash
kubectl apply -f pod.yaml
```

Verify:

```bash
kubectl get pod nginx -o yaml
```

---

# 10. ServiceAccount and RBAC

RBAC controls what a ServiceAccount can do.

## Role

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-reader

rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get","list","watch"]
```

---

## RoleBinding

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-reader-binding

subjects:
- kind: ServiceAccount
  name: app-sa

roleRef:
  kind: Role
  name: pod-reader
  apiGroup: rbac.authorization.k8s.io
```

---

## Authorization Flow

```text
Pod
 |
ServiceAccount
 |
RoleBinding
 |
Role
 |
Permission Granted
```

---

# 11. ServiceAccount in Amazon EKS

In EKS, ServiceAccounts are commonly used with IAM Roles.

Flow:

```text
Pod
 |
ServiceAccount
 |
IAM Role
 |
AWS Services
```

Applications can access:

- S3
- Secrets Manager
- SQS
- DynamoDB
- Route53

without AWS Access Keys.

---

# 12. ServiceAccount with AWS Secrets Manager

Example:

```text
Pod
 |
ServiceAccount
 |
IAM Role
 |
AWS Secrets Manager
```

Secret Retrieval:

```text
Pod
 |
CSI Driver
 |
Secrets Manager
 |
Secret Mounted
```

---

# 13. ServiceAccount with EKS Pod Identity

Modern EKS clusters support Pod Identity.

Flow:

```text
Pod
 |
ServiceAccount
 |
Pod Identity Agent
 |
IAM Role
 |
AWS API
```

Benefits:

- No AWS Keys
- Better Security
- Automatic Credential Rotation

Example:

```yaml
serviceAccountName: app-sa
```

Pod Identity Association:

```text
ServiceAccount
      |
IAM Role
```

---

# 14. Best Practices

## Use Dedicated ServiceAccounts

Good:

```text
frontend-sa
backend-sa
payment-sa
```

Bad:

```text
default
```

---

## Use Least Privilege

Allow only required permissions.

Good:

```text
List Pods
```

Bad:

```text
Cluster Admin
```

---

## Avoid Using Default ServiceAccount

Specify explicitly:

```yaml
serviceAccountName: app-sa
```

---

## Use IAM Roles Instead of AWS Keys

Avoid:

```text
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
```

Use:

```text
ServiceAccount
 |
IAM Role
```

---

# 15. Troubleshooting

## List ServiceAccounts

```bash
kubectl get sa
```

---

## Describe ServiceAccount

```bash
kubectl describe sa app-sa
```

---

## Check Pod ServiceAccount

```bash
kubectl get pod nginx -o yaml
```

Look for:

```yaml
serviceAccountName: app-sa
```

---

## Verify Token

Inside Pod:

```bash
ls /var/run/secrets/kubernetes.io/serviceaccount/
```

Output:

```text
ca.crt
namespace
token
```

---

## Check RBAC Access

```bash
kubectl auth can-i list pods \
--as=system:serviceaccount:default:app-sa
```

Output:

```text
yes
```

or

```text
no
```

---

# 16. Interview Questions

## What is a ServiceAccount?

A ServiceAccount provides an identity for Pods running inside Kubernetes.

---

## Why do we need ServiceAccounts?

To allow Pods to authenticate and access:

- Kubernetes API
- AWS Services
- Secrets Manager
- S3
- DynamoDB

securely.

---

## What is the difference between User and ServiceAccount?

Users are for humans.
ServiceAccounts are for applications running inside Pods.

---

## What is the default ServiceAccount?

Every namespace contains a ServiceAccount named:

```text
default
```

used automatically if no ServiceAccount is specified.

---

## How does ServiceAccount work with RBAC?

RBAC assigns permissions to ServiceAccounts through:

```text
Role
 |
RoleBinding
 |
ServiceAccount
```

---

## How does ServiceAccount work in EKS?

ServiceAccount is mapped to an IAM Role using:

- IRSA (IAM Roles for Service Accounts)
- EKS Pod Identity

allowing Pods to securely access AWS services without storing credentials.

---

# Summary

A ServiceAccount:

- Provides identity to Pods
- Enables Kubernetes API access
- Works with RBAC
- Works with IAM Roles
- Enables secure AWS access
- Is required for production-grade Kubernetes applications

Flow Summary:

```text
Pod
 |
ServiceAccount
 |
Authentication
 |
RBAC
 |
API Server
 |
AWS Services (Optional)
```

# ALB instance mode vs ip mode
In ALB Instance Mode, the ALB registers EC2 worker nodes as targets and forwards traffic to a NodePort service, which then routes traffic to Pods. In IP Mode, the ALB registers Pod IPs directly and sends traffic straight to the Pods. IP Mode is generally preferred in EKS because it provides direct routing, lower latency, better load distribution, and more efficient scaling. Instance Mode is mainly used for compatibility with environments where direct Pod IP targeting is not available.

| Feature                  | Instance Mode    | IP Mode   |
| ------------------------ | ---------------- | --------- |
| Target registered in ALB | EC2 Nodes        | Pod IPs   |
| Traffic path             | ALB → Node → Pod | ALB → Pod |
| Requires NodePort        | Yes              | No        |
| Extra network hop        | Yes              | No        |
| Performance              | Lower            | Better    |
| Load balancing           | Node level       | Pod level |
| Recommended for EKS      | No               | Yes       |
| AWS VPC CNI required     | No               | Yes       |


