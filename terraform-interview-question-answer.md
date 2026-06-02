# Terraform Interview Questions and Answers

## Core Terraform Concepts

### 1. What is Terraform and why is it used in infrastructure automation?  
Terraform is an Infrastructure as Code (IaC) tool by HashiCorp that lets you define, provision, and manage infrastructure using declarative configuration. It is used because it makes infrastructure version-controlled, repeatable, and easier to review before changes are applied.

### 2. What is the Terraform state file and why is it important?  
The state file maps Terraform configuration to real-world resources. It is important because Terraform uses it to determine what exists, what changed, and what needs to be created, updated, or destroyed.

### 3. What is a Terraform backend?  
A backend defines where Terraform stores state and how operations are executed. Common backends include S3, Azure Storage, Consul, and Terraform Cloud.

### 4. Why should state be stored remotely?  
Remote state improves collaboration, enables locking, supports backups, and reduces the risk of local state loss or corruption.

### 5. What is state locking?  
State locking prevents multiple users or pipelines from modifying the same state at the same time. This helps avoid race conditions and corrupted state.

### 6. What is the difference between Terraform plan and apply?  
`terraform plan` shows the changes Terraform intends to make. `terraform apply` executes those changes against the target infrastructure.

### 7. What does `terraform init` do?  
`terraform init` initializes the working directory, downloads providers and modules, and configures the backend.

### 8. What does `terraform validate` do?  
`terraform validate` checks whether the configuration is syntactically valid and internally consistent.

### 9. What does `terraform fmt` do?
`terraform fmt` formats Terraform files to a standard style.

### 10. What is `terraform taint`?  
`terraform taint` marks a resource for recreation on the next apply. In newer Terraform versions, `-replace` is preferred.

## Variables, Outputs, and Locals

### 11. What is a variable in Terraform?
Variables allow you to parameterize your configuration so the same code can be reused across environments.

### 12. What is the difference between input variables and output values?
Input variables provide values to modules or root configuration. Output values expose useful information after resources are created.

### 13. What are locals?
Locals define reusable expressions inside a configuration and help reduce repetition.

### 14. What is `terraform.tfvars` used for?
`terraform.tfvars` stores values for declared variables and is automatically loaded by Terraform.

### 15. How do you handle sensitive variables?
Mark them as sensitive, avoid hardcoding secrets, and use secret managers or environment variables instead.

## Resources and Data Sources

### 16. What is the difference between a resource and a data source?
A resource creates or manages infrastructure. A data source reads existing information without creating anything.

### 17. What is implicit dependency in Terraform?
Terraform creates an implicit dependency when one resource references another resource’s attributes.

### 18. What is explicit dependency?
You use `depends_on` when Terraform cannot automatically infer the dependency.

### 19. What are lifecycle rules?
Lifecycle rules control how Terraform manages a resource during updates, such as `create_before_destroy`, `prevent_destroy`, and `ignore_changes`.

### 20. When would you use `ignore_changes`?
Use it when certain fields are managed outside Terraform or when minor drift should not trigger replacement.

## Modules

### 21. What is a Terraform module?
A module is a reusable package of Terraform configuration that can include resources, variables, outputs, and provider settings.

### 22. Why use modules?
Modules improve reuse, consistency, maintainability, and standardization across environments.

### 23. What is the difference between root and child modules?
The root module is the main configuration directory. Child modules are reusable components called from the root module.

### 24. How do you version modules?
Use version tags, Git references, or registry versions so changes are controlled and predictable.

### 25. What is the Terraform Registry?
The Terraform Registry is a repository for public and private modules and providers.

## State Management

### 26. What happens if state is lost?
Terraform can no longer accurately track existing resources. You may need to restore a backup, import resources, or reconstruct state carefully.

### 27. How do you recover a corrupted state file?
Restore from backup or versioned remote storage, inspect with `terraform state pull`, and re-import resources if needed.

### 28. What is `terraform import` used for?
It brings existing infrastructure under Terraform management without recreating it.

### 29. Does `terraform import` generate configuration automatically?
No. It only updates state. You still need to write the matching configuration.

### 30. What is drift in Terraform?
Drift happens when real infrastructure changes outside Terraform and no longer matches the state or configuration.

## Workspaces and Environments

### 31. What are Terraform workspaces?
Workspaces let you use multiple state files with the same configuration, often for separate environments.

### 32. When should you avoid workspaces?
Avoid them when environments are very different or when stronger isolation is needed; separate directories are often clearer.

### 33. How do you manage dev, staging, and prod?
Common approaches include separate directories, separate state files, and environment-specific variable files.

### 34. Why is environment isolation important?
It prevents accidental changes to production and allows safer lifecycle management.

## Providers and Provisioners

### 35. What is a provider in Terraform?
A provider is the plugin that lets Terraform interact with an API, such as AWS, Azure, Kubernetes, or GitHub.

### 36. Can Terraform use multiple providers?
Yes. You can configure multiple provider instances and use aliases when needed.

### 37. What are provisioners?
Provisioners run scripts or commands on a resource after creation or before destruction.

### 38. Should you use provisioners often?
Usually no. They are a last resort because they are less reliable than native resource support or configuration tools.

## Advanced Questions

### 39. How does Terraform handle resource creation order?
Terraform builds a dependency graph and creates resources in the correct order based on references and explicit dependencies.

### 40. What is `for_each` used for?
`for_each` creates multiple 