# Linux Deep Dive Notes

# Chapter 2 - File and Directory Management

---

# 1. Introduction

Now that we understand:

* What Linux is
* How the filesystem is organized
* What directories are
* What inodes are
* Absolute and relative paths

we can begin learning how to interact with the filesystem.

This chapter focuses on the commands used to navigate, create, search, copy, move, and remove files and directories.

However, instead of simply memorizing commands, we will understand:

* Why the command exists
* What problem it solves
* How Linux performs the operation internally
* Common mistakes
* Real-world usage
* Interview questions

---

# 2. Understanding File Operations

Before studying commands, it is important to understand what actually happens when Linux manipulates files.

Suppose you create a file:

```bash
touch notes.txt
```

Linux does not simply "create a file."

Internally it performs several operations:

1. Allocates an inode.
2. Creates a directory entry.
3. Associates filename with inode.
4. Updates filesystem metadata.
5. Updates timestamps.

The same idea applies to almost every file operation.

Understanding this will make the commands much easier to remember.

---

# 3. pwd (Print Working Directory)

## What Is It?

Displays the current directory in which the shell is operating.

Example:

```bash
pwd
```

Output:

```text
/home/chirag/projects
```

---

## Why Does It Exist?

Linux commands often use relative paths.

To resolve those paths, Linux must know:

```text
Where am I currently?
```

That location is called the Current Working Directory (CWD).

---

## Internal Working

Every process stores:

```text
Current Working Directory
```

inside its process information.

When you execute:

```bash
pwd
```

the shell retrieves and displays that value.

---

## Example

Current directory:

```text
/home/chirag/projects
```

Command:

```bash
touch test.txt
```

Linux interprets:

```text
/home/chirag/projects/test.txt
```

---

## Interview Question

Q: Why is `pwd` useful?

Answer:

Because relative paths depend on the current working directory.

---

# 4. cd (Change Directory)

## What Is It?

Changes the current working directory.

Example:

```bash
cd /etc
```

---

## Why Does It Exist?

Instead of repeatedly typing long paths:

```bash
cat /home/chirag/projects/config/app.conf
```

we can move into the directory:

```bash
cd /home/chirag/projects/config
```

and use:

```bash
cat app.conf
```

---

## Important Examples

Go to home directory:

```bash
cd
```

or

```bash
cd ~
```

---

Go to previous directory:

```bash
cd -
```

---

Move one level up:

```bash
cd ..
```

---

Move two levels up:

```bash
cd ../..
```

---

## Internal Working

The shell updates the process's current working directory.

No files are modified.

---

## Interview Question

Q: Is `cd` a Linux kernel command?

Answer:

No.

It is a shell built-in command because it must modify the shell process itself.

---

# 5. ls (List Directory Contents)

## What Is It?

Displays files and directories.

Example:

```bash
ls
```

---

## Why Does It Exist?

Directories internally contain:

```text
Filename → Inode mappings
```

`ls` reads and displays these entries.

---

## Common Options

### ls -l

Long listing format.

```bash
ls -l
```

Output:

```text
-rw-r--r-- 1 user user 1024 Jan 1 notes.txt
```

---

Breakdown:

```text
Permissions
Link Count
Owner
Group
Size
Timestamp
Filename
```

---

### ls -a

Show hidden files.

```bash
ls -a
```

Example:

```text
.bashrc
.profile
.gitconfig
```

---

### ls -lh

Human-readable sizes.

```bash
ls -lh
```

Output:

```text
2K
15M
1G
```

instead of raw bytes.

---

### ls -R

Recursive listing.

```bash
ls -R
```

Displays subdirectories.

---

## Interview Question

Q: Why does `ls -l` display permissions?

Answer:

Because permissions are stored inside the inode metadata.

---

# 6. mkdir (Make Directory)

## What Is It?

Creates directories.

Example:

```bash
mkdir projects
```

---

## Internal Working

Linux:

1. Allocates inode.
2. Creates directory entry.
3. Creates special entries:

```text
.
..
```

---

## Create Nested Directories

Without:

```bash
mkdir dev/app/config
```

Linux fails if parent directories don't exist.

Use:

```bash
mkdir -p dev/app/config
```

---

## Why Is -p Important?

Creates parent directories automatically.

Very common in automation scripts.

---

# 7. touch

## What Is It?

Creates an empty file.

Example:

```bash
touch notes.txt
```

---

## Common Misconception

Many people think:

```bash
touch
```

means "create file."

Actually:

```text
touch updates timestamps.
```

If file doesn't exist:

```text
create file
```

If file exists:

```text
update timestamps
```

---

## Timestamps Updated

Linux stores:

```text
Access Time (atime)
Modify Time (mtime)
Change Time (ctime)
```

`touch` updates timestamps.

---

## Example

```bash
touch logfile.log
```

Creates:

```text
logfile.log
```

with size:

```text
0 bytes
```

---

# 8. cp (Copy Files)

## What Is It?

Copies files and directories.

---

## Basic Example

```bash
cp source.txt destination.txt
```

---

## Internal Working

Linux:

1. Reads source file.
2. Creates new inode.
3. Writes copied data.
4. Creates new directory entry.

Result:

```text
Two separate files.
```

---

## Copy Directory

```bash
cp -r project backup
```

---

## Preserve Metadata

```bash
cp -p file backup
```

Preserves:

* Ownership
* Permissions
* Timestamps

---

## Interview Question

Q: Does copying a file preserve the inode?

Answer:

No.

A new inode is created.

---

# 9. mv (Move and Rename)

## What Is It?

Moves or renames files.

---

## Rename File

```bash
mv old.txt new.txt
```

---

## Move File

```bash
mv file.txt /tmp
```

---

## Internal Working

Inside same filesystem:

Linux usually updates directory entries only.

Very fast.

---

Different filesystem:

Linux performs:

```text
Copy
+
Delete
```

behind the scenes.

---

## Interview Question

Q: Why is `mv` usually faster than `cp`?

Answer:

Because it often only updates metadata rather than copying data.

---

# 10. rm (Remove)

## What Is It?

Deletes files and directories.

---

## Delete File

```bash
rm file.txt
```

---

## Delete Directory

```bash
rm -r project
```

---

## Force Delete

```bash
rm -rf project
```

---

## Internal Working

Linux usually:

1. Removes filename entry.
2. Decrements inode link count.

Actual data blocks may remain until reused.

---

## Important Concept

Linux does not necessarily erase data immediately.

It removes references to the data.

---

## Dangerous Command

```bash
rm -rf /
```

Attempts to delete entire filesystem.

Modern Linux distributions protect against this.

---

## Interview Question

Q: Why is deleted data sometimes recoverable?

Answer:

Because references are removed before data blocks are overwritten.

---

# 11. cat

## What Is It?

Displays file contents.

Example:

```bash
cat notes.txt
```

---

## Internal Working

Linux performs:

```text
open()
read()
write()
close()
```

system calls.

---

## Combine Files

```bash
cat file1 file2 > merged.txt
```

---

## Create File

```bash
cat > notes.txt
```

Type content:

```text
Hello
Linux
```

Press:

```text
CTRL+D
```

---

## Limitation

Not ideal for huge files.

---

# 12. less

## What Is It?

View large files efficiently.

Example:

```bash
less access.log
```

---

## Why Not cat?

Suppose:

```text
10 GB log file
```

`cat` floods the terminal.

`less` loads incrementally.

---

## Useful Keys

Search:

```text
/error
```

Next match:

```text
n
```

Quit:

```text
q
```

---

## Real Usage

```bash
less /var/log/syslog
```

```bash
less application.log
```

---

## Interview Question

Q: Why use `less` instead of `cat`?

Answer:

Because `less` loads content lazily and allows navigation.

---

# 13. head

## What Is It?

Displays first lines.

Default:

```bash
head file.txt
```

Shows:

```text
10 lines
```

---

## Custom

```bash
head -20 file.txt
```

---

## Common Usage

Inspect beginning of large files.

---

# 14. tail

## What Is It?

Displays last lines.

Example:

```bash
tail file.txt
```

---

## Follow Mode

```bash
tail -f application.log
```

Displays updates continuously.

---

## Why Is It Useful?

Log files grow continuously.

Example:

```bash
tail -f nginx.log
```

Observe new entries in real time.

---

## Interview Question

Q: What does `tail -f` do?

Answer:

Monitors a file and displays new content as it is appended.

---

# 15. grep

## What Is It?

Searches text patterns.

One of the most important Linux commands.

---

## Basic Search

```bash
grep ERROR app.log
```

---

## Case Insensitive

```bash
grep -i error app.log
```

---

## Recursive Search

```bash
grep -r database /etc
```

---

## Count Matches

```bash
grep -c ERROR app.log
```

---

## Invert Match

```bash
grep -v INFO app.log
```

---

## Internal Working

Linux reads file contents and compares lines against a pattern.

Modern grep implementations use highly optimized search algorithms.

---

## Why Is grep So Important?

Used everywhere:

```bash
Logs
Configurations
Scripts
Troubleshooting
Monitoring
```

---

## Interview Question

Q: Difference between grep and find?

Answer:

```text
find:
Searches filenames.

grep:
Searches file contents.
```

---

# 16. find

## What Is It?

Searches filesystem objects.

One of the most powerful Linux commands.

---

## Search by Name

```bash
find /tmp -name "*.log"
```

---

## Case Insensitive

```bash
find /tmp -iname "*.LOG"
```

---

## Search by Size

```bash
find . -size +100M
```

Meaning:

```text
Files larger than 100 MB
```

---

## Search by Modification Time

Modified within 7 days:

```bash
find . -mtime -7
```

Older than 30 days:

```bash
find . -mtime +30
```

---

## Search by User

```bash
find /home -user john
```

---

## Execute Commands

Delete old logs:

```bash
find . -name "*.log" -delete
```

---

## Internal Working

Linux recursively traverses directories.

For every entry:

```text
Read inode
Check conditions
Display matches
```

---

## Interview Question

Q: Difference between:

```bash
locate
```

and

```bash
find
```

Answer:

```text
locate:
Uses database

find:
Searches actual filesystem
```

---

# 17. Combining Commands

Linux becomes powerful when commands are combined.

Example:

Find large log files:

```bash
find /var/log -size +100M
```

---

Search for errors:

```bash
grep ERROR app.log
```

---

Count errors:

```bash
grep ERROR app.log | wc -l
```

---

View recent logs:

```bash
tail -f app.log
```

---

# 18. Common Beginner Mistakes

## Mistake 1

Using:

```bash
rm -rf
```

without verifying path.

---

## Mistake 2

Using relative paths inside scripts.

---

## Mistake 3

Using cat on huge log files.

---

## Mistake 4

Forgetting:

```bash
cp -r
```

for directories.

---

## Mistake 5

Confusing:

```bash
grep
```

with

```bash
find
```

---

# 19. Summary

After this chapter you should understand:

✓ Current Working Directory

✓ Relative Paths

✓ Absolute Paths

✓ ls

✓ cd

✓ pwd

✓ mkdir

✓ touch

✓ cp

✓ mv

✓ rm

✓ cat

✓ less

✓ head

✓ tail

✓ grep

✓ find

✓ Internal working of file operations

✓ Common interview questions

✓ Common beginner mistakes

In the next chapter we will study one of the most important Linux topics:

# Permissions and Ownership

Including:

* rwx permissions
* chmod
* chown
* chgrp
* umask
* SUID
* SGID
* Sticky Bit

and understand how Linux secures files in a multi-user environment.
