# Linux Deep Dive Notes

# Chapter 12 - Linux Performance Monitoring and Troubleshooting

---

# 1. Introduction

One of the biggest differences between a Linux user and a Linux administrator is troubleshooting.

A user asks:

```text
Why is my application slow?
```

An administrator asks:

```text
Is the bottleneck CPU?
Memory?
Disk?
Network?
Application?
Database?
```

Performance troubleshooting is not about memorizing commands.

It is about understanding:

```text
How Linux uses resources
How workloads affect the system
How to identify bottlenecks
How to verify assumptions
```

This chapter focuses on performance analysis and troubleshooting from a Linux interview perspective.

---

# 2. The Four Primary System Resources

Almost every performance problem belongs to one or more of these categories:

```text
CPU
Memory
Disk
Network
```

Think of them as:

```text
CPU     = Compute Power
Memory  = Working Area
Disk    = Storage Speed
Network = Communication Speed
```

---

# 3. Performance Troubleshooting Methodology

Never start troubleshooting randomly.

Always follow a structured approach.

---

## Wrong Approach

```text
Server Slow
↓
Restart Everything
```

---

## Correct Approach

```text
Problem Reported
↓
Collect Evidence
↓
Identify Bottleneck
↓
Verify Findings
↓
Implement Fix
↓
Validate Results
```

---

# 4. Understanding CPU Utilization

CPU utilization indicates how busy the processor is.

Example:

```text
0%
```

CPU idle.

Example:

```text
100%
```

CPU fully utilized.

---

## Important Clarification

100% CPU does NOT always mean a problem.

Example:

```text
Video Encoding
Scientific Computation
Large Data Processing
```

may legitimately use full CPU.

---

# 5. Viewing CPU Usage

Command:

```bash
top
```

Shows:

```text
CPU Usage
Memory Usage
Processes
Load Average
```

---

Example:

```text
%Cpu(s):
10 us
5 sy
85 id
```

---

# 6. CPU States

Top breaks CPU usage into categories.

---

## us (User)

Time spent running user processes.

Example:

```text
Python
Java
NodeJS
```

---

## sy (System)

Time spent executing kernel code.

Example:

```text
Filesystem Operations
Networking
System Calls
```

---

## id (Idle)

Unused CPU time.

Example:

```text
90% id
```

means CPU is mostly free.

---

## wa (I/O Wait)

CPU waiting for disk operations.

Example:

```text
Slow Storage
Heavy Database Activity
```

---

## st (Steal)

Important in virtualization.

Time stolen by hypervisor.

Example:

```text
AWS
VMware
KVM
```

---

## Interview Question

Q:

High CPU or high load?

Which is worse?

Answer:

Neither alone.

Need context.

---

# 7. What Is Load Average?

One of the most misunderstood Linux concepts.

---

## Common Misconception

Many people think:

```text
Load Average = CPU Usage
```

This is incorrect.

---

## Actual Meaning

Load Average measures:

```text
Processes Waiting For CPU
+
Processes Waiting For Uninterruptible I/O
```

---

# 8. Viewing Load Average

Command:

```bash
uptime
```

Example:

```text
load average: 1.50 1.20 1.10
```

---

## Three Numbers

Represent:

```text
1 Minute Average
5 Minute Average
15 Minute Average
```

---

# 9. How To Interpret Load Average

Suppose:

```text
4 CPU Cores
```

---

Load:

```text
4.0
```

means:

```text
System Fully Utilized
```

---

Load:

```text
8.0
```

means:

```text
Processes Waiting
```

---

Load:

```text
1.0
```

means:

```text
Plenty Of Capacity
```

---

## Interview Question

Q:

Is load average of 10 bad?

Answer:

Depends on CPU count.

```text
Load 10 on 64 CPUs = Fine

Load 10 on 2 CPUs = Problem
```

---

# 10. Process Monitoring

Most troubleshooting starts by identifying resource-hungry processes.

---

## top

```bash
top
```

Shows:

```text
CPU Usage
Memory Usage
Load Average
Running Processes
```

---

## htop

```bash
htop
```

Enhanced version of top.

Features:

```text
Better Interface
Process Tree
Mouse Support
```

---

# 11. Memory Fundamentals

Memory stores active data.

Without memory:

```text
CPU cannot work efficiently.
```

---

Memory contains:

```text
Running Programs
Caches
Buffers
Kernel Data
```

---

# 12. Viewing Memory Usage

Command:

```bash
free -h
```

Example:

```text
total
used
free
shared
buff/cache
available
```

---

# 13. Understanding Free Memory

One of the most common interview traps.

---

Suppose:

```text
RAM = 16 GB
Free = 500 MB
```

Does this mean memory problem?

Not necessarily.

---

Linux aggressively uses RAM for:

```text
Filesystem Cache
Buffers
Performance Optimization
```

Unused RAM is wasted RAM.

---

# 14. The Most Important Memory Field

Look at:

```text
available
```

instead of:

```text
free
```

---

Example:

```text
Free: 500 MB
Available: 8 GB
```

System is healthy.

---

# 15. What Is Cache?

Linux caches frequently accessed data.

Example:

```text
File Read Once
↓
Stored In RAM
↓
Future Reads Faster
```

---

Benefits:

```text
Reduced Disk Access
Improved Performance
```

---

# 16. What Is Swap?

Swap is disk space used as emergency memory.

---

Example:

```text
RAM Full
↓
Kernel Moves Inactive Pages
↓
Swap
```

---

# 17. Why Swap Exists

Prevents:

```text
Out Of Memory Conditions
```

Provides:

```text
Memory Pressure Relief
```

---

# 18. Swap Is Not Extra RAM

Common misconception.

Swap is:

```text
Much Slower Than RAM
```

Because:

```text
Disk
≠
Memory
```

---

# 19. Viewing Swap Usage

```bash
free -h
```

or

```bash
swapon --show
```

---

# 20. What Happens When Memory Is Exhausted?

Kernel invokes:

```text
OOM Killer
```

---

OOM:

```text
Out Of Memory
```

---

Kernel selects processes and kills them.

Goal:

```text
Keep System Alive
```

---

## Interview Question

Q:

What is OOM Killer?

Answer:

Kernel mechanism that terminates processes when memory is exhausted.

---

# 21. vmstat

Powerful performance command.

Example:

```bash
vmstat 1
```

Updates every second.

---

Displays:

```text
CPU
Memory
Swap
Processes
I/O
```

all together.

---

# 22. Key vmstat Fields

---

## r

Runnable processes.

Waiting for CPU.

---

## b

Processes blocked on I/O.

---

## si

Swap In

---

## so

Swap Out

---

## wa

I/O Wait

---

Useful for identifying bottlenecks.

---

# 23. Disk Performance

Storage often becomes a bottleneck.

Symptoms:

```text
Slow Application
High Load
Database Delays
```

---

# 24. What Is I/O?

I/O means:

```text
Input / Output
```

Typically:

```text
Disk Reads
Disk Writes
```

---

# 25. iostat

Disk performance monitoring.

Provided by:

```text
sysstat package
```

---

Example:

```bash
iostat -x 1
```

---

Displays:

```text
Read Rates
Write Rates
Utilization
Latency
```

---

# 26. Important iostat Fields

---

## %util

Disk utilization.

---

Example:

```text
100%
```

means disk fully busy.

---

## await

Average wait time.

Measures latency.

Higher values indicate slower storage.

---

## r/s

Reads per second.

---

## w/s

Writes per second.

---

# 27. Disk Bottleneck Indicators

Common symptoms:

```text
High wa
High await
High %util
```

Together suggest storage issues.

---

# 28. Network Troubleshooting Basics

Network issues often appear as:

```text
Slow Application
Connection Failures
Timeouts
```

---

# 29. Check Interface Statistics

Command:

```bash
ip -s link
```

Displays:

```text
Packets
Errors
Drops
```

---

# 30. Network Connectivity Tests

---

## ping

```bash
ping host
```

Tests reachability.

---

## traceroute

```bash
traceroute host
```

Shows path through network.

---

## curl

```bash
curl URL
```

Tests application-layer connectivity.

---

# 31. Socket Inspection

Command:

```bash
ss -tulpn
```

Shows:

```text
Listening Ports
Active Connections
Associated Processes
```

---

Useful for:

```text
Application Troubleshooting
```

---

# 32. sar Command

Part of:

```text
sysstat
```

package.

---

Purpose:

```text
Historical Performance Data
```

---

Example:

```bash
sar -u
```

CPU statistics.

---

```bash
sar -r
```

Memory statistics.

---

```bash
sar -n DEV
```

Network statistics.

---

# 33. Why sar Is Powerful

Most tools show:

```text
Current State
```

sar shows:

```text
Past Performance
```

Useful when issue occurred earlier.

---

# 34. Linux Performance Analysis Workflow

Suppose:

```text
Application Slow
```

---

Step 1:

```bash
uptime
```

Check load.

---

Step 2:

```bash
top
```

Check CPU and memory.

---

Step 3:

```bash
free -h
```

Check memory pressure.

---

Step 4:

```bash
vmstat 1
```

Check CPU, I/O, swap.

---

Step 5:

```bash
iostat -x 1
```

Check disk performance.

---

Step 6:

```bash
ss -tulpn
```

Check networking.

---

Step 7:

```bash
journalctl
```

Check logs.

---

# 35. Real Interview Scenario 1

Question:

```text
Server load is 20.
CPU usage only 15%.
Why?
```

Possible Answer:

```text
Processes waiting on disk I/O.

High load does not necessarily mean high CPU.
```

---

# 36. Real Interview Scenario 2

Question:

```text
Memory usage shows 95%.
Is this a problem?
```

Answer:

```text
Need to inspect available memory.

Linux uses RAM for cache.
```

---

# 37. Real Interview Scenario 3

Question:

```text
Application slow.
CPU low.
Memory healthy.
Disk utilization 100%.
```

Likely:

```text
Storage Bottleneck
```

---

# 38. Real Interview Scenario 4

Question:

```text
Server becomes slow and processes disappear.
```

Possible Cause:

```text
OOM Killer
```

Check:

```bash
dmesg
```

or

```bash
journalctl
```

for OOM events.

---

# 39. Common Interview Questions

### Q1

What is load average?

---

### Q2

Difference between CPU utilization and load average?

---

### Q3

How do you check memory usage?

---

### Q4

Why is Linux using all available RAM?

---

### Q5

What is swap?

---

### Q6

What is OOM Killer?

---

### Q7

How do you identify a CPU bottleneck?

---

### Q8

How do you identify a disk bottleneck?

---

### Q9

Purpose of vmstat?

---

### Q10

Purpose of iostat?

---

### Q11

Purpose of sar?

---

### Q12

Why can high load exist with low CPU usage?

---

### Q13

How would you troubleshoot a slow Linux server?

---

# 40. Common Beginner Mistakes

## Mistake 1

Thinking:

```text
High Memory Usage
=
Problem
```

Not always true.

---

## Mistake 2

Looking only at CPU utilization.

---

## Mistake 3

Ignoring disk latency.

---

## Mistake 4

Confusing load average with CPU percentage.

---

## Mistake 5

Treating swap usage as automatically bad.

---

## Mistake 6

Restarting services before collecting evidence.

---

# 41. Summary

After completing this chapter you should understand:

✓ CPU Utilization

✓ CPU States

✓ Load Average

✓ top

✓ htop

✓ Memory Management

✓ Cache

✓ Buffers

✓ Swap

✓ OOM Killer

✓ free

✓ vmstat

✓ Disk I/O

✓ iostat

✓ Network Monitoring

✓ ss

✓ ping

✓ traceroute

✓ curl

✓ sar

✓ Performance Methodology

✓ Bottleneck Analysis

✓ Real Interview Scenarios

✓ Linux Troubleshooting Fundamentals

---

# Where To Go Next

At this point you have covered nearly all Linux topics asked in:

- Linux Administrator Interviews
- System Engineer Interviews
- Infrastructure Engineer Interviews
- Cloud Engineer Interviews
- Junior DevOps Interviews

The next chapter should be:

# Chapter 13 - Advanced Linux Interview Topics

covering:

- Signals Deep Dive
- Process Scheduling Internals
- cgroups
- Namespaces
- Containers vs Virtual Machines
- Shared Libraries
- Dynamic Linking
- ELF Binaries
- System Calls
- strace
- lsof
- Advanced Troubleshooting Scenarios

This is where Linux starts connecting directly with Docker, Kubernetes, modern DevOps, and platform engineering.

