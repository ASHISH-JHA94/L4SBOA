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
  sudo tc qdisc replace dev eno1 root dualpi2
  sudo sysctl -w net.ipv4.tcp_congestion_control=prague
  ```

### **2.2 Generate Test DICOM Files**
```bash
# Create synthetic DICOM files (varying sizes)
mkdir -p dicom_test && cd dicom_test
dd if=/dev/zero of=small.dcm bs=1M count=10  # 10MB
dd if=/dev/zero of=medium.dcm bs=1M count=100 # 100MB
dd if=/dev/zero of=large.dcm bs=1M count=500  # 500MB
```

---

## **3. DICOM Transfer Tests**
### **3.1 Baseline Transfer (No Congestion)**
**Purpose:** Measure optimal performance.  

#### **Commands**
```bash
# On Server (receiver)
storescp +sd /dicom_receiver 104 &

# On Client (sender)
time storescu -aet MY_CLIENT -aec MY_SERVER <SERVER_IP> 104 dicom_test/large.dcm
```

#### **Metrics to Record**
| Metric               | Command                          | Expected L4S Advantage       |
|----------------------|----------------------------------|-----------------------------|
| Transfer Time        | `time storescu ...`             | Faster than Cubic/BBR       |
| Throughput (MB/s)    | `file_size / transfer_time`     | Higher sustained bandwidth  |
| Retransmissions      | `ss -ti | grep retrans`          | Fewer retransmits          |
| ECN Usage            | `ss -tin | grep ecn`            | Should show "ecn"          |

---

### **3.2 Congestion Stress Test**
**Purpose:** Validate performance under packet loss/latency.  

#### **Commands**
```bash
# Add 50ms delay + 2% packet loss (on both ends)
sudo tc qdisc add dev eno1 root netem delay 50ms loss 2%

# Start competing traffic (simulate telehealth mix)
iperf3 -c <SERVER_IP> -p 5201 -t 60 -Z &  # L4S traffic  
iperf3 -c <SERVER_IP> -p 5202 -C cubic &   # Classic traffic  

# Run DICOM transfer
time storescu ... dicom_test/large.dcm
```

#### **Metrics to Record**
| Metric               | Command                          | Expected L4S Result         |
|----------------------|----------------------------------|-----------------------------|
| Transfer Time        | `time storescu ...`             | <20% increase from baseline |
| Packet Loss          | `tc -s qdisc show dev eno1`     | DualPI2 keeps loss <5%      |
| Queue Delay          | `tc -s qdisc | grep delay`      | Stable under 10ms          |
| Competing Flow Fairness | `iftop -i eno1`            | L4S doesn’t starve Cubic    |

---

### **3.3 Multi-Stream Fairness Test**
**Purpose:** Verify fairness when transferring multiple studies.  

#### **Commands**
```bash
# Run 3 concurrent DICOM transfers
for i in {1..3}; do  
  storescu ... dicom_test/medium.dcm &  
done

# Monitor bandwidth allocation
iftop -i eno1
```

#### **Metrics to Record**
| Metric               | Command                          | Expected Result             |
|----------------------|----------------------------------|-----------------------------|
| Throughput per Stream | `iftop -i eno1`               | Within ±15% of each other   |
| Retransmissions      | `ss -ti | grep -A 1 retrans`    | Balanced across streams     |

---

### **3.4 Large-File Burst Stability**
**Purpose:** Test TCP behavior with 1GB+ files.  

#### **Commands**
```bash
# Transfer a 1GB file while monitoring kernel
storescu ... dicom_test/large.dcm &  
watch -n 1 "ss -tpm | grep -A 1 'tcp_prague'"
```

#### **Metrics to Record**
| Metric               | Command                          | Expected Result             |
|----------------------|----------------------------------|-----------------------------|
| Congestion Window    | `ss -tpm | grep cwnd`           | Grows smoothly, no collapses |
| Kernel Errors        | `dmesg | grep -i tcp_prague`   | No warnings/errors          |

---

## **4. Advanced Validation**
### **4.1 Wireshark Analysis**
```bash
# Capture DICOM traffic
tshark -i eno1 -Y "tcp.port==104" -w dicom_l4s.pcap

# Analyze retransmissions
tshark -r dicom_l4s.pcap -q -z io,stat,1,"tcp.analysis.retransmission"
```

### **4.2 Real-World PACS Test**
```bash
# Send to actual PACS (replace with ANTHC’s AE Title)
storescu -aet MY_CLINIC -aec ANTHC_PACS <PACS_IP> 104 dicom_test/small.dcm

# Verify successful storage
dcmqrscp --log-level debug --storage-directory /pacs_received
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

echo "1. Baseline Transfer Test"
time storescu -aet TEST_CLIENT -aec TEST_SERVER $SERVER_IP 104 $DICOM_DIR/large.dcm

echo "2. Congestion Test"
sudo tc qdisc add dev eno1 root netem delay 50ms loss 2%
time storescu ... $DICOM_DIR/medium.dcm
sudo tc qdisc del dev eno1 root

echo "3. Multi-Stream Test"
for i in {1..3}; do 
  storescu ... $DICOM_DIR/small.dcm &
done
wait
```

---

## **7. Conclusion**
This test plan validates L4S for **Alaska’s telehealth needs** by:  
1. Ensuring **fast transfers** of large radiology files.  
2. Maintaining **reliability** under satellite/WAN congestion.  
3. Guaranteeing **fairness** with other clinical traffic.  

**Next Steps:**  
- Deploy in ANTHC’s testbed with real PACS systems.  
- Compare against non-L4S results (Cubic/BBR).  
- Optimize DICOM `MaxPDU` size for L4S (default: 16KB → test 64KB). 



