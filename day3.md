Meeting Date: May 6, 2026
Duration: 44m 18s
I. Providers & Configuration
Q1: What are the primary definitions provided in the required_providers block?
•	A: The block primarily defines the source (the location of the provider in a registry, such as a namespace like HashiCorp) and the version (the specific version of the provider required for the code). 

Q2: Why do we define a version in the provider section specifically for production?
•	A: It is a best practice to use the equal to habit for versions in production to ensure stability and avoid accidental upgrades to incompatible provider versions. 


Q3: How can you manage a project that requires multiple regions or multiple third-party providers (e.g., AWS and Cloudflare/GoDaddy)?
•	A: You can define multiple provider blocks in your provider.tf file. To distinguish between them, you must use an alias. When defining a resource, you explicitly mention which aliased provider to use so that Terraform knows which target environment to apply the changes to. 


Q4: What is the purpose of the .terraform.lock.hcl file?
•	A: Once you initialize a repository, this file locks the provider versions to ensure that subsequent initializations use the exact same versions across different machines. It is recommended to commit this file to your version control system. 

________________________________________
II. Dependency Management & Lifecycles
Q5: What is the difference between Implicit and Explicit dependencies?
•	A: * Implicit: Terraform automatically detects dependencies when one resource refers to another using resource addresses (e.g., a subnet referring to a VPC ID). 

o	Explicit: Manually defined by the user using the depends_on meta-argument, used when Terraform cannot automatically determine the order of resource creation. 

Q6: What are the three critical lifecycle rules discussed?
•	A: * create_before_destroy: Ensures a new resource is provisioned before the old one is terminated, which is essential for achieving zero downtime in resources like EC2 instances or EKS node groups. 

o	ignore_changes: Instructs Terraform to ignore specific manual changes made to a resource in the cloud, preventing Terraform from trying to revert those changes during the next apply. 

o	prevent_destroy: Acts as a safety guard that prevents Terraform from destroying a resource even if a destroy command is issued. 
________________________________________
III. Commands & State Management
Q7: What are some essential "next-level" Terraform commands beyond the basic plan and apply?

•	A: * terraform refresh: Aligns the state file with the actual infrastructure in the cloud, specifically used if resources were manually deleted. 
o	terraform workspace: Used to create separate state files for different environments like Staging or Production within the same configuration. 
o	terraform state list/show: Used to view and manage resources currently tracked in the state file. 
o	terraform replace: Formerly known as taint, this command tells Terraform to delete and recreate a specific resource during the next apply. 


Q8: What is "Drift Detection"?
•	A: It is the process of identifying differences between the actual state of the cloud infrastructure and the configuration defined in your code, typically identified during a terraform plan. 

________________________________________
IV. Drawbacks & Challenges of Terraform
Q9: What are the primary drawbacks or limitations of using Terraform?
•	A: * Version Compatibility: Minimal version changes can sometimes break existing modules or data blocks, requiring frequent code updates. 

o	State Locking Issues: Only one person can work on the state at a time. If the state is not released properly, it requires a force-unlock, which risks corrupting the state file. 

o	Configuration Management: Terraform is primarily for infrastructure provisioning; it cannot manage application-level configuration internally and usually requires third-party tools (like Ansible). 

o	No Auto-Rollback: If an apply fails midway, Terraform does not automatically roll back to the previous state; users must manually identify the failure point and fix it. 

o	Race Conditions: Dependencies can sometimes lead to race conditions where resources fail to create because their prerequisites are not fully ready despite the code logic.

