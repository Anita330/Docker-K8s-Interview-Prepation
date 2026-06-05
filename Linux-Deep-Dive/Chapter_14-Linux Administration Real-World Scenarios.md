# Linux Deep Dive Notes

# Chapter 14 - Linux Administration Real-World Scenarios and Troubleshooting Playbooks

---

# 1. Introduction

Up until now we have learned:

```text
Filesystems
Permissions
Processes
Users
Networking
Storage
Security
Shell Scripting
Performance
Linux Internals
```

However, Linux interviews rarely ask only theory.

Most interviewers eventually move toward:

```text
Scenario-Based Questions
```

Examples:

```text
Production server is slow.
Disk is full.
Application won't start.
SSH stopped working.
Memory usage is increasing.
DNS resolution fails.
```

The interviewer is trying to evaluate:

```text
Your troubleshooting methodology
Your Linux understanding
Your ability to isolate root causes
```

This chapter focuses on how experienced Linux administrators approach problems.

---

# 2. Golden Rules of Troubleshooting

Before discussing specific scenarios, understand these principles.

---

## Rule 1

Do Not Panic

Bad:

```text
Service down
↓
Reboot Server
```

Good:

```text
Observe
Collect Evidence
Analyze
Act
```

---

## Rule 2

Always Gather Facts First

Check:

```text
Logs
Metrics
Processes
Services
Resources
```

before making changes.

---

## Rule 3

Never Assume

Bad:

```text
CPU high
↓
Must be application issue
```

Maybe:

```text
Disk issue
Memory issue
Network issue
```

---

## Rule 4

Change One Thing At A Time

Otherwise:

```text
Root Cause Becomes Unknown
```

---

## Rule 5

Always Verify Fixes

Example:

```text
Problem appears fixed
```

is not enough.

Confirm:

```text
Metrics Normal
Logs Healthy
Users Unaffected
```

---

# 3. Troubleshooting Framework

Experienced administrators often follow:

```text
Identify Problem
↓
Collect Information
↓
Form Hypothesis
↓
Test Hypothesis
↓
Implement Fix
↓
Validate Result
```

---

# 4. Scenario 1 - Disk Full

One of the most common Linux problems.

---

## Symptoms

```text
Application Errors
Cannot Write Logs
Database Failures
"No space left on device"
```

---

## Step 1

Check filesystems.

```bash
df -h
```

Example:

```text
Filesystem
/dev/sda2

Use%
100%
```

---

## Step 2

Identify large directories.

```bash
du -sh /*
```

---

## Step 3

Drill down.

```bash
du -sh /var/*
```

---

## Step 4

Locate large files.

```bash
find / -type f -size +1G
```

---

## Common Causes

```text
Log Files
Core Dumps
Backups
Database Files
Temporary Files
```

---

# 5. Famous Interview Question

Disk full.

```bash
df -h
```

shows:

```text
100%
```

But:

```bash
du -sh /
```

does not explain usage.

Why?

---

## Answer

Deleted file still open.

Example:

```text
Application
 ↓
Open Log File
 ↓
File Deleted
 ↓
Process Still Holds FD
```

Space remains allocated.

---

## Verify

```bash
lsof | grep deleted
```

---

# 6. Scenario 2 - High CPU Usage

---

## Symptoms

```text
Slow Server
High Load
Users Complain
```

---

## Step 1

Check CPU.

```bash
top
```

---

## Step 2

Identify process.

```text
PID
CPU%
COMMAND
```

---

## Step 3

Sort by CPU.

In:

```bash
top
```

press:

```text
P
```

---

## Step 4

Inspect process.

```bash
ps -fp PID
```

---

## Common Causes

```text
Infinite Loops
Runaway Scripts
Java Applications
Database Queries
Compression Jobs
```

---

# 7. Scenario 3 - High Load Average

Interview favorite.

---

Example:

```text
Load = 20
CPU = 10%
```

---

Question:

```text
Why?
```

---

Possible Answer:

```text
Processes Waiting On Disk I/O
```

---

Verify:

```bash
vmstat 1
```

Check:

```text
wa
```

(I/O Wait)

---

# 8. Scenario 4 - Memory Leak

---

## Symptoms

```text
Memory Usage Increasing
Eventually OOM
```

---

## Step 1

Check memory.

```bash
free -h
```

---

## Step 2

Identify processes.

```bash
top
```

Sort by memory.

Press:

```text
M
```

---

## Step 3

Monitor over time.

```bash
ps aux --sort=-%mem
```

---

## Common Causes

```text
Application Bugs
Improper Cleanup
Caching Problems
```

---

# 9. Scenario 5 - OOM Killer

---

## Symptoms

```text
Application Suddenly Stops
No Manual Kill
```

---

## Check Logs

```bash
dmesg
```

or

```bash
journalctl
```

---

Example:

```text
Out of memory:
Killed process 1234
```

---

## Root Cause

```text
System Exhausted RAM
Kernel Killed Process
```

---

# 10. Scenario 6 - Zombie Processes

---

## Symptoms

```text
ps
```

shows:

```text
Z
```

state.

---

## Verify

```bash
ps aux | grep Z
```

---

## Root Cause

```text
Parent Process
Did Not Reap Child
```

---

## Solution

Fix parent process.

Or restart parent.

---

## Important

Zombie process:

```text
Consumes PID
Not CPU
Not Memory
```

---

# 11. Scenario 7 - Service Fails To Start

Very common interview question.

---

## Step 1

Check status.

```bash
systemctl status nginx
```

---

## Step 2

Check logs.

```bash
journalctl -u nginx
```

---

## Step 3

Check configuration.

Example:

```bash
nginx -t
```

---

## Common Causes

```text
Syntax Errors
Port Conflicts
Permission Issues
Missing Files
```

---

# 12. Scenario 8 - Port Already In Use

---

## Example

```text
Bind failed
Address already in use
```

---

## Find Process

```bash
ss -tulpn
```

or

```bash
lsof -i :80
```

---

## Example Output

```text
PID 1234
nginx
```

---

Now investigate.

---

# 13. Scenario 9 - SSH Not Working

Another interview favorite.

---

## Step 1

Check service.

```bash
systemctl status sshd
```

---

## Step 2

Check listening port.

```bash
ss -tulpn | grep 22
```

---

## Step 3

Check firewall.

```bash
iptables -L
```

or

```bash
firewall-cmd --list-all
```

---

## Step 4

Check logs.

```bash
journalctl -u sshd
```

---

## Common Causes

```text
Firewall Rules
Service Down
Port Changes
Authentication Failures
```

---

# 14. Scenario 10 - DNS Resolution Failure

---

## Symptoms

```text
Cannot Reach Website By Name
```

But:

```text
IP Works
```

---

Example:

```bash
ping 8.8.8.8
```

works.

---

```bash
ping google.com
```

fails.

---

## Root Cause

Likely DNS issue.

---

## Verify

```bash
cat /etc/resolv.conf
```

---

Check:

```bash
nslookup google.com
```

or

```bash
dig google.com
```

---

# 15. Scenario 11 - Network Connectivity Failure

---

## Step 1

Check interface.

```bash
ip addr
```

---

## Step 2

Check route.

```bash
ip route
```

---

## Step 3

Check gateway.

```bash
ping gateway-ip
```

---

## Step 4

Check external connectivity.

```bash
ping 8.8.8.8
```

---

## Step 5

Check DNS.

```bash
nslookup google.com
```

---

# 16. Scenario 12 - Website Down

---

## Step 1

Check process.

```bash
ps aux | grep nginx
```

---

## Step 2

Check service.

```bash
systemctl status nginx
```

---

## Step 3

Check listening port.

```bash
ss -tulpn
```

---

## Step 4

Check firewall.

---

## Step 5

Test locally.

```bash
curl localhost
```

---

## Step 6

Review logs.

```bash
journalctl -u nginx
```

---

# 17. Scenario 13 - Filesystem Mounted Read-Only

---

## Symptoms

```text
Cannot Create Files
Read-only filesystem
```

---

## Verify

```bash
mount
```

---

Possible causes:

```text
Filesystem Corruption
Disk Errors
Kernel Protection
```

---

Check:

```bash
dmesg
```

---

# 18. Scenario 14 - Application Cannot Access File

---

## Verify

```bash
ls -l
```

Check:

```text
Owner
Group
Permissions
```

---

## Check ACLs

```bash
getfacl file
```

---

## Check SELinux

```bash
getenforce
```

---

Common causes:

```text
Permission Denied
ACL Restriction
SELinux Policy
```

---

# 19. Scenario 15 - Cron Job Not Running

---

## Verify Cron Service

```bash
systemctl status cron
```

or

```bash
systemctl status crond
```

---

## Verify Schedule

```bash
crontab -l
```

---

## Verify Logs

```bash
journalctl -u cron
```

---

## Common Causes

```text
Wrong PATH
Wrong Permissions
Script Failure
Incorrect Schedule
```

---

# 20. Scenario 16 - Slow Disk Performance

---

## Check

```bash
iostat -x 1
```

---

Look for:

```text
High await
High %util
```

---

## Verify

```bash
vmstat 1
```

Look at:

```text
wa
```

---

Common causes:

```text
Database Activity
Backup Jobs
Slow Storage
```

---

# 21. Scenario 17 - Application Hangs

---

## Check Process State

```bash
ps aux
```

---

Possible states:

```text
R Running
S Sleeping
D Uninterruptible Sleep
```

---

## Investigate

```bash
strace -p PID
```

---

Look for:

```text
Blocked System Calls
Waiting For Resources
```

---

# 22. Incident Response Mindset

Production troubleshooting is not:

```text
Guessing
```

It is:

```text
Observe
Measure
Verify
Fix
Validate
```

---

# 23. Common Linux Investigation Commands

CPU:

```bash
top
htop
```

---

Memory:

```bash
free -h
vmstat
```

---

Disk:

```bash
df -h
du -sh
iostat
```

---

Network:

```bash
ip addr
ip route
ss
ping
curl
```

---

Processes:

```bash
ps
top
lsof
strace
```

---

Services:

```bash
systemctl
journalctl
```

---

# 24. End-to-End Troubleshooting Checklist

When server is reported as:

```text
Slow
Broken
Unavailable
```

Follow:

---

Check:

```bash
uptime
```

---

Check:

```bash
top
```

---

Check:

```bash
free -h
```

---

Check:

```bash
df -h
```

---

Check:

```bash
ss -tulpn
```

---

Check:

```bash
systemctl status service
```

---

Check:

```bash
journalctl
```

---

Only then:

```text
Form Conclusions
```

---

# 25. Common Interview Questions

### Q1

Disk is full. How do you investigate?

---

### Q2

Difference between:

```bash
df
du
```

during troubleshooting?

---

### Q3

Load average is high but CPU low. Why?

---

### Q4

How do you identify a memory leak?

---

### Q5

What is OOM Killer?

---

### Q6

How do you troubleshoot SSH issues?

---

### Q7

Website down. Where do you start?

---

### Q8

Application cannot bind to port. Why?

---

### Q9

How do you identify a process holding a deleted file?

---

### Q10

How do you troubleshoot DNS issues?

---

### Q11

How would you investigate a slow Linux server?

---

### Q12

What is your troubleshooting methodology?

---

# 26. Common Beginner Mistakes

## Mistake 1

Restarting services immediately.

---

## Mistake 2

Ignoring logs.

---

## Mistake 3

Assuming cause without evidence.

---

## Mistake 4

Looking only at CPU.

---

## Mistake 5

Not checking disk space.

---

## Mistake 6

Ignoring SELinux/AppArmor.

---

## Mistake 7

Changing multiple things simultaneously.

---

# 27. Summary

After completing this chapter you should understand:

✓ Real-world Linux Troubleshooting

✓ Disk Full Investigation

✓ CPU Analysis

✓ Load Average Analysis

✓ Memory Leak Investigation

✓ OOM Killer Investigation

✓ Zombie Process Investigation

✓ Service Failures

✓ SSH Troubleshooting

✓ DNS Troubleshooting

✓ Network Troubleshooting

✓ Website Troubleshooting

✓ Read-only Filesystem Investigation

✓ Cron Troubleshooting

✓ Port Conflict Investigation

✓ strace-based Debugging

✓ Incident Response Mindset

✓ End-to-End Troubleshooting Workflow

✓ Scenario-Based Linux Interviews

---

# Linux Learning Journey Completed

After Chapters 1-14 you have covered:

✓ Linux Fundamentals

✓ Filesystems

✓ Permissions

✓ Users & Groups

✓ Processes

✓ Storage

✓ Linux Internals

✓ Networking

✓ Boot Process

✓ Systemd

✓ Security

✓ Bash Scripting

✓ Performance Analysis

✓ Advanced Linux Internals

✓ Production Troubleshooting

This knowledge base covers approximately **95% of Linux topics asked in Linux System Administrator, Infrastructure Engineer, Cloud Engineer, DevOps Engineer, Platform Engineer, and SRE interviews.**
