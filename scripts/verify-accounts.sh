#!/usr/bin/env bash
set -euo pipefail

BANK_BASE_URL="${BANK_BASE_URL:-http://localhost:3101}"

echo "verify.endpoint ${BANK_BASE_URL}/accounts"
response="$(curl -sS "${BANK_BASE_URL}/accounts")"
count="$(printf '%s' "${response}" | node -e "
const fs = require('fs');
const input = fs.readFileSync(0, 'utf8');
const json = JSON.parse(input);
const count = Array.isArray(json.accounts) ? json.accounts.length : 0;
console.log(count);
")"

echo "verify.account_count ${count}"
echo "${response}"
