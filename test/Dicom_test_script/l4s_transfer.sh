#!/bin/bash
# Working DICOM Transfer Script

SERVER_IP="172.21.4.251"
AET="YOUR_CLIENT"          # Must match exactly
AEC="PACS_SERVER"          # Must match server AE Title
PORT="1104"
DICOM_DIR="$HOME/l4s/dicom_test"

# Verify files and connection
echo "=== Verification ==="
echo "DICOM files: $(find "$DICOM_DIR" -name "*.dcm" | wc -l)"
timeout 2 bash -c "echo > /dev/tcp/$SERVER_IP/$PORT" && echo "Connection OK" || echo "Connection Failed"

# Transfer files
echo "=== Starting Transfer ==="
cd "$DICOM_DIR" || exit 1

# Process 10 files at a time
find . -maxdepth 1 -name "*.dcm" -print0 | \
  xargs -0 -n 10 storescu -v \
  -aet "$AET" \
  -aec "$AEC" \
  --max-pdu 65536 \
  "$SERVER_IP" "$PORT"

echo "=== Transfer Complete ==="
