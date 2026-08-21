# Docker Mock Interview Feedback & Improved Answers (5+ Years Experience)

## Overall Interview Assessment

### Current Rating: 5.5/10

### Target Rating for 5+ Years: 8/10

### Strengths

* Good understanding of Docker basics
* Familiar with Docker commands:

  * docker logs
  * docker inspect
  * docker exec
  * docker stats
* Basic networking knowledge
* Comfortable with Docker Compose
* Understands Docker caching concepts

### Areas for Improvement

* Answers are too short
* Missing structured troubleshooting approach
* Not explaining root causes
* Not providing command examples
* Not explaining remediation steps
* Need more production-oriented thinking

---

# Question 1

## How do you optimize Docker build performance?

### Your Answer

* Use Docker cache
* Reuse previously built layers

### Feedback

Correct, but incomplete.

### Improved 5+ Years Answer

To optimize Docker build performance, I focus on layer caching, Dockerfile optimization, and image size reduction.

### Best Practices

1. Use Docker layer caching efficiently.
2. Keep frequently changing instructions at the bottom.
3. Use multi-stage builds.
4. Combine RUN commands.
5. Use .dockerignore.
6. Use BuildKit.
7. Cache dependency installation layers.

### Example

```dockerfile
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY . .
```

This ensures dependency installation is cached.

### BuildKit

```bash
DOCKER_BUILDKIT=1 docker build .
```

---

# Question 2

## Container Running but Application Not Reachable

### Your Answer

```bash
docker logs
docker inspect
```

### Feedback

Good start but lacks troubleshooting flow.

### Improved 5+ Years Answer

When a container is running but the application is not reachable, I follow a structured troubleshooting approach.

### Step 1: Verify Container Status

```bash
docker ps
```

### Step 2: Check Logs

```bash
docker logs <container>
```

### Step 3: Verify Application Process

```bash
docker exec -it <container> ps -ef
```

### Step 4: Verify Listening Port

```bash
docker exec -it <container> netstat -tulpn
```

or

```bash
docker exec -it <container> ss -tulpn
```

### Step 5: Check Port Mapping

```bash
docker port <container>
```

### Step 6: Inspect Networking

```bash
docker inspect <container>
```

### Step 7: Test Connectivity

```bash
curl localhost:8080
```

### Possible Root Causes

* Application crashed
* Incorrect port mapping
* Firewall issue
* DNS issue
* Reverse proxy issue
* Dependency issue

---

# Question 3

## Container Restarting Continuously

### Your Answer

* Check logs
* Check inspect
* Verify CPU and Memory

### Feedback

Correct direction but missing root-cause analysis.

### Improved 5+ Years Answer

If a container keeps restarting, I first identify why it exited.

### Check Restart Count

```bash
docker ps -a
```

### Check Logs

```bash
docker logs <container>
```

### Check Exit Code

```bash
docker inspect <container>
```

Look for:

```json
ExitCode
```

### Check OOM Kill

```bash
docker inspect <container>
```

Look for:

```json
OOMKilled: true
```

Also verify:

```bash
dmesg | grep -i kill
```

### Common Causes

* Application crash
* Database unreachable
* Incorrect environment variables
* Memory exhaustion
* Port conflict
* Health-check failure

### Fix

* Increase memory
* Correct configuration
* Resolve dependency issues
* Fix application bugs

---

# Question 4

## Docker Compose Services Cannot Communicate

### Your Answer

* Same network
* Port issue
* Service communication

### Feedback

Good basic understanding.

### Improved 5+ Years Answer

Docker Compose creates an internal network and allows services to communicate using service names.

### Verify Network

```bash
docker network ls
```

```bash
docker network inspect <network>
```

### Verify DNS Resolution

```bash
docker exec -it app ping database
```

### Verify Connectivity

```bash
docker exec -it app nc -zv database 3306
```

### Verify Service Name

Correct:

```text
database:3306
```

Wrong:

```text
localhost:3306
```

### Common Causes

* Wrong service name
* Wrong port
* DNS issue
* Network misconfiguration
* Target service not running

---

# How to Structure Answers in Interviews

## A → B → C → D Method

### A = Problem

Example:

Container is restarting.

### B = Investigation

Commands:

```bash
docker logs
docker inspect
docker stats
```

### C = Root Cause Analysis

Possible causes:

* OOM
* Application crash
* Dependency failure
* Port conflict

### D = Resolution

* Increase memory
* Fix application
* Resolve dependency issues
* Correct configuration

---

# Example of a Strong 5+ Years Answer

Instead of saying:

"I will check docker logs and docker inspect."

Say:

"First, I will verify the container state using docker ps -a. Then I will review the application logs using docker logs. Next, I will inspect the container using docker inspect to check exit codes, restart counts, network configuration, and resource limits. If required, I will access the container using docker exec and verify the application process, listening ports, and connectivity to dependent services such as databases. Based on the findings, I will determine whether the issue is related to the application, networking, resources, or configuration and apply the appropriate fix."

This sounds like a strong 5–7 years DevOps Engineer answer.

---

# Final Recommendation

To clear Docker interviews for 5+ years experience:

Focus on:

1. Docker Architecture
2. Docker Networking
3. OverlayFS
4. Namespaces
5. Cgroups
6. Docker Compose
7. Docker Security
8. Container Troubleshooting
9. Image Optimization
10. Production Scenarios

Remember:

Interviewers are not only looking for commands.

They want to hear:

Problem → Investigation → Root Cause → Resolution

This structure significantly improves interview performance.
