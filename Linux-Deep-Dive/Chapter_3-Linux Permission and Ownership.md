# Linux Deep Dive Notes

# Chapter 3 - Linux Permissions and Ownership

---

# 1. Introduction

One of Linux's greatest strengths is its security model.

Unlike single-user operating systems, Linux was designed from the beginning as a multi-user operating system.

Consider a shared Linux server:

```text
Users:
- Alice
- Bob
- Charlie
```

Suppose Alice stores:

```text
salary.xlsx
```

on the server.

Without a permission system:

* Bob could read the file.
* Charlie could modify the file.
* Any user could delete it.

This would make the operating system unusable.

Linux solves this problem using:

```text
Users
Groups
Permissions
Ownership
```

Every file and directory in Linux is protected by this security model.

Understanding permissions is one of the most important Linux concepts and is frequently discussed in interviews.

---

# 2. How Linux Stores Permissions

Before learning commands, let's understand where permissions are stored.

Recall from Chapter 1:

Every file has an inode.

An inode stores metadata such as:

```text
Owner UID
Group GID
Permission Bits
File Size
Timestamps
File Type
```

Example:

```bash
ls -l notes.txt
```

Output:

```text
-rw-r--r-- 1 john developers 1024 Jan 10 notes.txt
```

The permission information:

```text
-rw-r--r--
```

is stored inside the inode.

The file contents are stored elsewhere.

This means:

```text
Changing permissions
does not modify file contents.
```

Only inode metadata changes.

---

# 3. The Linux Permission Model

Every file has three permission sets.

```text
User (Owner)
Group
Others
```

Diagram:

```text
File
│
├── Owner Permissions
├── Group Permissions
└── Others Permissions
```

---

## Example

```text
-rwxr-xr--
```

Breakdown:

```text
Owner   = rwx
Group   = r-x
Others  = r--
```

Meaning:

```text
Owner:
Read
Write
Execute

Group:
Read
Execute

Others:
Read
```

---

# 4. Understanding Read Permission (r)

Symbol:

```text
r
```

Numeric Value:

```text
4
```

---

## For Regular Files

Read permission allows:

```text
View file contents
```

Example:

```bash
cat notes.txt
```

Without read permission:

```text
Permission Denied
```

---

## For Directories

Read permission means:

```text
List directory contents
```

Example:

```bash
ls directory
```

---

# 5. Understanding Write Permission (w)

Symbol:

```text
w
```

Value:

```text
2
```

---

## For Files

Allows:

```text
Modify file content
```

Examples:

```bash
echo hello >> file.txt
nano file.txt
```

---

## For Directories

Allows:

```text
Create files
Delete files
Rename files
```

Many beginners find this surprising.

Directory write permission controls changes to directory entries.

---

# 6. Understanding Execute Permission (x)

Symbol:

```text
x
```

Value:

```text
1
```

---

## For Files

Allows execution.

Example:

```bash
./backup.sh
```

Without execute permission:

```text
Permission denied
```

even if the file is readable.

---

## For Directories

Allows entering the directory.

Example:

```bash
cd project
```

Without execute permission:

```text
Cannot access directory
```

even if read permission exists.

---

# 7. Reading Permission Strings

Example:

```text
-rwxr-x---
```

Breakdown:

```text
-
rwx
r-x
---
```

---

## First Character

Represents file type.

```text
-  Regular File
d  Directory
l  Symbolic Link
c  Character Device
b  Block Device
s  Socket
```

---

## Remaining Characters

```text
rwx
r-x
---
```

Represent:

```text
Owner
Group
Others
```

---

# 8. Numeric Permission System

Linux permissions are often represented numerically.

Many beginners memorize:

```text
755
644
600
777
```

without understanding them.

Let's understand how they are calculated.

---

## Permission Values

```text
Read    = 4
Write   = 2
Execute = 1
```

---

## Examples

### rwx

```text
4 + 2 + 1 = 7
```

Result:

```text
7
```

---

### rw-

```text
4 + 2 = 6
```

Result:

```text
6
```

---

### r-x

```text
4 + 1 = 5
```

Result:

```text
5
```

---

### r--

```text
4
```

Result:

```text
4
```

---

# 9. Understanding 755

Permission:

```text
rwxr-xr-x
```

Calculation:

```text
Owner   = 7
Group   = 5
Others  = 5
```

Result:

```text
755
```

Meaning:

```text
Owner:
Read Write Execute

Group:
Read Execute

Others:
Read Execute
```

Common usage:

```text
Scripts
Directories
Executables
```

---

# 10. Understanding 644

Permission:

```text
rw-r--r--
```

Meaning:

```text
Owner:
Read Write

Group:
Read

Others:
Read
```

Common usage:

```text
Configuration Files
Text Files
Source Code
```

---

# 11. Understanding 600

Permission:

```text
rw-------
```

Meaning:

```text
Only owner can access
```

Common usage:

```text
SSH Private Keys
Passwords
Sensitive Data
```

---

# 12. Understanding 777

Permission:

```text
rwxrwxrwx
```

Everyone can:

```text
Read
Write
Execute
```

This is generally considered unsafe.

Interviewers often ask:

```text
Why is chmod 777 dangerous?
```

Answer:

Because every user on the system can modify the file.

---

# 13. chmod

## Purpose

Changes permission bits.

---

## Numeric Method

Example:

```bash
chmod 755 script.sh
```

Result:

```text
rwxr-xr-x
```

---

## Symbolic Method

Add execute permission:

```bash
chmod +x script.sh
```

---

Owner only:

```bash
chmod u+x script.sh
```

---

Group:

```bash
chmod g+w file.txt
```

---

Others:

```bash
chmod o-r file.txt
```

---

## Internal Working

Linux updates:

```text
Permission Bits
```

inside the inode.

The file contents remain unchanged.

---

# 14. Ownership

Every file has:

```text
Owner
Group
```

Example:

```text
-rw-r--r-- john developers notes.txt
```

Owner:

```text
john
```

Group:

```text
developers
```

---

# 15. Why Ownership Exists

Permissions alone are not enough.

Linux needs to know:

```text
Who owns the file?
```

Ownership determines who can:

```text
Modify permissions
Change ownership
Delete files
```

---

# 16. User IDs (UID)

Internally Linux does not store usernames.

It stores:

```text
UID
```

Example:

```text
john
```

may be:

```text
UID 1001
```

The kernel works with:

```text
1001
```

not the name "john".

---

# 17. Group IDs (GID)

Similar to UID.

Example:

```text
developers
```

may be:

```text
GID 1005
```

Kernel stores:

```text
1005
```

internally.

---

# 18. chown

Changes ownership.

---

## Example

```bash
sudo chown john file.txt
```

New owner:

```text
john
```

---

## Owner and Group

```bash
sudo chown john:developers file.txt
```

---

## Recursive

```bash
sudo chown -R john:developers project
```

Changes ownership for all files recursively.

---

## Internal Working

Updates:

```text
UID
GID
```

stored in inode metadata.

---

# 19. chgrp

Changes group ownership.

Example:

```bash
chgrp developers file.txt
```

Changes:

```text
Group
```

only.

---

# 20. Why Root Bypasses Permissions

Linux has a special user:

```text
root
```

UID:

```text
0
```

Kernel treats UID 0 specially.

Root can generally:

```text
Read any file
Write any file
Change ownership
Modify permissions
```

This is why root access is extremely powerful.

---

# 21. Understanding umask

One of the most misunderstood Linux concepts.

---

## What Problem Does umask Solve?

When a file is created:

```bash
touch file.txt
```

Linux must determine:

```text
What permissions should it have?
```

umask controls this default behavior.

---

# 22. Default Permissions

Linux starts with:

Files:

```text
666
```

Directories:

```text
777
```

Then applies:

```text
umask
```

---

## Example

Current umask:

```bash
umask
```

Output:

```text
022
```

---

### File

```text
666 - 022 = 644
```

Result:

```text
rw-r--r--
```

---

### Directory

```text
777 - 022 = 755
```

Result:

```text
rwxr-xr-x
```

---

# 23. Why Files Don't Get 777

A common interview question.

Question:

```text
Why don't newly created files get 777 permissions?
```

Answer:

Because executable permission is not granted by default.

Regular files start from:

```text
666
```

not

```text
777
```

---

# 24. Special Permissions

Linux provides three advanced permission mechanisms.

```text
SUID
SGID
Sticky Bit
```

These are common interview topics.

---

# 25. SUID (Set User ID)

Purpose:

```text
Run program as file owner.
```

---

## Example

```bash
passwd
```

Normal users can change passwords.

But password data is stored in:

```text
/etc/shadow
```

which normal users cannot modify.

How does this work?

Because:

```bash
ls -l /usr/bin/passwd
```

shows:

```text
-rwsr-xr-x
```

Notice:

```text
s
```

instead of:

```text
x
```

This indicates SUID.

When executed:

```text
Program runs as owner.
```

Usually:

```text
root
```

---

## Setting SUID

```bash
chmod 4755 program
```

---

# 26. SGID (Set Group ID)

Purpose:

```text
Run using group permissions.
```

or

```text
Preserve group ownership in directories.
```

---

## Directory Example

Shared project:

```text
/project
```

Group:

```text
developers
```

Enable SGID:

```bash
chmod 2775 project
```

Now all new files inherit:

```text
developers
```

group automatically.

---

# 27. Sticky Bit

Purpose:

```text
Prevent users from deleting files
they do not own.
```

---

## Why Is It Needed?

Suppose:

```text
/tmp
```

is writable by everyone.

Without Sticky Bit:

```text
User A could delete User B's files.
```

---

## Example

```bash
ls -ld /tmp
```

Output:

```text
drwxrwxrwt
```

Notice:

```text
t
```

This indicates Sticky Bit.

---

## Setting Sticky Bit

```bash
chmod 1777 shared_directory
```

---

# 28. Permission Evaluation Process

When a user accesses a file:

Linux checks:

```text
1. Is user owner?
      Yes → Use owner permissions

2. Otherwise:
      Is user in file group?
      Yes → Use group permissions

3. Otherwise:
      Use others permissions
```

Only one permission set is evaluated.

---

# 29. Common Beginner Mistakes

## Mistake 1

Using:

```bash
chmod 777
```

to solve every permission problem.

---

## Mistake 2

Confusing ownership with permissions.

---

## Mistake 3

Thinking root obeys normal permission checks.

---

## Mistake 4

Misunderstanding directory permissions.

---

## Mistake 5

Forgetting recursive options:

```bash
chmod -R
chown -R
```

---

# 30. Interview Questions

## Question 1

Difference between:

```text
644
755
600
```

---

## Question 2

Why is:

```bash
chmod 777
```

dangerous?

---

## Question 3

What is SUID?

Provide passwd example.

---

## Question 4

What is SGID?

Explain shared directory usage.

---

## Question 5

Why does /tmp have Sticky Bit?

---

## Question 6

How does Linux decide which permission set to use?

---

## Question 7

What is stored in an inode?

---

## Question 8

What is umask?

---

## Question 9

Difference between:

```bash
chmod
chown
chgrp
```

---

# 31. Summary

After completing this chapter, you should understand:

✓ Linux permission model

✓ Read, Write, Execute

✓ Owner, Group, Others

✓ Numeric permissions

✓ 755

✓ 644

✓ 600

✓ chmod

✓ Ownership

✓ UID and GID

✓ chown

✓ chgrp

✓ umask

✓ SUID

✓ SGID

✓ Sticky Bit

✓ Permission evaluation process

✓ Common interview questions

In the next chapter, we will study:

# Processes and Jobs

including:

* What a process actually is
* Process lifecycle
* Process states
* PID and PPID
* Zombie processes
* Orphan processes
* Daemons
* Signals
* ps
* top
* htop
* kill
* nice
* renice
* jobs
* bg
* fg
* nohup

This chapter forms the foundation for understanding how Linux executes programs and manages running tasks.
