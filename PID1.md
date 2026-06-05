# Kubernetes & Containers: Understanding PID 1

## Why PID 1 Is Important

One of the most frequently asked Kubernetes and Container interview topics is **PID 1 behavior**.

Many production issues occur because engineers treat containers like VMs and don't understand that the main process inside a container becomes **PID 1**.

Understanding PID 1 demonstrates knowledge of:

* Linux process management
* Container internals
* Signal handling
* Graceful shutdown
* Zombie process cleanup
* Kubernetes pod lifecycle

---

# What Is PID 1?

On a normal Linux machine:

```bash
ps -ef
```

Example:

```text
PID  PPID CMD
1    0    systemd
10   1    sshd
20   1    nginx
30   1    mysql
```

PID 1 is usually:

```text
systemd
```

Responsibilities:

* Parent of orphan processes
* Signal management
* Zombie process cleanup (reaping)

---

# PID 1 Inside a Container

Example Dockerfile:

```dockerfile
CMD ["python", "app.py"]
```

Inside the container:

```bash
ps -ef
```

Output:

```text
PID  PPID CMD
1    0    python app.py
```

Notice:

```text
python app.py = PID 1
```

There is no systemd.

Your application is now responsible for PID 1 duties.

---

# PID 1 Responsibility #1: Signal Handling

This is the most important Kubernetes interview topic.

---

## Pod Deletion Flow

When a user runs:

```bash
kubectl delete pod mypod
```

The flow is:

```text
User
 │
 ▼
API Server
 │
 ▼
Kubelet
 │
 ▼
Container Runtime
 │
 ▼
SIGTERM
 │
 ▼
PID 1
```

Kubernetes sends SIGTERM to PID 1.

---

## Graceful Shutdown

Application:

```python
import signal

def shutdown(signum, frame):
    print("Cleaning up...")

signal.signal(signal.SIGTERM, shutdown)
```

When SIGTERM is received:

```text
Stop accepting requests
Finish in-flight requests
Flush logs
Close DB connections
Exit cleanly
```

This is called:

```text
Graceful Shutdown
```

---

# What Happens If PID 1 Ignores SIGTERM?

Example:

```python
while True:
    pass
```

No signal handler.

Pod deletion:

```text
SIGTERM
   │
   ▼
No Response
   │
   ▼
Wait 30 Seconds
   │
   ▼
SIGKILL
```

Default behavior:

```text
SIGTERM
 ↓
terminationGracePeriodSeconds
(default: 30s)
 ↓
SIGKILL
```

Consequences:

* Request failures
* Abrupt termination
* Possible data loss
* Poor rolling update behavior

---

# PID 1 Responsibility #2: Zombie Process Reaping

Another popular interview topic.

---

## What Is a Zombie Process?

A process creates a child:

```c
fork()
```

Child exits.

Parent never calls:

```c
wait()
```

Result:

```text
Zombie Process
```

Example:

```text
PID  STATUS
100  Z
```

Where:

```text
Z = Zombie
```

---

# Why PID 1 Must Reap Zombies

Linux expects PID 1 to clean up orphaned and zombie processes.

Example:

```text
PID 1 = Java
```

Java spawns child processes:

```text
java
 ├── child-1
 ├── child-2
 └── child-3
```

Child exits:

```text
child-1 exits
```

If PID 1 doesn't reap it:

```text
child-1 becomes zombie
```

Over time:

```text
10 zombies
100 zombies
1000 zombies
```

Eventually process table resources are wasted.

---

# Bad Container Pattern

Dockerfile:

```dockerfile
CMD ["bash", "start.sh"]
```

start.sh:

```bash
java -jar app.jar &
tail -f /dev/null
```

Process tree:

```text
bash (PID 1)
 ├── java
 └── child processes
```

Problems:

* Signal forwarding may fail
* Java may not receive SIGTERM
* Zombie processes may accumulate
* Graceful shutdown becomes unreliable

---

# Good Container Pattern

Dockerfile:

```dockerfile
CMD ["java","-jar","app.jar"]
```

Process tree:

```text
java (PID 1)
```

Benefits:

* Receives SIGTERM directly
* Supports graceful shutdown
* Simpler process management

---

# Using Tini

Production containers often use an init process.

Example:

```dockerfile
ENTRYPOINT ["tini","--"]
CMD ["java","-jar","app.jar"]
```

Process tree:

```text
PID 1  tini
PID 7  java
```

Responsibilities of Tini:

```text
Receive SIGTERM
Forward SIGTERM
Reap Zombie Processes
Manage Child Processes
```

Benefits:

* Proper signal handling
* Proper zombie cleanup
* Production-safe behavior

---

# Kubernetes Pod Termination Lifecycle

```text
kubectl delete pod
        │
        ▼
API Server
        │
        ▼
Kubelet
        │
        ▼
SIGTERM to PID 1
        │
        ▼
Grace Period Starts
(default 30s)
        │
        ▼
Application Exits
        │
        ▼
Container Stops
```

If application does not exit:

```text
kubectl delete pod
        │
        ▼
SIGTERM
        │
        ▼
Grace Period Expires
        │
        ▼
SIGKILL
        │
        ▼
Forced Termination
```

---

# Common Interview Questions

## Q1. Which process receives SIGTERM when a pod is deleted?

Answer:

```text
PID 1 inside the container.
```

---

## Q2. What happens if PID 1 ignores SIGTERM?

Answer:

```text
Kubernetes waits for terminationGracePeriodSeconds and then sends SIGKILL.
```

---

## Q3. Why can zombie processes accumulate in containers?

Answer:

```text
PID 1 is responsible for reaping child processes.
If it does not reap them, zombie processes accumulate.
```

---

## Q4. Why is Tini used?

Answer:

```text
Acts as PID 1.
Forwards signals.
Reaps zombie processes.
```

---

## Q5. Why is "bash start.sh" as PID 1 considered risky?

Answer:

```text
Signal forwarding may fail.
Application may not receive SIGTERM.
Zombie processes can accumulate.
Graceful shutdown becomes unreliable.
```

---

# Production Best Practices

✅ Handle SIGTERM in applications

✅ Use graceful shutdown logic

✅ Finish in-flight requests before exit

✅ Close database connections properly

✅ Flush logs before termination

✅ Use Tini or another lightweight init process

✅ Avoid unnecessary shell wrappers

✅ Test pod termination behavior regularly

---

# One-Minute Interview Answer

"In a container, the main process becomes PID 1. PID 1 has special Linux responsibilities such as signal handling and zombie process reaping. When Kubernetes terminates a pod, kubelet sends SIGTERM to PID 1. If PID 1 handles the signal correctly, the application can shut down gracefully. If it does not exit within terminationGracePeriodSeconds, Kubernetes sends SIGKILL. Improper PID 1 behavior can also lead to zombie process accumulation. This is why production containers often use Tini and implement proper SIGTERM handling."
