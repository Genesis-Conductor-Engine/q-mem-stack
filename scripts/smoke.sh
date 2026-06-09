#!/bin/bash
# scripts/smoke.sh
# Automated Smoke Test for Genesis Conductor
# Verifies Fail-Closed Logic & Route Protection

BASE_URL="http://localhost:3000"
INTERNAL_YENNEFER="http://localhost:5000"
COLOR_GREEN='\033[0;32m'
COLOR_RED='\033[0;31m'
NC='\033[0m' # No Color

echo "════════════════════════════════════════════════════════════"
echo "  GENESIS CONDUCTOR - SMOKE TEST"
echo "  Target: $BASE_URL"
echo "════════════════════════════════════════════════════════════"

fail() {
  echo -e "${COLOR_RED}[FAIL] $1${NC}"
  exit 1
}

pass() {
  echo -e "${COLOR_GREEN}[PASS] $1${NC}"
}

# 1. Check if App is Running
echo "1. Checking System Availability..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL")
if [ "$HTTP_CODE" -eq 200 ] || [ "$HTTP_CODE" -eq 307 ]; then
  pass "System is reachable (Status: $HTTP_CODE)"
else
  fail "System unreachable (Status: $HTTP_CODE)"
fi

# 2. Assert Fail-Closed on Protected Routes (No Session)
echo "2. Verifying Fail-Closed (Unauthenticated Access)..."
PROTECTED_ROUTES=("/yennefer" "/wvs-pilot-b" "/api/proxy/yennefer/status")

for route in "${PROTECTED_ROUTES[@]}"; do
  # We expect a redirect (307) to login or a 401/403 depending on your middleware config
  # For this specific stack, Middleware redirects to /login on page loads
  CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL$route")

  if [ "$CODE" -eq 307 ] || [ "$CODE" -eq 401 ] || [ "$CODE" -eq 403 ]; then
    pass "Protected route $route rejected access (Status: $CODE)"
  else
    fail "Protected route $route EXPOSED to unauthenticated user (Status: $CODE)"
  fi
done

# 3. Verify Login Page is Public
echo "3. Verifying Login Page Accessibility..."
CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE_URL/login")
if [ "$CODE" -eq 200 ]; then
  pass "Login page accessible"
else
  fail "Login page unreachable (Status: $CODE)"
fi

# 4. Proxy Isolation Check (Can we bypass the proxy?)
# This test assumes the script is running on the server itself.
# It checks if the internal port is listening but clarifies it should NOT be exposed publicly.
echo "4. Internal Service Health (Localhost Check)..."
# We assert that the internal service is running, but rely on firewall rules for external blocking.
if lsof -i:5000 > /dev/null; then
  pass "Yennefer Agent active on port 5000 (Internal)"
else
  echo -e "${COLOR_RED}[WARN] Yennefer Agent (Port 5000) not detected locally.${NC}"
fi

echo "════════════════════════════════════════════════════════════"
echo "  SMOKE TEST COMPLETE"
echo "════════════════════════════════════════════════════════════"
