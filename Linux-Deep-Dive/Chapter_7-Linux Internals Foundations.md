# Linux Deep Dive Notes

# Chapter 7 - Linux Internals Foundations

---

# 1. Introduction

Up to this point, we have learned:

* Files and Directories
* Permissions
* Processes
* Users and Groups
* Storage

However, many Linux interview questions are not about commands.

Instead, they focus on:

```text
How Linux works internally.
```

Examples:

```text
What is an inode?

What is a file descriptor?

What happens when I run:

echo hello > file.txt

What is a pipe?

What is /proc?

What is a symbolic link?
```

This chapter explains the concepts that connect all previous chapters together.

Understanding these concepts is often what separates:

```text
Linux User
```

from

```text
Linux Administrator
```

---

# 2. Understanding How Linux Views Files

Most beginners think:

```text
File
    ↓
Filename
```

Linux actually sees:

```text
Filename
    ↓
Inode
    ↓
Data Blocks
```

This distinction is extremely important.

---

## Example

File:

```text
notes.txt
```

Linux internally stores:

```text
Filename
notes.txt

Inode
12345

Data
Hello World
```

The filename is not the file itself.

The inode is what Linux truly identifies.

---

# 3. What Is an Inode?

An inode is a data structure that stores metadata about a file.

Think of it as:

```text
File Identity Card
```

---

## Stored Inside an Inode

```text
File Type
Permissions
Owner UID
Group GID
File Size
Timestamps
Link Count
Data Block Locations
```

---

## Not Stored Inside an Inode

Surprisingly:

```text
Filename
```

is NOT stored inside the inode.

---

## Why?

Allows:

```text
Multiple names
pointing to same inode
```

which makes hard links possible.

---

# 4. Visualizing File Access

Suppose:

```text
notes.txt
```

exists.

Directory contains:

```text
notes.txt → inode 12345
```

Inode contains:

```text
inode 12345
      ↓
Data Blocks
```

Access flow:

```text
Filename
     ↓
Directory Lookup
     ↓
Inode
     ↓
Data Blocks
```

---

# 5. Viewing Inodes

Command:

```bash
ls -i
```

Example:

```text
12345 notes.txt
```

Where:

```text
12345
```

is inode number.

---

# 6. What Are Data Blocks?

Actual file content is stored in:

```text
Data Blocks
```

Example:

```text
File Content
```

```text
Hello Linux
```

resides inside blocks on disk.

---

## Why Separate Inode and Data?

Benefits:

```text
Efficient Metadata Access
Flexible Storage
Scalable Filesystems
```

---

# 7. Hard Links

One of the most common interview topics.

---

## What Is a Hard Link?

Multiple filenames pointing to the same inode.

Example:

```bash
ln file1 file2
```

---

## Result

```text
file1 → inode 123
file2 → inode 123
```

Both names refer to the same file.

---

## Example

Original:

```text
file1
```

Create:

```bash
ln file1 file2
```

Now:

```text
file1
file2
```

share the same inode.

---

## Important Behavior

Modify:

```text
file1
```

Changes appear in:

```text
file2
```

because both reference identical data.

---

# 8. Hard Link Link Count

Every inode stores:

```text
Link Count
```

Number of directory entries pointing to it.

Example:

```text
inode 123
 ↑      ↑
file1 file2
```

Link Count:

```text
2
```

---

## Deleting Hard Links

Remove:

```bash
rm file1
```

Linux:

```text
Removes filename
```

but inode remains because:

```text
file2 still exists
```

Data is removed only when:

```text
Link Count = 0
```

---

# 9. Symbolic Links (Soft Links)

Another extremely common interview topic.

---

## What Is a Symbolic Link?

A special file pointing to another file.

Example:

```bash
ln -s original.txt shortcut.txt
```

---

## Result

```text
shortcut.txt
        ↓
original.txt
```

---

## Similar To

Windows:

```text
Shortcut
```

---

## Internal Structure

Symbolic link contains:

```text
Path To Target
```

Example:

```text
original.txt
```

---

# 10. Hard Link vs Soft Link

One of the most frequently asked Linux interview questions.

---

## Hard Link

```text
Points To Inode
```

---

## Soft Link

```text
Points To Path
```

---

## Hard Link

```text
Works if original name removed
```

---

## Soft Link

```text
Breaks if target removed
```

---

## Hard Link

```text
Cannot span filesystems
```

---

## Soft Link

```text
Can span filesystems
```

---

## Interview Answer

```text
Hard Link:
Multiple names for same inode.

Soft Link:
Separate file containing path to target.
```

---

# 11. What Is a File Descriptor?

One of the most important Linux concepts.

Many advanced Linux topics depend on this.

---

## Definition

A file descriptor is:

```text
A number used by a process
to access an open file.
```

---

## Why Needed?

Opening a file repeatedly by filename would be inefficient.

Linux opens file once and assigns:

```text
File Descriptor
```

---

## Example

```bash
cat notes.txt
```

Linux:

```text
Open File
 ↓
Assign FD
 ↓
Read Using FD
```

---

# 12. Standard File Descriptors

Every process starts with:

| FD | Meaning         |
| -- | --------------- |
| 0  | Standard Input  |
| 1  | Standard Output |
| 2  | Standard Error  |

---

## Standard Input

FD:

```text
0
```

Usually:

```text
Keyboard
```

---

## Standard Output

FD:

```text
1
```

Usually:

```text
Terminal
```

---

## Standard Error

FD:

```text
2
```

Usually:

```text
Terminal
```

---

# 13. Viewing Open File Descriptors

Every process has:

```text
/proc/PID/fd
```

Example:

```bash
ls /proc/1234/fd
```

Shows open descriptors.

---

# 14. Input and Output Redirection

One of Linux's most powerful features.

---

## Standard Output Redirection

Example:

```bash
echo hello > file.txt
```

Normally:

```text
echo
 ↓
Terminal
```

With redirection:

```text
echo
 ↓
file.txt
```

---

## Append Output

```bash
echo hello >> file.txt
```

Adds content to end.

---

# 15. Error Redirection

Redirect errors.

Example:

```bash
ls missingfile 2> error.log
```

Meaning:

```text
FD 2
 ↓
error.log
```

---

# 16. Redirect Both Output And Errors

Example:

```bash
command > output.log 2>&1
```

Meaning:

```text
stdout
stderr
 ↓
same file
```

Very common in scripts.

---

# 17. What Is a Pipe?

Another fundamental Linux concept.

Pipe symbol:

```text
|
```

---

## Purpose

Connect output of one command to input of another.

Example:

```bash
cat file.txt | grep error
```

---

Flow:

```text
cat
 ↓
Pipe
 ↓
grep
```

---

# 18. Why Pipes Matter

Without pipes:

```text
Temporary files needed.
```

With pipes:

```text
Direct communication.
```

Efficient and elegant.

---

# 19. Common Pipe Examples

Count errors:

```bash
grep ERROR app.log | wc -l
```

---

View running processes:

```bash
ps aux | grep nginx
```

---

Sort data:

```bash
cat users.txt | sort
```

---

# 20. What Is the /proc Filesystem?

One of Linux's most interesting features.

---

## What Is /proc?

Virtual filesystem generated by the kernel.

Not stored on disk.

---

Example:

```bash
ls /proc
```

Shows:

```text
CPU Info
Memory Info
Process Information
Kernel Information
```

---

# 21. Process Directories

Every process receives a directory.

Example:

```text
/proc/1234
```

where:

```text
1234 = PID
```

---

Contains:

```text
Memory Information
Open Files
Environment Variables
Status
```

---

# 22. Useful /proc Files

---

## CPU Information

```bash
cat /proc/cpuinfo
```

---

## Memory Information

```bash
cat /proc/meminfo
```

---

## Process Status

```bash
cat /proc/PID/status
```

---

## Mount Information

```bash
cat /proc/mounts
```

---

# 23. Why /proc Exists

Provides a simple interface:

```text
Kernel Information
     ↓
Files
```

Again demonstrating:

```text
Everything Is A File
```

---

# 24. What Is Sysfs?

Another virtual filesystem.

Mounted at:

```text
/sys
```

---

## Purpose

Expose hardware and kernel objects.

Examples:

```text
Devices
Drivers
Buses
Kernel Components
```

---

## Difference Between /proc and /sys

### /proc

Focuses on:

```text
Processes
Kernel State
```

---

### /sys

Focuses on:

```text
Hardware
Devices
Drivers
```

---

# 25. What Happens When You Open a File?

Suppose:

```bash
cat notes.txt
```

Linux performs:

```text
Locate filename
      ↓
Find inode
      ↓
Open file
      ↓
Create file descriptor
      ↓
Read data blocks
      ↓
Display output
```

This single command uses concepts from every previous chapter.

---

# 26. What Happens When You Delete a File?

Example:

```bash
rm notes.txt
```

Linux does NOT immediately erase data.

It:

```text
Removes directory entry
      ↓
Decrements link count
      ↓
Checks count
      ↓
If zero:
Release inode
Release blocks
```

This explains why deleted data can sometimes be recovered.

---

# 27. Open File Deletion Scenario

Famous interview question.

Suppose:

```bash
rm logfile.log
```

but application still has file open.

Result:

```text
Directory Entry Removed
File Still Exists
Disk Space Still Used
```

until process closes file.

This explains some:

```text
df vs du
```

discrepancies.

---

# 28. Common Interview Questions

### Q1

What is an inode?

---

### Q2

What information is stored inside an inode?

---

### Q3

Is filename stored in inode?

Answer:

```text
No
```

---

### Q4

What is a hard link?

---

### Q5

What is a symbolic link?

---

### Q6

Difference between hard link and soft link?

---

### Q7

What is a file descriptor?

---

### Q8

What are:

```text
0
1
2
```

file descriptors?

---

### Q9

Difference between:

```text
>
>>
```

---

### Q10

What is a pipe?

---

### Q11

What is /proc?

---

### Q12

What is /sys?

---

### Q13

What happens internally when opening a file?

---

### Q14

What happens internally when deleting a file?

---

# 29. Common Beginner Mistakes

## Mistake 1

Thinking filename is the file.

---

## Mistake 2

Confusing hard links with soft links.

---

## Mistake 3

Not understanding file descriptors.

---

## Mistake 4

Using temporary files instead of pipes.

---

## Mistake 5

Ignoring /proc during troubleshooting.

---

# 30. Summary

After completing this chapter you should understand:

✓ Inodes

✓ Data Blocks

✓ File Metadata

✓ Hard Links

✓ Symbolic Links

✓ Hard Link vs Soft Link

✓ File Descriptors

✓ Standard Input

✓ Standard Output

✓ Standard Error

✓ Redirection

✓ Pipes

✓ /proc Filesystem

✓ /sys Filesystem

✓ Open File Lifecycle

✓ Delete File Lifecycle

✓ Common Linux Interview Questions

At this point you have covered most of the Linux fundamentals asked in interviews.

The next logical chapter is:

# Chapter 8 - Linux Networking Fundamentals

including:

* IP Addressing
* MAC Addresses
* Routing
* DNS
* TCP vs UDP
* Ports
* Sockets
* netstat
* ss
* ping
* traceroute
* curl
* wget
* Network Troubleshooting

This chapter will explain how Linux systems communicate with each other and how network applications actually work.
