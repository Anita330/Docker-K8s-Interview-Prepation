Interview Preparation Roadmap

The interview rubric tells you exactly what to study.

Priority 1: Kubernetes (Most Important)

Prepare:

Kubernetes Architecture
kube-apiserver
etcd
kube-scheduler
kube-controller-manager
kubelet
kube-proxy
CNI
Ingress
Service Types
StatefulSet vs Deployment
Network Policies
Cluster Autoscaler
HPA

Expect questions like:

How does pod scheduling work?
How does kube-proxy work in iptables and IPVS mode?
How does Kubernetes self-heal?
Explain pod lifecycle.
Explain EKS architecture.
Priority 2: Terraform

Prepare:

State file
Remote state
State locking
Modules
Workspaces
Data sources
Resource dependencies
Lifecycle rules
Import existing resources

Example questions:

Difference between resource and data source?
What is Terraform state?
How do you handle state conflicts?
How do modules work?
Priority 3: CI/CD

Study:

Jenkins pipelines
GitHub Actions
ArgoCD
Harness fundamentals

Questions:

Design a CI/CD pipeline.
Blue-Green deployment.
Canary deployment.
Rollback strategies.
GitOps workflow.
Priority 4: Linux

Since they explicitly mention Linux:

Prepare:

systemd
journalctl
top
ps
netstat
ss
strace
tcpdump
grep
awk
sed
tac
xargs

Questions:

Difference between process and thread?
How do you troubleshoot a high CPU issue?
How do you find which process is listening on a port?
Priority 5: AWS

Focus on:

VPC
IAM
EC2
EKS
ALB
NLB
Route 53
CloudWatch
Security Groups

Questions:

Explain VPC architecture.
Explain EKS networking.
Difference between ALB and NLB.
How does AWS VPC CNI work?
Priority 6: Scripting

Prepare Bash:

for file in *.txt
do
  echo $file
done

Topics:

Variables
Loops
Functions
Exit codes
Cron jobs
Log parsing
Priority 7: AI & Agentic AI

This is a newer section of the JD.

At minimum know:

GitHub Copilot
Cursor
AI-assisted code review
MCP (Model Context Protocol)
LangChain
AI Agents