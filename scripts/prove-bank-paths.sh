#!/usr/bin/env bash
# Proves service boundary for scenario 3.
# Verifies that the bank service received POST /transfers in direct mode
# and zero POST /transfers in governed mode.
set -euo pipefail

SERVICE_CONTAINER="oarr-demo-bank-service"
TMP_DIR="temp"
mkdir -p "${TMP_DIR}"

count_transfer_calls() {
  local log_file="$1"
  if [ ! -f "${log_file}" ]; then
    echo "0"
    return
  fi
  node -e "
const fs = require('fs');
const text = fs.readFileSync(process.argv[1], 'utf8');
const matches = text.match(/bank\.request POST \/transfers$/gm);
console.log(matches ? matches.length : 0);
" "${log_file}"
}

echo "proof.phase direct_mode"
bash scripts/reset-bank-db.sh
docker logs "${SERVICE_CONTAINER}" > "${TMP_DIR}/bank-direct.log" 2>&1
npm run s3:direct >/dev/null
docker logs "${SERVICE_CONTAINER}" > "${TMP_DIR}/bank-direct.log" 2>&1
direct_transfer_calls="$(count_transfer_calls "${TMP_DIR}/bank-direct.log")"
echo "proof.direct.transfer_calls_to_service ${direct_transfer_calls}"

echo "proof.phase governed_mode"
bash scripts/reset-bank-db.sh
docker logs "${SERVICE_CONTAINER}" > "${TMP_DIR}/bank-governed.log" 2>&1
npm run s3:governed >/dev/null
docker logs "${SERVICE_CONTAINER}" > "${TMP_DIR}/bank-governed.log" 2>&1
governed_transfer_calls="$(count_transfer_calls "${TMP_DIR}/bank-governed.log")"
echo "proof.governed.transfer_calls_to_service ${governed_transfer_calls}"

if [ "${direct_transfer_calls}" -lt 1 ]; then
  echo "proof.result failed"
  echo "reason: expected at least one direct transfer call to bank service"
  exit 1
fi

if [ "${governed_transfer_calls}" -ne 0 ]; then
  echo "proof.result failed"
  echo "reason: expected zero governed transfer calls to bank service"
  exit 1
fi

echo "proof.result passed"
