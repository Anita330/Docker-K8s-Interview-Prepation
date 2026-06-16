# Helm Complete Handbook for DevOps & Kubernetes Interviews

# Table of Contents

1. Introduction to Helm
2. Why Helm is Needed
3. Helm Architecture
4. Helm Components
5. Helm Installation
6. Helm Chart Structure
7. Chart.yaml
8. Values.yaml
9. Templates
10. Helm Functions
11. Helm Lifecycle
12. Helm Commands
13. Helm Packaging
14. Helm Repositories
15. Helm Releases
16. Helm Upgrade & Rollback
17. Helm Hooks
18. Helm Dependencies
19. Helm Best Practices
20. Helm Troubleshooting
21. Helm Interview Questions
22. Real-World DevOps Usage
23. Interview Cheat Sheet

---

# 1. Introduction to Helm

Helm is the package manager for Kubernetes.

Similarities:

| Technology  | Package Manager |
| ----------- | --------------- |
| Ubuntu      | apt             |
| RHEL/CentOS | yum/dnf         |
| NodeJS      | npm             |
| Python      | pip             |
| Kubernetes  | Helm            |

Without Helm:

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f ingress.yaml
kubectl apply -f configmap.yaml
kubectl apply -f secret.yaml
```

With Helm:

```bash
helm install myapp .
```

---

# 2. Why Helm is Needed

Problems Without Helm:

* Large number of YAML files
* Repeated configurations
* Difficult upgrades
* Difficult rollback
* Environment-specific configuration issues

Helm Solves:

* Packaging
* Templating
* Versioning
* Rollback
* Reusability

---

# 3. Helm Architecture

```text
Developer
    |
    v
Helm CLI
    |
    v
Chart
    |
    v
Templates + Values
    |
    v
Rendered YAML
    |
    v
Kubernetes API
    |
    v
Cluster
```

---

# 4. Helm Components

## Chart

Collection of Kubernetes manifests.

## Release

Running instance of a chart.

Example:

```bash
helm install prod-nginx nginx-chart
```

Release Name:

```text
prod-nginx
```

Chart Name:

```text
nginx-chart
```

## Repository

Storage location for Helm charts.

Examples:

* Bitnami
* Harbor
* Artifactory

---

# 5. Installing Helm

Linux:

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

Verify:

```bash
helm version
```

---

# 6. Create First Chart

```bash
helm create myapp
```

Generated Structure:

```text
myapp/
├── Chart.yaml
├── values.yaml
├── charts/
├── templates/
├── .helmignore
```

---

# 7. Chart.yaml

Contains chart metadata.

```yaml
apiVersion: v2
name: myapp
description: Sample Helm Chart
type: application
version: 1.0.0
appVersion: "1.0"
```

Fields:

| Field       | Purpose             |
| ----------- | ------------------- |
| apiVersion  | Helm API Version    |
| name        | Chart Name          |
| description | Description         |
| version     | Chart Version       |
| appVersion  | Application Version |

---

# 8. Values.yaml

Stores variables.

Example:

```yaml
replicaCount: 2

image:
  repository: nginx
  tag: latest

service:
  type: ClusterIP
  port: 80
```

Override Values:

```bash
helm install app . \
--set replicaCount=5
```

---

# 9. Templates

Deployment Example:

```yaml
apiVersion: apps/v1
kind: Deployment

metadata:
  name: {{ .Release.Name }}

spec:
  replicas: {{ .Values.replicaCount }}

  template:
    spec:
      containers:
      - image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
```

---

# 10. Helm Variables

## Values

```yaml
{{ .Values.replicaCount }}
```

## Release

```yaml
{{ .Release.Name }}
```

## Namespace

```yaml
{{ .Release.Namespace }}
```

## Chart

```yaml
{{ .Chart.Name }}
```

---

# 11. Useful Functions

Uppercase:

```yaml
{{ upper .Values.env }}
```

Lowercase:

```yaml
{{ lower .Values.env }}
```

Default:

```yaml
{{ default "nginx" .Values.image }}
```

Quote:

```yaml
{{ quote .Values.name }}
```

---

# 12. Helm Lifecycle

Create Chart

```bash
helm create myapp
```

Lint

```bash
helm lint myapp
```

Template

```bash
helm template myapp
```

Install

```bash
helm install app myapp
```

Upgrade

```bash
helm upgrade app myapp
```

Rollback

```bash
helm rollback app 1
```

Delete

```bash
helm uninstall app
```

---

# 13. Helm Package

Create package:

```bash
helm package myapp
```

Output:

```text
myapp-1.0.0.tgz
```

Install package:

```bash
helm install app myapp-1.0.0.tgz
```

---

# 14. Helm Repository

Add Repo:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
```

Update Repo:

```bash
helm repo update
```

Search:

```bash
helm search repo nginx
```

Install:

```bash
helm install nginx bitnami/nginx
```

---

# 15. Helm Release Commands

List Releases:

```bash
helm list
```

Release Status:

```bash
helm status app
```

Release History:

```bash
helm history app
```

---

# 16. Upgrade & Rollback

Upgrade:

```bash
helm upgrade app myapp
```

History:

```bash
helm history app
```

Rollback:

```bash
helm rollback app 2
```

Interview Point:

Helm stores release history as Kubernetes Secrets.

---

# 17. Helm Hooks

Pre-install:

```yaml
annotations:
  "helm.sh/hook": pre-install
```

Post-install:

```yaml
annotations:
  "helm.sh/hook": post-install
```

Other Hooks:

* pre-install
* post-install
* pre-upgrade
* post-upgrade
* pre-delete
* post-delete

---

# 18. Helm Dependencies

Chart.yaml

```yaml
dependencies:
  - name: mysql
    version: 9.4.6
    repository: https://charts.bitnami.com/bitnami
```

Update:

```bash
helm dependency update
```

---

# 19. Helm Secrets

Never store passwords directly.

Use:

* Kubernetes Secrets
* External Secrets Operator
* HashiCorp Vault

Example:

```yaml
env:
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: db-secret
      key: password
```

---

# 20. Helm Best Practices

Use values.yaml

Use helper templates

Separate environments

Use versioning

Use linting

Use rollback strategy

Keep secrets external

---

# 21. Troubleshooting

Validate:

```bash
helm lint myapp
```

Render YAML:

```bash
helm template myapp
```

Debug:

```bash
helm install app myapp --debug
```

Check Releases:

```bash
helm list
```

Check Status:

```bash
helm status app
```

---

# 22. Real Project Workflow

Developer updates code.

CI/CD pipeline:

```text
GitHub
  |
  v
Jenkins
  |
  v
Docker Build
  |
  v
Push Image
  |
  v
Helm Upgrade
  |
  v
Kubernetes
```

Deployment:

```bash
helm upgrade \
myapp \
helm-chart \
--set image.tag=v1.2.3
```

---

# 23. Most Asked Interview Questions

## What is Helm?

Helm is a package manager for Kubernetes used to package, deploy, upgrade, and rollback applications.

---

## What is a Chart?

A chart is a collection of Kubernetes manifests packaged together.

---

## What is a Release?

A release is an installed instance of a Helm chart.

---

## Difference Between Chart and Release?

Chart = Blueprint

Release = Running Deployment

---

## How Does Rollback Work?

```bash
helm history app
helm rollback app 1
```

---

## What is values.yaml?

Stores configurable parameters.

---

## What is Helm Template?

Converts templates into Kubernetes YAML manifests.

---

## Difference Between kubectl and Helm?

kubectl:

* Deploys raw YAML

Helm:

* Deploys packaged, versioned templates

---

# Interview Cheat Sheet

```bash
helm create myapp
helm lint myapp
helm template myapp
helm install app myapp
helm list
helm status app
helm history app
helm upgrade app myapp
helm rollback app 1
helm uninstall app
helm package myapp
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

Memory Trick:

CLTIUR

C = Create

L = Lint

T = Template

I = Install

U = Upgrade

R = Rollback
