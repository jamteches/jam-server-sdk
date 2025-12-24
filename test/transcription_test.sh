#!/bin/bash
#
# Transcription API Test Script
# ================================
# Tests the transcription endpoints via curl
#
# Usage:
#   ./transcription_test.sh [BASE_URL] [API_KEY]
#
# Example:
#   ./transcription_test.sh https://api.jamteches.com YOUR_API_KEY
#

set -e

# Configuration
BASE_URL="${1:-http://localhost:8080}"
API_KEY="${2:-}"
AI_SERVICE_URL="${3:-http://localhost:8001}"
PROJECT_ID="test_project_$(date +%s)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
SKIPPED=0

# Functions
pass() {
    PASSED=$((PASSED + 1))
    echo -e "  ${GREEN}✓ PASS${NC}: $1"
}

fail() {
    FAILED=$((FAILED + 1))
    echo -e "  ${RED}✗ FAIL${NC}: $1"
}

skip() {
    SKIPPED=$((SKIPPED + 1))
    echo -e "  ${YELLOW}○ SKIP${NC}: $1"
}

# Create test audio file
create_test_audio() {
    local duration="${1:-2}"
    local filename="${2:-/tmp/test_audio_$$.wav}"
    
    ffmpeg -y -f lavfi -i "sine=frequency=440:duration=$duration" \
        -ar 16000 -ac 1 "$filename" 2>/dev/null
    
    echo "$filename"
}

# Create test video file
create_test_video() {
    local duration="${1:-2}"
    local filename="${2:-/tmp/test_video_$$.mp4}"
    
    ffmpeg -y \
        -f lavfi -i "testsrc=duration=$duration:size=320x240:rate=15" \
        -f lavfi -i "sine=frequency=440:duration=$duration" \
        -c:v libx264 -c:a aac -shortest "$filename" 2>/dev/null
    
    echo "$filename"
}

echo "=================================================="
echo "🎤 Transcription API Tests"
echo "=================================================="
echo ""
echo "Base URL: $BASE_URL"
echo "AI Service: $AI_SERVICE_URL"
echo "API Key: ${API_KEY:+***${API_KEY: -4}}"
echo "Project ID: $PROJECT_ID"
echo ""

# ==================== Health Tests ====================

echo "📋 Section: Health & Status"
echo "----------------------------------------"

# Test 1: Health Check
echo "  Testing: Health Check"
RESPONSE=$(curl -s "$BASE_URL/health" 2>/dev/null || echo '{"error":"failed"}')
if echo "$RESPONSE" | grep -q '"status":"ok"'; then
    pass "Health check returned ok"
else
    fail "Health check failed: $RESPONSE"
fi

# Test 2: AI Health Check
echo "  Testing: AI Health Check"
RESPONSE=$(curl -s "$BASE_URL/api/ai/health" 2>/dev/null || echo '{"error":"failed"}')
if echo "$RESPONSE" | grep -q '"status":"ok"'; then
    pass "AI health check returned ok"
else
    fail "AI health check failed: $RESPONSE"
fi

# Test 3: GPU Queue Status
echo "  Testing: GPU Queue Status"
RESPONSE=$(curl -s "$AI_SERVICE_URL/gpu-queue/status" 2>/dev/null || echo '{"error":"failed"}')
if echo "$RESPONSE" | grep -qE '"queue_length"|"status"'; then
    pass "GPU queue status available"
    echo "      Response: $RESPONSE"
else
    skip "GPU queue status not available (direct AI service access)"
fi

echo ""

# ==================== Sync Transcription Tests ====================

echo "📋 Section: Sync Transcription"
echo "----------------------------------------"

# Test 4: Transcribe Short Audio
echo "  Testing: Transcribe Short Audio"
AUDIO_FILE=$(create_test_audio 2)
if [ -f "$AUDIO_FILE" ]; then
    if [ -n "$API_KEY" ]; then
        RESPONSE=$(curl -s -X POST "$BASE_URL/api/ai/transcribe" \
            -H "X-API-Key: $API_KEY" \
            -F "file=@$AUDIO_FILE" \
            -F "language=en" \
            -F "project_id=$PROJECT_ID" 2>/dev/null || echo '{"error":"failed"}')
        
        if echo "$RESPONSE" | grep -qE '"segments"|"language"|"duration"'; then
            pass "Sync transcription works"
            echo "      Language: $(echo "$RESPONSE" | grep -o '"language":"[^"]*"' | cut -d'"' -f4)"
        else
            fail "Sync transcription failed: $RESPONSE"
        fi
    else
        skip "No API key provided"
    fi
    rm -f "$AUDIO_FILE"
else
    fail "Could not create test audio file"
fi

# Test 5: Transcribe with Subtitle
echo "  Testing: Transcribe with Subtitle Format"
AUDIO_FILE=$(create_test_audio 2)
if [ -f "$AUDIO_FILE" ] && [ -n "$API_KEY" ]; then
    RESPONSE=$(curl -s -X POST "$BASE_URL/api/ai/transcribe" \
        -H "X-API-Key: $API_KEY" \
        -F "file=@$AUDIO_FILE" \
        -F "language=en" \
        -F "subtitle_format=srt" \
        -F "project_id=$PROJECT_ID" 2>/dev/null || echo '{"error":"failed"}')
    
    if echo "$RESPONSE" | grep -qE '"segments"|"subtitle"'; then
        pass "Transcription with subtitle works"
    else
        fail "Transcription with subtitle failed: $RESPONSE"
    fi
    rm -f "$AUDIO_FILE"
else
    skip "No API key or audio file"
fi

# Test 6: Transcribe Video
echo "  Testing: Transcribe Video File"
VIDEO_FILE=$(create_test_video 2)
if [ -f "$VIDEO_FILE" ] && [ -n "$API_KEY" ]; then
    RESPONSE=$(curl -s -X POST "$BASE_URL/api/ai/transcribe" \
        -H "X-API-Key: $API_KEY" \
        -F "file=@$VIDEO_FILE" \
        -F "language=en" \
        -F "project_id=$PROJECT_ID" 2>/dev/null || echo '{"error":"failed"}')
    
    if echo "$RESPONSE" | grep -qE '"is_video":true|"segments"'; then
        pass "Video transcription works"
    else
        fail "Video transcription failed: $RESPONSE"
    fi
    rm -f "$VIDEO_FILE"
else
    skip "No API key or video file"
fi

echo ""

# ==================== Async Transcription Tests ====================

echo "📋 Section: Async Transcription"
echo "----------------------------------------"

# Test 7: Queue Async Job
echo "  Testing: Queue Async Transcription"
AUDIO_FILE=$(create_test_audio 2)
JOB_ID=""
if [ -f "$AUDIO_FILE" ] && [ -n "$API_KEY" ]; then
    RESPONSE=$(curl -s -X POST "$BASE_URL/api/ai/transcribe-async" \
        -H "X-API-Key: $API_KEY" \
        -F "file=@$AUDIO_FILE" \
        -F "owner=test_user" \
        -F "project_id=$PROJECT_ID" \
        -F "language=en" 2>/dev/null || echo '{"error":"failed"}')
    
    if echo "$RESPONSE" | grep -q '"job_id"'; then
        JOB_ID=$(echo "$RESPONSE" | grep -o '"job_id":"[^"]*"' | cut -d'"' -f4)
        pass "Job queued: $JOB_ID"
    else
        fail "Async queue failed: $RESPONSE"
    fi
    rm -f "$AUDIO_FILE"
else
    skip "No API key or audio file"
fi

# Test 8: Queue with Options
echo "  Testing: Queue with Diarization"
AUDIO_FILE=$(create_test_audio 2)
if [ -f "$AUDIO_FILE" ] && [ -n "$API_KEY" ]; then
    RESPONSE=$(curl -s -X POST "$BASE_URL/api/ai/transcribe-async" \
        -H "X-API-Key: $API_KEY" \
        -F "file=@$AUDIO_FILE" \
        -F "owner=test_user" \
        -F "project_id=$PROJECT_ID" \
        -F "diarize=true" 2>/dev/null || echo '{"error":"failed"}')
    
    if echo "$RESPONSE" | grep -q '"job_id"'; then
        pass "Job with diarization queued"
    else
        fail "Queue with options failed: $RESPONSE"
    fi
    rm -f "$AUDIO_FILE"
else
    skip "No API key or audio file"
fi

echo ""

# ==================== Job Management Tests ====================

echo "📋 Section: Job Management"
echo "----------------------------------------"

# Test 9: List Jobs
echo "  Testing: List Jobs"
if [ -n "$API_KEY" ]; then
    RESPONSE=$(curl -s "$BASE_URL/api/jobs?owner=test_user&limit=10" \
        -H "X-API-Key: $API_KEY" 2>/dev/null || echo '{"error":"failed"}')
    
    if echo "$RESPONSE" | grep -q '"jobs"'; then
        pass "Jobs list returned"
        TOTAL=$(echo "$RESPONSE" | grep -o '"total":[0-9]*' | cut -d':' -f2)
        echo "      Total: ${TOTAL:-N/A}"
    else
        fail "List jobs failed: $RESPONSE"
    fi
else
    skip "No API key"
fi

# Test 10: Get Job Status
echo "  Testing: Get Job Status"
if [ -n "$JOB_ID" ] && [ -n "$API_KEY" ]; then
    RESPONSE=$(curl -s "$BASE_URL/api/jobs/$JOB_ID" \
        -H "X-API-Key: $API_KEY" 2>/dev/null || echo '{"error":"failed"}')
    
    if echo "$RESPONSE" | grep -qE '"status"|"progress"'; then
        pass "Job status returned"
        STATUS=$(echo "$RESPONSE" | grep -o '"status":"[^"]*"' | cut -d'"' -f4)
        PROGRESS=$(echo "$RESPONSE" | grep -o '"progress":[0-9]*' | cut -d':' -f2)
        echo "      Status: $STATUS, Progress: ${PROGRESS}%"
    else
        fail "Get job status failed: $RESPONSE"
    fi
else
    skip "No job ID or API key"
fi

# Test 11: Delete Job
echo "  Testing: Delete Job"
if [ -n "$JOB_ID" ] && [ -n "$API_KEY" ]; then
    RESPONSE=$(curl -s -X DELETE "$BASE_URL/api/jobs/$JOB_ID" \
        -H "X-API-Key: $API_KEY" 2>/dev/null || echo '{"error":"failed"}')
    
    if echo "$RESPONSE" | grep -qE '"message"|"success"|"deleted"'; then
        pass "Job deleted"
    else
        fail "Delete job failed: $RESPONSE"
    fi
else
    skip "No job ID or API key"
fi

echo ""

# ==================== Error Handling Tests ====================

echo "📋 Section: Error Handling"
echo "----------------------------------------"

# Test 12: Missing File
echo "  Testing: Missing File Error"
RESPONSE=$(curl -s -X POST "$BASE_URL/api/ai/transcribe" \
    -H "X-API-Key: ${API_KEY:-dummy}" \
    -H "Content-Type: application/json" \
    -d '{"language":"en"}' 2>/dev/null || echo '{"error":"failed"}')

if echo "$RESPONSE" | grep -qE '"error"|"detail"|422'; then
    pass "Missing file handled correctly"
else
    fail "Missing file not handled: $RESPONSE"
fi

# Test 13: Invalid Job ID
echo "  Testing: Invalid Job ID"
RESPONSE=$(curl -s "$BASE_URL/api/jobs/invalid_job_12345" \
    -H "X-API-Key: ${API_KEY:-dummy}" 2>/dev/null || echo '{"error":"failed"}')

# Should return 404 or error
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/api/jobs/invalid_job_12345" \
    -H "X-API-Key: ${API_KEY:-dummy}" 2>/dev/null || echo "0")

if [ "$HTTP_CODE" = "404" ] || echo "$RESPONSE" | grep -qE '"error"|"detail"'; then
    pass "Invalid job ID handled correctly (HTTP $HTTP_CODE)"
else
    fail "Invalid job ID not handled correctly"
fi

echo ""

# ==================== Summary ====================

echo "=================================================="
echo "📊 Test Summary"
echo "=================================================="
echo "  ✅ Passed:  $PASSED"
echo "  ❌ Failed:  $FAILED"
echo "  ⏭️  Skipped: $SKIPPED"
echo "  📈 Total:   $((PASSED + FAILED + SKIPPED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Some tests failed. Check the output above.${NC}"
    exit 1
fi
