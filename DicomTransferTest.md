# **L4S Telehealth Testing: DICOM Transfer Performance Evaluation**  
## **Flexible Testing with User-Provided Datasets**  

### **1. Introduction**  
This methodology enables testing with **user-acquired DICOM datasets** of varying sizes. Users should:  
1. Obtain datasets from clinical PACS or public archives
2. Use DICOM files from the cancer imaging archive (TCIA). https://www.cancerimagingarchive.net/browse-collections/
3. Organize them by size in the test directory  
4. Run standardized L4S performance tests  


---

### **2. Test Environment Setup**  
#### **2.1 Prerequisite Configuration** 
L4S Should be configure on both client and Server using documentation [link](./L4SkernelPatchSetUp.md) 

```bash
# Verify setup
tc qdisc show dev eno1
sysctl net.ipv4.tcp_congestion_control
```

#### **2.2 Dataset Organization**  
```bash
# Recommended directory structure
mkdir -p ~/dicom_test/{small,medium,large}

# Example content verification
find ~/dicom_test -type f -name "*.dcm" -exec dcmdump {} + | head
```

---

### **3. Transfer Testing Methodology**  
#### **3.1 Server Configuration**  
```bash
# Start receiver (adjust AE title)

# Start storescp on port 1104 (run in foreground first to check for errors)
storescp -v -aet PACS_SERVER -od ~/dicom_received 1104

# If successful, run in background with:
storescp -v -aet PACS_SERVER -od ~/dicom_received 1104 > ~/dicom_logs/storescp.log 2>&1 &

# Verify it's running
ps aux | grep [s]torescp
netstat -tulnp | grep 1104
```

#### **3.2 Client Test Script**  

## First test basic connectivity:
```bash
telnet $SERVER_IP $PORT
```



```bash
#!/bin/bash
# Flexible DICOM Transfer Tester

SERVER="172.21.4.251"
PORT=1104
AET="TEST_CLIENT"
AEC="PACS_SERVER"

for size_dir in small medium large; do
  [ -d ~/dicom_test/$size_dir ] || continue
  
  echo "=== Testing $size_dir dataset ==="
  time storescu -v -aet $AET -aec $AEC \
    --max-pdu 65536 \
    ~/dicom_test/$size_dir/* \
    $SERVER $PORT
    
  echo "=== Network Metrics ==="
  ss -tin dst $SERVER | grep -E 'ecn|cwnd|rtt'
done
```

---

### **4. Test Scenarios**  
#### **4.1 Baseline Performance**  
```bash
# Clean network condition test
./test_script.sh > baseline_results.log
```

#### **4.2 Congestion Testing**  
```bash
# Add impairment (run in separate terminal)
sudo tc qdisc add dev eno1 parent dualpi2: handle 1: netem delay 50ms loss 2%

# Run tests
./test_script.sh > congested_results.log

# Remove impairment
sudo tc qdisc del dev eno1 root
```

---


### **5. Customization Guide**  
**To Adapt for Your Environment**:  
1. Replace `SERVER`, `AET`, and `AEC` with your values  
2. Place DICOM files in corresponding size directories  
3. Adjust impairment parameters in congestion tests  

**Key Recommendations**:  
- Use at least 3 different dataset sizes  
- Include multi-slice studies for real-world simulation  
- Verify DICOM validity with `dcmdump` before testing  

---

### **6. Analysis Tools**  
**Post-Processing**:  
```bash
# Calculate average throughput
awk '/Throughput/{sum+=$2; count++} END{print "Avg:",sum/count,"MB/s"}' results.log

# Check for retransmissions
grep -A 5 'retrans' results.log
```