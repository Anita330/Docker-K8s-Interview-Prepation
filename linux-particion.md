fdisk /dev/sdd
![alt text](image.png)

![alt text](image-1.png)

mkfs -t type device 
mkfs -t ext4 /dev/sdb2

LVM summary
lvremove /dev/vg_name/
vg_reduce vg_name /dev/sdb
vg_remove vg_name 
pvremove /dev/sdb

# LVM (Logical Volume Manager) in Linux

LVM is a storage management layer in Linux that provides flexibility in managing disk space compared to traditional partitions.

Instead of creating fixed partitions directly on disks, LVM allows you to create logical volumes that can be resized dynamically.

-----------------
# IP Address
![alt text](image-2.png)


![alt text](image-3.png)

# Network traffic
ping - test connectivity with ping 
![alt text](image-4.png)

rtt -round trip time

tracroute - convert ip into DNS 
![alt text](image-5.png)

# Variables
storage location that have a name
syntax 
VARIABLE_NAME="value"
variables are case sensetive 
By convention variables are uppercase

![alt text](image-6.png)
 String operation
 ![alt text](image-7.png)

# arthematic operatior 
 ![alt text](image-8.png)

 # Reuse the last item of a command 
 ![alt text](image-9.png) 

 