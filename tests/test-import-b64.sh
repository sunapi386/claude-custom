#!/usr/bin/env bash
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/claude-custom"
TEST_DIR="${TMPDIR:-/tmp}/claude-custom-test-$$"
export XDG_CONFIG_HOME="$TEST_DIR"
PROFILE_DIR="$XDG_CONFIG_HOME/claude-custom/profiles"

cleanup() {
  rm -rf "$TEST_DIR"
}
trap cleanup EXIT

mkdir -p "$PROFILE_DIR"

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
RESET=$'\033[0m'
PASS=0
FAIL=0

echo "=== Testing --import-b64 ==="

PROFILE_NAME="testb64"
BASE_URL="https://open.palebluedot.ai"
AUTH_TOKEN="sk-r5Tn2MYEAOXnFtfPqPBqdkVMTshb6mTU5BLJMFdENnIlNQVF"
MODELS="z-ai/glm-5,z-ai/glm-5-turbo"
DEFAULT_MODEL="z-ai/glm-5"
SMALL_FAST_MODEL="z-ai/glm-5"

"$SCRIPT" --import-b64 "$PROFILE_NAME" \
  "BASE_URL=$(printf '%s' "$BASE_URL" | base64)" \
  "AUTH_TOKEN=$(printf '%s' "$AUTH_TOKEN" | base64)" \
  "MODELS=$(printf '%s' "$MODELS" | base64)" \
  "DEFAULT_MODEL=$(printf '%s' "$DEFAULT_MODEL" | base64)" \
  "SMALL_FAST_MODEL=$(printf '%s' "$SMALL_FAST_MODEL" | base64)" || true

if [[ -f "$PROFILE_DIR/$PROFILE_NAME.env" ]]; then
  echo -e "${GREEN}PASS${RESET} profile file created"
  PASS=$((PASS + 1))
else
  echo -e "${RED}FAIL${RESET} profile file created"
  FAIL=$((FAIL + 1))
fi

if grep -q "BASE_URL=$BASE_URL" "$PROFILE_DIR/$PROFILE_NAME.env"; then
  echo -e "${GREEN}PASS${RESET} BASE_URL correct"
  PASS=$((PASS + 1))
else
  echo -e "${RED}FAIL${RESET} BASE_URL correct"
  FAIL=$((FAIL + 1))
fi

if grep -q "AUTH_TOKEN=$AUTH_TOKEN" "$PROFILE_DIR/$PROFILE_NAME.env"; then
  echo -e "${GREEN}PASS${RESET} AUTH_TOKEN correct"
  PASS=$((PASS + 1))
else
  echo -e "${RED}FAIL${RESET} AUTH_TOKEN correct"
  FAIL=$((FAIL + 1))
fi

if grep -q "MODELS=$MODELS" "$PROFILE_DIR/$PROFILE_NAME.env"; then
  echo -e "${GREEN}PASS${RESET} MODELS correct"
  PASS=$((PASS + 1))
else
  echo -e "${RED}FAIL${RESET} MODELS correct"
  FAIL=$((FAIL + 1))
fi

echo
echo "=== Testing --share-b64 ==="

SHARE_OUTPUT="$("$SCRIPT" --share-b64 "$PROFILE_NAME")"
if echo "$SHARE_OUTPUT" | grep -q "\-\-import-b64"; then
  echo -e "${GREEN}PASS${RESET} share-b64 outputs --import-b64 command"
  PASS=$((PASS + 1))
else
  echo -e "${RED}FAIL${RESET} share-b64 outputs --import-b64 command"
  FAIL=$((FAIL + 1))
fi

# Re-import from share-b64 output to verify round-trip
"$SCRIPT" --import-b64 roundtrip-test \
  BASE_URL="$(printf '%s' "$BASE_URL" | base64)" \
  AUTH_TOKEN="$(printf '%s' "$AUTH_TOKEN" | base64)" \
  MODELS="$(printf '%s' "$MODELS" | base64)" \
  DEFAULT_MODEL="$(printf '%s' "$DEFAULT_MODEL" | base64)" \
  SMALL_FAST_MODEL="$(printf '%s' "$SMALL_FAST_MODEL" | base64)" || true

if [[ -f "$PROFILE_DIR/roundtrip-test.env" ]]; then
  echo -e "${GREEN}PASS${RESET} round-trip profile created"
  PASS=$((PASS + 1))
else
  echo -e "${RED}FAIL${RESET} round-trip profile created"
  FAIL=$((FAIL + 1))
fi

if grep -q "BASE_URL=$BASE_URL" "$PROFILE_DIR/roundtrip-test.env"; then
  echo -e "${GREEN}PASS${RESET} round-trip BASE_URL matches"
  PASS=$((PASS + 1))
else
  echo -e "${RED}FAIL${RESET} round-trip BASE_URL matches"
  FAIL=$((FAIL + 1))
fi

if grep -q "AUTH_TOKEN=$AUTH_TOKEN" "$PROFILE_DIR/roundtrip-test.env"; then
  echo -e "${GREEN}PASS${RESET} round-trip AUTH_TOKEN matches"
  PASS=$((PASS + 1))
else
  echo -e "${RED}FAIL${RESET} round-trip AUTH_TOKEN matches"
  FAIL=$((FAIL + 1))
fi

echo
echo "Results: ${GREEN}$PASS passed${RESET} ${RED}$FAIL failed${RESET}"
[[ "$FAIL" -eq 0 ]]
