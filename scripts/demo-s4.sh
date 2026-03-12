#!/usr/bin/env bash
# Scenario 4: Multi-Agent Medical Claims Pipeline
# Demonstrates OARR governing cross-domain agent coordination.
# Two agents run in sequence; the second is blocked from initiating a wire transfer.
# Usage: bash scripts/demo-s4.sh
#        INTERACTIVE=1 bash scripts/demo-s4.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

source "${SCRIPT_DIR}/lib/ui.sh"

scenario_header "4" "MULTI-AGENT CLAIMS PIPELINE" "Healthcare + Finance · Agent Coordination · Cross-Domain Governance"

printf "${DIM}"
printf "  Pain point:  A hospital deploys a two-agent pipeline to automate\n"
printf "               insurance claims. Agent 1 reads patient records.\n"
printf "               Agent 2 processes billing by initiating a wire\n"
printf "               transfer. Without governance, the pipeline executes\n"
printf "               end-to-end — including the unauthorized transfer.\n"
printf "\n"
printf "  OARR governs EACH agent independently. Read actions pass through.\n"
printf "               The billing transfer is blocked at Step 2 before the\n"
printf "               bank service receives any request.\n"
printf "\n"
printf "  This is where governance matters most: coordinated agents can\n"
printf "               chain dangerous actions across domain boundaries.\n"
printf "${NC}\n"

pause_for_effect

# ── Step 1: Initial state ─────────────────────────────────────────────────────
print_step "1" "INITIAL STATE"
echo ""
print_section "Healthcare: Patient Records"
bash scripts/verify-patients-pretty.sh
echo ""
print_section "Finance: Account Balances"
bash scripts/verify-accounts-pretty.sh

pause_for_effect

# ── Step 2: Direct (uncontrolled) pipeline ───────────────────────────────────
print_step "2" "WITHOUT OARR — PIPELINE RUNS UNCONTROLLED"
print_label "Policy: none   Both agents: unrestricted"
echo ""
print_warn "Step 1/2  patient-records-agent reads clinic records    →  EXECUTED"
print_warn "Step 2/2  claims-billing-agent reads account balances   →  EXECUTED"
print_warn "Step 2/2  claims-billing-agent initiates wire transfer  →  EXECUTED"
print_label "          From: Priya Nair / CHK-00287  →  To: Firm Operations / OPS-00401"
print_label "          Memo: Insurance claims batch — 5 patients, \$350.00 each"
echo ""
npm run s4:direct
echo ""
print_danger "PIPELINE EXECUTED — \$1,750.00 billing transfer completed without authorization"

pause_for_effect

# ── Step 3: Show damage ──────────────────────────────────────────────────────
print_step "3" "DAMAGE — ACCOUNT BALANCES AFTER UNCONTROLLED PIPELINE"
bash scripts/verify-accounts-pretty.sh

pause_for_effect

# ── Step 4: Reset ────────────────────────────────────────────────────────────
print_step "4" "RESET ALL SERVICES"
bash scripts/reset-all.sh
echo ""
print_ok "All services reset — clinic and bank data restored"

pause_for_effect

# ── Step 5: Show restored state ──────────────────────────────────────────────
print_step "5" "RESTORED STATE — PATIENTS AND ACCOUNTS"
echo ""
print_section "Healthcare: Patient Records"
bash scripts/verify-patients-pretty.sh
echo ""
print_section "Finance: Account Balances"
bash scripts/verify-accounts-pretty.sh

pause_for_effect

# ── Step 6: Governed pipeline ────────────────────────────────────────────────
print_step "6" "WITH OARR — GOVERNED PIPELINE EXECUTION"
print_label "Step 1 policy: allowed_tools = [db.read_patients]   max_tool_calls = 5"
print_label "Step 2 policy: allowed_tools = [accounts.list_all, transactions.read_history]"
echo ""
print_ok "Step 1/2  patient-records-agent reads clinic records    →  OARR: ALLOWED"
print_ok "Step 2/2  claims-billing-agent reads account balances   →  OARR: ALLOWED"
print_ok "Step 2/2  claims-billing-agent reads transactions       →  OARR: ALLOWED"
print_blocked "Step 2/2  claims-billing-agent requests wire transfer   →  OARR: BLOCKED  policy_violation"
echo ""
npm run s4:governed
echo ""

pause_for_effect

# ── Step 7: Verify data unchanged ────────────────────────────────────────────
print_step "7" "PROOF — ALL DATA UNCHANGED AFTER GOVERNED PIPELINE"
echo ""
print_section "Healthcare: Patient Records"
bash scripts/verify-patients-pretty.sh
echo ""
print_section "Finance: Account Balances"
bash scripts/verify-accounts-pretty.sh

pause_for_effect

# ── Step 8: Audit trail ───────────────────────────────────────────────────────
print_step "8" "AUDIT TRAIL — OARR TRACE (BOTH PIPELINE STEPS)"
print_label "Step 1 and Step 2 traces are stored independently in .oarr/traces.db"
echo ""
npm run audit:beautify

# ── Result ───────────────────────────────────────────────────────────────────
print_proof "RESULT: \$1,750.00 PROTECTED · PIPELINE BLOCKED AT BILLING STEP"
