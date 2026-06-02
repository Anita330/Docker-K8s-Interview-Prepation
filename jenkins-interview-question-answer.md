# Jenkins Interview Questions and Answers

## Core Concepts

### 1. What is Jenkins?
Jenkins is an open-source automation server used to build, test, and deploy software in CI/CD pipelines.

### 2. Why is Jenkins used in DevOps?
Jenkins automates software delivery, reduces manual effort, and helps teams implement continuous integration and continuous delivery.

### 3. What is a Jenkins job?
A Jenkins job is a configured task that performs a build, test, or deployment action.

### 4. What is the difference between Freestyle and Pipeline jobs?
Freestyle jobs are configured through the UI and are suitable for simple workflows. Pipeline jobs define the CI/CD process as code, making them better for complex and version-controlled workflows.

### 5. What is a Jenkinsfile?
A Jenkinsfile is a text file stored in source control that defines a Jenkins pipeline as code.

### 6. What is the difference between declarative and scripted pipelines?
Declarative pipelines use a structured syntax that is easier to read and maintain. Scripted pipelines use Groovy code and provide more flexibility for complex logic.

### 7. What are the main stages in a Jenkins pipeline?
A typical pipeline includes checkout, build, test, and deploy stages.

### 8. What is a Jenkins agent?
A Jenkins agent is a machine that runs pipeline tasks and build steps on behalf of the Jenkins controller.

### 9. What is the difference between Jenkins controller and agent?
The controller manages Jenkins configuration, scheduling, and orchestration. Agents execute the actual build jobs.

### 10. What is a Jenkins workspace?
The workspace is the directory where Jenkins checks out source code and runs build operations.

## Pipelines

### 11. How do you implement parallel execution in Jenkins?
Use the `parallel` block in a pipeline to run multiple stages or tasks simultaneously, reducing build time.

### 12. How do you make Jenkins pipelines reusable?
Use shared libraries, parameterized pipelines, and reusable templates to standardize logic across projects.

### 13. What is a multibranch pipeline?
A multibranch pipeline automatically creates jobs for branches and pull requests from a repository.

### 14. How do you manage branch-based pipelines?
Use multibranch pipelines so Jenkins can detect branches and run the correct Jenkinsfile automatically.

### 15. What is the role of build triggers?
Build triggers start jobs based on events such as SCM changes, webhooks, schedules, or upstream job completion.

### 16. How do you optimize pipeline performance?
Use parallel stages, caching, optimized agents, and avoid unnecessary workspace cleanup.

### 17. How do you troubleshoot a Jenkins pipeline failure?
Inspect console output, stage timing, agent logs, SCM checkout, environment variables, and plugin behavior.

### 18. How do you implement continuous delivery with Jenkins?
Set up a pipeline with build, test, approval, and deployment stages using automated checks before release.

### 19. How do you deploy across multiple environments?
Use separate pipeline stages for dev, test, and prod with approval gates or promotion steps between them.

### 20. How do you prevent build pollution between jobs?
Use isolated workspaces, clean agents, containerized builds, and avoid sharing mutable state between jobs.

## Plugins and Integrations

### 21. Why are Jenkins plugins important?
Plugins extend Jenkins functionality and let it integrate with Git, Docker, Kubernetes, SonarQube, Slack, and many other tools.

### 22. How do you integrate Jenkins with Git?
Use a Git plugin and configure repository URL, credentials, and branch strategy in the job or pipeline.

### 23. How do you integrate Jenkins with Docker?
Jenkins can build Docker images, run containers during tests, and push images to registries.

### 24. How do you integrate Jenkins with Kubernetes?
Use Kubernetes-based agents or pods so Jenkins can dynamically provision build environments on demand.

### 25. How do you integrate Jenkins with SonarQube?
Add pipeline stages to run code analysis and fail the build if quality gates are not met.

### 26. What is artifact management in Jenkins?
Artifact management is the process of storing build outputs such as JARs, WARs, Docker images, or deployment bundles for later use.

### 27. What is a Jenkins Shared Library?
A Shared Library is reusable pipeline code stored separately and imported into multiple Jenkinsfiles to reduce duplication.

### 28. What are node labels in Jenkins?
Labels are used to target builds to specific agents with required capabilities such as OS, tools, or hardware.

## Security

### 29. How do you secure Jenkins credentials?
Store credentials in Jenkins credentials management, restrict access by permissions, and avoid hardcoding secrets in pipelines.

### 30. What are Jenkins credentials?
Credentials are securely stored secrets such as usernames, passwords, SSH keys, or tokens used by jobs and pipelines.

### 31. Why is role-based access control important in Jenkins?
It limits what users can view or change, reducing the risk of unauthorized changes or secret exposure.

### 32. How do you secure a Jenkins pipeline?
Use least privilege, credentials binding, code review for Jenkinsfiles, secure plugins, and avoid exposing secrets in logs.

### 33. Why should containers or build agents not run as root?
Running as root increases the blast radius if a Jenkins agent or build container is compromised.

### 34. How do you manage secrets in a Jenkinsfile?
Use Jenkins credentials bindings or external secret stores and inject values at runtime rather than placing them directly in code.

## Storage, Backups, and Recovery

### 35. How do you back up Jenkins?
Back up Jenkins home, job configs, credentials, plugins, and pipeline definitions regularly so you can restore after failure.

### 36. What should be included in a Jenkins disaster recovery plan?
Include backups of Jenkins home, versioned pipeline code, plugin lists, credentials strategy, and restore procedures.

### 37. How do you restore Jenkins after a failure?
Restore Jenkins home and configuration from backup, verify plugins and credentials, then re-enable jobs carefully.

## Advanced Questions

### 38. What is the difference between Continuous Integration and Continuous Deployment?
Continuous Integration focuses on frequent merging and automated validation. Continuous Deployment automatically releases successful changes to production without manual approval.

### 39. What is the role of a Jenkins environment variable?
Environment variables provide runtime context such as branch name, build number, workspace path, or credentials references.

### 40. How do you create standardized CI/CD across multiple teams?
Use shared libraries, common pipeline templates, centralized credential controls, and policy-based approvals.

### 41. How do you handle dynamic agent provisioning?
Use Kubernetes or cloud plugins to create agents on demand based on workload and destroy them after the job completes.

### 42. What logs or metrics would you monitor in Jenkins?
Monitor build duration, queue time, agent utilization, job failure rates, plugin errors, and controller health.

### 43. What is the difference between a controller and a build executor?
The controller manages Jenkins; the executor is the runtime slot on an agent that actually runs a job.

### 44. What is the purpose of `.git` checkout in Jenkins?
It pulls source code from version control so the pipeline can build, test, and package the application.

### 45. What is the best practice for tagging artifacts or Docker images in Jenkins?
Use versioned or commit-based tags instead of relying only on `latest`.

## Scenario-Based

### 46. A Jenkins job keeps failing due to dependency issues. What do you do?
Check dependency versions, network access, cached artifacts, package repository availability, and ensure the build environment is reproducible.

### 47. A production deployment failed even though the build passed. What would you do?
Rollback to the last stable version, inspect pipeline logs, identify the faulty stage, and add checks to prevent recurrence.

### 48. How would you standardize CI/CD across multiple teams using Jenkins?
Use shared libraries, reusable pipeline templates, common security rules, and version-controlled Jenkinsfiles.

### 49. How would you make Jenkins builds faster?
Use parallel stages, caching, dedicated agents, cleaner workspaces, and ephemeral workers where possible.

### 50. Why is Jenkins popular for DevOps teams?
It supports pipeline-as-code, automation, extensibility, integrations, and flexible CI/CD workflows.