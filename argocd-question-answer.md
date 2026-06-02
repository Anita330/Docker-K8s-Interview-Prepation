# ArgoCD Interview Questions and Answers

## Core Concepts

### 1. What is ArgoCD?
ArgoCD is a declarative GitOps continuous delivery tool for Kubernetes that syncs cluster state with the desired state stored in Git.

### 2. What problem does ArgoCD solve?
It keeps Kubernetes manifests in Git as the source of truth and continuously reconciles live cluster state with that desired state.

### 3. What is GitOps?
GitOps is an operating model where Git is the single source of truth for application and infrastructure configuration, and deployments happen by reconciling runtime state to Git state.

### 4. How is ArgoCD different from Jenkins?
Jenkins is primarily used for CI tasks such as build, test, and package. ArgoCD focuses on CD for Kubernetes using GitOps principles.

### 5. How does ArgoCD detect drift?
ArgoCD continuously compares the live cluster state with the desired state in Git and marks resources as out-of-sync when differences are found.

## Architecture

### 6. What are the main components of ArgoCD?
The main components are the API server, application controller, repository server, Redis, and the UI/CLI.

### 7. What does the application controller do?
The application controller monitors applications and continuously reconciles the live Kubernetes state with the desired Git state.

### 8. What is the role of the repository server?
The repository server fetches Git repositories and generates manifests from sources such as raw YAML, Helm, or Kustomize.

### 9. Why does ArgoCD use Redis?
Redis is used for caching and internal performance support.

### 10. What is the purpose of the ArgoCD API server?
It serves the UI, CLI, and external API requests, and handles authentication and authorization flows.

## Applications and Projects

### 11. What is an ArgoCD Application?
An Application represents a Kubernetes workload tracked from Git and deployed to a target cluster and namespace.

### 12. What is an AppProject?
An AppProject is a logical grouping that defines boundaries for repositories, destinations, and permissions.

### 13. How does ArgoCD support Helm and Kustomize?
ArgoCD can deploy applications defined with plain YAML, Helm charts, and Kustomize overlays directly from Git.

### 14. What is sync policy in ArgoCD?
Sync policy defines whether synchronization is manual or automated, including options like auto-sync and self-heal.

### 15. What is the difference between manual sync and auto-sync?
Manual sync requires a user to trigger deployment, while auto-sync reconciles changes automatically when Git changes are detected.

## Operations and Security

### 16. How does rollback work in ArgoCD?
ArgoCD keeps deployment history, so you can roll back to a previous Git revision or application version.

### 17. How do you secure ArgoCD in production?
Use RBAC, SSO/OIDC, repository access controls, HTTPS, and network policies.

### 18. How do you handle private repositories in ArgoCD?
Configure repository credentials securely and use credential templates where appropriate for scaling access across teams.

### 19. How do you manage multi-cluster deployments?
Use one ArgoCD control plane to manage multiple clusters and organize deployments using Applications or ApplicationSets.

### 20. What is ApplicationSet?
ApplicationSet helps generate and manage multiple ArgoCD Applications dynamically, which is useful for multi-cluster or multi-environment setups.

## Scenario-Based Questions

### 21. How do you handle configuration drift in ArgoCD?
Enable auto-sync and self-heal where appropriate, or alert on drift and reconcile it through Git changes.

### 22. How do you speed up deployment after a Git push?
Use webhooks so ArgoCD can detect repository changes faster and sync more quickly.

### 23. How would you design ArgoCD for a large organization?
Use AppProjects for boundaries, ApplicationSets for scale, RBAC for access control, and separate environments or clusters for isolation.

### 24. How do you deploy only to specific environments?
Use branch-based Git workflows and ArgoCD sync rules so dev, staging, and production map to separate paths or clusters.

### 25. What do you do if a deployment fails in ArgoCD?
Inspect sync status and health, review diffs, check application logs, and roll back to a known good Git revision if needed.

## Advanced Topics

### 26. What are the benefits of using ArgoCD with Kubernetes?
It provides declarative deployment, automatic reconciliation, versioned rollback, and consistent environment management.

### 27. How does ArgoCD fit into a CI/CD pipeline?
CI tools build and test artifacts, then ArgoCD handles the deployment phase by continuously reconciling Git and cluster state.

### 28. What is self-heal in ArgoCD?
Self-heal means ArgoCD can automatically correct live cluster changes that drift from Git.

### 29. What is prune in ArgoCD?
Prune removes Kubernetes resources that no longer exist in Git when syncing.

### 30. Why is ArgoCD popular for DevOps teams?
It simplifies Kubernetes deployment management, improves auditability, and makes Git the source of truth for production changes.