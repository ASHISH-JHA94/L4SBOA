#!/bin/bash
# Enhanced L4S DICOM Transfer Test Script

# ===== Configuration =====
SERVER_IP="172.21.4.251"
PORT="1104"
AET="YOUR_CLIENT"          # Must match exactly
AEC="PACS_SERVER"          # Must match server AE Title
DICOM_DIR="$HOME/l4s/dicom_test"
LOG_DIR="$HOME/l4s/logs"
TEST_DATE=$(date +%Y%m%d_%H%M%S)

# ===== Setup =====
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/dicom_test_$TEST_DATE.log"
METRICS_FILE="$LOG_DIR/metrics_$TEST_DATE.csv"

# Initialize metrics file
echo "timestamp,file_count,transfer_time,throughput_mbps,retransmissions,ecn_marks" > "$METRICS_FILE"

# ===== Verification =====
{
echo "=== L4S DICOM Transfer Test ==="
echo "Test Date: $TEST_DATE"
echo "=== System Verification ==="
echo "L4S Qdisc Status:"
tc qdisc show dev $(ip route show default | awk '/default/ {print $5}')
echo "TCP Congestion Control:"
sysctl net.ipv4.tcp_congestion_control

echo "=== DICOM Verification ==="
FILE_COUNT=$(find "$DICOM_DIR" -name "*.dcm" | wc -l)
echo "DICOM files found: $FILE_COUNT"

echo "=== Connection Test ==="
if timeout 2 bash -c "echo > /dev/tcp/$SERVER_IP/$PORT"; then
    echo "Connection OK"
else
    echo "Connection Failed - Aborting"
    exit 1
fi

# ===== Transfer Test =====
echo "=== Starting Transfer Test ==="
START_TIME=$(date +%s.%N)

# Capture baseline network stats
ss -tin dst "$SERVER_IP" > "$LOG_DIR/network_before.log"

# Process files in batches (10 at a time)
find "$DICOM_DIR" -maxdepth 1 -name "*.dcm" -print0 | \
  xargs -0 -n 10 storescu -v \
  -aet "$AET" \
  -aec "$AEC" \
  --max-pdu 65536 \
  "$SERVER_IP" "$PORT" 2>&1 | tee -a "$LOG_FILE"

# Capture post-transfer metrics
END_TIME=$(date +%s.%N)
ELAPSED=$(printf "%.2f" $(echo "$END_TIME - $START_TIME" | bc))
ss -tin dst "$SERVER_IP" > "$LOG_DIR/network_after.log"

# Calculate throughput (assuming average DICOM file size ~5MB)
TOTAL_SIZE_MB=$(echo "$FILE_COUNT * 5" | bc)
THROUGHPUT=$(printf "%.2f" $(echo "$TOTAL_SIZE_MB / $ELAPSED" | bc))

# Extract L4S metrics
RETRANS=$(grep -o "retrans:[0-9]*" "$LOG_DIR/network_after.log" | cut -d: -f2)
ECN_MARKS=$(grep -o "ecn[^ ]*" "$LOG_DIR/network_after.log" | sort | uniq -c | tr '\n' ';')

# Record metrics
echo "$(date +%T),$FILE_COUNT,$ELAPSED,$THROUGHPUT,$RETRANS,$ECN_MARKS" >> "$METRICS_FILE"

# ===== Results =====
echo "=== Test Complete ==="
echo "Transfer Time: $ELAPSED seconds"
echo "Throughput: $THROUGHPUT MB/s"
echo "Retransmissions: $RETRANS"
echo "ECN Marks: $ECN_MARKS"
} | tee "$LOG_FILE"

# ===== Post-Test Analysis =====
echo "=== Suggested Analysis Commands ==="
echo "Throughput over time:"
echo "  column -t -s, $METRICS_FILE"
echo "Network metric differences:"
echo "  diff $LOG_DIR/network_{before,after}.log"
echo "Detailed transfer log:"
echo "  less $LOG_FILE"
