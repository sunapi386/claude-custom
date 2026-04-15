#!/usr/bin/env bash
set -uo pipefail

SCRIPT="$(cd "$(dirname "$0")/.." && pwd)/claude-custom"

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
RESET=$'\033[0m'
PASS=0
FAIL=0

echo "=== Testing version ==="

VERSION_OUTPUT="$("$SCRIPT" --version)"
if echo "$VERSION_OUTPUT" | grep -q "claude-custom version"; then
  echo -e "${GREEN}PASS${RESET} --version outputs claude-custom version"
  PASS=$((PASS + 1))
else
  echo -e "${RED}FAIL${RESET} --version outputs claude-custom version"
  FAIL=$((FAIL + 1))
fi

if echo "$VERSION_OUTPUT" | grep -qE "[0-9]+\.[0-9]+\.[0-9]+"; then
  echo -e "${GREEN}PASS${RESET} --version outputs version number"
  PASS=$((PASS + 1))
else
  echo -e "${RED}FAIL${RESET} --version outputs version number"
  FAIL=$((FAIL + 1))
fi

echo
echo "Results: ${GREEN}$PASS passed${RESET} ${RED}$FAIL failed${RESET}"
[[ "$FAIL" -eq 0 ]]
