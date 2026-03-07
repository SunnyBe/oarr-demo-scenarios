#!/usr/bin/env bash
# Interactive demo: prompts "Continue? (Y/N)" before each step so results can sink in.
# Usage: npm run demo:interactive  or  BEAUTIFY=1 npm run demo:interactive

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

VERIFY_CMD="verify:patients"
[[ -n "${BEAUTIFY:-}" ]] && VERIFY_CMD="verify:patients:beautify"

prompt_and_run() {
  local desc="$1"
  local cmd="$2"
  echo ""
  echo "---"
  echo "Next: $desc"
  echo "Command: $cmd"
  read -r -p "Continue? (Enter=yes, N=stop): " reply || true
  case "${reply:-y}" in
    [nN]|[nN][oO]) echo "Stopped."; exit 0 ;;
    *) ;;
  esac
  eval "$cmd"
}

echo "=== OARR Demo: Interactive (paused between steps) ==="

prompt_and_run "Reset database" "bash scripts/reset-db.sh"
prompt_and_run "Verify seeded patients" "npm run $VERIFY_CMD"
prompt_and_run "Run direct unsafe scenario" "npm run scenario:direct"
prompt_and_run "Verify wipe occurred" "npm run $VERIFY_CMD"
prompt_and_run "Reset database" "bash scripts/reset-db.sh"
prompt_and_run "Verify reseed" "npm run $VERIFY_CMD"
prompt_and_run "Run governed scenario" "npm run scenario:governed"
prompt_and_run "Verify data survived" "npm run $VERIFY_CMD"
prompt_and_run "Service boundary proof" "npm run prove:paths"

echo ""
echo "=== Demo complete ==="
