#!/bin/bash
# Jam Server Flutter SDK - API Test Script
# Tests all major API endpoints

set -e

BASE_URL="${JAM_API_URL:-https://api.jamteches.com}"
TOKEN=""
PROJECT_ID=""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

PASSED=0
FAILED=0

print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

pass() {
    echo -e "   ${GREEN}✅ PASS:${NC} $1"
    ((PASSED++))
}

fail() {
    echo -e "   ${RED}❌ FAIL:${NC} $1"
    ((FAILED++))
}

info() {
    echo -e "   ${YELLOW}ℹ️  INFO:${NC} $1"
}

# ====================
# PUBLIC ENDPOINTS
# ====================

print_header "🏥 Testing Public Endpoints"

echo "📋 Test: Health Check"
HEALTH=$(curl -s "$BASE_URL/health")
if echo "$HEALTH" | grep -q '"status":"ok"'; then
    pass "Health check returned ok"
    echo "   Response: $HEALTH"
else
    fail "Health check failed"
    echo "   Response: $HEALTH"
fi

echo ""
echo "🤖 Test: AI Health Check"
AI_HEALTH=$(curl -s "$BASE_URL/api/ai/health")
if echo "$AI_HEALTH" | grep -q '"status":"ok"'; then
    pass "AI Health check returned ok"
    echo "$AI_HEALTH" | jq -r '.ollama.model // "N/A"' | while read model; do
        info "Ollama Model: $model"
    done
else
    fail "AI Health check failed"
    echo "   Response: $AI_HEALTH"
fi

echo ""
echo "⚡ Test: GPU Queue Status (via Python service)"
GPU_STATUS=$(curl -s "http://localhost:8001/gpu-queue/status" 2>/dev/null || echo '{"error":"not reachable"}')
if echo "$GPU_STATUS" | grep -q '"queue_length"'; then
    pass "GPU Queue Status accessible"
    QUEUE_LEN=$(echo "$GPU_STATUS" | jq -r '.queue_length')
    IS_PROCESSING=$(echo "$GPU_STATUS" | jq -r '.is_processing')
    info "Queue Length: $QUEUE_LEN, Processing: $IS_PROCESSING"
else
    info "Local GPU Queue not reachable (expected if testing remotely)"
fi

# ====================
# AUTH ENDPOINTS
# ====================

print_header "🔐 Testing Authentication"

# Test with provided credentials or skip
if [ -n "$JAM_USERNAME" ] && [ -n "$JAM_PASSWORD" ]; then
    echo "📝 Test: Login"
    LOGIN_RESPONSE=$(curl -s -X POST "$BASE_URL/api/login" \
        -H "Content-Type: application/json" \
        -d "{\"username\":\"$JAM_USERNAME\",\"password\":\"$JAM_PASSWORD\"}")
    
    if echo "$LOGIN_RESPONSE" | grep -q '"token"'; then
        pass "Login successful"
        TOKEN=$(echo "$LOGIN_RESPONSE" | jq -r '.token')
        USERNAME=$(echo "$LOGIN_RESPONSE" | jq -r '.username')
        ROLE=$(echo "$LOGIN_RESPONSE" | jq -r '.role')
        info "Logged in as: $USERNAME (role: $ROLE)"
    else
        fail "Login failed"
        echo "   Response: $LOGIN_RESPONSE"
    fi
else
    info "Skipping auth tests (set JAM_USERNAME and JAM_PASSWORD to test)"
fi

# ====================
# PROTECTED ENDPOINTS (if logged in)
# ====================

if [ -n "$TOKEN" ]; then
    print_header "📦 Testing Protected Endpoints"
    
    # Test Projects List
    echo "📁 Test: List Projects"
    PROJECTS=$(curl -s "$BASE_URL/api/projects" \
        -H "Authorization: Bearer $TOKEN")
    
    if echo "$PROJECTS" | grep -q '\['; then
        pass "List projects successful"
        PROJECT_COUNT=$(echo "$PROJECTS" | jq 'length')
        info "Found $PROJECT_COUNT projects"
        
        # Get first project ID if available
        if [ "$PROJECT_COUNT" -gt 0 ]; then
            PROJECT_ID=$(echo "$PROJECTS" | jq -r '.[0].id')
            PROJECT_NAME=$(echo "$PROJECTS" | jq -r '.[0].name')
            info "Using project: $PROJECT_NAME ($PROJECT_ID)"
        fi
    else
        fail "List projects failed"
        echo "   Response: $PROJECTS"
    fi
    
    # Test AI Chat (if have project)
    if [ -n "$PROJECT_ID" ]; then
        echo ""
        echo "💬 Test: AI Chat"
        CHAT_RESPONSE=$(curl -s -X POST "$BASE_URL/api/ai/chat" \
            -H "Authorization: Bearer $TOKEN" \
            -H "Content-Type: application/json" \
            -d "{\"project_id\":\"$PROJECT_ID\",\"message\":\"Hello, this is a test.\",\"stream\":false}" \
            --max-time 120)
        
        if echo "$CHAT_RESPONSE" | grep -q '"response"'; then
            pass "AI Chat successful"
            RESPONSE_TEXT=$(echo "$CHAT_RESPONSE" | jq -r '.response' | head -c 100)
            info "Response: $RESPONSE_TEXT..."
        elif echo "$CHAT_RESPONSE" | grep -q 'error\|Error'; then
            fail "AI Chat failed"
            echo "   Response: $CHAT_RESPONSE"
        else
            info "AI Chat returned unexpected format"
            echo "   Response: $CHAT_RESPONSE"
        fi
    fi
    
    # Test Database
    echo ""
    echo "🗄️ Test: Database Collection"
    if [ -n "$PROJECT_ID" ]; then
        DB_RESPONSE=$(curl -s "$BASE_URL/api/db/sdk_test?project_id=$PROJECT_ID&limit=5" \
            -H "Authorization: Bearer $TOKEN")
        
        if echo "$DB_RESPONSE" | grep -q '"data"\|"total"'; then
            pass "Database query successful"
            TOTAL=$(echo "$DB_RESPONSE" | jq -r '.total // 0')
            info "Collection 'sdk_test' has $TOTAL documents"
        else
            info "Database query returned: $(echo "$DB_RESPONSE" | head -c 100)"
        fi
    fi
fi

# ====================
# SUMMARY
# ====================

print_header "📊 Test Summary"
echo ""
echo -e "   ${GREEN}✅ Passed:${NC} $PASSED"
echo -e "   ${RED}❌ Failed:${NC} $FAILED"
echo -e "   📈 Total:  $((PASSED + FAILED))"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}🎉 All tests passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some tests failed. Check the output above.${NC}"
    exit 1
fi
