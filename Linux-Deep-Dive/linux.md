Show all listening ports:


lsof -i -P -n | grep LISTEN


# The safest way to truncate a file to zero bytes
sudo truncate -s 0 /var/log/problematic_file.log

# Alternative method
sudo true > /var/log/problematic_file.log


# How does a process interact with the kernel?
A process interacts with the kernel through system calls.
+-------------------+
| User Application  |
| (User Space)      |
+-------------------+
          |
          | 1. System Call
          v
+-------------------+
| Linux Kernel      |
| (Kernel Space)    |
+-------------------+
          |
          | 2. Access Hardware/Resources
          v
+-------------------+
| CPU, Memory, Disk |
| Network, Devices  |
+-------------------+
          |
          | 3. Return Result
          v
+-------------------+
| User Application  |
+-------------------+

The following happens:

Process runs in user mode.
It invokes the open() system call.
CPU switches from user mode to kernel mode.
Kernel validates permissions and locates the file.
Kernel opens the file and creates a file descriptor.
CPU switches back to user mode.
The file descriptor is returned to the process.

# CPU Modes
User Mode
Limited privileges.
Cannot directly access hardware.
Cannot modify kernel memory.
Applications normally run here.
Kernel Mode
Full privileges.
Can access hardware, memory, and devices.
Operating system code runs here.

# Interview Answer
A process interacts with the kernel through system calls. When a process needs access to hardware, files, memory, or networking resources, it issues a system call. The CPU switches from user mode to kernel mode, the kernel performs the requested operation, and then control returns to the process in user mode with the result.


# What is a cgroup?
A cgroup (Control Group) is a Linux kernel feature that allows you to limit, prioritize, monitor, and isolate resource usage of a group of processes.

cgroup

Controls:

CPU
Memory
I/O
Process count

# What is a cgroup?
A cgroup (Control Group) is a Linux kernel feature that manages and limits resource usage for a group of processes. It can control CPU, memory, disk I/O, and process counts. Containers use cgroups for resource management, while namespaces provide isolation. In Kubernetes, pod resource requests and limits are enforced through Linux cgroups.

# What is an ELF binary?
An ELF (Executable and Linkable Format) binary is the standard file format used by Linux and Unix-like operating systems for:

Executable programs
Shared libraries (.so files)
Object files (.o)
Core dumps

#   Why is ELF Important?

The Linux kernel understands the ELF format and knows:

Where the program code is located
Where data is stored
Which libraries are required
Where execution should begin


# How a Program Runs?
./myapp
1. Shell calls execve().
2. Kernel reads the ELF header.
3. Kernel loads code and data into memory.
4. Required shared libraries are loaded.
5. Control jumps to the program's entry point.
6. Program starts executing.

User
  |
  v
./myapp
  |
  v
execve()
  |
  v
Linux Kernel
  |
  v
Load ELF
  |
  v
Start Program

| Action          | Command                      |
| --------------- | ---------------------------- |
| Create          | `tar -cvf file.tar dir/`     |
| Extract         | `tar -xvf file.tar`          |
| Compress (gzip) | `tar -czvf file.tar.gz dir/` |
| Extract gzip    | `tar -xzvf file.tar.gz`      |
| List contents   | `tar -tvf file.tar`          |



| Feature        | tar                                      | gzip                             |
| -------------- | ---------------------------------------- | -------------------------------- |
| Purpose        | Archives files/directories into one file | Compresses a file to reduce size |
| Compression    | ❌ No compression by default              | ✅ Compresses data                |
| Multiple files | ✅ Can combine multiple files             | ❌ Compresses one file at a time  |
| Output         | `.tar`                                   | `.gz`                            |
| Common Use     | Packaging files                          | Reducing file size               |


