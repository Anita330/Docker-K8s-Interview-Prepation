# Linux Deep Dive Notes

# Chapter 11 - Shells, Bash Scripting, Environment Variables, and Automation

---

# 1. Introduction

Throughout this document we have executed commands such as:

```bash
ls
ps
grep
find
systemctl
```

But we have not yet discussed an important question:

```text
Who receives these commands?
```

When you type:

```bash
ls -l
```

something must:

```text
Read your input
Interpret it
Execute it
Display output
```

That "something" is called a:

```text
Shell
```

Understanding the shell is critical because it acts as the primary interface between users and Linux.

Most Linux automation, scripting, and administration tasks are built on shell concepts.

---

# 2. What Is a Shell?

A shell is a program that provides a command-line interface to the operating system.

Think of it as:

```text
User
 ↓
Shell
 ↓
Linux Kernel
```

The shell accepts commands and executes them.

---

## Example

User enters:

```bash
pwd
```

Shell:

```text
Receives Command
Parses Command
Executes Command
Displays Output
```

---

## Why Is It Called a Shell?

Because it surrounds the kernel.

Diagram:

```text
+-------------------+
|      User         |
+-------------------+
          ↓
+-------------------+
|      Shell        |
+-------------------+
          ↓
+-------------------+
|      Kernel       |
+-------------------+
          ↓
+-------------------+
|     Hardware      |
+-------------------+
```

---

# 3. Popular Linux Shells

Linux supports multiple shells.

Examples:

```text
Bash
Sh
Zsh
Ksh
Fish
```

---

## Bash

Most common shell.

Bash stands for:

```text
Bourne Again Shell
```

Default shell on many Linux distributions.

---

## Zsh

Popular among developers.

Provides:

```text
Better Auto Completion
Themes
Plugins
```

---

## Sh

Traditional Unix shell.

Often used in scripts.

---

# 4. How To Check Current Shell

Command:

```bash
echo $SHELL
```

Example:

```text
/bin/bash
```

---

## Check Running Shell

```bash
ps -p $$
```

Example:

```text
bash
```

---

# 5. How Command Execution Works

Suppose:

```bash
ls -l
```

is entered.

Shell performs:

```text
Read Input
Parse Command
Locate Executable
Create Process
Execute Program
Wait For Completion
Display Output
```

---

## Internal Flow

```text
User
 ↓
Bash
 ↓
fork()
 ↓
exec()
 ↓
ls Executes
```

Concepts from the Processes chapter are involved.

---

# 6. What Is PATH?

One of the most important Linux concepts.

---

## Problem

When you type:

```bash
ls
```

Linux somehow finds:

```text
/bin/ls
```

How?

Using:

```text
PATH
```

---

# 7. Understanding PATH

Environment variable containing directories to search.

Example:

```bash
echo $PATH
```

Output:

```text
/usr/local/bin:
/usr/bin:
/bin
```

---

## Search Process

When you run:

```bash
ls
```

Shell checks:

```text
/usr/local/bin/ls
/usr/bin/ls
/bin/ls
```

until found.

---

## Interview Question

Q:

Why can we run:

```bash
ls
```

instead of:

```bash
/bin/ls
```

Answer:

Because PATH contains the directory where ls resides.

---

# 8. Environment Variables

Processes often need configuration data.

Environment variables provide this.

---

## Examples

```bash
HOME
PATH
USER
HOSTNAME
SHELL
```

---

## View Variables

```bash
env
```

or

```bash
printenv
```

---

# 9. Common Environment Variables

---

## HOME

User's home directory.

Example:

```bash
echo $HOME
```

Output:

```text
/home/john
```

---

## USER

Current username.

```bash
echo $USER
```

---

## HOSTNAME

System hostname.

```bash
echo $HOSTNAME
```

---

## PATH

Executable search paths.

```bash
echo $PATH
```

---

# 10. Creating Variables

Example:

```bash
name="John"
```

Access:

```bash
echo $name
```

Output:

```text
John
```

---

## Important Rule

No spaces:

Correct:

```bash
name="John"
```

Wrong:

```bash
name = "John"
```

---

# 11. Environment Variables vs Shell Variables

Common interview question.

---

## Shell Variable

Only available in current shell.

Example:

```bash
name="John"
```

---

## Environment Variable

Inherited by child processes.

Example:

```bash
export name="John"
```

---

## Why export Exists

Without export:

```text
Child Processes Cannot See Variable
```

With export:

```text
Variable Inherited
```

---

# 12. Command Substitution

Allows storing command output.

Example:

```bash
current_date=$(date)
```

Output stored in:

```text
current_date
```

---

## Example

```bash
echo $current_date
```

---

## Older Syntax

```bash
current_date=`date`
```

Still works but less preferred.

---

# 13. Quoting in Bash

Frequently misunderstood.

---

## Double Quotes

Example:

```bash
name="John"

echo "$name"
```

Output:

```text
John
```

Variable expands.

---

## Single Quotes

Example:

```bash
echo '$name'
```

Output:

```text
$name
```

No expansion.

---

## Interview Question

Difference between:

```bash
"$HOME"
```

and

```bash
'$HOME'
```

Answer:

Double quotes expand variables.

Single quotes do not.

---

# 14. Wildcards (Globbing)

Shell expands patterns.

---

## *

Matches everything.

Example:

```bash
ls *.txt
```

Matches:

```text
notes.txt
logs.txt
```

---

## ?

Matches one character.

Example:

```bash
file?.txt
```

Matches:

```text
file1.txt
file2.txt
```

---

# 15. What Is a Shell Script?

A text file containing shell commands.

Example:

```bash
#!/bin/bash

echo Hello
echo World
```

---

## Why Scripts Exist

Instead of manually executing:

```text
100 commands
```

automate them.

---

# 16. Script Execution

Make executable:

```bash
chmod +x script.sh
```

Run:

```bash
./script.sh
```

---

## Shebang

First line:

```bash
#!/bin/bash
```

called:

```text
Shebang
```

Tells Linux which interpreter should execute script.

---

# 17. Reading User Input

Example:

```bash
read username
```

User enters value.

Access:

```bash
echo $username
```

---

## Example Script

```bash
#!/bin/bash

echo "Enter Name:"
read name

echo "Hello $name"
```

---

# 18. Conditional Statements

Allow decision making.

---

## if Statement

Example:

```bash
if [ "$USER" = "root" ]
then
    echo "Running as root"
fi
```

---

## Structure

```bash
if condition
then
    commands
fi
```

---

# 19. if-else Example

```bash
if [ "$USER" = "root" ]
then
    echo "Root User"
else
    echo "Normal User"
fi
```

---

# 20. Comparison Operators

Strings:

```text
=
!=
```

---

Numbers:

```text
-eq
-ne
-gt
-lt
-ge
-le
```

---

## Example

```bash
if [ "$age" -gt 18 ]
```

Meaning:

```text
age > 18
```

---

# 21. Loops

Used for repetition.

---

# 22. For Loop

Example:

```bash
for i in 1 2 3
do
    echo $i
done
```

Output:

```text
1
2
3
```

---

## Practical Example

```bash
for file in *.log
do
    echo $file
done
```

---

# 23. While Loop

Example:

```bash
count=1

while [ $count -le 5 ]
do
    echo $count
    count=$((count+1))
done
```

---

# 24. Functions

Functions group reusable code.

---

## Example

```bash
greet() {
    echo "Hello"
}
```

Call:

```bash
greet
```

---

## Why Use Functions?

Avoid duplication.

Improve readability.

---

# 25. Exit Codes

Every command returns an exit status.

---

## Success

```text
0
```

---

## Failure

```text
Non-Zero
```

---

## Example

```bash
ls file.txt

echo $?
```

Output:

```text
0
```

if successful.

---

# 26. Why Exit Codes Matter

Scripts use them to make decisions.

Example:

```bash
if [ $? -eq 0 ]
then
    echo Success
fi
```

---

# 27. Logical Operators

---

## AND

```bash
&&
```

Example:

```bash
mkdir test && cd test
```

Second command runs only if first succeeds.

---

## OR

```bash
||
```

Example:

```bash
grep error file || echo "Not Found"
```

---

# 28. Cron Jobs

Linux automation mechanism.

---

## What Is Cron?

Background scheduler.

Runs commands automatically.

---

## Examples

```text
Daily Backup
Hourly Cleanup
Weekly Report
Monthly Maintenance
```

---

# 29. Crontab

User cron configuration.

View:

```bash
crontab -l
```

Edit:

```bash
crontab -e
```

---

# 30. Cron Format

```text
Minute Hour Day Month Weekday Command
```

Example:

```bash
0 2 * * * backup.sh
```

Meaning:

```text
Run Daily At 2:00 AM
```

---

# 31. Special Cron Values

Every minute:

```bash
* * * * *
```

---

Every hour:

```bash
0 * * * *
```

---

Every Sunday:

```bash
0 0 * * 0
```

---

# 32. Common Automation Examples

---

## Delete Old Logs

```bash
find /logs -mtime +30 -delete
```

---

## Backup Directory

```bash
tar -czf backup.tar.gz /data
```

---

## Check Service Status

```bash
systemctl is-active nginx
```

---

# 33. Bash Debugging

Useful option:

```bash
bash -x script.sh
```

Displays executed commands.

Very useful for troubleshooting.

---

# 34. Common Interview Questions

### Q1

What is a shell?

---

### Q2

What is Bash?

---

### Q3

What is PATH?

---

### Q4

Difference between:

```text
Shell Variable
Environment Variable
```

---

### Q5

Purpose of export?

---

### Q6

What is command substitution?

---

### Q7

Difference between:

```text
Single Quotes
Double Quotes
```

---

### Q8

Purpose of shebang?

---

### Q9

How do you make a script executable?

---

### Q10

What is an exit code?

---

### Q11

What does:

```bash
$?
```

represent?

---

### Q12

Difference between:

```bash
&&
||
```

---

### Q13

What is cron?

---

### Q14

Explain cron schedule:

```bash
0 2 * * *
```

---

### Q15

How would you debug a shell script?

---

# 35. Common Beginner Mistakes

## Mistake 1

Forgetting:

```bash
chmod +x
```

---

## Mistake 2

Using spaces in variable assignment.

Wrong:

```bash
name = John
```

---

## Mistake 3

Confusing shell variables with environment variables.

---

## Mistake 4

Ignoring exit codes.

---

## Mistake 5

Using single quotes when variable expansion is needed.

---

## Mistake 6

Not testing scripts before scheduling them with cron.

---

# 36. Summary

After completing this chapter you should understand:

✓ Shells

✓ Bash

✓ Command Execution

✓ PATH

✓ Environment Variables

✓ Shell Variables

✓ export

✓ Command Substitution

✓ Quotes

✓ Wildcards

✓ Shell Scripts

✓ Shebang

✓ Input Handling

✓ Conditionals

✓ Loops

✓ Functions

✓ Exit Codes

✓ Logical Operators

✓ Cron

✓ Crontab

✓ Automation Fundamentals

✓ Script Debugging

✓ Common Interview Questions

At this point, you have covered nearly all core Linux topics expected from a strong Linux administrator or engineer.

The next advanced chapter should be:

# Chapter 12 - Linux Performance Monitoring and Troubleshooting

covering:

* CPU Utilization
* Load Average
* Memory Management
* Swap
* vmstat
* iostat
* free
* sar
* top/htop Deep Dive
* Network Troubleshooting
* Disk Bottlenecks
* Performance Analysis Methodology
* Real Interview Scenarios

This chapter ties together everything learned so far and teaches how to diagnose real-world Linux problems.
