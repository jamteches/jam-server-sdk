#!/bin/bash
# Chunked Upload Test Script
# Tests the chunked upload system for large files

set -e

BASE_URL="${JAM_API_URL:-https://api.jamteches.com}"
API_KEY="${JAM_API_KEY:-jam_pk_test_ohgryrye0xl4m10p5ztfxv}"
PROJECT_ID="${JAM_PROJECT_ID:-692d79007214ae6e80e63d7a}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
}

pass() {
    echo -e "   ${GREEN}✅ PASS:${NC} $1"
}

fail() {
    echo -e "   ${RED}❌ FAIL:${NC} $1"
}

info() {
    echo -e "   ${CYAN}ℹ️ ${NC} $1"
}

# Create test file
TEST_FILE="/tmp/chunked_upload_test.txt"
TEST_SIZE=1048576  # 1MB for quick test
CHUNK_SIZE=262144  # 256KB chunks

header "🧪 Creating Test File"
echo "Creating ${TEST_SIZE} byte test file..."
dd if=/dev/urandom of="$TEST_FILE" bs=1024 count=$((TEST_SIZE/1024)) 2>/dev/null
ACTUAL_SIZE=$(stat -f%z "$TEST_FILE" 2>/dev/null || stat -c%s "$TEST_FILE" 2>/dev/null)
info "Created: $TEST_FILE ($ACTUAL_SIZE bytes)"

# Calculate checksum
CHECKSUM=$(sha256sum "$TEST_FILE" | cut -d' ' -f1)
info "Checksum: ${CHECKSUM:0:16}..."

header "📤 Step 1: Initialize Upload Session"

INIT_RESPONSE=$(curl -s -X POST "$BASE_URL/api/upload/init" \
    -H "X-API-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
        \"filename\": \"test_upload.bin\",
        \"total_size\": $ACTUAL_SIZE,
        \"chunk_size\": $CHUNK_SIZE,
        \"project_id\": \"$PROJECT_ID\",
        \"checksum\": \"$CHECKSUM\"
    }")

echo "Response: $INIT_RESPONSE"

SESSION_ID=$(echo "$INIT_RESPONSE" | jq -r '.session_id // empty')
TOTAL_CHUNKS=$(echo "$INIT_RESPONSE" | jq -r '.total_chunks // 0')

if [ -n "$SESSION_ID" ] && [ "$SESSION_ID" != "null" ]; then
    pass "Session created: $SESSION_ID"
    info "Total chunks: $TOTAL_CHUNKS"
else
    fail "Failed to create upload session"
    echo "$INIT_RESPONSE"
    exit 1
fi

header "📦 Step 2: Upload Chunks"

for ((i=0; i<TOTAL_CHUNKS; i++)); do
    OFFSET=$((i * CHUNK_SIZE))
    
    # Read chunk
    CHUNK_FILE="/tmp/chunk_$i.bin"
    dd if="$TEST_FILE" of="$CHUNK_FILE" bs=1 skip=$OFFSET count=$CHUNK_SIZE 2>/dev/null
    CHUNK_ACTUAL_SIZE=$(stat -f%z "$CHUNK_FILE" 2>/dev/null || stat -c%s "$CHUNK_FILE" 2>/dev/null)
    
    # Upload chunk
    CHUNK_RESPONSE=$(curl -s -X PUT "$BASE_URL/api/upload/$SESSION_ID/chunk/$i" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/octet-stream" \
        --data-binary @"$CHUNK_FILE")
    
    PROGRESS=$(echo "$CHUNK_RESPONSE" | jq -r '.progress // 0')
    
    if echo "$CHUNK_RESPONSE" | grep -q '"message"'; then
        echo -e "   ${GREEN}✓${NC} Chunk $((i+1))/$TOTAL_CHUNKS uploaded (${CHUNK_ACTUAL_SIZE} bytes) - ${PROGRESS}%"
    else
        fail "Failed to upload chunk $i"
        echo "$CHUNK_RESPONSE"
    fi
    
    rm -f "$CHUNK_FILE"
done

header "📊 Step 3: Check Upload Status"

STATUS_RESPONSE=$(curl -s "$BASE_URL/api/upload/$SESSION_ID/status" \
    -H "X-API-Key: $API_KEY")

echo "Status: $STATUS_RESPONSE" | jq '.'

UPLOADED=$(echo "$STATUS_RESPONSE" | jq -r '.uploaded_chunks | length')
MISSING=$(echo "$STATUS_RESPONSE" | jq -r '.missing_chunks | length')

if [ "$MISSING" -eq 0 ]; then
    pass "All $UPLOADED chunks uploaded successfully"
else
    fail "Missing $MISSING chunks"
fi

header "✅ Step 4: Complete Upload"

COMPLETE_RESPONSE=$(curl -s -X POST "$BASE_URL/api/upload/$SESSION_ID/complete" \
    -H "X-API-Key: $API_KEY" \
    -H "Content-Type: application/json")

echo "Response: $COMPLETE_RESPONSE" | jq '.'

FILE_URL=$(echo "$COMPLETE_RESPONSE" | jq -r '.url // empty')
FILE_ID=$(echo "$COMPLETE_RESPONSE" | jq -r '.file_id // empty')

if [ -n "$FILE_URL" ] && [ "$FILE_URL" != "null" ]; then
    pass "Upload completed!"
    info "File URL: $FILE_URL"
    info "File ID: $FILE_ID"
else
    fail "Failed to complete upload"
    echo "$COMPLETE_RESPONSE"
fi

header "🧹 Cleanup"
rm -f "$TEST_FILE"
info "Test file removed"

header "📋 Summary"
echo ""
echo -e "   ${CYAN}Session:${NC} $SESSION_ID"
echo -e "   ${CYAN}File Size:${NC} $ACTUAL_SIZE bytes"
echo -e "   ${CYAN}Chunks:${NC} $TOTAL_CHUNKS"
echo -e "   ${CYAN}Chunk Size:${NC} $CHUNK_SIZE bytes"
echo -e "   ${CYAN}URL:${NC} $FILE_URL"
echo ""
echo -e "${GREEN}🎉 Chunked upload test completed!${NC}"
