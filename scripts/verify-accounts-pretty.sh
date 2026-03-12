#!/usr/bin/env bash
set -euo pipefail

BANK_BASE_URL="${BANK_BASE_URL:-http://localhost:3101}"

response="$(curl -sS "${BANK_BASE_URL}/accounts")"

printf '%s' "${response}" | node -e "
const fs = require('fs');
const input = fs.readFileSync(0, 'utf8');
const json = JSON.parse(input);
const accounts = Array.isArray(json.accounts) ? json.accounts : [];

console.log('verify.account_count', accounts.length);
if (accounts.length === 0) {
  console.log('');
  console.log('No accounts found.');
  process.exit(0);
}

const rows = accounts.map((a) => ({
  id:          a.id,
  holder:      a.holder,
  account_num: a.account_num,
  type:        a.type,
  balance:     '\$' + Number(a.balance).toLocaleString('en-US', { minimumFractionDigits: 2 })
}));

console.log('');
console.table(rows);
"
