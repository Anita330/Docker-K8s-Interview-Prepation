# Linux Deep Dive Notes

# Chapter 10 - Linux Security Fundamentals

---

# 1. Introduction

Security is one of the most important responsibilities of a Linux administrator.

A Linux system may contain:

```text
User Data
Source Code
Databases
Financial Records
Cloud Credentials
SSH Keys
Production Applications
```

If attackers gain unauthorized access, the consequences can be severe.

Linux security is not a single feature.

Instead, Linux uses multiple layers:

```text
Authentication
Authorization
Permissions
Access Control
Network Security
Process Isolation
Auditing
```

This chapter explains the fundamental security mechanisms used in Linux systems.

---

# 2. Authentication vs Authorization

One of the most common interview questions.

Many people use these terms interchangeably.

They are different.

---

## Authentication

Answers:

```text
Who are you?
```

Examples:

```text
Username + Password
SSH Key
Fingerprint
Smart Card
```

Authentication verifies identity.

---

## Authorization

Answers:

```text
What are you allowed to do?
```

Examples:

```text
Read File
Start Service
Access Database
Install Software
```

Authorization determines permissions.

---

## Example

```text
Login Successful
```

means:

```text
Authentication Successful
```

But user may still be unable to:

```text
Read Sensitive Files
```

because authorization denies access.

---

# 3. Linux Security Layers

Modern Linux systems typically use:

```text
User Authentication
Password Policies
Permissions
ACLs
PAM
sudo
SELinux/AppArmor
Firewall
SSH Security
```

Each layer contributes to overall security.

---

# 4. What Is PAM?

PAM stands for:

```text
Pluggable Authentication Modules
```

One of the most important Linux security concepts.

---

## Why PAM Exists

Imagine:

```text
SSH Login
Console Login
sudo
FTP
```

All require authentication.

Without PAM:

Each application would implement authentication independently.

This creates:

```text
Duplication
Inconsistency
Maintenance Problems
```

---

## Solution

Centralized authentication framework.

```text
Application
      ↓
PAM
      ↓
Authentication Modules
```

---

# 5. PAM Architecture

Example:

```text
SSH
 ↓
PAM
 ↓
Password Check
 ↓
Account Policy Check
 ↓
Authentication Success
```

---

## Benefits

Applications do not need to know:

```text
Password Validation
Account Locking
MFA
Authentication Rules
```

PAM handles everything.

---

# 6. PAM Configuration

Stored in:

```text
/etc/pam.d/
```

Examples:

```text
/etc/pam.d/sshd
/etc/pam.d/login
/etc/pam.d/sudo
```

---

## Common Interview Question

Q:

What is PAM?

Answer:

```text
A framework that allows Linux applications
to use centralized authentication and
account management modules.
```

---

# 7. Understanding sudo

Many users know:

```bash
sudo command
```

but do not understand how it works.

---

## Why sudo Exists

Giving everyone:

```text
root password
```

is dangerous.

Problems:

```text
No Accountability
No Auditing
High Risk
```

---

## Solution

Grant specific privileges through sudo.

---

# 8. How sudo Works

Example:

```bash
sudo systemctl restart nginx
```

Flow:

```text
User
 ↓
sudo
 ↓
PAM Authentication
 ↓
Permission Check
 ↓
Command Runs As Root
```

---

# 9. sudo Configuration

Main file:

```text
/etc/sudoers
```

Should be edited using:

```bash
visudo
```

---

## Why visudo?

Prevents:

```text
Syntax Errors
Broken sudo Configuration
```

---

# 10. Example sudo Rule

```text
john ALL=(ALL) ALL
```

Meaning:

```text
john
can execute commands as any user.
```

---

# 11. Principle of Least Privilege

One of the most important security concepts.

Rule:

```text
Grant only the permissions required.
```

Example:

Bad:

```text
Full Root Access
```

Good:

```text
Only Restart Nginx
```

---

## Why?

Limits damage from:

```text
Mistakes
Compromised Accounts
Malicious Actions
```

---

# 12. Access Control Lists (ACLs)

Basic permissions support:

```text
Owner
Group
Others
```

Sometimes this is insufficient.

---

## Example Problem

Need:

```text
john → Read
alice → Read
bob → No Access
```

Basic permissions may not handle this cleanly.

---

## Solution

ACLs

Allow fine-grained permissions.

---

# 13. Viewing ACLs

Command:

```bash
getfacl file.txt
```

Example:

```text
user:john:r--
user:alice:r--
```

---

# 14. Setting ACLs

Example:

```bash
setfacl -m u:john:r file.txt
```

Meaning:

```text
Grant Read Access To John
```

---

## Why ACLs Exist

Provide more flexibility than:

```text
Owner
Group
Others
```

model alone.

---

# 15. SSH Fundamentals

SSH stands for:

```text
Secure Shell
```

Primary remote administration protocol for Linux.

---

## Why SSH Exists

Historically:

```text
Telnet
```

sent data in plaintext.

Attackers could capture:

```text
Passwords
Commands
Sensitive Data
```

---

## SSH Provides

```text
Encryption
Authentication
Integrity
```

---

# 16. SSH Architecture

Connection:

```text
Client
   ↓
Encrypted Channel
   ↓
Server
```

Example:

```bash
ssh user@server
```

---

# 17. SSH Authentication Methods

---

## Password Authentication

User enters:

```text
Username
Password
```

Server verifies credentials.

---

## SSH Key Authentication

Preferred method.

Uses:

```text
Private Key
Public Key
```

---

# 18. How SSH Keys Work

User generates:

```text
id_rsa
id_rsa.pub
```

or modern equivalents:

```text
id_ed25519
id_ed25519.pub
```

---

## Public Key

Stored on server:

```text
~/.ssh/authorized_keys
```

---

## Private Key

Remains with user.

Never shared.

---

## Authentication Flow

```text
Client Proves
Private Key Ownership
      ↓
Server Verifies
Using Public Key
```

---

# 19. Why SSH Keys Are Better

Advantages:

```text
No Password Transmission
Stronger Security
Automation Friendly
Resistant To Brute Force
```

---

# 20. Important SSH Configuration

File:

```text
/etc/ssh/sshd_config
```

Controls:

```text
Authentication
Port
Root Login
Key Usage
```

---

## Common Security Settings

Disable root login:

```text
PermitRootLogin no
```

Disable password login:

```text
PasswordAuthentication no
```

Require SSH keys.

---

# 21. What Is SELinux?

One of the most feared Linux interview topics.

SELinux stands for:

```text
Security Enhanced Linux
```

Originally developed by:

```text
NSA
```

---

## Why SELinux Exists

Traditional permissions answer:

```text
Which user owns this file?
```

But what if:

```text
Nginx Process
```

gets compromised?

Traditional permissions may not stop it.

---

## SELinux Adds

```text
Mandatory Access Control (MAC)
```

on top of standard permissions.

---

# 22. DAC vs MAC

Traditional Linux:

```text
DAC
Discretionary Access Control
```

Based on:

```text
Owner
Group
Permissions
```

---

SELinux:

```text
MAC
Mandatory Access Control
```

Additional security layer.

---

# 23. Example SELinux Protection

Suppose:

```text
nginx
```

is compromised.

Even as root:

SELinux may prevent:

```text
Access To Database Files
```

because policy denies it.

---

# 24. SELinux Modes

Command:

```bash
getenforce
```

---

## Enforcing

```text
Rules Applied
Violations Blocked
```

---

## Permissive

```text
Violations Logged
Not Blocked
```

---

## Disabled

```text
SELinux Off
```

---

# 25. AppArmor

Alternative to SELinux.

Common on:

```text
Ubuntu
```

---

## Purpose

Restrict application capabilities.

Example:

```text
Nginx
Can Read:
    /var/www

Cannot Read:
    /etc/shadow
```

---

## Difference

SELinux:

```text
Label-Based
```

AppArmor:

```text
Path-Based
```

---

# 26. Linux Firewalls

A firewall controls network traffic.

Purpose:

```text
Allow Desired Traffic
Block Unwanted Traffic
```

---

# 27. What Is iptables?

Traditional Linux firewall framework.

Rules determine:

```text
Allow
Reject
Drop
```

network packets.

---

## Example

Allow SSH:

```bash
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```

---

# 28. nftables

Modern replacement for:

```text
iptables
```

Provides:

```text
Better Architecture
Improved Performance
Simpler Rule Management
```

---

# 29. firewalld

Higher-level firewall manager.

Common on:

```text
RHEL
CentOS
Rocky Linux
```

---

## Example

Allow HTTP:

```bash
firewall-cmd --add-service=http
```

---

# 30. Security Zones

firewalld introduces:

```text
trusted
public
internal
dmz
```

zones.

Different trust levels for different networks.

---

# 31. Fail2Ban

Popular security tool.

Purpose:

```text
Detect Repeated Failures
Automatically Block Attackers
```

---

## Example

Repeated SSH failures:

```text
Attacker
    ↓
Many Failed Logins
    ↓
Fail2Ban Detects
    ↓
IP Blocked
```

---

# 32. Why Fail2Ban Matters

Protects against:

```text
Brute Force Attacks
Credential Guessing
```

---

# 33. Password Security

Good password policies should enforce:

```text
Length
Complexity
Expiration
Reuse Restrictions
```

---

## Common Mistake

Using:

```text
Password123
```

for administrative accounts.

---

# 34. File Integrity Concepts

Important files:

```text
/etc/passwd
/etc/shadow
/etc/sudoers
```

should be monitored.

Unexpected modifications may indicate compromise.

---

# 35. Security Hardening Checklist

Common server hardening steps:

---

## Disable Root SSH Login

```text
PermitRootLogin no
```

---

## Use SSH Keys

Avoid passwords.

---

## Enable Firewall

Restrict unnecessary ports.

---

## Keep System Updated

Install security patches.

---

## Remove Unused Services

Reduce attack surface.

---

## Use Least Privilege

Avoid unnecessary root access.

---

## Enable Auditing

Monitor activity.

---

## Review Logs

Detect suspicious behavior.

---

# 36. Security Auditing

Questions administrators should ask:

```text
Who Logged In?
Who Used sudo?
What Failed?
What Changed?
```

Logs help answer these questions.

---

# 37. Common Interview Questions

### Q1

Difference between:

```text
Authentication
Authorization
```

---

### Q2

What is PAM?

---

### Q3

How does sudo work?

---

### Q4

Why use visudo?

---

### Q5

What is the Principle of Least Privilege?

---

### Q6

What are ACLs?

---

### Q7

Difference between ACLs and traditional permissions?

---

### Q8

Why are SSH keys more secure than passwords?

---

### Q9

What is:

```text
authorized_keys
```

used for?

---

### Q10

Difference between:

```text
SELinux
AppArmor
```

---

### Q11

What is MAC?

---

### Q12

Difference between:

```text
DAC
MAC
```

---

### Q13

What is a firewall?

---

### Q14

Difference between:

```text
iptables
nftables
firewalld
```

---

### Q15

What problem does Fail2Ban solve?

---

# 38. Common Beginner Mistakes

## Mistake 1

Disabling SELinux instead of understanding it.

---

## Mistake 2

Allowing direct root SSH access.

---

## Mistake 3

Using passwords instead of SSH keys.

---

## Mistake 4

Giving users full sudo access unnecessarily.

---

## Mistake 5

Leaving unused services running.

---

## Mistake 6

Opening all firewall ports.

---

## Mistake 7

Ignoring authentication logs.

---

# 39. Summary

After completing this chapter you should understand:

✓ Authentication

✓ Authorization

✓ PAM

✓ sudo

✓ visudo

✓ Least Privilege

✓ ACLs

✓ getfacl

✓ setfacl

✓ SSH

✓ SSH Keys

✓ authorized_keys

✓ SSH Hardening

✓ SELinux

✓ AppArmor

✓ DAC

✓ MAC

✓ iptables

✓ nftables

✓ firewalld

✓ Fail2Ban

✓ Security Hardening

✓ Security Auditing

✓ Common Security Interview Questions

At this point you have built a strong Linux foundation covering:

* Filesystems
* Permissions
* Processes
* Users
* Storage
* Linux Internals
* Networking
* Boot Process
* Service Management
* Security

The next advanced chapter should be:

# Chapter 11 - Shells, Bash Scripting, Environment Variables, and Automation

covering:

* What a shell actually is
* Bash internals
* Variables
* Environment Variables
* PATH
* Shell Expansion
* Command Substitution
* Conditionals
* Loops
* Functions
* Script Execution
* Cron Jobs
* Automation Fundamentals

This chapter is extremely important because scripting is what turns Linux knowledge into practical administration and automation skills.
