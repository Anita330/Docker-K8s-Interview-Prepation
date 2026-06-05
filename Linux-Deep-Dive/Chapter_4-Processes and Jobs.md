# Linux Deep Dive Notes

# Chapter 4 - Processes and Jobs

---

# 1. Introduction

Everything we have learned so far has focused on data:

* Files
* Directories
* Permissions
* Ownership

Now we move to something equally important:

```text
Processes
```

A Linux system is not just a collection of files.

At any given moment Linux is running hundreds or even thousands of processes.

Examples:

```text
Bash
SSH
Nginx
Chrome
Docker
Systemd
Kubernetes Components
Database Servers
```

Whenever a program runs, Linux creates a process.

Understanding processes is fundamental because:

```text
Every command you execute
creates one or more processes.
```

This chapter explains:

* What processes are
* How they are created
* How they are managed
* Process states
* Signals
* Jobs
* Process monitoring

Many Linux interviews spend significant time on these concepts.

---

# 2. What Is a Process?

A process is:

```text
A running instance of a program.
```

Many beginners confuse:

```text
Program
and
Process
```

These are different concepts.

---

## Program

A program is simply a file stored on disk.

Example:

```text
/bin/bash
/usr/bin/python
/usr/bin/nginx
```

These are not running.

They are merely executable files.

---

## Process

When Linux executes a program:

```text
Program
    ↓
Loaded into Memory
    ↓
Process Created
```

The running instance becomes a process.

---

## Example

File:

```text
/bin/bash
```

Running:

```bash
bash
```

creates:

```text
Bash Process
```

---

## Interview Question

Q: Difference between a program and a process?

Answer:

```text
Program:
Static executable file on disk.

Process:
Running instance of that program in memory.
```

---

# 3. What Information Does a Process Contain?

A process is much more than executable code.

Linux maintains a structure containing:

```text
Process ID
Parent Process ID
User Information
Memory Information
Open Files
Environment Variables
Current Working Directory
Scheduling Information
Signal Handlers
```

Every process has its own execution context.

---

# 4. Process Creation

How is a process created?

Suppose you execute:

```bash
ls
```

The shell performs:

```text
1. fork()
2. exec()
```

---

## fork()

Creates a copy of the current process.

Example:

```text
Bash
  |
  +---- Child Process
```

Initially:

```text
Parent
Child
```

look almost identical.

---

## exec()

The child replaces its memory with:

```text
/bin/ls
```

and starts executing.

Result:

```text
Bash
  |
  +---- ls
```

---

## Process Creation Flow

```text
User
 ↓
Bash
 ↓
fork()
 ↓
Child Process
 ↓
exec(ls)
 ↓
ls Executes
 ↓
Exit
```

This process happens constantly.

---

# 5. Process ID (PID)

Every process receives a unique identifier.

Called:

```text
PID
```

Example:

```bash
ps
```

Output:

```text
PID
1234
5678
9012
```

Linux uses PIDs to track processes.

---

## Why PIDs Exist

Imagine:

```text
500 running processes
```

Linux needs a way to identify each process.

The PID acts like a unique process number.

---

# 6. Parent Process ID (PPID)

Every process has a parent.

Example:

```text
Bash
 |
 +--- vim
 |
 +--- ls
 |
 +--- grep
```

Parent:

```text
Bash
```

Children:

```text
vim
ls
grep
```

Each child stores:

```text
PPID
```

which identifies its parent.

---

## Example

```bash
ps -ef
```

Output:

```text
UID   PID  PPID
root 100   1
john 200 100
```

Process:

```text
PID = 200
```

Parent:

```text
PPID = 100
```

---

# 7. Process Hierarchy

Linux organizes processes as a tree.

Example:

```text
systemd (PID 1)
|
├── sshd
│     └── bash
│           └── vim
│
├── nginx
│
└── docker
```

Every process originates from:

```text
PID 1
```

---

# 8. PID 1

One of the most important Linux concepts.

Modern Linux systems:

```text
systemd
```

usually runs as:

```text
PID 1
```

Historically:

```text
init
```

performed this role.

---

## Responsibilities

PID 1:

```text
Starts Services
Adopts Orphans
Controls Shutdown
Controls Boot Sequence
```

---

## Interview Question

Q: Why is PID 1 special?

Answer:

Because it is the first userspace process and becomes the ultimate parent of orphaned processes.

---

# 9. Process States

Processes are not always running.

Linux schedules processes continuously.

Common states:

```text
R Running
S Sleeping
D Uninterruptible Sleep
T Stopped
Z Zombie
```

---

# 10. Running State (R)

Process currently executing.

Or waiting for CPU.

Example:

```text
CPU Intensive Program
```

---

# 11. Sleeping State (S)

Most processes spend most of their life here.

Waiting for:

```text
User Input
Network Data
Disk Operations
Timer Events
```

Example:

```text
SSH Session Waiting For Input
```

---

# 12. Uninterruptible Sleep (D)

Waiting for hardware operation.

Usually:

```text
Disk I/O
NFS Operations
```

Cannot easily be interrupted.

---

## Why It Exists

Kernel is waiting for a critical operation to finish.

---

# 13. Stopped State (T)

Process paused.

Example:

Press:

```text
CTRL+Z
```

Process enters:

```text
Stopped State
```

---

# 14. Zombie State (Z)

One of the most famous Linux interview topics.

---

## What Is a Zombie?

A process that has:

```text
Finished execution
```

but still has an entry in the process table.

---

## Why Does This Happen?

Child exits:

```text
exit()
```

Kernel stores:

```text
Exit Status
```

for parent.

Parent has not collected it yet.

Result:

```text
Zombie Process
```

---

## Example

```text
Parent
 |
 +---- Zombie Child
```

---

## Characteristics

Zombie:

```text
Consumes no CPU
Consumes almost no memory
Still occupies PID
```

---

## Interview Question

Q: Can kill -9 remove a zombie?

Answer:

No.

Zombie is already dead.

Its parent must reap it.

Or parent must exit.

---

# 15. Orphan Process

Another common interview topic.

---

## What Is an Orphan?

Parent exits first.

Child continues running.

Example:

```text
Parent Dies
     ↓
Child Survives
```

---

## What Happens?

Linux reassigns child to:

```text
PID 1
```

Usually:

```text
systemd
```

---

## Example

```text
systemd
   |
   +---- orphan process
```

---

# 16. Daemon Processes

Daemon:

```text
Background Service Process
```

Examples:

```text
sshd
nginx
docker
cron
systemd-journald
```

Usually:

```text
No Terminal
Runs Continuously
Provides Services
```

---

## Naming Convention

Historically many daemons end with:

```text
d
```

Examples:

```text
sshd
httpd
crond
```

---

# 17. Process Scheduling

Linux cannot run all processes simultaneously.

CPU executes one instruction stream per core at a time.

Linux scheduler decides:

```text
Which process gets CPU
How long it runs
When it is paused
```

This creates the illusion of parallelism.

---

# 18. Process Priority

Not all processes are equally important.

Linux uses:

```text
Nice Values
```

to influence scheduling.

---

# 19. Nice Values

Range:

```text
-20 to 19
```

---

Lower value:

```text
Higher Priority
```

---

Higher value:

```text
Lower Priority
```

---

Examples:

```text
-20 Highest Priority
0 Default
19 Lowest Priority
```

---

# 20. nice Command

Start process with custom priority.

Example:

```bash
nice -n 10 backup.sh
```

Creates process with lower priority.

---

## Why Useful?

Large backup job:

```text
Should not slow down server.
```

Use:

```bash
nice
```

to reduce impact.

---

# 21. renice Command

Modify priority of running process.

Example:

```bash
renice 5 -p 1234
```

Changes priority of PID:

```text
1234
```

---

# 22. ps Command

Displays process information.

---

## Basic

```bash
ps
```

Shows current shell processes.

---

## Common Usage

```bash
ps aux
```

Displays:

```text
USER
PID
CPU
MEM
COMMAND
```

---

## Example

```bash
ps aux | grep nginx
```

Find nginx processes.

---

# 23. top Command

Real-time process monitoring.

Run:

```bash
top
```

Displays:

```text
CPU Usage
Memory Usage
Load Average
Running Processes
```

Updates continuously.

---

## Why Important?

Useful for:

```text
Performance Troubleshooting
```

---

# 24. htop

Enhanced version of top.

Features:

```text
Better UI
Mouse Support
Tree View
Easy Process Killing
```

Many administrators prefer htop.

---

# 25. Signals

Signals are software interrupts.

Used for communication between processes.

---

## Example

```text
Process A
      |
      | Signal
      ↓
Process B
```

---

# 26. Common Signals

| Signal  | Number | Purpose                |
| ------- | ------ | ---------------------- |
| SIGTERM | 15     | Graceful Termination   |
| SIGKILL | 9      | Force Kill             |
| SIGINT  | 2      | Ctrl+C                 |
| SIGHUP  | 1      | Reload/Terminal Closed |

---

# 27. SIGTERM

Default signal.

Example:

```bash
kill 1234
```

actually sends:

```text
SIGTERM
```

Process gets opportunity to:

```text
Save Data
Close Files
Cleanup Resources
```

---

# 28. SIGKILL

Forceful termination.

Example:

```bash
kill -9 1234
```

Kernel immediately destroys process.

Process cannot:

```text
Ignore
Handle
Cleanup
```

---

## Interview Question

Q: Difference between SIGTERM and SIGKILL?

Answer:

SIGTERM allows graceful shutdown.

SIGKILL immediately terminates process.

---

# 29. kill Command

Sends signals.

Example:

```bash
kill 1234
```

SIGTERM.

---

Force kill:

```bash
kill -9 1234
```

SIGKILL.

---

# 30. killall Command

Kill by process name.

Example:

```bash
killall nginx
```

Kills all nginx processes.

---

# 31. Jobs

Now we move to shell job control.

Many people confuse:

```text
Process
and
Job
```

---

## Process

Kernel-managed execution unit.

---

## Job

Shell-managed collection of processes.

---

## Interview Answer

```text
Every job contains one or more processes.

Every process is not necessarily a job.
```

---

# 32. Running Background Jobs

Example:

```bash
sleep 300 &
```

Notice:

```text
&
```

Shell immediately returns prompt.

Process continues running.

---

# 33. jobs Command

Display active jobs.

Example:

```bash
jobs
```

Output:

```text
[1]+ Running sleep 300 &
```

---

# 34. Stopping Jobs

Press:

```text
CTRL+Z
```

Process enters:

```text
Stopped State
```

---

# 35. bg Command

Resume stopped job in background.

Example:

```bash
bg %1
```

---

# 36. fg Command

Bring job to foreground.

Example:

```bash
fg %1
```

Now terminal attaches to job.

---

# 37. nohup

One of the most useful Linux commands.

---

## Problem

User logs out:

```text
Terminal closes
```

Process receives:

```text
SIGHUP
```

and exits.

---

## Solution

```bash
nohup python app.py &
```

Process ignores hangup signal.

Continues running after logout.

---

## Output

Redirected to:

```text
nohup.out
```

unless specified otherwise.

---

# 38. Common Interview Questions

### Q1

Difference between program and process?

---

### Q2

What is fork()?

---

### Q3

What is exec()?

---

### Q4

What is PID?

---

### Q5

What is PPID?

---

### Q6

What is PID 1?

---

### Q7

What is a zombie process?

---

### Q8

What is an orphan process?

---

### Q9

Can SIGKILL be ignored?

Answer:

```text
No
```

---

### Q10

Difference between SIGTERM and SIGKILL?

---

### Q11

Difference between process and job?

---

### Q12

Difference between nice and renice?

---

### Q13

What happens when CTRL+Z is pressed?

---

### Q14

What does nohup solve?

---

# 39. Common Beginner Mistakes

## Mistake 1

Using:

```bash
kill -9
```

for everything.

---

## Mistake 2

Confusing zombies with high CPU processes.

---

## Mistake 3

Believing zombie processes consume memory.

---

## Mistake 4

Forgetting:

```bash
nohup
```

before disconnecting SSH.

---

## Mistake 5

Confusing jobs with processes.

---

# 40. Summary

After completing this chapter you should understand:

✓ Program vs Process

✓ Process Creation

✓ fork()

✓ exec()

✓ PID

✓ PPID

✓ Process Hierarchy

✓ PID 1

✓ Process States

✓ Running

✓ Sleeping

✓ Stopped

✓ Zombie

✓ Orphan

✓ Daemons

✓ Scheduler

✓ Nice Values

✓ nice

✓ renice

✓ ps

✓ top

✓ htop

✓ Signals

✓ SIGTERM

✓ SIGKILL

✓ kill

✓ killall

✓ Jobs

✓ bg

✓ fg

✓ nohup

✓ Common interview questions

In the next chapter we will study:

# Users and Groups

including:

* Linux user architecture
* UID and GID
* /etc/passwd
* /etc/shadow
* /etc/group
* useradd
* usermod
* userdel
* passwd
* group management
* authentication fundamentals

This chapter will explain how Linux identifies users and controls access across the entire system.
