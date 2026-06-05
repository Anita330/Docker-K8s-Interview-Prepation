# Linux Deep Dive Notes

# Chapter 9 - Linux Boot Process, Systemd, Logging, and Service Management

---

# 1. Introduction

One of the most common interview scenarios is:

```text
A Linux server is not booting.
A service is failing.
Logs are missing.
A daemon isn't starting.
```

To troubleshoot such problems, we must understand:

```text
How Linux boots
How services are started
How logs are generated
How systemd manages the system
```

Most users simply power on a Linux machine and see a login prompt.

However, behind the scenes, Linux performs hundreds of operations before the system becomes usable.

This chapter explains:

* Boot Process
* BIOS and UEFI
* GRUB Bootloader
* Kernel Initialization
* Init Process
* systemd
* Services
* Logging
* Troubleshooting

---

# 2. High-Level Linux Boot Process

When a machine powers on:

```text
Power On
    ↓
BIOS / UEFI
    ↓
Bootloader (GRUB)
    ↓
Linux Kernel
    ↓
systemd (PID 1)
    ↓
System Services
    ↓
Login Prompt
```

This sequence occurs every time Linux starts.

---

# 3. What Happens When You Press the Power Button?

Many people think:

```text
Power Button
     ↓
Linux Starts
```

In reality:

```text
Hardware initializes first.
```

The operating system is not running yet.

The CPU begins executing firmware instructions.

---

# 4. BIOS

BIOS stands for:

```text
Basic Input Output System
```

Traditional firmware found on older systems.

Responsibilities:

```text
Hardware Initialization
Power-On Self Test (POST)
Boot Device Selection
```

---

## POST (Power-On Self Test)

BIOS verifies:

```text
CPU
RAM
Storage Devices
Keyboard
Basic Hardware
```

If hardware fails:

```text
Boot Process Stops
```

---

# 5. UEFI

Modern replacement for BIOS.

UEFI stands for:

```text
Unified Extensible Firmware Interface
```

Most modern systems use UEFI.

---

## Advantages Over BIOS

```text
Faster Boot
Larger Disk Support
Improved Security
Graphical Interfaces
Secure Boot
```

---

## Interview Question

Q:

Difference between BIOS and UEFI?

Answer:

```text
BIOS:
Older firmware standard.

UEFI:
Modern replacement supporting larger disks,
faster booting, and advanced features.
```

---

# 6. What Is a Bootloader?

After firmware finishes initialization:

Linux still cannot start.

Reason:

```text
Kernel is stored on disk.
```

The CPU does not know:

```text
Where kernel exists.
How to load it.
```

This is the bootloader's job.

---

# 7. GRUB

Most Linux systems use:

```text
GRUB
```

which stands for:

```text
GRand Unified Bootloader
```

---

## Responsibilities

GRUB:

```text
Loads Linux Kernel
Loads Initramfs
Provides Boot Menu
Supports Multiple Operating Systems
```

---

## Example

GRUB menu:

```text
Ubuntu
Advanced Options
Recovery Mode
Windows
```

User selects operating system.

GRUB loads the chosen kernel.

---

# 8. What Is the Kernel Image?

Usually located in:

```text
/boot
```

Examples:

```text
vmlinuz-6.x
```

Kernel image contains:

```text
Core Linux Kernel
```

but not all drivers.

---

# 9. What Is Initramfs?

Interview favorite topic.

---

## Problem

Kernel loads.

However:

```text
Root Filesystem
Drivers
Storage Modules
```

may not yet be available.

---

## Solution

Initramfs

```text
Initial RAM Filesystem
```

Temporary filesystem loaded into memory.

---

## Responsibilities

Provides:

```text
Drivers
Modules
Temporary Environment
```

until real root filesystem becomes available.

---

## Boot Flow

```text
GRUB
  ↓
Kernel
  ↓
Initramfs
  ↓
Real Root Filesystem
```

---

# 10. Kernel Initialization

Once loaded:

Kernel begins initialization.

Tasks include:

```text
Memory Management
CPU Scheduling
Hardware Detection
Driver Loading
Filesystem Initialization
```

---

## Kernel Messages

Can be viewed using:

```bash
dmesg
```

Example:

```bash
dmesg | less
```

Shows boot-related kernel messages.

---

# 11. Mounting the Root Filesystem

Kernel eventually mounts:

```text
/
```

the root filesystem.

Without it:

```text
Linux cannot continue booting.
```

---

## Why?

System files reside in:

```text
/bin
/etc
/usr
/lib
```

All require the root filesystem.

---

# 12. Starting PID 1

After initialization:

Kernel launches:

```text
PID 1
```

This is the first userspace process.

---

Historically:

```text
init
```

Today:

```text
systemd
```

on most distributions.

---

# 13. Why PID 1 Is Special

If PID 1 fails:

```text
System becomes unusable.
```

Responsibilities:

```text
Service Management
System Initialization
Orphan Adoption
Shutdown Coordination
```

---

## Interview Question

Q:

Why is PID 1 special?

Answer:

Because it is the first userspace process and manages system initialization and services.

---

# 14. What Is systemd?

Modern Linux initialization and service management framework.

Runs as:

```text
PID 1
```

on most modern distributions.

---

## Responsibilities

```text
Start Services
Stop Services
Manage Targets
Handle Logging
Control System State
Monitor Processes
```

---

## Why Was systemd Created?

Older systems used:

```text
SysVinit
```

Problems:

```text
Slow Startup
Limited Dependency Handling
Complex Service Management
```

systemd solved many of these issues.

---

# 15. Viewing PID 1

Command:

```bash
ps -p 1
```

Example:

```text
PID COMMAND
1 systemd
```

Confirms systemd is PID 1.

---

# 16. What Is a Service?

A service is:

```text
Long Running Background Process
```

Examples:

```text
sshd
nginx
docker
cron
postgresql
```

Usually started automatically during boot.

---

# 17. What Is a Unit?

systemd manages objects called:

```text
Units
```

Types:

```text
.service
.socket
.mount
.target
.timer
```

---

## Example

```text
nginx.service
```

represents:

```text
Nginx Service
```

---

# 18. Service Unit Files

Usually stored in:

```text
/etc/systemd/system
/usr/lib/systemd/system
```

---

Example:

```text
nginx.service
```

Contains:

```text
Description
Dependencies
Start Command
Restart Policy
```

---

# 19. systemctl

Primary command for managing systemd.

Most important Linux administration command.

---

# 20. Start a Service

Example:

```bash
sudo systemctl start nginx
```

Starts service immediately.

---

# 21. Stop a Service

```bash
sudo systemctl stop nginx
```

Stops service.

---

# 22. Restart a Service

```bash
sudo systemctl restart nginx
```

Very common after configuration changes.

---

# 23. Reload a Service

```bash
sudo systemctl reload nginx
```

Reloads configuration without full restart.

---

## Difference

Restart:

```text
Stop
Start
```

Reload:

```text
Re-read Configuration
```

without stopping service.

---

# 24. Check Service Status

```bash
systemctl status nginx
```

Displays:

```text
Running State
Logs
PID
Errors
```

One of the most commonly used troubleshooting commands.

---

# 25. Enable a Service

```bash
sudo systemctl enable nginx
```

Meaning:

```text
Start Automatically During Boot
```

---

# 26. Disable a Service

```bash
sudo systemctl disable nginx
```

Prevents automatic startup.

---

# 27. Viewing All Services

```bash
systemctl list-units --type=service
```

Displays active services.

---

# 28. Understanding Targets

Older Linux systems used:

```text
Runlevels
```

Modern systemd uses:

```text
Targets
```

---

## Common Targets

```text
multi-user.target
graphical.target
rescue.target
```

---

### multi-user.target

Text-based system.

Equivalent to traditional server mode.

---

### graphical.target

Desktop environment enabled.

Equivalent to graphical login.

---

### rescue.target

Single-user recovery mode.

Useful for troubleshooting.

---

# 29. Viewing Current Target

```bash
systemctl get-default
```

Example:

```text
multi-user.target
```

---

# 30. Changing Default Target

Example:

```bash
sudo systemctl set-default graphical.target
```

Changes default boot target.

---

# 31. Logging in Linux

Everything eventually fails.

When failures occur:

```text
Logs Explain What Happened
```

Logs are critical for troubleshooting.

---

# 32. Traditional Logging

Historically Linux used:

```text
syslog
rsyslog
```

Logs stored in:

```text
/var/log
```

---

# 33. Important Log Files

---

## System Messages

```text
/var/log/messages
```

or:

```text
/var/log/syslog
```

depending on distribution.

---

## Authentication Logs

```text
/var/log/auth.log
```

or:

```text
/var/log/secure
```

Contains:

```text
SSH Logins
sudo Activity
Authentication Events
```

---

## Kernel Logs

```text
dmesg
```

Kernel messages.

---

# 34. journalctl

systemd introduces:

```text
systemd-journald
```

which stores logs in the journal.

Primary command:

```bash
journalctl
```

---

# 35. View All Logs

```bash
journalctl
```

Displays entire journal.

Can be very large.

---

# 36. View Recent Logs

```bash
journalctl -n 50
```

Shows last 50 lines.

---

# 37. Follow Logs

Equivalent of:

```bash
tail -f
```

Command:

```bash
journalctl -f
```

Live log monitoring.

---

# 38. View Service Logs

Example:

```bash
journalctl -u nginx
```

Displays logs only for nginx.

Extremely useful for troubleshooting.

---

# 39. View Logs Since Boot

```bash
journalctl -b
```

Shows logs generated since last boot.

---

# 40. Log Rotation

Logs grow continuously.

Without management:

```text
Disk Fills Up
```

---

## Solution

```text
logrotate
```

---

## Purpose

Automatically:

```text
Archive Logs
Compress Logs
Delete Old Logs
```

---

Example:

```text
app.log
```

becomes:

```text
app.log.1
app.log.2.gz
```

---

# 41. Troubleshooting Failed Services

Suppose:

```text
Nginx Fails To Start
```

Typical workflow:

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

Verify configuration.

Application-specific validation.

Example:

```bash
nginx -t
```

---

## Step 4

Restart service.

```bash
systemctl restart nginx
```

---

# 42. Common Interview Questions

### Q1

Describe Linux boot process.

Expected answer:

```text
BIOS/UEFI
↓
GRUB
↓
Kernel
↓
Initramfs
↓
systemd
↓
Services
```

---

### Q2

Difference between BIOS and UEFI?

---

### Q3

What is GRUB?

---

### Q4

What is Initramfs?

---

### Q5

What is PID 1?

---

### Q6

What is systemd?

---

### Q7

Difference between service and process?

---

### Q8

Difference between:

```bash
start
stop
restart
reload
```

---

### Q9

Purpose of:

```bash
systemctl enable
```

---

### Q10

Purpose of:

```bash
journalctl
```

---

### Q11

Where are Linux logs stored?

---

### Q12

What is log rotation?

---

### Q13

How would you troubleshoot a failed service?

---

### Q14

Difference between:

```bash
journalctl -f
```

and

```bash
tail -f
```

---

# 43. Common Beginner Mistakes

## Mistake 1

Restarting services without checking logs.

---

## Mistake 2

Confusing enable with start.

---

## Mistake 3

Ignoring journalctl.

---

## Mistake 4

Not understanding boot sequence.

---

## Mistake 5

Assuming systemd is the service itself.

systemd manages services.

---

# 44. Summary

After completing this chapter you should understand:

✓ Linux Boot Process

✓ BIOS

✓ UEFI

✓ GRUB

✓ Initramfs

✓ Kernel Initialization

✓ Root Filesystem Mounting

✓ PID 1

✓ systemd

✓ Services

✓ Units

✓ Targets

✓ systemctl

✓ Logging

✓ journalctl

✓ Log Files

✓ Log Rotation

✓ Service Troubleshooting

✓ Common Interview Questions

At this point, you have covered the majority of Linux topics commonly asked in Linux Administrator, Infrastructure, Cloud, and Platform interviews.

The next advanced chapter should be:

# Chapter 10 - Linux Security Fundamentals

covering:

* PAM (Pluggable Authentication Modules)
* SSH Deep Dive
* sudo Internals
* ACLs
* SELinux
* AppArmor
* Firewalls (iptables/nftables/firewalld)
* Fail2Ban
* Security Hardening
* Common Security Interview Questions

This chapter moves beyond basic permissions and explains how Linux enforces security at the operating system level.
