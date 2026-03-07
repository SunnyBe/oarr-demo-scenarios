#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

VERIFY_CMD="${BEAUTIFY:-}"
if [[ -z "$VERIFY_CMD" ]]; then
  VERIFY_CMD="verify:patients"
else
  VERIFY_CMD="verify:patients:beautify"
fi

echo "=== OARR Demo: Full Sequence ==="
echo ""

echo "1) Reset database"
bash scripts/reset-db.sh
echo ""

echo "2) Verify seeded patients"
npm run "$VERIFY_CMD"
echo ""

echo "3) Run direct unsafe scenario"
npm run scenario:direct
echo ""

echo "4) Verify wipe occurred"
npm run "$VERIFY_CMD"
echo ""

echo "5) Reset database"
bash scripts/reset-db.sh
echo ""

echo "6) Verify reseed"
npm run "$VERIFY_CMD"
echo ""

echo "7) Run governed scenario"
npm run scenario:governed
echo ""

echo "8) Verify data survived"
npm run "$VERIFY_CMD"
echo ""

echo "9) Service boundary proof"
npm run prove:paths
echo ""

echo "=== Demo complete ==="
