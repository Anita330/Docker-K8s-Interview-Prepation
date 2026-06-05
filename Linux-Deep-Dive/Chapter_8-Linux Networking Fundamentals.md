# Linux Deep Dive Notes

# Chapter 8 - Linux Networking Fundamentals

---

# 1. Introduction

Modern Linux systems rarely operate in isolation.

Whether it is:

```text
Opening a website
Connecting to a database
Sending an email
SSH into a server
Accessing cloud resources
```

all of these activities depend on networking.

Many Linux users can execute commands like:

```bash
ping
curl
ssh
wget
```

without understanding what happens behind the scenes.

This chapter explains:

* How Linux communicates over networks
* How IP addresses work
* How DNS works
* What ports are
* What sockets are
* How network troubleshooting works

Understanding networking fundamentals is essential because almost every modern application depends on networking.

---

# 2. What Is a Network?

A network is a collection of devices capable of communicating with each other.

Examples:

```text
Laptop
Server
Phone
Printer
Router
```

Communication happens through:

```text
Network Interfaces
Protocols
Addresses
```

---

## Simple Example

```text
Laptop
   |
   |
Router
   |
   |
Server
```

For communication to work:

```text
Devices need identities.
```

These identities are called addresses.

---

# 3. Understanding Network Layers

Modern networking is organized into layers.

The most common model:

```text
Application Layer
Transport Layer
Internet Layer
Link Layer
```

---

## Example

When opening a website:

```text
Browser
 ↓
TCP
 ↓
IP
 ↓
Ethernet/WiFi
 ↓
Network
```

Each layer performs a specific task.

---

# 4. What Is an IP Address?

IP stands for:

```text
Internet Protocol
```

An IP address uniquely identifies a device on a network.

Example:

```text
192.168.1.10
```

Think of it as:

```text
House Address
```

for a computer.

---

# 5. Why Do We Need IP Addresses?

Suppose:

```text
100 computers
```

exist on a network.

When sending data:

```text
Linux must know:

Where should the data go?
```

IP addresses solve this problem.

---

# 6. IPv4 Addresses

Most familiar format.

Example:

```text
192.168.1.100
```

Structure:

```text
4 Numbers
0-255
Separated By Dots
```

---

## Examples

```text
10.0.0.1
172.16.1.20
192.168.1.50
8.8.8.8
```

---

# 7. Public vs Private IP Addresses

---

## Public IP

Accessible on the internet.

Example:

```text
203.0.113.10
```

Assigned by ISPs.

---

## Private IP

Used inside private networks.

Examples:

```text
10.0.0.0/8
172.16.0.0/12
192.168.0.0/16
```

Home routers commonly assign:

```text
192.168.x.x
```

addresses.

---

# 8. What Is a Subnet Mask?

IP address consists of:

```text
Network Portion
Host Portion
```

Subnet mask determines where the split occurs.

Example:

```text
192.168.1.10/24
```

Means:

```text
Network:
192.168.1

Host:
10
```

---

## Why Important?

Determines:

```text
Who Is Local?
Who Requires Routing?
```

---

# 9. CIDR Notation

Modern subnet notation.

Example:

```text
192.168.1.0/24
```

Means:

```text
First 24 Bits
Represent Network
```

Common examples:

```text
/8
/16
/24
/32
```

---

## Interview Question

Q:

What does:

```text
/32
```

mean?

Answer:

```text
Single Host
```

---

# 10. What Is a MAC Address?

MAC:

```text
Media Access Control
```

address.

Assigned to network interface hardware.

Example:

```text
00:1A:2B:3C:4D:5E
```

---

## Difference Between IP and MAC

IP:

```text
Logical Address
```

MAC:

```text
Physical Hardware Address
```

---

## Analogy

IP:

```text
House Address
```

MAC:

```text
Person's Identity Card
```

---

# 11. Network Interfaces

Network communication occurs through interfaces.

Examples:

```text
eth0
ens33
wlan0
lo
```

---

## Viewing Interfaces

Command:

```bash
ip addr
```

or

```bash
ip a
```

Example:

```text
eth0
192.168.1.10
```

---

# 12. The Loopback Interface

Special interface:

```text
lo
```

Address:

```text
127.0.0.1
```

---

## Purpose

Allows a machine to communicate with itself.

Example:

```bash
ping 127.0.0.1
```

Never leaves the machine.

---

## Interview Question

Q:

What is localhost?

Answer:

```text
127.0.0.1
```

which refers to the local machine.

---

# 13. What Is Routing?

Suppose:

```text
Laptop A
```

wants to communicate with:

```text
Server B
```

on another network.

Data must travel through routers.

Routing determines:

```text
Where packets go next.
```

---

# 14. Routing Table

Linux maintains:

```text
Routing Table
```

Example:

```bash
ip route
```

Output:

```text
default via 192.168.1.1
192.168.1.0/24 dev eth0
```

---

## Default Gateway

Example:

```text
192.168.1.1
```

Acts as:

```text
Exit Door
```

for unknown destinations.

---

# 15. What Is DNS?

DNS:

```text
Domain Name System
```

---

## Problem

Humans prefer:

```text
google.com
```

Computers require:

```text
142.250.190.14
```

DNS translates:

```text
Name
 ↓
IP Address
```

---

# 16. DNS Resolution Process

Example:

```text
google.com
```

Flow:

```text
Application
 ↓
DNS Resolver
 ↓
DNS Server
 ↓
IP Address Returned
```

---

## Example

```text
google.com
```

becomes:

```text
142.x.x.x
```

---

# 17. DNS Configuration

File:

```text
/etc/resolv.conf
```

Example:

```text
nameserver 8.8.8.8
```

This tells Linux which DNS server to use.

---

# 18. Testing DNS

Command:

```bash
nslookup google.com
```

or:

```bash
dig google.com
```

Displays DNS information.

---

# 19. What Is a Port?

One of the most important networking concepts.

---

## Problem

Suppose a server runs:

```text
SSH
Web Server
Database
```

all on same IP.

How does Linux know:

```text
Which application
should receive traffic?
```

Answer:

```text
Ports
```

---

# 20. Port Examples

| Service    | Port |
| ---------- | ---- |
| SSH        | 22   |
| HTTP       | 80   |
| HTTPS      | 443  |
| DNS        | 53   |
| MySQL      | 3306 |
| PostgreSQL | 5432 |

---

## Analogy

IP Address:

```text
Building Address
```

Port:

```text
Apartment Number
```

---

# 21. What Is TCP?

TCP:

```text
Transmission Control Protocol
```

Reliable transport protocol.

---

## Features

```text
Reliable
Ordered
Error Checking
Retransmission
```

---

## Examples

Used by:

```text
SSH
HTTPS
Databases
Email
```

---

# 22. What Is UDP?

UDP:

```text
User Datagram Protocol
```

Connectionless protocol.

---

## Features

```text
Fast
Low Overhead
No Delivery Guarantee
```

---

## Examples

Used by:

```text
DNS
Streaming
Gaming
VoIP
```

---

# 23. TCP vs UDP

TCP:

```text
Reliable
Slower
Connection-Oriented
```

UDP:

```text
Faster
Connectionless
No Guarantees
```

---

## Interview Question

Q:

Why does DNS often use UDP?

Answer:

```text
Fast
Small Requests
Low Overhead
```

---

# 24. What Is a Socket?

One of the most important Linux networking concepts.

---

## Definition

A socket is:

```text
An endpoint for communication.
```

---

## Example

Socket:

```text
IP Address
+
Port
```

Example:

```text
192.168.1.10:443
```

---

## Why Important?

Applications communicate through sockets.

Examples:

```text
Nginx
SSH
Databases
Browsers
```

all use sockets.

---

# 25. Viewing Open Sockets

Modern command:

```bash
ss -tulpn
```

Displays:

```text
Listening Ports
Processes
Connections
```

---

## Example Output

```text
LISTEN
0.0.0.0:22
sshd
```

Meaning:

```text
SSH Listening
On Port 22
```

---

# 26. netstat

Older utility.

Example:

```bash
netstat -tulpn
```

Historically used for network troubleshooting.

Today:

```text
ss
```

is preferred.

---

# 27. What Is ping?

Tests connectivity.

Example:

```bash
ping google.com
```

Uses:

```text
ICMP
```

protocol.

---

## What Does It Verify?

```text
Reachability
Latency
Packet Loss
```

---

# 28. traceroute

Shows network path.

Example:

```bash
traceroute google.com
```

Displays:

```text
Hop 1
Hop 2
Hop 3
...
Destination
```

Useful for troubleshooting routing problems.

---

# 29. curl

One of the most important Linux networking tools.

---

## Purpose

Make HTTP requests.

Example:

```bash
curl https://example.com
```

---

## Why Useful?

Test:

```text
Web Servers
APIs
Connectivity
```

---

## Example

Check headers:

```bash
curl -I https://example.com
```

---

# 30. wget

Downloads files.

Example:

```bash
wget https://example.com/file.zip
```

Useful for:

```text
Downloads
Automation
Scripts
```

---

# 31. Network Troubleshooting Flow

Suppose website inaccessible.

Typical troubleshooting steps:

---

## Step 1

Check Interface

```bash
ip addr
```

---

## Step 2

Check Route

```bash
ip route
```

---

## Step 3

Check DNS

```bash
nslookup example.com
```

---

## Step 4

Check Connectivity

```bash
ping example.com
```

---

## Step 5

Check Application

```bash
curl example.com
```

---

# 32. Common Interview Questions

### Q1

Difference between IP and MAC address?

---

### Q2

What is localhost?

---

### Q3

Purpose of loopback interface?

---

### Q4

What is DNS?

---

### Q5

Purpose of:

```text
/etc/resolv.conf
```

---

### Q6

Difference between TCP and UDP?

---

### Q7

What is a port?

---

### Q8

What is a socket?

---

### Q9

Purpose of default gateway?

---

### Q10

Difference between:

```bash
ping
traceroute
```

---

### Q11

Purpose of:

```bash
curl
```

---

### Q12

Purpose of:

```bash
ss -tulpn
```

---

### Q13

Difference between:

```bash
netstat
ss
```

---

### Q14

What happens when you open:

```text
https://google.com
```

in a browser?

Expected answer should include:

```text
DNS Resolution
TCP Connection
TLS Handshake
HTTP Request
HTTP Response
```

---

# 33. Common Beginner Mistakes

## Mistake 1

Confusing IP address with port.

---

## Mistake 2

Thinking DNS stores websites.

---

## Mistake 3

Believing localhost requires network access.

---

## Mistake 4

Using ping to test application availability.

Ping only tests network reachability.

---

## Mistake 5

Confusing TCP and UDP use cases.

---

# 34. Summary

After completing this chapter you should understand:

✓ IP Addresses

✓ IPv4

✓ Public vs Private Networks

✓ CIDR Notation

✓ Subnet Masks

✓ MAC Addresses

✓ Network Interfaces

✓ Loopback Interface

✓ Routing

✓ Routing Tables

✓ Default Gateway

✓ DNS

✓ /etc/resolv.conf

✓ Ports

✓ TCP

✓ UDP

✓ Sockets

✓ ss

✓ netstat

✓ ping

✓ traceroute

✓ curl

✓ wget

✓ Basic Network Troubleshooting

✓ Common Interview Questions

You now have a solid foundation in Linux fundamentals:

* Filesystems
* Permissions
* Processes
* Users
* Storage
* Linux Internals
* Networking

The next major chapter should be:

# Chapter 9 - Linux Boot Process, Systemd, Logging and Service Management

covering:

* BIOS vs UEFI
* Bootloader (GRUB)
* Kernel Initialization
* Init Process
* systemd
* Targets
* Services
* systemctl
* journalctl
* Logging Architecture
* Log Rotation
* Troubleshooting Failed Services

These topics are heavily asked in Linux Administrator and Infrastructure interviews because they explain how Linux starts, runs services, and records system activity.

