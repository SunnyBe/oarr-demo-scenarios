#!/usr/bin/env bash
set -euo pipefail

SERVICE_CONTAINER="oarr-demo-clinic-service"
TMP_DIR="temp"
mkdir -p "${TMP_DIR}"

count_delete_calls() {
  local log_file="$1"
  if [ ! -f "${log_file}" ]; then
    echo "0"
    return
  fi
  node -e "const fs=require('fs'); const text=fs.readFileSync(process.argv[1],'utf8'); const matches=text.match(/clinic\\.request DELETE \\/patients$/gm); console.log(matches ? matches.length : 0);" "${log_file}"
}

echo "proof.phase direct_mode"
bash scripts/reset-db.sh
docker logs "${SERVICE_CONTAINER}" > "${TMP_DIR}/clinic-direct.log" 2>&1
npm run scenario:direct >/dev/null
docker logs "${SERVICE_CONTAINER}" > "${TMP_DIR}/clinic-direct.log" 2>&1
direct_delete_calls="$(count_delete_calls "${TMP_DIR}/clinic-direct.log")"
echo "proof.direct.delete_calls_to_service ${direct_delete_calls}"

echo "proof.phase governed_mode"
bash scripts/reset-db.sh
docker logs "${SERVICE_CONTAINER}" > "${TMP_DIR}/clinic-governed.log" 2>&1
npm run scenario:governed >/dev/null
docker logs "${SERVICE_CONTAINER}" > "${TMP_DIR}/clinic-governed.log" 2>&1
governed_delete_calls="$(count_delete_calls "${TMP_DIR}/clinic-governed.log")"
echo "proof.governed.delete_calls_to_service ${governed_delete_calls}"

if [ "${direct_delete_calls}" -lt 1 ]; then
  echo "proof.result failed"
  echo "reason: expected at least one direct delete call to service"
  exit 1
fi

if [ "${governed_delete_calls}" -ne 0 ]; then
  echo "proof.result failed"
  echo "reason: expected zero governed delete calls to service"
  exit 1
fi

echo "proof.result passed"
