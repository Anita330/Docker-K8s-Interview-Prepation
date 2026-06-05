# Linux Deep Dive Notes

# Chapter 5 - Users and Groups

---

# 1. Introduction

One of the biggest reasons Linux became successful in servers, universities, enterprises, and cloud systems is its ability to support multiple users simultaneously.

Imagine a Linux server being used by:

```text
Alice
Bob
Charlie
David
```

All four users may be logged into the same machine at the same time.

Each user may:

* Run their own programs
* Store their own files
* Have their own permissions
* Have their own processes

Without a proper user management system, Linux would be chaotic.

This chapter explains:

* How Linux identifies users
* How users are stored
* What groups are
* Authentication fundamentals
* Important system files
* User management commands

---

# 2. What Is a User?

A user is simply an identity recognized by Linux.

A user allows Linux to answer questions such as:

```text
Who owns this file?

Who started this process?

Who is allowed to access this resource?

Who is currently logged in?
```

Without users, Linux would have no way to separate activities between different people.

---

# 3. Usernames vs User IDs (UID)

Beginners often think Linux uses usernames internally.

Example:

```text
john
alice
bob
```

This is not entirely true.

Linux primarily uses:

```text
UID
(User ID)
```

---

## Example

User:

```text
john
```

may have:

```text
UID = 1001
```

Internally Linux stores:

```text
1001
```

not:

```text
john
```

The username is simply a human-friendly label.

---

## Why Use UIDs?

Computers work more efficiently with numbers than strings.

Comparing:

```text
1001
```

is faster than comparing:

```text
john
```

---

# 4. Special User IDs

Some UIDs have special meaning.

---

## Root User

```text
UID = 0
```

Most important account in Linux.

Root can:

```text
Read Any File
Write Any File
Modify Any Process
Change Ownership
Install Software
Manage Users
```

The kernel treats UID 0 specially.

---

## System Users

Examples:

```text
nginx
mysql
sshd
daemon
```

Usually have low-numbered UIDs.

These accounts run services.

---

## Normal Users

Typically:

```text
UID >= 1000
```

Examples:

```text
john
alice
chirag
```

Used for human logins.

---

# 5. What Is a Group?

A group is a collection of users.

Instead of assigning permissions individually:

```text
Alice
Bob
Charlie
```

we can place them into:

```text
developers
```

group.

Then grant permissions to the group.

---

## Why Groups Exist

Imagine:

```text
100 developers
```

Need access to:

```text
/project
```

Without groups:

```text
100 permission assignments
```

With groups:

```text
1 group assignment
```

Much easier to manage.

---

# 6. Group IDs (GID)

Groups also use numeric identifiers.

Example:

```text
developers
```

may have:

```text
GID = 1005
```

Linux internally stores:

```text
1005
```

rather than:

```text
developers
```

---

# 7. Primary and Secondary Groups

Every user has:

```text
Primary Group
```

and may have:

```text
Secondary Groups
```

---

## Example

User:

```text
john
```

Primary Group:

```text
john
```

Secondary Groups:

```text
developers
docker
admins
```

---

## Why?

Allows flexible permission management.

User can belong to multiple teams.

---

# 8. How Linux Stores User Information

Linux stores user information in text files.

Three files are extremely important:

```text
/etc/passwd
/etc/shadow
/etc/group
```

Every Linux administrator should understand these files.

---

# 9. /etc/passwd

Historically stored user information and passwords.

Today:

```text
Stores user account information.
```

---

## Example Entry

```text
john:x:1001:1001:John Doe:/home/john:/bin/bash
```

---

## Field Breakdown

### Username

```text
john
```

---

### Password Placeholder

```text
x
```

Actual password stored elsewhere.

---

### UID

```text
1001
```

User ID.

---

### GID

```text
1001
```

Primary Group ID.

---

### Comment Field

```text
John Doe
```

Optional description.

---

### Home Directory

```text
/home/john
```

---

### Login Shell

```text
/bin/bash
```

Shell started after login.

---

# 10. Why Passwords Are Not Stored Here

Historically passwords were stored inside:

```text
/etc/passwd
```

Problem:

```text
Everyone can read /etc/passwd
```

Security risk.

Linux moved password hashes into:

```text
/etc/shadow
```

---

# 11. /etc/shadow

Stores password information.

Only root can access.

---

## Example

```text
john:$6$xyz123...
```

---

## Contains

```text
Password Hash
Password Expiration
Password Aging Information
```

---

# 12. Password Hashes

Linux does not store passwords.

Instead:

```text
Passwords
      ↓
Hash Function
      ↓
Hash Stored
```

Example:

```text
password123
```

becomes:

```text
$6$aslkdj1234...
```

---

## Why Hashes?

If the file is stolen:

```text
Actual passwords remain unknown.
```

---

# 13. Authentication Process

Suppose user logs in.

Linux performs:

```text
User enters password
        ↓
Password hashed
        ↓
Compare with hash in /etc/shadow
        ↓
Match?
        ↓
Login successful
```

Linux never compares plain text passwords.

---

# 14. /etc/group

Stores group information.

---

## Example

```text
developers:x:1005:john,alice,bob
```

---

## Breakdown

Group Name:

```text
developers
```

---

Group Password Placeholder:

```text
x
```

---

GID:

```text
1005
```

---

Members:

```text
john
alice
bob
```

---

# 15. Home Directories

Each user receives:

```text
Home Directory
```

Example:

```text
/ home / john
```

(Without spaces:)

```text
/home/john
```

Contains:

```text
Documents
Downloads
Configurations
Scripts
```

---

## Why Home Directories Exist

Provides separation between users.

Example:

```text
/home/alice
/home/bob
```

Each user controls their own files.

---

# 16. Login Shell

After authentication Linux launches a shell.

Examples:

```text
/bin/bash
/bin/sh
/bin/zsh
/bin/fish
```

Stored in:

```text
/etc/passwd
```

---

## Why Important?

If shell is:

```text
/sbin/nologin
```

user cannot obtain an interactive shell.

Common for service accounts.

---

# 17. useradd

Creates users.

---

## Example

```bash
sudo useradd john
```

Creates account.

---

## Create Home Directory

```bash
sudo useradd -m john
```

Creates:

```text
/home/john
```

automatically.

---

# 18. passwd

Sets or changes passwords.

Example:

```bash
sudo passwd john
```

Linux updates:

```text
/etc/shadow
```

---

## Lock Account

```bash
sudo passwd -l john
```

---

## Unlock Account

```bash
sudo passwd -u john
```

---

# 19. usermod

Modifies user accounts.

---

## Change Login Shell

```bash
sudo usermod -s /bin/zsh john
```

---

## Change Home Directory

```bash
sudo usermod -d /home/newhome john
```

---

## Add User To Group

```bash
sudo usermod -aG docker john
```

---

## Why -a Is Important?

Without:

```text
-a
```

existing groups may be replaced.

This is a common mistake.

---

# 20. userdel

Deletes users.

---

## Delete Account

```bash
sudo userdel john
```

---

## Delete Account And Home

```bash
sudo userdel -r john
```

Removes:

```text
/home/john
```

as well.

---

# 21. groupadd

Creates groups.

Example:

```bash
sudo groupadd developers
```

---

# 22. groupmod

Modifies groups.

Example:

```bash
sudo groupmod -n devops developers
```

Renames group.

---

# 23. groupdel

Deletes groups.

Example:

```bash
sudo groupdel developers
```

---

# 24. id Command

Displays user identity information.

Example:

```bash
id john
```

Output:

```text
uid=1001(john)
gid=1001(john)
groups=1001(john),1005(developers)
```

---

## Why Useful?

Quickly view:

```text
UID
Primary Group
Secondary Groups
```

---

# 25. who Command

Shows logged-in users.

Example:

```bash
who
```

Output:

```text
john pts/0
alice pts/1
```

---

# 26. w Command

Enhanced version of who.

Shows:

```text
Logged-in Users
Terminal
Login Time
Current Activity
CPU Usage
```

---

## Example

```bash
w
```

Useful for administrators.

---

# 27. last Command

Displays login history.

Example:

```bash
last
```

Reads:

```text
/var/log/wtmp
```

---

## Why Useful?

Investigating:

```text
Who Logged In?
When?
From Where?
```

---

# 28. sudo

One of the most important Linux concepts.

---

## Problem

Normal users should not have:

```text
Full Administrative Access
```

---

## Solution

Use:

```bash
sudo
```

to temporarily execute commands as root.

Example:

```bash
sudo apt update
```

---

## Benefits

Provides:

```text
Accountability
Auditing
Controlled Privileges
```

Instead of sharing root password.

---

# 29. Why Not Log In As Root?

Security best practice:

```text
Login As Normal User
Use sudo When Needed
```

Reasons:

```text
Reduced Risk
Better Auditing
Less Accidental Damage
```

---

# 30. Service Accounts

Not every user represents a human.

Examples:

```text
nginx
mysql
postgres
sshd
```

Purpose:

```text
Run Services
```

---

## Why Separate Accounts?

Compromise of one service should not compromise entire system.

Example:

```text
nginx compromised
```

Should not automatically gain:

```text
mysql access
```

---

# 31. User Ownership And Processes

Every process belongs to a user.

Example:

```bash
ps aux
```

Output:

```text
USER PID COMMAND
john 123 bash
root 456 nginx
```

Linux uses ownership for:

```text
Permission Checks
Resource Limits
Auditing
```

---

# 32. User Ownership And Files

Every file belongs to:

```text
User
Group
```

Example:

```text
-rw-r--r--
john developers
```

This integrates directly with the permission system from Chapter 3.

---

# 33. Common Interview Questions

### Q1

Difference between UID and username?

---

### Q2

What is GID?

---

### Q3

Difference between primary and secondary groups?

---

### Q4

Purpose of:

```text
/etc/passwd
```

---

### Q5

Purpose of:

```text
/etc/shadow
```

---

### Q6

Why are passwords stored in /etc/shadow?

---

### Q7

Purpose of:

```text
/etc/group
```

---

### Q8

Difference between useradd and usermod?

---

### Q9

Why use sudo instead of root login?

---

### Q10

How does Linux verify passwords?

---

### Q11

What does:

```bash
usermod -aG
```

do?

---

### Q12

What does the login shell field represent?

---

# 34. Common Beginner Mistakes

## Mistake 1

Editing:

```text
/etc/passwd
```

without understanding consequences.

---

## Mistake 2

Using root account for everything.

---

## Mistake 3

Forgetting:

```text
-a
```

in:

```bash
usermod -aG
```

---

## Mistake 4

Confusing usernames with UIDs.

---

## Mistake 5

Thinking passwords are stored in plain text.

---

# 35. Summary

After completing this chapter you should understand:

✓ Users

✓ Groups

✓ UID

✓ GID

✓ Primary Groups

✓ Secondary Groups

✓ Root User

✓ Service Accounts

✓ Home Directories

✓ Login Shells

✓ /etc/passwd

✓ /etc/shadow

✓ /etc/group

✓ Authentication Basics

✓ Password Hashing

✓ useradd

✓ usermod

✓ userdel

✓ passwd

✓ groupadd

✓ groupmod

✓ groupdel

✓ id

✓ who

✓ w

✓ last

✓ sudo

✓ Common interview questions

In the next chapter we will study:

# Disk and Storage Management

including:

* Disks
* Partitions
* Filesystems
* Mount Points
* df
* du
* lsblk
* blkid
* fdisk
* parted
* LVM
* Storage hierarchy
* How Linux actually stores data on disk

This chapter will connect everything learned so far and explain where files physically reside.
