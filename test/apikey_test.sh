#!/bin/bash
# Jam Server SDK - API Key Authentication Test
# Tests all major features using API Key

set -e

# Configuration
BASE_URL="https://api.jamteches.com"
API_KEY="jam_pk_test_ohgryrye0xl4m10p5ztfxv"
PROJECT_ID="692d79007214ae6e80e63d7a"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PASSED=0
FAILED=0

header() {
    echo ""
    echo -e "${BLUE}════════════════════════════════════════${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}════════════════════════════════════════${NC}"
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
    echo -e "   ${CYAN}ℹ️ ${NC} $1"
}

# ==========================================
header "🔐 Testing API Key Authentication"
# ==========================================

echo "📋 API Key: ${API_KEY:0:20}..."
echo "📁 Project: $PROJECT_ID"
echo ""

# Test 1: Health Check (no auth needed)
echo "🏥 Test 1: Health Check"
HEALTH=$(curl -s "$BASE_URL/health")
if echo "$HEALTH" | grep -q '"status":"ok"'; then
    pass "Health check OK"
else
    fail "Health check failed"
fi

# Test 2: AI Health
echo ""
echo "🤖 Test 2: AI Health"
AI_HEALTH=$(curl -s "$BASE_URL/api/ai/health")
if echo "$AI_HEALTH" | grep -q '"status":"ok"'; then
    pass "AI Health OK"
    MODEL=$(echo "$AI_HEALTH" | jq -r '.ollama.model // "N/A"')
    info "Model: $MODEL"
else
    fail "AI Health failed"
fi

# Test 3: List Projects with API Key
echo ""
echo "📂 Test 3: List Projects (API Key Auth)"
PROJECTS=$(curl -s "$BASE_URL/api/projects" -H "X-API-Key: $API_KEY")
if echo "$PROJECTS" | grep -q '"id"'; then
    pass "API Key authentication works"
    PROJECT_NAME=$(echo "$PROJECTS" | jq -r '.[0].name // "N/A"')
    info "Project: $PROJECT_NAME"
else
    fail "API Key authentication failed"
    echo "   Response: $PROJECTS"
fi

# Test 4: Create Document
echo ""
echo "📝 Test 4: Create Document"
TIMESTAMP=$(date +%s)
CREATE_RESP=$(curl -s -X POST "$BASE_URL/api/db/sdk_apikey_test" \
    -H "X-API-Key: $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{\"project_id\":\"$PROJECT_ID\",\"test_name\":\"API Key Test\",\"created_at\":$TIMESTAMP}")

if echo "$CREATE_RESP" | grep -q '"id"'; then
    pass "Document created"
    DOC_ID=$(echo "$CREATE_RESP" | jq -r '.id // .data.id // "N/A"')
    info "Document ID: $DOC_ID"
else
    fail "Create document failed"
    echo "   Response: $CREATE_RESP"
fi

# Test 5: List Documents
echo ""
echo "📋 Test 5: List Documents"
LIST_RESP=$(curl -s "$BASE_URL/api/db/sdk_apikey_test?project_id=$PROJECT_ID" \
    -H "X-API-Key: $API_KEY")

if echo "$LIST_RESP" | grep -q '"data"'; then
    pass "List documents successful"
    TOTAL=$(echo "$LIST_RESP" | jq -r '.total // 0')
    info "Total documents: $TOTAL"
else
    fail "List documents failed"
fi

# Test 6: Get specific document
if [ -n "$DOC_ID" ] && [ "$DOC_ID" != "N/A" ]; then
    echo ""
    echo "🔍 Test 6: Get Document"
    GET_RESP=$(curl -s "$BASE_URL/api/db/sdk_apikey_test/$DOC_ID?project_id=$PROJECT_ID" \
        -H "X-API-Key: $API_KEY")
    
    if echo "$GET_RESP" | grep -q 'test_name\|API Key Test'; then
        pass "Get document successful"
    else
        fail "Get document failed"
        echo "   Response: $GET_RESP"
    fi
fi

# Test 7: Update Document
if [ -n "$DOC_ID" ] && [ "$DOC_ID" != "N/A" ]; then
    echo ""
    echo "✏️ Test 7: Update Document"
    UPDATE_RESP=$(curl -s -X PATCH "$BASE_URL/api/db/sdk_apikey_test/$DOC_ID?project_id=$PROJECT_ID" \
        -H "X-API-Key: $API_KEY" \
        -H "Content-Type: application/json" \
        -d '{"updated":true,"update_time":'$(date +%s)'}')
    
    if echo "$UPDATE_RESP" | grep -q '"message"\|"updated":true\|success'; then
        pass "Update document successful"
    else
        fail "Update document failed"
        echo "   Response: $UPDATE_RESP"
    fi
fi

# Test 8: Delete Document
if [ -n "$DOC_ID" ] && [ "$DOC_ID" != "N/A" ]; then
    echo ""
    echo "🗑️ Test 8: Delete Document"
    DELETE_RESP=$(curl -s -X DELETE "$BASE_URL/api/db/sdk_apikey_test/$DOC_ID?project_id=$PROJECT_ID" \
        -H "X-API-Key: $API_KEY")
    
    if echo "$DELETE_RESP" | grep -q '"message"\|deleted\|success'; then
        pass "Delete document successful"
    else
        fail "Delete document failed"
        echo "   Response: $DELETE_RESP"
    fi
fi

# Test 9: Invalid API Key
echo ""
echo "🚫 Test 9: Invalid API Key (should fail)"
INVALID_RESP=$(curl -s "$BASE_URL/api/projects" -H "X-API-Key: invalid_key_12345")
if echo "$INVALID_RESP" | grep -qi "invalid\|unauthorized\|error"; then
    pass "Invalid API Key correctly rejected"
else
    fail "Invalid API Key was not rejected"
    echo "   Response: $INVALID_RESP"
fi

# Test 10: Test without API Key on protected route
echo ""
echo "🔒 Test 10: Protected route without auth (should fail)"
NO_AUTH_RESP=$(curl -s "$BASE_URL/api/projects")
if echo "$NO_AUTH_RESP" | grep -qi "unauthorized\|auth\|token"; then
    pass "Protected route requires authentication"
else
    fail "Protected route accessible without auth"
    echo "   Response: $NO_AUTH_RESP"
fi

# ==========================================
header "📊 Test Summary"
# ==========================================

echo ""
echo -e "   ${GREEN}✅ Passed:${NC} $PASSED"
echo -e "   ${RED}❌ Failed:${NC} $FAILED"
echo -e "   📈 Total:  $((PASSED + FAILED))"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}🎉 All API Key tests passed!${NC}"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some tests failed. Check the output above.${NC}"
    exit 1
fi
