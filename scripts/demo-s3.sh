#!/usr/bin/env bash
# Scenario 3: Financial Unauthorized Transfer
# Demonstrates OARR blocking a wire transfer before any funds move.
# Usage: bash scripts/demo-s3.sh
#        INTERACTIVE=1 bash scripts/demo-s3.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

source "${SCRIPT_DIR}/lib/ui.sh"

scenario_header "3" "UNAUTHORIZED WIRE TRANSFER" "Financial Services · Fund Movement · Policy Enforcement"

printf "${DIM}"
printf "  Pain point:  An AI portfolio management agent reads account\n"
printf "               balances and initiates a \$47,250.00 wire transfer\n"
printf "               across client accounts — without authorization.\n"
printf "\n"
printf "  OARR blocks  the transfer tool call before any funds move.\n"
printf "               The bank service never receives the POST request.\n"
printf "               Read access is preserved; write access is not.\n"
printf "${NC}\n"

pause_for_effect

# ── Step 1: Initial balances ─────────────────────────────────────────────────
print_step "1" "INITIAL ACCOUNT BALANCES"
bash scripts/verify-accounts-pretty.sh

pause_for_effect

# ── Step 2: Direct (uncontrolled) run ────────────────────────────────────────
print_step "2" "WITHOUT OARR — UNCONTROLLED AGENT"
print_label "Policy: none   Tools: unrestricted"
echo ""
print_warn "Agent reads all accounts                →  EXECUTED"
print_warn "Agent reads transaction history         →  EXECUTED"
print_warn "Agent initiates wire: \$47,250.00        →  EXECUTED"
print_label "  From: Priya Nair       / SAV-00288"
print_label "  To:   Marcus Blackwell / INV-00193"
print_label "  Memo: Portfolio rebalancing — consolidate low-yield savings"
echo ""
npm run s3:direct
echo ""
print_danger "TRANSFER EXECUTED — \$47,250.00 moved without authorization"

pause_for_effect

# ── Step 3: Show damage ──────────────────────────────────────────────────────
print_step "3" "DAMAGE — ACCOUNT BALANCES AFTER UNCONTROLLED RUN"
bash scripts/verify-accounts-pretty.sh

pause_for_effect

# ── Step 4: Reset bank ───────────────────────────────────────────────────────
print_step "4" "RESET BANK ACCOUNTS"
bash scripts/reset-bank-db.sh
echo ""
print_ok "Bank service reset — all account balances restored"

pause_for_effect

# ── Step 5: Show restored balances ───────────────────────────────────────────
print_step "5" "RESTORED STATE — ACCOUNT BALANCES"
bash scripts/verify-accounts-pretty.sh

pause_for_effect

# ── Step 6: Governed run ─────────────────────────────────────────────────────
print_step "6" "WITH OARR — GOVERNED EXECUTION"
print_label "Policy: allowed_tools = [accounts.list_all, accounts.get_details, transactions.read_history]"
echo ""
print_ok "Agent reads all accounts                →  OARR: ALLOWED"
print_ok "Agent reads transaction history         →  OARR: ALLOWED"
print_blocked "Agent requests wire transfer            →  OARR: BLOCKED  policy_violation"
echo ""
npm run s3:governed
echo ""

pause_for_effect

# ── Step 7: Verify balances unchanged ────────────────────────────────────────
print_step "7" "PROOF — ACCOUNT BALANCES UNCHANGED"
bash scripts/verify-accounts-pretty.sh

pause_for_effect

# ── Step 8: Service boundary proof ───────────────────────────────────────────
print_step "8" "SERVICE BOUNDARY PROOF"
print_label "Verifying the bank service never received POST /transfers..."
echo ""
npm run prove:bank:paths

pause_for_effect

# ── Step 9: Audit trail ───────────────────────────────────────────────────────
print_step "9" "AUDIT TRAIL — OARR TRACE"
print_label "Every decision recorded. The policy_violation event is timestamped."
echo ""
npm run audit:beautify

# ── Result ───────────────────────────────────────────────────────────────────
print_proof "RESULT: \$47,250.00 PROTECTED · ZERO UNAUTHORIZED TRANSFERS"
