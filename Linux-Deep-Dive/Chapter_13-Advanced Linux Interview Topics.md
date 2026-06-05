# Linux Deep Dive Notes

# Chapter 13 - Advanced Linux Interview Topics

---

# 1. Introduction

At this stage you already understand:

```text
Filesystems
Permissions
Processes
Users
Storage
Networking
Boot Process
Security
Shell Scripting
Performance Troubleshooting
```

Most Linux interviews stop around these topics.

However, advanced interviews often go deeper and ask:

```text
How does Docker isolate containers?

What is a system call?

How does a process interact with the kernel?

What is a cgroup?

What is a namespace?

What is an ELF binary?

What happens internally when a process starts?
```

This chapter focuses on the Linux internals that are frequently asked in advanced Linux, Infrastructure, DevOps, Platform Engineering, and Kubernetes interviews.

---

# 2. User Space vs Kernel Space

One of the most important Linux concepts.

Linux separates execution into two areas:

```text
User Space
Kernel Space
```

---

## User Space

Applications run here.

Examples:

```text
Chrome
Nginx
Python
Java
Bash
Docker CLI
```

Applications do NOT have direct access to:

```text
CPU
Memory
Disk
Network Hardware
```

---

## Kernel Space

Kernel runs here.

Responsible for:

```text
Process Scheduling
Memory Management
Filesystems
Networking
Device Drivers
Security
```

---

## Architecture

```text
Application
    ↓
System Call
    ↓
Kernel
    ↓
Hardware
```

---

## Why Separation Exists

Security and stability.

Without separation:

```text
Any application
could crash entire system.
```

---

# 3. What Is a System Call?

One of the most common advanced interview questions.

---

## Definition

A system call is:

```text
A controlled entry point
from user space
into kernel space.
```

---

## Example

Application wants to:

```text
Read File
```

Application cannot access disk directly.

Instead:

```text
Application
      ↓
read()
      ↓
Kernel
      ↓
Disk
```

---

# 4. Common System Calls

---

## open()

Open file.

---

## read()

Read file.

---

## write()

Write data.

---

## fork()

Create process.

---

## exec()

Execute program.

---

## kill()

Send signal.

---

## socket()

Create network socket.

---

## connect()

Connect to remote host.

---

# 5. What Happens When You Run ls?

Suppose:

```bash
ls
```

Execution flow:

```text
Bash
 ↓
fork()
 ↓
Child Process
 ↓
exec(/bin/ls)
 ↓
Kernel Loads ELF
 ↓
ls Executes
 ↓
write()
 ↓
Terminal Output
```

Many Linux internals concepts participate in this simple command.

---

# 6. What Is strace?

Interview favorite.

---

## Purpose

Displays system calls made by a process.

Example:

```bash
strace ls
```

Output:

```text
open()
read()
write()
close()
```

---

## Why Useful?

Shows:

```text
What process is doing
What files are accessed
Which system calls fail
```

Excellent troubleshooting tool.

---

# 7. Common strace Use Cases

---

## Missing File

```bash
strace app
```

reveals:

```text
ENOENT
```

(File not found)

---

## Permission Issues

Shows:

```text
EACCES
```

(Permission denied)

---

## Network Problems

Shows:

```text
connect()
```

failures.

---

# 8. What Is lsof?

lsof means:

```text
List Open Files
```

---

## Why Important?

Remember:

```text
Everything Is A File
```

Processes open:

```text
Files
Sockets
Devices
Pipes
```

---

## Example

```bash
lsof -p 1234
```

Displays all open files for PID 1234.

---

# 9. Famous Interview Scenario

Question:

```text
Filesystem full.

File deleted.

Space not reclaimed.

Why?
```

Answer:

```text
Process still holds file open.
```

Verify using:

```bash
lsof
```

---

# 10. Signals Deep Dive

We introduced signals earlier.

Now let's go deeper.

---

## What Is a Signal?

Kernel mechanism for notifying processes.

Think of signals as:

```text
Software Interrupts
```

---

# 11. Signal Lifecycle

Example:

```bash
kill -15 1234
```

Flow:

```text
kill command
      ↓
Kernel
      ↓
SIGTERM
      ↓
Target Process
```

---

# 12. Important Signals

| Signal | Number | Purpose |
|----------|----------|----------|
| SIGTERM | 15 | Graceful Stop |
| SIGKILL | 9 | Force Stop |
| SIGINT | 2 | Ctrl+C |
| SIGSTOP | 19 | Pause Process |
| SIGCONT | 18 | Resume Process |
| SIGHUP | 1 | Reload/Hangup |

---

# 13. Signal Handling

Processes may:

```text
Handle Signal
Ignore Signal
Perform Cleanup
```

Example:

```text
SIGTERM
```

allows:

```text
Save Data
Close Files
Cleanup Resources
```

---

# 14. Why SIGKILL Is Special

Cannot be:

```text
Ignored
Blocked
Handled
```

Kernel immediately terminates process.

---

## Interview Question

Why can't SIGKILL be ignored?

Answer:

Because kernel guarantees administrators can always terminate a process.

---

# 15. Process Scheduling Internals

Linux runs many processes simultaneously.

Reality:

```text
CPU executes only one task per core at a time.
```

---

## Scheduler Responsibility

Decides:

```text
Who Runs
When
For How Long
```

---

# 16. Context Switching

Suppose:

```text
Process A
Process B
Process C
```

share one CPU.

Linux performs:

```text
A
↓
Switch
↓
B
↓
Switch
↓
C
```

Very rapidly.

---

## Context Switch

Saving:

```text
CPU Registers
Process State
```

and loading another process.

---

# 17. Why Context Switching Matters

Too many switches create overhead.

Symptoms:

```text
High CPU
Poor Performance
```

---

# 18. What Are cgroups?

One of the most important container concepts.

cgroup means:

```text
Control Group
```

---

## Purpose

Limit resources used by processes.

Examples:

```text
CPU
Memory
Network
Disk I/O
```

---

## Without cgroups

One process may consume:

```text
100% CPU
All Memory
```

---

## With cgroups

Linux can enforce:

```text
2 CPUs
4 GB RAM
```

limits.

---

# 19. Why cgroups Matter

Docker relies heavily on cgroups.

Example:

```bash
docker run --memory=1g
```

Internally:

```text
Docker
 ↓
cgroups
 ↓
Memory Limit Enforced
```

---

# 20. What Are Namespaces?

Another critical container technology.

---

## Purpose

Provide isolation.

Makes process believe:

```text
It owns entire system.
```

even though it does not.

---

# 21. Major Namespace Types

---

## PID Namespace

Process isolation.

Container sees:

```text
PID 1
```

inside container.

---

## Network Namespace

Own:

```text
Interfaces
Routing Table
IP Addresses
```

---

## Mount Namespace

Own filesystem view.

---

## UTS Namespace

Own hostname.

---

## IPC Namespace

Own shared memory resources.

---

## User Namespace

Separate users and IDs.

---

# 22. Namespace Example

Container:

```text
PID 1
PID 2
PID 3
```

Host:

```text
PID 4521
PID 4522
PID 4523
```

Container cannot see host processes.

---

# 23. Containers vs Virtual Machines

Extremely common interview question.

---

## Virtual Machines

```text
Application
Guest OS
Hypervisor
Host
```

Each VM has its own kernel.

---

## Containers

```text
Application
Container Runtime
Host Kernel
```

Containers share host kernel.

---

# 24. Comparison

Virtual Machine:

```text
More Isolation
Higher Overhead
Slower Startup
```

Container:

```text
Less Overhead
Fast Startup
Shared Kernel
```

---

# 25. What Is an ELF Binary?

ELF:

```text
Executable and Linkable Format
```

Standard Linux executable format.

---

## Examples

```text
/bin/bash
/bin/ls
/usr/bin/python
```

are ELF binaries.

---

# 26. Viewing ELF Information

Command:

```bash
file /bin/ls
```

Example:

```text
ELF 64-bit executable
```

---

# 27. ELF Components

Contains:

```text
Executable Code
Libraries
Metadata
Symbols
Sections
```

---

# 28. Dynamic Linking

Most binaries do NOT contain all required code.

Instead:

```text
Binary
 ↓
Shared Libraries
```

---

## Example

```bash
ldd /bin/ls
```

Displays dependencies.

Example:

```text
libc.so
libpthread.so
```

---

# 29. Why Dynamic Linking Exists

Benefits:

```text
Smaller Executables
Shared Code
Easier Updates
```

---

# 30. Shared Libraries

Linux equivalent of:

```text
DLL files (Windows)
```

Examples:

```text
libc.so
libssl.so
libcrypto.so
```

---

# 31. What Happens When Program Starts?

Advanced interview favorite.

---

Execution flow:

```text
Shell
 ↓
fork()
 ↓
exec()
 ↓
Kernel Loads ELF
 ↓
Dynamic Linker Loads Libraries
 ↓
Process Memory Created
 ↓
Program Starts
```

---

# 32. Process Memory Layout

Every process gets memory regions.

---

## Text Segment

Executable code.

---

## Data Segment

Global variables.

---

## Heap

Dynamic allocations.

Example:

```c
malloc()
```

---

## Stack

Function calls.

Local variables.

---

# 33. Heap vs Stack

Interview classic.

---

## Stack

```text
Fast
Automatic
Limited Size
```

---

## Heap

```text
Dynamic
Larger
Manual Management
```

---

# 34. Shared Memory

Fast Inter-Process Communication.

Processes can access:

```text
Same Memory Region
```

instead of:

```text
Files
Sockets
```

---

# 35. Advanced Troubleshooting Scenario

Application fails.

Error:

```text
No such file
```

File exists.

Why?

Possible cause:

```text
Missing Shared Library
```

Verify:

```bash
ldd application
```

---

# 36. Advanced Troubleshooting Scenario

Container exceeds memory limit.

Killed unexpectedly.

Possible cause:

```text
cgroup memory limit
```

Check:

```text
OOM Event
Container Limits
```

---

# 37. Advanced Troubleshooting Scenario

Application hangs.

Use:

```bash
strace -p PID
```

Observe:

```text
System Calls
Blocked Operations
```

---

# 38. Common Interview Questions

### Q1

Difference between user space and kernel space?

---

### Q2

What is a system call?

---

### Q3

What happens when you run:

```bash
ls
```

---

### Q4

Purpose of:

```bash
strace
```

---

### Q5

Purpose of:

```bash
lsof
```

---

### Q6

Difference between SIGTERM and SIGKILL?

---

### Q7

Why can't SIGKILL be ignored?

---

### Q8

What is a context switch?

---

### Q9

What are cgroups?

---

### Q10

What resources can cgroups control?

---

### Q11

What are namespaces?

---

### Q12

Name major Linux namespaces.

---

### Q13

Containers vs Virtual Machines?

---

### Q14

What is ELF?

---

### Q15

Purpose of:

```bash
ldd
```

---

### Q16

Heap vs Stack?

---

### Q17

How does Docker isolate containers?

Expected answer:

```text
Namespaces
cgroups
Capabilities
Filesystem Isolation
```

---

# 39. Common Beginner Mistakes

## Mistake 1

Thinking containers are virtual machines.

---

## Mistake 2

Confusing namespaces with cgroups.

---

## Mistake 3

Ignoring shared library dependencies.

---

## Mistake 4

Using SIGKILL immediately.

---

## Mistake 5

Believing high CPU always means scheduler issue.

---

## Mistake 6

Thinking system calls are normal function calls.

---

# 40. Summary

After completing this chapter you should understand:

✓ User Space

✓ Kernel Space

✓ System Calls

✓ strace

✓ lsof

✓ Signals Deep Dive

✓ SIGTERM

✓ SIGKILL

✓ Process Scheduling

✓ Context Switching

✓ cgroups

✓ Namespaces

✓ PID Namespace

✓ Network Namespace

✓ Mount Namespace

✓ Containers vs Virtual Machines

✓ ELF Binaries

✓ Shared Libraries

✓ Dynamic Linking

✓ ldd

✓ Process Memory Layout

✓ Heap

✓ Stack

✓ Advanced Troubleshooting

✓ Advanced Linux Interview Questions

---

# What Comes Next?

At this point you have covered approximately 90-95% of Linux concepts asked in interviews.

The next chapter should be:

# Chapter 14 - Linux Administration Real-World Scenarios

covering:

- Server Out Of Space
- High CPU Investigation
- High Memory Investigation
- Zombie Process Investigation
- Service Fails To Start
- SSH Access Lost
- DNS Failure
- Network Troubleshooting
- Log Analysis
- Incident Response Methodology
- End-to-End Troubleshooting Playbooks

This chapter will focus less on theory and more on how Linux administrators actually think and troubleshoot production systems.