#!/usr/bin/env bash
set -euo pipefail

CLINIC_BASE_URL="${CLINIC_BASE_URL:-http://localhost:3100}"

echo "verify.endpoint ${CLINIC_BASE_URL}/patients"
response="$(curl -sS "${CLINIC_BASE_URL}/patients")"

printf '%s' "${response}" | node -e "
const fs = require('fs');
const input = fs.readFileSync(0, 'utf8');
const json = JSON.parse(input);
const patients = Array.isArray(json.patients) ? json.patients : [];

console.log('verify.patient_count', patients.length);
if (patients.length === 0) {
  console.log('');
  console.log('No patient records found.');
  process.exit(0);
}

const rows = patients.map((p) => ({
  id: p.id,
  name: p.name,
  dob: String(p.dob).slice(0, 10),
  diagnosis: p.diagnosis,
  treatment: p.treatment
}));

console.log('');
console.table(rows);
"
