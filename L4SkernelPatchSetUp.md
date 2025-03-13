 **step-by-step guide** to set up and configure the L4S-enabled Linux kernel for our experiments, including the necessary patches and configurations.

---

### **Step 1: Prerequisites**
Before proceeding, ensure you have the following:
1. **A Linux system**: Ubuntu, Debian, or any Debian-based distribution is recommended.
2. **Build tools**: Install the necessary tools to compile the Linux kernel.
   ```bash
   sudo apt update
   sudo apt install build-essential libncurses-dev bison flex libssl-dev libelf-dev git wget unzip
   ```
3. **Enough disk space**: Kernel compilation requires significant disk space (at least 20 GB free).
4. **Stable internet connection**: For downloading the kernel source and dependencies.

---

### **Step 2: Download and Install the Pre-Built Kernel**
The repository provides pre-built Debian packages for easier installation. Follow these steps:

1. **Download the pre-built kernel**:
   ```bash
   wget https://github.com/L4STeam/linux/releases/download/testing-build/l4s-testing.zip
   ```

2. **Unzip the archive**:
   ```bash
   unzip l4s-testing.zip
   ```

3. **Install the kernel packages**:
   ```bash
   sudo dpkg --install debian_build/*
   ```

4. **Update GRUB**:
   ```bash
   sudo update-grub
   ```

5. **Reboot into the new kernel**:
   ```bash
   sudo reboot
   ```

6. **Verify the kernel version**:
   After rebooting, check the kernel version to ensure the new kernel is in use:
   ```bash
   uname -r
   ```

---

### **Step 3: Load Required Kernel Modules**
Load the necessary modules for L4S (e.g., `sch_dualpi2` and `tcp_prague`):
```bash
sudo modprobe sch_dualpi2
sudo modprobe tcp_prague
```

---

### **Step 4: Configure Networking for L4S**
1. **Enable ECN**:
   ```bash
   sudo sysctl -w net.ipv4.tcp_ecn=3
   ```

2. **Set TCP Congestion Control to Prague**:
   ```bash
   sudo sysctl -w net.ipv4.tcp_congestion_control=prague
   ```

3. **Configure DualPI2 AQM**:
   Apply the DualPI2 queueing discipline to your network interface (e.g., `eth0`):
   ```bash
   sudo tc qdisc replace dev eth0 root dualpi2
   ```

4. **Disable Offloading Features**:
   To avoid bursts and ensure proper pacing, disable offloading features on your network interface:
   ```bash
   sudo ethtool -K eth0 tso off gso off gro off lro off
   ```

5. **Configure FQ (Fair Queueing)**:
   Replace the default queueing discipline with FQ for better pacing:
   ```bash
   sudo tc qdisc replace dev eth0 root handle 1: fq limit 20480 flow_limit 10240
   ```

---

### **Step 5: Verify the Configuration**
1. **Check the congestion control algorithm**:
   ```bash
   sysctl net.ipv4.tcp_congestion_control
   ```

2. **Check the queueing discipline**:
   ```bash
   tc qdisc show dev eth0
   ```

3. **Check ECN settings**:
   ```bash
   sysctl net.ipv4.tcp_ecn
   ```

---

### **Step 6: Perform Experiments**
1. **Test with `iperf3`**:
   - Install `iperf3`:
     ```bash
     sudo apt install iperf3
     ```
   - Run a server on one machine:
     ```bash
     iperf3 -s
     ```
   - Run a client on another machine:
     ```bash
     iperf3 -c <server-ip>
     ```

2. **Monitor Network Performance**:
   - Use tools like `ping`, `ss`, and `tcpdump` to monitor latency, throughput, and packet loss.

---

### **Step 7: Persistent Configuration**
To ensure the settings persist across reboots:
1. Add the `sysctl` settings to `/etc/sysctl.conf`:
   ```bash
   echo "net.ipv4.tcp_ecn=3" | sudo tee -a /etc/sysctl.conf
   echo "net.ipv4.tcp_congestion_control=prague" | sudo tee -a /etc/sysctl.conf
   ```

2. Add the `tc qdisc` configuration to a startup script (e.g., `/etc/rc.local`):
   ```bash
   sudo tc qdisc replace dev eth0 root dualpi2
   ```

3. Add the `ethtool` commands to a startup script:
   ```bash
   sudo ethtool -K eth0 tso off gso off gro off lro off
   ```

---

### **Step 8: Compile the Kernel from Source (Optional)**
If you prefer to compile the kernel from source instead of using the pre-built packages, follow these steps:

1. **Clone the L4S kernel repository**:
   ```bash
   git clone https://github.com/L4STeam/linux
   cd linux
   ```

2. **Configure the kernel**:
   ```bash
   cp /boot/config-$(uname -r) .config
   make olddefconfig
   scripts/config -m TCP_CONG_PRAGUE
   scripts/config -m NET_SCH_DUALPI2
   ```

3. **Compile and install the kernel**:
   ```bash
   make -j$(nproc) LOCALVERSION=-prague-1
   sudo make modules_install
   sudo make install
   sudo update-grub
   ```

4. **Reboot into the new kernel**:
   ```bash
   sudo reboot
   ```

---

### **Additional Notes**
- **Testing in a Controlled Environment**: Test the L4S setup in a controlled network environment to isolate variables and measure performance accurately.
- **Telehealth Applications**: For telehealth use cases (e.g., DICOM imaging, telemonitoring, and televisits), ensure the network is optimized for both high-throughput and low-latency traffic.
- **Documentation**: Refer to the [L4STeam/linux repository documentation](https://github.com/L4STeam/linux) for any additional setup instructions or troubleshooting.

---

This setup should allow you to experiment with L4S on a Linux system.