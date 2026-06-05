# Linux Interview Questions and Answers

## Beginner Questions

**1. What is Linux?**  
Linux is a Unix-like, open-source operating system developed by Linus Torvalds in 1991. It is known for security, stability, and flexibility. [web:1][web:5]

**2. What are Linux's core components?**  
Kernel, shell, directory structure, and background services (daemons) are the main components of a Linux system. [web:2][web:3]

**3. What is the Kernel?**  
The kernel is the core part of Linux that communicates with hardware, manages CPU, memory, and I/O, and exposes system calls to processes. [web:2][web:3]

**4. What is a shell vs. bash?**  
A shell is the command interpreter used to run commands, while bash is a specific shell and one of the most common on Linux systems. [web:3]

**5. What is the init process?**  
The init process is PID 1 and is the first process started during boot. Modern Linux systems often use systemd as the init system. [web:3]

## Intermediate Questions

**6. Difference between soft link and hard link?**  
A soft link points to a file path and breaks if the original file is removed. A hard link points to the same inode, so it remains valid even if the original filename is deleted, as long as the data still exists. [web:3]

**7. How to change file permissions with chmod?**  
Use `chmod` to change permissions. Example: `chmod 755 file.sh` or `chmod +x script.sh`. [web:3]

**8. Permission types in Linux?**  
Linux permissions are read, write, and execute. They are applied to the owner, group, and others. [web:3]

**9. How to check free disk space?**  
Use `df -h` to view free disk space in a human-readable format. [web:3]

**10. What is LVM and why important?**  
Logical Volume Manager gives flexible disk management and lets you resize or reorganize storage more easily than traditional partitions. [web:2]

**11. How to find files containing a specific string?**  
Use `grep -r "pattern" /directory` or combine `find` with `grep` for more targeted searches. [web:3]

**12. What is pipe (|) in Linux?**  
A pipe sends the output of one command to another command as input. Example: `ps aux | grep nginx`. [web:3]

## Advanced Questions

**13. How to check IP address?**  
Use `ip addr show` or `hostname -I` to view IP addresses. [web:3]

**14. How to terminate a process?**  
Use `kill PID` to stop a process gracefully, or `kill -9 PID` to forcefully terminate it. [web:3]

**15. How to check system architecture, CPU, and memory?**  
Use `uname -m` for architecture, `lscpu` for CPU details, and `free -h` for memory usage. [web:3]

**16. What is SSH and how to use it?**  
SSH is a secure protocol for remote login and command execution. Example: `ssh user@host`. [web:3]

**17. What is /etc/fstab?**  
It is the file that defines how filesystems are mounted on boot. [web:4]

**18. How to install packages on RHEL vs Ubuntu?**  
RHEL-based systems use `yum` or `dnf`, while Ubuntu/Debian use `apt-get` or `apt`. [web:4]

**19. What is a user's $PATH?**  
`$PATH` is an environment variable that tells the shell where to search for executable commands. [web:4]

## DevOps Scenarios

**20. How do you restart a service?**  
Use `systemctl restart service_name` on systemd-based systems. [web:4]

**21. How to read or follow logs?**  
Use `tail -f /var/log/syslog`, `grep`, or `journalctl -u service_name` depending on the log source. [web:4]

**22. Basic user management?**  
Common commands are `useradd`, `usermod`, `userdel`, and `passwd`. [web:4]



# Linux Interview Questions and Answers for Experienced Candidates

## Advanced Linux Questions

**1. What is the difference between a process and a thread?**  
A process is an independent program with its own memory space, while threads are smaller execution units within a process that share the same memory and resources. [web:12][web:11]

**2. What is the difference between fork and exec?**  
`fork()` creates a new child process by copying the parent process, while `exec()` replaces the current process image with a new program. [web:11]

**3. What is the purpose of the /proc directory?**  
`/proc` is a virtual filesystem that exposes process and kernel information such as CPU details, memory stats, and running process data. [web:12]

**4. What are cgroups?**  
Cgroups, or control groups, are used to limit, isolate, and account for resource usage of process groups, such as CPU, memory, and I/O. [web:11][web:12]

**5. What are Linux namespaces?**  
Namespaces isolate system resources such as process IDs, mounts, network interfaces, and users so containers can run independently on the same host. [web:12]

**6. What is load average in Linux?**  
Load average is the average number of processes waiting to run or waiting on I/O over a specific time period, commonly shown for 1, 5, and 15 minutes. [web:12]

**7. What does the nice command do?**  
`nice` changes a process’s scheduling priority, where a higher nice value means lower priority. [web:12]

**8. What is systemd?**  
Systemd is the modern init system and service manager used by many Linux distributions to bootstrap the system and manage services. [web:12]

**9. How do you debug a process that is not working as expected?**  
Common tools include `strace` to trace system calls, `lsof` to inspect open files, `ps` to check process state, and `journalctl` for service logs. [web:12][web:16]

**10. What is SELinux?**  
SELinux is a security framework that enforces mandatory access control policies to restrict what processes can do, even if they have elevated privileges. [web:12]

## Performance and Troubleshooting

**11. How do you optimize Linux performance?**  
Typical steps include checking CPU, memory, disk I/O, and load average, then tuning the bottleneck using tools like `top`, `vmstat`, `iostat`, and service logs. [web:12][web:16]

**12. How do you find which process is using a busy directory when umount fails?**  
Use tools like `lsof` or `fuser` to identify which PID is holding files or directories open. [web:11]

**13. What is the OOM killer?**  
The OOM killer is a kernel mechanism that terminates processes when the system runs out of memory, choosing victims based on memory usage and other factors. [web:11]

**14. What is the Linux boot process?**  
The boot process starts at firmware, then the bootloader loads the kernel, followed by init/systemd starting services and reaching a login prompt. [web:11]

**15. How do you manage kernel modules?**  
Use commands like `lsmod` to list modules, `modprobe` to load them, and `rmmod` to remove them when needed. [web:12]

**16. What is the difference between ext4 and XFS?**  
ext4 is a widely used general-purpose filesystem, while XFS is often preferred for high-performance and large-file workloads. [web:12]

## Security and Access

**17. What is a chroot jail?**  
A chroot jail changes the apparent root directory for a process, limiting its filesystem access to a specific subtree. [web:11]

**18. What is SSH port forwarding?**  
SSH port forwarding tunnels traffic through an encrypted SSH connection, allowing local or remote ports to be forwarded securely. [web:11]

**19. Why might SSH key authentication fail even after adding a public key?**  
Common reasons include wrong file permissions, incorrect key type, an invalid username, or SSH server configuration issues. [web:11]

**20. What is LD_PRELOAD used for?**  
`LD_PRELOAD` forces the dynamic loader to load a shared library before others, which is useful for overriding functions or debugging. [web:11]

## DevOps and Automation

**21. What is the difference between statically and dynamically linked binaries?**  
A statically linked binary includes all required libraries inside the executable, while a dynamically linked binary loads shared libraries at runtime. [web:11]

**22. What is the use of `./configure && make && make install`?**  
This is a common build flow: configure the source, compile it with `make`, and install the resulting software onto the system. [web:11]

**23. What are Puppet, Chef, and Ansible used for?**  
They are configuration management and automation tools used to provision systems and enforce desired state consistently. [web:11]

**24. What are cgroups and namespaces in containers?**  
Namespaces provide isolation, while cgroups control resource limits; together they form a major part of container isolation on Linux. [web:11][web:12]

**25. How would you troubleshoot a service that fails after restart?**  
Check service logs, validate configuration, inspect dependent ports and files, and test the service manually before restarting it again. [web:11][web:16]