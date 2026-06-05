# Linux Deep Dive Notes

# Chapter 6 - Disk and Storage Management

---

# 1. Introduction

Everything we have learned so far ultimately depends on storage.

Consider the following:

```text
Files
Directories
Permissions
Users
Logs
Applications
Databases
```

All of them eventually reside on some storage device.

When you execute:

```bash
cat file.txt
```

Linux retrieves data from storage.

When you execute:

```bash
echo "hello" > file.txt
```

Linux writes data to storage.

Understanding Linux storage is essential because it helps answer questions such as:

```text
Where are files actually stored?

What is a filesystem?

What is a partition?

What happens when a disk becomes full?

How does Linux find data on disk?
```

This chapter builds the foundation for understanding storage in Linux.

---

# 2. The Storage Stack

Many beginners think:

```text
File
  ↓
Disk
```

In reality, Linux storage contains multiple layers.

```text
Application
     ↓
Filesystem
     ↓
Logical Volume (Optional)
     ↓
Partition
     ↓
Disk
```

Example:

```text
notes.txt
    ↓
ext4 Filesystem
    ↓
Logical Volume
    ↓
Partition
    ↓
SSD
```

Understanding these layers is extremely important.

---

# 3. What Is a Disk?

A disk is a physical storage device.

Examples:

```text
Hard Disk Drive (HDD)
Solid State Drive (SSD)
NVMe SSD
USB Drive
```

Linux exposes disks as device files.

Examples:

```text
/dev/sda
/dev/sdb
/dev/nvme0n1
```

---

## Why Are Disks Represented As Files?

Recall Linux philosophy:

```text
Everything is a File
```

Disks are treated as block device files.

Applications can interact with them through the kernel.

---

# 4. Understanding Block Devices

Storage devices transfer data in chunks.

These chunks are called:

```text
Blocks
```

Typical block sizes:

```text
512 Bytes
4 KB
```

Unlike regular files:

```text
Storage devices operate on blocks.
```

Hence:

```text
Disk = Block Device
```

---

# 5. Viewing Disks

Command:

```bash
lsblk
```

Example output:

```text
NAME    SIZE TYPE
sda     100G disk
├─sda1   1G part
└─sda2  99G part
```

---

## Why lsblk Is Important

Provides:

```text
Disk Layout
Partitions
Mount Points
Relationships
```

Very useful during troubleshooting.

---

# 6. What Is a Partition?

A partition is a logical subdivision of a disk.

Example:

```text
100 GB Disk
```

can be divided into:

```text
20 GB
30 GB
50 GB
```

Diagram:

```text
+----------------------+
|      Disk            |
+----------------------+

+------+-------+-------+
|20 GB |30 GB  |50 GB  |
+------+-------+-------+

 sda1   sda2   sda3
```

---

## Why Partitions Exist

Partitions provide:

```text
Organization
Isolation
Flexibility
```

Example:

```text
/
/home
/var
```

may use different partitions.

---

# 7. How Linux Names Partitions

Disk:

```text
/dev/sda
```

Partitions:

```text
/dev/sda1
/dev/sda2
/dev/sda3
```

---

NVMe devices:

```text
/dev/nvme0n1
```

Partitions:

```text
/dev/nvme0n1p1
/dev/nvme0n1p2
```

---

# 8. What Is a Filesystem?

A filesystem organizes data on storage.

Without a filesystem:

```text
Disk = Random Blocks
```

Linux would not know:

```text
Where files begin
Where files end
Where metadata exists
```

---

## Filesystem Responsibilities

A filesystem manages:

```text
Files
Directories
Permissions
Ownership
Timestamps
Inodes
Free Space
```

---

## Analogy

Think of a filesystem like a library catalog.

Without a catalog:

```text
Books exist
```

but finding them is difficult.

The filesystem provides structure.

---

# 9. Common Linux Filesystems

---

## ext4

Most common Linux filesystem.

Features:

```text
Reliable
Mature
Widely Supported
```

---

## XFS

Popular on enterprise servers.

Features:

```text
Excellent Performance
Large Filesystem Support
```

---

## Btrfs

Modern filesystem.

Features:

```text
Snapshots
Compression
Advanced Features
```

---

# 10. Disk vs Partition vs Filesystem

This is one of the most common interview questions.

---

## Disk

Physical device.

Example:

```text
/dev/sda
```

---

## Partition

Logical division of disk.

Example:

```text
/dev/sda1
```

---

## Filesystem

Data organization structure.

Example:

```text
ext4
xfs
btrfs
```

---

Diagram:

```text
Disk
 ↓
Partition
 ↓
Filesystem
 ↓
Files
```

---

# 11. What Is a Mount Point?

One of the most important Linux concepts.

---

## Problem

Suppose:

```text
Filesystem exists
```

How does user access it?

Linux uses:

```text
Mount Points
```

---

## Example

Filesystem:

```text
/dev/sdb1
```

Mounted at:

```text
/data
```

Now users access:

```text
/data
```

instead of:

```text
/dev/sdb1
```

---

Diagram:

```text
Disk
 ↓
Partition
 ↓
Filesystem
 ↓
Mount Point
 ↓
/data
```

---

# 12. Why Linux Uses Mount Points

Unlike Windows:

```text
C:
D:
E:
```

Linux uses:

```text
Single Unified Tree
```

Everything appears under:

```text
/
```

---

Example:

```text
/
├── home
├── var
├── data
└── backup
```

Each directory may represent a different storage device.

Applications don't need to know.

---

# 13. mount Command

Used to attach filesystems.

Example:

```bash
mount /dev/sdb1 /data
```

After mounting:

```text
/data
```

contains the filesystem contents.

---

# 14. umount Command

Used to detach filesystems.

Example:

```bash
umount /data
```

Filesystem becomes inaccessible.

---

## Why Unmount?

Ensures:

```text
Pending Writes Complete
Filesystem Consistency
Data Integrity
```

---

# 15. Viewing Mounted Filesystems

Command:

```bash
mount
```

Displays:

```text
Mounted Filesystems
Mount Points
Filesystem Types
```

---

# 16. df Command

Displays filesystem usage.

---

## Example

```bash
df -h
```

Output:

```text
Filesystem Size Used Avail Use%
```

Example:

```text
/dev/sda2 100G 60G 40G 60%
```

---

## Why Use -h?

Human-readable sizes.

Example:

```text
GB
MB
TB
```

instead of raw bytes.

---

# 17. Common Use Cases For df

Check:

```text
Disk Full?
Filesystem Usage?
Available Space?
```

Very common troubleshooting command.

---

# 18. du Command

Displays space consumed by files and directories.

---

## Example

```bash
du -sh /var/log
```

Output:

```text
2.5G /var/log
```

---

## Difference Between df and du

Common interview question.

---

### df

Shows:

```text
Filesystem Usage
```

Example:

```text
Whole Disk
```

---

### du

Shows:

```text
Directory Usage
```

Example:

```text
Specific Folder
```

---

# 19. Why df and du Differ

Suppose:

```text
File Deleted
```

but process still holds file open.

Result:

```text
df shows space used
du cannot find file
```

This is a famous troubleshooting scenario.

---

# 20. blkid Command

Displays block device information.

Example:

```bash
blkid
```

Output:

```text
UUID
Filesystem Type
Partition Information
```

---

## Why Important?

Used by:

```text
/etc/fstab
```

for persistent mounts.

---

# 21. What Is UUID?

UUID:

```text
Universally Unique Identifier
```

Example:

```text
1234-ABCD-5678-EFGH
```

---

## Why Not Use Device Names?

Device names can change:

```text
sda
sdb
```

after reboot.

UUID remains constant.

---

# 22. Persistent Mounting

Problem:

```text
Manual mount disappears after reboot.
```

Solution:

```text
/etc/fstab
```

---

## Example

```text
UUID=abcd1234 /data ext4 defaults 0 0
```

Linux mounts automatically during boot.

---

# 23. fdisk

Traditional partition management tool.

Example:

```bash
fdisk /dev/sdb
```

Used to:

```text
Create Partitions
Delete Partitions
View Partition Table
```

---

## Why Important?

Before creating a filesystem:

```text
Disk
 ↓
Partition Required
```

---

# 24. Partition Tables

Partitions are described using partition tables.

Two major formats:

```text
MBR
GPT
```

---

# 25. MBR (Master Boot Record)

Older standard.

Limitations:

```text
Maximum 2 TB Disk
Maximum 4 Primary Partitions
```

---

# 26. GPT (GUID Partition Table)

Modern standard.

Advantages:

```text
Large Disks
Many Partitions
Improved Reliability
```

Preferred today.

---

# 27. parted

Modern partitioning utility.

Example:

```bash
parted /dev/sdb
```

Supports:

```text
GPT
Large Disks
Modern Systems
```

---

# 28. What Is LVM?

One of the most important Linux storage concepts.

LVM stands for:

```text
Logical Volume Manager
```

---

## Why LVM Exists

Traditional partitions are rigid.

Example:

```text
Partition = 50 GB
```

Later:

```text
Need 80 GB
```

Resizing becomes difficult.

LVM provides flexibility.

---

# 29. Traditional Storage Layout

```text
Disk
 ↓
Partition
 ↓
Filesystem
```

Limited flexibility.

---

# 30. LVM Storage Layout

```text
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

Much more flexible.

---

# 31. Physical Volume (PV)

Physical storage device used by LVM.

Example:

```text
/dev/sdb1
```

Create:

```bash
pvcreate /dev/sdb1
```

---

# 32. Volume Group (VG)

Storage pool.

Example:

```text
Disk A = 100 GB
Disk B = 100 GB

VG = 200 GB
```

Create:

```bash
vgcreate data_vg /dev/sdb1
```

---

## Analogy

Think of VG as:

```text
Storage Reservoir
```

---

# 33. Logical Volume (LV)

Virtual partition created from a Volume Group.

Example:

```bash
lvcreate -L 50G -n app_lv data_vg
```

Creates:

```text
50 GB Logical Volume
```

---

## Analogy

Think of LV as:

```text
Flexible Partition
```

---

# 34. Filesystem Creation

After creating LV:

```bash
mkfs.ext4 /dev/data_vg/app_lv
```

Creates filesystem.

---

# 35. Mounting Logical Volume

```bash
mount /dev/data_vg/app_lv /app
```

Applications now use:

```text
/app
```

normally.

---

# 36. Advantages of LVM

---

## Easy Expansion

Add storage later.

---

## Storage Pooling

Combine multiple disks.

---

## Flexible Allocation

Create volumes as needed.

---

## Snapshots

Capture filesystem state.

Useful for backups.

---

# 37. Real Storage Flow

When application writes file:

```text
Application
 ↓
Filesystem
 ↓
Logical Volume
 ↓
Volume Group
 ↓
Physical Volume
 ↓
Disk
```

Understanding this flow helps during troubleshooting.

---

# 38. Common Interview Questions

### Q1

Difference between:

```text
Disk
Partition
Filesystem
```

---

### Q2

What is a mount point?

---

### Q3

Why does Linux use mount points instead of drive letters?

---

### Q4

Difference between:

```bash
df
du
```

---

### Q5

Why can df and du show different values?

---

### Q6

Purpose of:

```bash
lsblk
```

---

### Q7

Purpose of:

```bash
blkid
```

---

### Q8

What is UUID?

---

### Q9

Purpose of:

```text
/etc/fstab
```

---

### Q10

What is LVM?

---

### Q11

Difference between:

```text
PV
VG
LV
```

---

### Q12

Why use LVM instead of traditional partitions?

---

### Q13

Difference between GPT and MBR?

---

# 39. Common Beginner Mistakes

## Mistake 1

Confusing disk with filesystem.

---

## Mistake 2

Thinking partitions store files.

Actually:

```text
Filesystem stores files.
```

---

## Mistake 3

Forgetting to mount a filesystem.

---

## Mistake 4

Removing devices without unmounting.

---

## Mistake 5

Using device names instead of UUIDs in fstab.

---

# 40. Summary

After completing this chapter you should understand:

✓ Storage Architecture

✓ Disks

✓ Block Devices

✓ Partitions

✓ Filesystems

✓ ext4

✓ XFS

✓ Mount Points

✓ mount

✓ umount

✓ lsblk

✓ blkid

✓ UUID

✓ /etc/fstab

✓ df

✓ du

✓ fdisk

✓ GPT

✓ MBR

✓ parted

✓ LVM

✓ PV

✓ VG

✓ LV

✓ Storage Expansion Concepts

✓ Common Interview Questions

At this point you have covered the core Linux topics that appear in most Linux interviews:

* File Management
* Permissions
* Processes
* Users & Groups
* Storage

The next logical chapter should be:

# Chapter 7 - Linux Internals Foundations

where we dive deeper into:

* Inodes (Advanced)
* Hard Links vs Soft Links
* File Descriptors
* Standard Input / Output / Error
* Redirection
* Pipes
* /proc Filesystem
* Sysfs
* Kernel Interaction

These are the concepts that separate someone who merely uses Linux from someone who truly understands how Linux works internally.
