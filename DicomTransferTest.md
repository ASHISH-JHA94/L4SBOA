# **L4S Telehealth Testing: DICOM Transfer Performance Evaluation**

## **1. Introduction**
This document provides a **comprehensive methodology** for testing DICOM medical image transfers over L4S-enabled networks. The goal is to validate whether L4S improves:
- **Throughput** for large radiology files (CT/MRI)  
- **Reliability** under network congestion (packet loss, latency)  
- **Fairness** when sharing bandwidth with other telehealth traffic  

---

## **2. Test Environment Setup**
### **2.1 Prerequisites**
- Two L4S-enabled Linux machines (client + server)  
- `dcmtk` installed for DICOM operations:  
  ```bash
  sudo apt install dcmtk
  ```
- Network interface configured with L4S (DualPI2 qdisc, TCP Prague)  
  ```bash
  # Install required kernel modules if not present
  sudo modprobe sch_dualpi2
  
  # Configure the network interface with DualPI2 queue discipline
  sudo tc qdisc replace dev eth0 root dualpi2
  
  # Enable TCP Prague congestion control
  sudo sysctl -w net.ipv4.tcp_congestion_control=prague
  
  # Check that Prague is active
  sysctl net.ipv4.tcp_congestion_control
  ```
  Note: Replace `eth0` with your actual network interface name (e.g., `eno1`, `enp2s0`, etc.)

### **2.2 Generate Test DICOM Files**
```bash
# Create synthetic DICOM files (varying sizes)
mkdir -p dicom_test && cd dicom_test

# Create proper DICOM file structure (raw binary isn't valid DICOM)
for size in 10 100 500; do
  # First create raw data
  dd if=/dev/urandom of=raw_${size}MB.bin bs=1M count=${size}
  
  # Then convert to valid DICOM using dcmtk tools
  img2dcm -df dcm_template.dcm raw_${size}MB.bin ${size}MB.dcm
done

# Alternatively, use dcmtk's dcmgpdir to create valid test files
dcmgpdir -nC -v -d test_dicoms
```

---

## **3. DICOM Transfer Tests**
### **3.1 Baseline Transfer (No Congestion)**
**Purpose:** Measure optimal performance.  

#### **Commands**
```bash
# On Server (receiver)
storescp --fork --promiscuous --output-directory /dicom_receiver 104 &

# On Client (sender)
time storescu -v -aet SENDER -aec RECEIVER server_ip 104 dicom_test/500MB.dcm
```

#### **Metrics to Record**
| Metric               | Command                                | Expected L4S Advantage       |
|----------------------|----------------------------------------|-----------------------------|
| Transfer Time        | `time storescu ...`                   | Faster than Cubic/BBR       |
| Throughput (MB/s)    | `file_size / transfer_time`           | Higher sustained bandwidth  |
| Retransmissions      | `ss -ti | grep -i retrans`            | Fewer retransmits          |
| ECN Usage            | `ss -tin | grep -i ecn`               | Should show "ecn"          |

---

### **3.2 Congestion Stress Test**
**Purpose:** Validate performance under packet loss/latency.  

#### **Commands**
```bash
# Add 50ms delay + 2% packet loss
sudo tc qdisc add dev eth0 parent root: handle 1: netem delay 50ms loss 2%

# Start competing traffic (simulate telehealth mix)
# L4S traffic with Prague congestion control
iperf3 -c server_ip -p 5201 -t 60 -C prague &
  
# Classic traffic with Cubic congestion control 
iperf3 -c server_ip -p 5202 -C cubic &

# Run DICOM transfer
time storescu -v -aet SENDER -aec RECEIVER server_ip 104 dicom_test/500MB.dcm

# Remove netem qdisc when done
sudo tc qdisc del dev eth0 root
```

#### **Metrics to Record**
| Metric               | Command                                  | Expected L4S Result         |
|----------------------|------------------------------------------|-----------------------------|
| Transfer Time        | `time storescu ...`                     | <20% increase from baseline |
| Packet Loss          | `tc -s qdisc show dev eth0`             | DualPI2 keeps loss <5%      |
| Queue Delay          | `tc -s qdisc show dev eth0 | grep delay` | Stable under 10ms          |
| Competing Flow Fairness | `iftop -nP -i eth0`                  | L4S doesn't starve Cubic    |

---

### **3.3 Multi-Stream Fairness Test**
**Purpose:** Verify fairness when transferring multiple studies.  

#### **Commands**
```bash
# Run 3 concurrent DICOM transfers
for i in {1..3}; do  
  storescu -v -aet SENDER_${i} -aec RECEIVER server_ip 104 dicom_test/100MB.dcm &  
done

# Monitor bandwidth allocation
iftop -nP -i eth0
```

#### **Metrics to Record**
| Metric               | Command                                   | Expected Result             |
|----------------------|-------------------------------------------|-----------------------------|
| Throughput per Stream | `iftop -nP -i eth0`                     | Within ±15% of each other   |
| Retransmissions      | `ss -ti | grep -A 1 -i retrans`          | Balanced across streams     |

---

### **3.4 Large-File Burst Stability**
**Purpose:** Test TCP behavior with 1GB+ files.  

#### **Commands**
```bash
# Create a larger test file
dd if=/dev/urandom of=raw_1GB.bin bs=1M count=1024
img2dcm -df dcm_template.dcm raw_1GB.bin 1GB.dcm

# Transfer while monitoring TCP metrics
storescu -v -aet SENDER -aec RECEIVER server_ip 104 dicom_test/1GB.dcm &
PID=$!

# Watch congestion window stats every second
watch -n 1 "ss -tiepm src :$(ss -tpn | grep $PID | awk '{print $4}' | cut -d: -f2)"

# Wait for transfer to complete
wait $PID
```

#### **Metrics to Record**
| Metric               | Command                                       | Expected Result             |
|----------------------|-----------------------------------------------|-----------------------------|
| Congestion Window    | `ss -tiepm | grep cwnd`                      | Grows smoothly, no collapses |
| Kernel Errors        | `dmesg | grep -iE 'tcp_prague|l4s'`          | No warnings/errors          |

---

## **4. Advanced Validation**
### **4.1 Wireshark Analysis**
```bash
# Capture DICOM traffic with ECN marking info
sudo tshark -i eth0 -f "tcp port 104" -w dicom_l4s.pcap

# Analyze ECN markings and retransmissions
tshark -r dicom_l4s.pcap -Y "ip.dsfield.ecn == 0x03" | wc -l
tshark -r dicom_l4s.pcap -q -z "io,stat,1,tcp.analysis.retransmission"

# Check for L4S markings in packets
tshark -r dicom_l4s.pcap -Y "ip.dsfield.ecn == 0x01" | wc -l
```

### **4.2 Real-World PACS Test**
```bash
# Send to actual PACS (replace with ANTHC's AE Title and IP)
storescu -v -aet MY_CLINIC -aec ANTHC_PACS pacs_ip 104 dicom_test/100MB.dcm

# Verify successful storage (if you have access to the PACS)
findscu -v -S -aet MY_CLINIC -aec ANTHC_PACS pacs_ip 104 -k QueryRetrieveLevel=SERIES
```

---

## **5. Expected Results Table**
| Test Case          | Metric               | L4S (Expected) | Cubic (Baseline) | Improvement |
|--------------------|----------------------|----------------|------------------|-------------|
| Baseline Transfer  | Throughput (MB/s)    | 180            | 120              | +50%        |
| Congestion Stress  | Transfer Time Increase | +15%         | +300%            | 20x better  |
| Multi-Stream       | Fairness Deviation   | ±10%           | ±50%             | 5x fairer   |
| Large-File Burst   | Cwnd Stability       | Smooth         | Frequent drops   | No timeouts |

---

## **6. Automation Script**
```bash
#!/bin/bash
# DICOM Automated Test Script
SERVER_IP="172.21.4.251"
DICOM_DIR="dicom_test"
AET_SENDER="SENDER"
AEC_RECEIVER="RECEIVER"
INTERFACE="eth0"  # Change to your interface name

echo "Setting up L4S..."
sudo modprobe sch_dualpi2
sudo tc qdisc replace dev $INTERFACE root dualpi2
sudo sysctl -w net.ipv4.tcp_congestion_control=prague

echo "1. Baseline Transfer Test"
echo "Starting DICOM receiver on server..."
ssh user@$SERVER_IP "storescp --fork --promiscuous --output-directory /dicom_receiver 104 &"
sleep 2

echo "Sending DICOM files..."
time storescu -v -aet $AET_SENDER -aec $AEC_RECEIVER $SERVER_IP 104 $DICOM_DIR/500MB.dcm
echo "Baseline throughput: $((500*1024*1024 / $(cat /tmp/time_result) / 1024 / 1024)) MB/s"

echo "2. Congestion Test"
echo "Adding network congestion..."
sudo tc qdisc add dev $INTERFACE parent root: handle 1: netem delay 50ms loss 2%

echo "Starting competing traffic..."
iperf3 -c $SERVER_IP -p 5201 -t 120 -C prague &
iperf3 -c $SERVER_IP -p 5202 -t 120 -C cubic &
sleep 5

echo "Sending DICOM under congestion..."
time storescu -v -aet $AET_SENDER -aec $AEC_RECEIVER $SERVER_IP 104 $DICOM_DIR/100MB.dcm

echo "Removing network congestion..."
sudo tc qdisc del dev $INTERFACE root

echo "3. Multi-Stream Test"
echo "Starting multiple transfers..."
for i in {1..3}; do 
  storescu -v -aet ${AET_SENDER}_${i} -aec $AEC_RECEIVER $SERVER_IP 104 $DICOM_DIR/100MB.dcm &
done
wait

echo "Tests complete!"
echo "Restoring network settings..."
sudo sysctl -w net.ipv4.tcp_congestion_control=cubic
```

---

## **7. Conclusion**
This test plan validates L4S for **Alaska's telehealth needs** by:  
1. Ensuring **fast transfers** of large radiology files.  
2. Maintaining **reliability** under satellite/WAN congestion.  
3. Guaranteeing **fairness** with other clinical traffic.  

**Next Steps:**  
- Deploy in ANTHC's testbed with real PACS systems.  
- Compare against non-L4S results (Cubic/BBR).  
- Optimize DICOM transfer parameters for L4S:
  - Test with larger `MaxPDUSize` (default: 16KB → test 64KB)
  - Adjust `--max-send-pdu` and `--max-receive-pdu` parameters
  - Test with multiple association requests (`--propose-tls`)