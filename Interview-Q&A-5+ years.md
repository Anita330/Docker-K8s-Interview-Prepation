(CI/CD + GitHub + Production)

A developer pushes code to the main branch.

Your GitHub Actions pipeline starts and fails during deployment to Kubernetes.

Explain:
How would you troubleshoot the pipeline?
How would you determine whether the issue is:
GitHub Actions
Docker build
Image Registry
Kubernetes Deployment
Application
What logs would you check?
How would you perform a rollback?
How would you prevent this from happening in production again?

Answer exactly as you would in a real interview.

First, I would inspect the GitHub Actions workflow logs and identify the exact stage where the pipeline failed. If the failure occurs during Docker build, I would review the Dockerfile and build logs. If it occurs during image push, I would verify registry credentials and permissions. If deployment to Kubernetes fails, I would check kubeconfig access, service account permissions, deployment status, pod logs, and events. If the application is deployed but unhealthy, I would inspect pod logs and health checks. To recover quickly, I would perform a rollback using either Git revert or kubectl rollout undo. To prevent future failures, I would enforce pull request reviews, automated testing, staging validation, security scanning, and progressive deployment strategies such as canary or blue-green deployments.


# Production prevention
Pull Request Reviews
Branch Protection Rules
Unit Tests
Integration Tests
Security Scans
Staging Environment
Canary Deployment
Blue-Green Deployment
Automatic Rollback