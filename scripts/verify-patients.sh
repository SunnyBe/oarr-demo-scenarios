#!/usr/bin/env bash
set -euo pipefail

CLINIC_BASE_URL="${CLINIC_BASE_URL:-http://localhost:3100}"

echo "verify.endpoint ${CLINIC_BASE_URL}/patients"
response="$(curl -sS "${CLINIC_BASE_URL}/patients")"
count="$(printf '%s' "${response}" | node -e "const fs=require('fs'); const input=fs.readFileSync(0,'utf8'); const json=JSON.parse(input); const count=Array.isArray(json.patients) ? json.patients.length : 0; console.log(count);")"

echo "verify.patient_count ${count}"
echo "${response}"
