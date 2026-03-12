#!/usr/bin/env bash
# Scenario 1: Healthcare Data Wipe
# Demonstrates OARR blocking a bulk-delete tool call before it reaches the service.
# Usage: bash scripts/demo-s1.sh
#        INTERACTIVE=1 bash scripts/demo-s1.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

source "${SCRIPT_DIR}/lib/ui.sh"

scenario_header "1" "HEALTHCARE DATA WIPE" "Healthcare · Bulk Deletion · Policy Enforcement"

printf "${DIM}"
printf "  Pain point:  An AI agent with access to a healthcare system can\n"
printf "               delete all patient records with a single tool call.\n"
printf "\n"
printf "  OARR blocks  the delete action before the request reaches the\n"
printf "               service — no data is touched, no rollback needed.\n"
printf "${NC}\n"

pause_for_effect

# ── Step 1: Reset ────────────────────────────────────────────────────────────
print_step "1" "RESET DATABASE"
bash scripts/reset-db.sh
echo ""
print_ok "Database reset — 5 patient records seeded"

pause_for_effect

# ── Step 2: Show initial state ───────────────────────────────────────────────
print_step "2" "INITIAL STATE — PATIENT RECORDS"
bash scripts/verify-patients-pretty.sh

pause_for_effect

# ── Step 3: Direct (uncontrolled) run ────────────────────────────────────────
print_step "3" "WITHOUT OARR — UNCONTROLLED AGENT"
print_label "Policy: none   Tools: unrestricted"
echo ""
print_warn "Agent requests:  db.read_patients"
print_warn "Agent requests:  db.delete_all_patients"
print_warn "Direct API call: DELETE /patients"
echo ""
npm run scenario:direct
echo ""
print_danger "WIPE EXECUTED — All patient records deleted"

pause_for_effect

# ── Step 4: Verify damage ────────────────────────────────────────────────────
print_step "4" "DAMAGE — PATIENT RECORDS AFTER UNCONTROLLED RUN"
bash scripts/verify-patients-pretty.sh

pause_for_effect

# ── Step 5: Reset ────────────────────────────────────────────────────────────
print_step "5" "RESET DATABASE"
bash scripts/reset-db.sh
echo ""
print_ok "Database reset — 5 patient records restored"

pause_for_effect

# ── Step 6: Show restored state ──────────────────────────────────────────────
print_step "6" "RESTORED STATE — PATIENT RECORDS"
bash scripts/verify-patients-pretty.sh

pause_for_effect

# ── Step 7: Governed run ─────────────────────────────────────────────────────
print_step "7" "WITH OARR — GOVERNED EXECUTION"
print_label "Policy: allowed_tools = [db.read_patients]   max_tool_calls = 12"
echo ""
print_ok "Agent reads patient records      →  OARR: ALLOWED"
print_blocked "Agent requests bulk delete       →  OARR: BLOCKED  policy_violation"
echo ""
npm run scenario:governed
echo ""

pause_for_effect

# ── Step 8: Verify data survived ─────────────────────────────────────────────
print_step "8" "PROOF — ALL PATIENT RECORDS SURVIVED"
bash scripts/verify-patients-pretty.sh

pause_for_effect

# ── Step 9: Service boundary proof ───────────────────────────────────────────
print_step "9" "SERVICE BOUNDARY PROOF"
print_label "Counting DELETE /patients calls in clinic-service logs..."
echo ""
npm run prove:paths

pause_for_effect

# ── Step 10: Audit trail ─────────────────────────────────────────────────────
print_step "10" "AUDIT TRAIL — OARR TRACE"
print_label "Every decision recorded. Every action accounted for."
echo ""
npm run audit:beautify

# ── Result ───────────────────────────────────────────────────────────────────
print_proof "RESULT: 5 PATIENT RECORDS PROTECTED · 0 DATA LOSS"
