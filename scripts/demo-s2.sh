#!/usr/bin/env bash
# Scenario 2: Healthcare Audit Loop (Runaway Tool Budget)
# Demonstrates OARR enforcing max_tool_calls before API budget is exhausted.
# Usage: bash scripts/demo-s2.sh
#        INTERACTIVE=1 bash scripts/demo-s2.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

source "${SCRIPT_DIR}/lib/ui.sh"

scenario_header "2" "HEALTHCARE AUDIT LOOP" "Healthcare · Runaway Agent · Budget Enforcement"

printf "${DIM}"
printf "  Pain point:  A compliance audit agent spirals into repeated tool\n"
printf "               calls — re-reading the same records to 'verify' and\n"
printf "               'cross-reference'. In production, each call costs API\n"
printf "               tokens and database resources.\n"
printf "\n"
printf "  OARR stops   the agent at call #4 via max_tool_calls policy,\n"
printf "               preventing 5 unnecessary calls and logging exactly\n"
printf "               where the budget was exceeded.\n"
printf "${NC}\n"

pause_for_effect

# ── Step 1: Without OARR ─────────────────────────────────────────────────────
print_step "1" "WITHOUT OARR — AGENT RUNS UNCONTROLLED"
print_label "Policy: none   Budget limit: none   Intended calls: 8"
echo ""
print_warn "Agent is running compliance audit..."
echo ""
npm run s2:direct
echo ""
print_danger "RUNAWAY COMPLETE — 8 tool calls executed with no limit applied"

pause_for_effect

# ── Step 2: With OARR ────────────────────────────────────────────────────────
print_step "2" "WITH OARR — BUDGET ENFORCEMENT"
print_label "Policy: allowed_tools = [db.read_patients]   max_tool_calls = 3"
echo ""
print_ok "Agent reads patient records    call 1  →  OARR: ALLOWED"
print_ok "Agent reads patient records    call 2  →  OARR: ALLOWED"
print_ok "Agent reads patient records    call 3  →  OARR: ALLOWED"
print_blocked "Agent reads patient records    call 4  →  OARR: BLOCKED  budget_exceeded"
echo ""
npm run s2:governed
echo ""

pause_for_effect

# ── Step 3: Audit trail ───────────────────────────────────────────────────────
print_step "3" "AUDIT TRAIL — OARR TRACE"
print_label "The trace shows exactly which call hit the limit and at what timestamp."
echo ""
npm run audit:beautify

# ── Result ───────────────────────────────────────────────────────────────────
print_proof "RESULT: AGENT STOPPED AT CALL 4 · 5 UNNECESSARY CALLS PREVENTED"
