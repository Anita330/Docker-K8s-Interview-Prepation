Meeting Date: May 7, 2026 Duration: 52m 36s  

I. Terraform Versioning & Tooling 

Q1: How does Terraform handle specific version ranges in the required_version block? 

A: Terraform allows for defining valid conditions, such as >= 1.0.0, < 2.0.0, which considers all versions within that range. However, if you specify incompatible versions (e.g., both 1.2.7 and 1.6.5) in the same configuration, it will fail in the initial stage.  

Q2: What is the difference between the pessimistic constraint (~>) and the greater than or equal to operator (>=)? 

A: The ~> 5.1 operator allows updates only for the minor version (e.g., up to 5.x) and will not automatically upgrade to a major version change like 6.0. In contrast, >= 5.1 allows the system to move to the latest available version, regardless of major increments.  

Q3: How do tfenv and tfswitch differ from the Terraform code's required_version block? 

A: These tools manage Terraform versions on the host machine, allowing users to switch between multiple versions for different environments. The required_version block is defined within the code itself and specifies what version the infrastructure needs to run.  

Shape 

II. Infrastructure Migration & Modularization 

Q4: Why is a modular approach preferred over "vanilla" (raw) code? 

A: Modules provide several key benefits: 

Reusability: Code for common resources like VPCs can be reused across different projects or environments without rewriting.  

Scalability: They are ideal for large-scale environments due to their compatibility and organization.  

Isolation: When combined with workspaces, they help isolate environment-specific code.  

Versioning: They allow team members to tag specific releases (e.g., V1, V2) to control which version is used in different environments like Dev or Production.  

Q5: How do you safely migrate from vanilla code to a modular approach? 

A: You cannot simply run a new plan, as it would delete existing resources and recreate them under new module names. You must use the terraform state mv command to manually move the state of resources from their traditional addresses (e.g., aws_vpc.example) to their new modular addresses (e.g., module.vpc.aws_vpc.example).  

Q6: What is a "circular dependency" in modules and how is it resolved? 

A: This occurs when Module A's output is required for Module B, while Module B's output is simultaneously required for Module A. To resolve this, you must carefully manage outputs and variables by referring to the specific required resources or splitting layers to break the loop.  

Shape 

III. State Management, Recovery & Security 

Q7: How do you recover infrastructure if a state file is deleted from a remote backend (S3) without a backup? 

A: If the state is lost and no versioning is enabled, the infrastructure falls out of Terraform's management. To recover, you must manually map and import every existing resource one by one into a new state file using the terraform import command.  

Q8: What are the best practices for protecting a state file? 

A: * Enable Versioning: Always enable versioning on the S3 bucket to allow switching back to a previous state version.  

State Locking: Use remote backends (like S3 with DynamoDB) to lock the state during execution, preventing corruption from concurrent runs.  

Restrict Permissions: Implement strict IAM policies to prevent accidental deletion of the S3 backend.  

Q9: What happens if you run Terraform on an environment where the state file has been deleted? 

A: Terraform will not recognize the existing infrastructure and will attempt to create all new resources. This often leads to errors because resources with the same names already exist in the environment.  

Shape 

IV. Advanced Operations & Collaboration 

Q10: How do you destroy only a specific instance when using the count argument? 

A: Terraform assigns index numbers (starting at 0) to resources created with count. To delete a specific one (e.g., the third instance), you must use the target flag with its index: terraform destroy -target=aws_instance.example[2].  

Q11: How can a team ensure they work smoothly in a shared repository without affecting each other? 

A: * Branching Strategy: Use a feature-branching model where changes are pushed to a separate branch and peer-reviewed via Pull Requests before merging into main.  

Proper Tagging: Always refer to modules via specific version tags or release numbers rather than the "main" branch to avoid "nightmares" from unintended code changes.  

Q12: What is the risk of using force-unlock on a state file? 

A: While it can resolve deadlocks, if another user is actually in the middle of an apply and you force-unlock it, the state file could crash or become corrupted.  

Q13: What are Sentinel policies in Terraform Cloud? 

A: Sentinel is a policy-as-code framework used to verify that code meets organizational standards (like naming conventions for subnets) before it is allowed to be applied. 

 