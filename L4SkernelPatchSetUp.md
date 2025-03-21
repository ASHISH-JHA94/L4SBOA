

# **Step-by-Step Guide to Setting Up an L4S-Enabled Linux Kernel for Experiments**

## **Step 1: Prerequisites**
Before you begin, ensure you have the following:

### **1.1 System Requirements**
- **Operating System**: Ubuntu/Debian or another Debian-based distribution is recommended.
- **Kernel Build Tools**: Install essential dependencies:
  ```bash
  sudo apt update
  sudo apt install build-essential libncurses-dev bison flex libssl-dev libelf-dev git wget unzip
  ```
- **Enough Disk Space**: Ensure at least **20GB of free disk space** for compiling the kernel.
- **Stable Internet Connection**: Required to download the kernel source and dependencies.

### **1.2 Identify Your Network Interface Name**
Newer Linux distributions use **Predictable Network Interface Names** instead of `eth0`. To find your correct interface name, run:
```bash
ip link show
```
Look for an interface like `eno1`, `ens33`, or `eth0`. Use this correct name in later steps.

---

## **Step 2: Install the Pre-Built L4S Kernel**
Instead of compiling the kernel manually, you can install a **pre-built** kernel.

1. **Download the Pre-Built Kernel Packages**
   ```bash
   wget https://github.com/L4STeam/linux/releases/download/testing-build/l4s-testing.zip
   ```
2. **Extract the Kernel Package**
   ```bash
   unzip l4s-testing.zip
   ```
3. **Install the Kernel**
   ```bash
   sudo dpkg --install debian_build/*
   ```
4. **Update GRUB Bootloader**
   ```bash
   sudo update-grub
   ```
5. **Reboot into the New Kernel**
   ```bash
   sudo reboot
   ```
6. **Verify the Installed Kernel**
   After rebooting, ensure you are running the new L4S kernel:
   ```bash
   uname -r
   ```

---

## **Step 3: Load Required Kernel Modules**
L4S requires specific kernel modules. Load them manually:

```bash
sudo modprobe sch_dualpi2
sudo modprobe tcp_prague
```

To **verify if the modules are loaded**, run:
```bash
lsmod | grep -E "sch_dualpi2|tcp_prague"
```

---

## **Step 4: Configure Networking for L4S**
### **4.1 Enable ECN**
Enable Explicit Congestion Notification (ECN):
```bash
sudo sysctl -w net.ipv4.tcp_ecn=3
```

### **4.2 Set TCP Congestion Control to Prague**
```bash
sudo sysctl -w net.ipv4.tcp_congestion_control=prague
```
To confirm, check:
```bash
sysctl net.ipv4.tcp_congestion_control
```

### **4.3 Apply DualPI2 AQM to Your Network Interface**
**Important:** Replace `eth0` with the correct interface (`eno1`, `ens33`, etc.).
```bash
sudo tc qdisc replace dev eno1 root dualpi2
```

### **4.4 Disable Offloading Features**
**Issue Fixed**: Earlier, `ethtool` was missing. Install it before running:
```bash
sudo apt install ethtool -y
```
Then disable offloading to prevent network bursts:
```bash
sudo ethtool -K eno1 tso off gso off gro off lro off
```

### **4.5 Enable Fair Queueing (FQ)**
```bash
sudo tc qdisc replace dev eno1 root handle 1: fq limit 20480 flow_limit 10240
```

---

## **Step 5: Verify Configuration**
Run the following checks:

1. **Verify Congestion Control**  
   ```bash
   sysctl net.ipv4.tcp_congestion_control
   ```
2. **Check Queueing Discipline**  
   ```bash
   tc qdisc show dev eno1
   ```
3. **Confirm ECN Settings**  
   ```bash
   sysctl net.ipv4.tcp_ecn
   ```

---

## **Step 6: Perform Network Performance Experiments**
### **6.1 Install `iperf3`**
```bash
sudo apt install iperf3 -y
```

### **6.2 Run an `iperf3` Test**
Earlier, I tried running `iperf3` with an **incorrect server address format (`http://172.21.4.251:5201`)**.
Again you need to check your localhost from ifconfig -a.

 The correct method is:

- **On the Server Machine** (`172.21.4.251`):
  ```bash
  iperf3 -s
  ```
- **On the Client Machine**:
  ```bash
  iperf3 -c 172.21.4.251 -p 5201
  ```
- **For Reverse Mode Testing** (Useful for NAT/firewall issues):
  ```bash
  iperf3 -c 172.21.4.251 -p 5201 -R
  ```

---

## **Step 7: Make Configuration Persistent**
To ensure settings persist after reboot:

### **7.1 Persist ECN & Prague TCP in `/etc/sysctl.conf`**
```bash
echo "net.ipv4.tcp_ecn=3" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=prague" | sudo tee -a /etc/sysctl.conf
```

### **7.2 Persist `tc qdisc` Setup**
Create a startup script `/etc/network/if-up.d/l4s_qdisc`:
```bash
sudo nano /etc/network/if-up.d/l4s_qdisc
```
Add:
```bash
#!/bin/sh
tc qdisc replace dev eno1 root dualpi2
```
Save and make it executable:
```bash
sudo chmod +x /etc/network/if-up.d/l4s_qdisc
```

### **7.3 Persist `ethtool` Settings**
Append to `/etc/rc.local`:
```bash
sudo nano /etc/rc.local
```
Add:
```bash
#!/bin/sh -e
ethtool -K eno1 tso off gso off gro off lro off
exit 0
```
Make it executable:
```bash
sudo chmod +x /etc/rc.local
```

---

## **Step 8: Compile the Kernel from Source (Optional)**
If you prefer to compile the kernel instead of using the pre-built package:

1. **Clone the L4S Kernel Repository**
   ```bash
   git clone https://github.com/L4STeam/linux
   cd linux
   ```
2. **Configure the Kernel**
   ```bash
   cp /boot/config-$(uname -r) .config
   make olddefconfig
   scripts/config -m TCP_CONG_PRAGUE
   scripts/config -m NET_SCH_DUALPI2
   ```
3. **Compile & Install the Kernel**
   ```bash
   make -j$(nproc) LOCALVERSION=-prague-1
   sudo make modules_install
   sudo make install
   sudo update-grub
   ```
4. **Reboot into the New Kernel**
   ```bash
   sudo reboot
   ```

---

## **Final Notes & Troubleshooting**
- If your interface (`eno1`) isn't recognized, run:
  ```bash
  ip link show
  ```
- If `iperf3` fails to connect:
  - Check if the server is running:
    ```bash
    sudo netstat -tulnp | grep 5201
    ```
  - Ensure port `5201` is open:
    ```bash
    sudo ufw allow 5201/tcp
    ```
- For debugging network issues, use:
  ```bash
  dmesg | grep -i dualpi2
  ```


