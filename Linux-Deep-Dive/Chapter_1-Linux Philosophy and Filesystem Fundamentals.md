# Linux Deep Dive Notes

# Chapter 1 - Linux Philosophy and Filesystem Fundamentals

---

# 1. Introduction

Before learning Linux commands, permissions, processes, storage, networking, or system administration, it is important to understand the philosophy on which Linux was built.

Many beginners start learning Linux by memorizing commands:

```bash
ls
cd
cp
mv
rm
```

While this may help complete daily tasks, it does not help in understanding how Linux actually works.

The goal of this chapter is to build a strong mental model of Linux.

Once these concepts become clear, the rest of Linux becomes much easier to understand.

---

# 2. What Is Linux?

Many people say:

> Linux is an Operating System.

While this is not completely wrong, it is not technically accurate.

Linux itself is actually a **kernel**.

The kernel is the core software that directly interacts with computer hardware.

The complete operating system that users interact with is usually called a Linux Distribution.

Examples:

* Ubuntu
* Debian
* Fedora
* Rocky Linux
* CentOS
* Arch Linux

These distributions contain:

* Linux Kernel
* GNU Utilities
* Package Managers
* System Libraries
* User Applications

For example:

```text
Ubuntu =
Linux Kernel
+ Bash
+ Core Utilities
+ apt Package Manager
+ System Libraries
+ Desktop Environment
```

---

# 3. What Is a Kernel?

The kernel is the most important component of Linux.

It acts as a bridge between applications and hardware.

Without the kernel:

* Applications cannot access memory
* Applications cannot access disks
* Applications cannot access networks
* Applications cannot access CPUs

Example:

When a text editor saves a file:

```text
Text Editor
    ↓
Kernel
    ↓
Disk
```

The application never directly writes to the disk.

Instead, it requests the kernel to perform the operation.

---

# 4. Kernel Space vs User Space

Linux separates the system into two worlds.

## User Space

This is where normal programs run.

Examples:

* Chrome
* Firefox
* Bash
* Python
* Nginx
* VS Code

These applications have limited privileges.

They cannot directly:

* Access hardware
* Modify kernel memory
* Control CPUs

---

## Kernel Space

This is where the Linux kernel operates.

The kernel has complete control over:

* CPU
* RAM
* Disk
* Network Devices
* USB Devices

Diagram:

```text
+-----------------------+
|     User Space        |
|                       |
|  Bash                 |
|  Python               |
|  Chrome               |
|  Nginx                |
+-----------------------+
            |
            | System Calls
            |
+-----------------------+
|     Kernel Space      |
|                       |
| Linux Kernel          |
+-----------------------+
            |
            |
+-----------------------+
|      Hardware         |
+-----------------------+
```

---

# 5. What Are System Calls?

Applications cannot directly talk to hardware.

Instead they ask the kernel through system calls.

Example:

When you run:

```bash
cat file.txt
```

The `cat` command does not directly read the disk.

Instead:

```text
cat
 ↓
read() system call
 ↓
Kernel
 ↓
Disk
```

The kernel performs the operation and returns the result.

Common system calls:

```text
open()
read()
write()
close()
fork()
exec()
socket()
```

These form the foundation of Linux.

---

# 6. Linux Philosophy

Linux follows several important design principles.

---

## Philosophy 1: Everything Is a File

This is one of the most important Linux concepts.

In Linux, many resources are represented as files.

Examples:

```text
Regular Files
Directories
Hard Disks
USB Devices
Network Devices
Process Information
```

Examples:

```text
/dev/sda
/dev/null
/proc/cpuinfo
/proc/meminfo
```

All appear as files.

This allows Linux to provide a consistent interface.

Instead of learning different APIs for every device, applications simply interact with files.

---

## Philosophy 2: Small Tools Doing One Thing Well

Linux utilities are intentionally simple.

Examples:

```bash
grep
sort
uniq
wc
cat
head
tail
```

Each command performs a specific task.

Commands are combined together using pipes.

Example:

```bash
cat access.log | grep ERROR | wc -l
```

This demonstrates the Linux philosophy:

```text
Build complex workflows
by combining simple tools.
```

---

## Philosophy 3: Text Is Universal

Linux heavily relies on text.

Configuration files:

```text
/etc/passwd
/etc/fstab
/etc/hosts
```

Logs:

```text
/var/log/*
```

Scripts:

```text
shell scripts
python scripts
```

Because text is human-readable and easy to process.

---

# 7. Understanding the Linux Filesystem

Linux organizes files using a hierarchical tree structure.

Everything begins from a single directory called:

```text
/
```

This is known as the root directory.

Diagram:

```text
/
├── bin
├── boot
├── dev
├── etc
├── home
├── lib
├── media
├── mnt
├── opt
├── proc
├── root
├── run
├── sbin
├── tmp
├── usr
└── var
```

Unlike Windows:

```text
C:\
D:\
E:\
```

Linux has a single filesystem hierarchy.

---

# 8. Important Linux Directories

---

## /

Root directory.

The starting point of the entire filesystem.

Everything exists under this directory.

---

## /bin

Contains essential user commands.

Examples:

```text
ls
cp
mv
cat
mkdir
```

Historically:

```text
/bin = Binary Programs
```

---

## /sbin

System administration commands.

Examples:

```text
fdisk
mount
ifconfig
reboot
```

Mostly intended for administrators.

---

## /etc

System configuration files.

Examples:

```text
/etc/passwd
/etc/shadow
/etc/ssh/sshd_config
/etc/fstab
```

A Linux administrator spends significant time in this directory.

---

## /home

Home directories for users.

Examples:

```text
/home/john
/home/alice
```

User-specific files are stored here.

---

## /root

Home directory of the root user.

Do not confuse:

```text
/
```

with:

```text
/root
```

These are completely different.

---

## /tmp

Temporary files.

Applications frequently use this location.

Files here may be removed automatically.

---

## /var

Variable data.

Examples:

```text
/var/log
/var/cache
/var/spool
```

Frequently changing information is stored here.

---

## /proc

Virtual filesystem.

Contains information about:

* Processes
* CPU
* Memory
* Kernel

Examples:

```bash
cat /proc/cpuinfo
cat /proc/meminfo
```

These are generated dynamically by the kernel.

No actual files exist on disk.

---

## /dev

Device files.

Examples:

```text
/dev/sda
/dev/null
/dev/tty
```

Linux represents hardware devices through files.

---

# 9. Absolute and Relative Paths

Understanding paths is fundamental.

---

## Absolute Path

Starts from root.

Example:

```text
/etc/nginx/nginx.conf
```

Absolute paths always begin with:

```text
/
```

No matter where you currently are.

The path always refers to the same location.

---

## Relative Path

Relative paths start from the current directory.

Suppose:

```bash
pwd
```

returns:

```text
/home/chirag/projects
```

Then:

```text
config/app.conf
```

actually means:

```text
/home/chirag/projects/config/app.conf
```

---

## Why Scripts Prefer Absolute Paths

Imagine:

```bash
./backup.sh
```

executed from different directories.

Relative paths may break.

Absolute paths remain predictable.

This is why production scripts often use absolute paths.

---

# 10. Current Working Directory

Every process has a current working directory.

When you execute:

```bash
pwd
```

the shell displays that directory.

Example:

```text
/home/chirag/projects
```

When a command uses a relative path:

```bash
touch notes.txt
```

Linux interprets it as:

```text
/home/chirag/projects/notes.txt
```

because that is the current working directory.

---

# 11. Special Directory References

Linux provides shortcuts.

Current directory:

```text
.
```

Parent directory:

```text
..
```

Examples:

```bash
cd .
```

Stay in current directory.

```bash
cd ..
```

Move one level up.

---

# 12. Hidden Files

Files beginning with a dot are hidden.

Examples:

```text
.bashrc
.profile
.gitconfig
```

These are usually configuration files.

Display them:

```bash
ls -a
```

---

# 13. Understanding File Types

Not all Linux files are regular files.

Linux supports several file types.

---

## Regular File

Examples:

```text
notes.txt
image.jpg
script.sh
```

Stores data.

---

## Directory

Contains references to files.

Example:

```text
/home
/etc
/var
```

---

## Symbolic Link

Shortcut pointing to another file.

Example:

```bash
ln -s original.txt shortcut.txt
```

Similar to Windows shortcuts.

---

## Character Device

Handles data character by character.

Examples:

```text
Keyboard
Terminal
Serial Port
```

---

## Block Device

Handles data in blocks.

Examples:

```text
Hard Disks
SSDs
NVMe Devices
```

---

## Socket

Used for communication between processes.

Examples:

```text
Docker Socket
Nginx Socket
System Services
```

---

# 14. What Is an Inode?

One of the most important Linux concepts.

Every file consists of:

```text
Data
+
Metadata
```

Linux stores metadata inside a structure called an inode.

An inode contains:

```text
Owner
Permissions
Size
Timestamps
Location on Disk
File Type
```

An inode does NOT contain:

```text
Filename
```

This surprises many beginners.

---

## Why Filenames Are Separate

Directories maintain mappings.

Example:

```text
notes.txt → inode 12345
```

Linux looks up:

```text
Filename
 ↓
Inode
 ↓
Data
```

This design enables:

* Hard Links
* Efficient File Management
* Flexible Filesystem Design

---

# 15. What Is a Directory Internally?

Most beginners think a directory is a special container.

Internally:

```text
A directory is simply a file.
```

The content of the directory file consists of:

```text
Filename → Inode mappings
```

Example:

```text
file1.txt → inode 111
file2.txt → inode 222
file3.txt → inode 333
```

When you run:

```bash
ls
```

Linux reads the directory file and displays the entries.

---

# 16. Understanding Mount Points

This concept becomes important later when learning storage.

Suppose you connect a new disk.

Windows:

```text
D:\
```

Linux does not create drive letters.

Instead:

```text
Disk
 ↓
Mounted
 ↓
Directory
```

Example:

```bash
mount /dev/sdb1 /data
```

Now:

```text
/data
```

becomes the entry point for that disk.

Users access files through:

```text
/data
```

without worrying about the underlying device.

---

# 17. Why Linux Uses Mount Points

Advantages:

### Unified Filesystem

Everything appears under one tree.

```text
/
```

---

### Flexibility

Any filesystem can be mounted anywhere.

Examples:

```text
/backup
/data
/mnt/storage
```

---

### Transparency

Applications do not need to know which disk stores data.

They simply access:

```text
/path/to/file
```

---

# 18. Summary

After completing this chapter, you should understand:

✓ What Linux actually is

✓ Difference between Linux and a Linux Distribution

✓ Kernel vs User Space

✓ System Calls

✓ Linux Philosophy

✓ Everything Is a File

✓ Linux Filesystem Hierarchy

✓ Important Directories

✓ Absolute vs Relative Paths

✓ Hidden Files

✓ File Types

✓ Inodes

✓ Why Directories Are Files

✓ Mount Point Fundamentals

These concepts form the foundation for every Linux topic that follows.

In the next chapter, we will move into practical filesystem interaction and study:

* ls
* cd
* pwd
* mkdir
* touch
* cp
* mv
* rm
* find
* grep
* cat
* less
* head
* tail

while also understanding how Linux performs these operations internally.
