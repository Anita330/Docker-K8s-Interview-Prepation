# Linux Interview Questions and Answers (6 Years Experience)

## 1. Explain the Linux Boot Process.

### Answer
The Linux boot process consists of the following stages:

1. BIOS/UEFI initializes the hardware.
2. GRUB (bootloader) loads the Linux kernel.
3. Kernel initializes CPU, memory, and device drivers.
4. initramfs mounts the temporary root filesystem.
5. systemd (or init) starts.
6. systemd starts services and reaches the target (runlevel).

---

## 2. Difference Between Hard Link and Soft Link

| Hard Link | Soft Link |
|------------|-----------|
| Shares the same inode | Has a different inode |
| Cannot cross filesystem | Can cross filesystem |
| Cannot link directories | Can link directories |
| Works even if original file is deleted | Breaks if original file is deleted |

### Commands

```bash
ln file1 hardlink
ln -s file1 softlink
```

---

## 3. What is an Inode?

### Answer

An inode stores metadata about a file.

It contains:

- Owner
- Group
- Permissions
- File size
- Time stamps
- Disk block locations

It does **not** contain the filename.

### Command

```bash
ls -i
```

---

## 4. How Do You Troubleshoot High CPU Utilization?

### Answer

Use the following commands:

```bash
top
htop
ps -eo pid,user,%cpu,command --sort=-%cpu
pidstat
sar
```

Steps:

- Identify the process consuming CPU.
- Check application logs.
- Verify if it is expected.
- Restart the service if required.
- Tune or optimize the application.

---

## 5. How Do You Troubleshoot High Memory Usage?

### Commands

```bash
free -h
vmstat
top
ps aux --sort=-%mem
cat /proc/meminfo
```

Check:

- Memory leaks
- Swap usage
- Cache usage
- Large applications consuming RAM

---

## 6. Difference Between Buffer and Cache

### Buffer

Temporary storage used during data transfer to disks.

### Cache

Stores frequently accessed data to improve performance.

### Command

```bash
free -h
```

---

## 7. What Happens if Disk Usage Reaches 100%?

### Problems

- Applications cannot write data.
- Databases may stop.
- Logs stop generating.
- System performance degrades.
- Users may not be able to log in.

### Commands

```bash
df -h
du -sh *
```

---

## 8. Difference Between df and du

### df

Displays filesystem usage.

```bash
df -h
```

### du

Displays directory or file usage.

```bash
du -sh /var/log
```

---

## 9. What is Load Average?

Load average indicates the average number of processes waiting for CPU.

Shows values for:

- 1 minute
- 5 minutes
- 15 minutes

### Command

```bash
uptime
```

Example:

```
Load Average:
1.5 1.8 2.0
```

If a system has 2 CPU cores:

- Load = 2 → Normal
- Load > 2 → CPU overloaded

---

## 10. Difference Between Cron and Anacron

### Cron

- Executes jobs at scheduled time.
- Missed jobs are skipped.

### Anacron

- Executes missed jobs after the system starts.

---

## 11. How to Check Listening Ports?

```bash
ss -tulnp
netstat -tulnp
lsof -i
```

---

## 12. Explain systemctl

systemctl is used to manage services.

Examples:

```bash
systemctl status nginx
systemctl restart nginx
systemctl stop nginx
systemctl enable nginx
systemctl disable nginx
```

---

## 13. Difference Between systemctl and service

| systemctl | service |
|-----------|----------|
| Uses systemd | Uses SysV init |
| Supports dependencies | Limited functionality |
| Faster boot | Older method |

---

## 14. What is a Zombie Process?

A process that has completed execution but still exists because its parent has not collected its exit status.

### Command

```bash
ps aux | grep Z
```

---

## 15. What is an Orphan Process?

When the parent process exits before the child.

The orphan process is adopted by:

```
systemd (PID 1)
```

---

## 16. What is Swap Memory?

Swap is disk space used as virtual memory when RAM becomes full.

### Commands

```bash
swapon --show
free -h
```

---

## 17. Difference Between ext4 and XFS

| ext4 | XFS |
|------|------|
| General-purpose | Enterprise filesystem |
| Easier resizing | Better for large files |
| Suitable for small systems | Better performance for large storage |

---

## 18. Explain LVM

LVM stands for Logical Volume Manager.

Structure:

```
Disk
   ↓
Physical Volume (PV)
   ↓
Volume Group (VG)
   ↓
Logical Volume (LV)
   ↓
Filesystem
```

### Commands

```bash
pvcreate
vgcreate
lvcreate
```

---

## 19. How Do You Extend an LVM?

```bash
lvextend
resize2fs
```

For XFS:

```bash
xfs_growfs
```

---

## 20. Difference Between RAID Levels

| RAID | Purpose |
|------|---------|
| RAID 0 | Performance |
| RAID 1 | Mirroring |
| RAID 5 | Parity with fault tolerance |

---

## 21. What is SELinux?

SELinux provides Mandatory Access Control (MAC).

### Modes

```bash
getenforce
```

Output:

- Enforcing
- Permissive
- Disabled

---

## 22. Difference Between chmod, chown and chgrp

### chmod

Changes file permissions.

```bash
chmod 755 file
```

### chown

Changes file owner.

```bash
chown user file
```

### chgrp

Changes group ownership.

```bash
chgrp developers file
```

---

## 23. What is umask?

umask defines the default permissions for newly created files and directories.

### Command

```bash
umask
```

---

## 24. How Do You Find Large Files?

```bash
find / -type f -size +1G
du -ah | sort -rh | head
```

---

## 25. How Do You Troubleshoot an Unreachable Server?

Steps:

1. Verify server status.
2. Check network connectivity.
3. Verify SSH service.
4. Check firewall.
5. Check disk usage.
6. Review system logs.
7. Check CPU and memory utilization.
8. Use cloud serial console if necessary.

---

## 26. Difference Between kill, pkill and killall

### kill

Kills a process using PID.

```bash
kill PID
```

### pkill

Kills processes by name or pattern.

```bash
pkill nginx
```

### killall

Kills all processes with the exact name.

```bash
killall nginx
```

---

## 27. Difference Between grep and xargs

### grep

Searches for matching text.

### xargs

Converts input into command-line arguments.

Example:

```bash
find . -name "*.log" | xargs rm
```

---

## 28. Explain File Permissions (755 vs 644)

### 755 (rwxr-xr-x)

- Owner: Read, Write, Execute
- Group: Read, Execute
- Others: Read, Execute

### 644 (rw-r--r--)

- Owner: Read, Write
- Group: Read
- Others: Read

---

## 29. What is /etc/fstab?

It stores filesystem mount information used during boot.

### Command

```bash
cat /etc/fstab
```

---

## 30. Explain journald and journalctl

systemd-journald collects system logs.

Useful commands:

```bash
journalctl
journalctl -u nginx
journalctl -xe
journalctl --since "1 hour ago"
```

---

# Scenario-Based Questions

## 1. Production Server is Slow

### Answer

1. Check CPU using `top`.
2. Check memory using `free -h`.
3. Check disk using `df -h`.
4. Check I/O using `iostat`.
5. Review logs using `journalctl`.
6. Identify root cause before restarting services.

---

## 2. SSH is Not Working

### Answer

Check:

- Network connectivity
- SSH service
- Port 22 listening
- Firewall rules
- Security groups (cloud)
- SSH configuration
- Authentication logs

---

## 3. Root Filesystem is 100% Full

### Answer

1. Find large files.
2. Remove old logs.
3. Clean temporary files.
4. Remove package cache.
5. Compress or rotate logs.
6. Extend filesystem if required.

---

# Interview Tips

- Explain commands with practical examples.
- Mention production troubleshooting experience.
- Focus on root cause analysis rather than only restarting services.
- Understand Linux internals such as systemd, memory management, networking, and storage.
- Be prepared to answer scenario-based questions involving CPU, memory, disk, networking, and security.