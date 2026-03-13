#!/usr/bin/env bash
# Scenario 5: Light Agent with Live LLM
# Demonstrates a real LLM-based agent (reasoning, tool selection, memory) under OARR governance.
# Usage: OPENAI_API_KEY=sk-... bash scripts/demo-s5.sh
#        INTERACTIVE=1 bash scripts/demo-s5.sh
# Requires: OPENAI_API_KEY (real key), OARR CLI, docker compose up

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

source "${SCRIPT_DIR}/lib/ui.sh"

if [ -z "${OPENAI_API_KEY:-}" ] || [ "${OPENAI_API_KEY}" = "oarr-local-demo-key" ]; then
  echo "error: Scenario 5 requires a real OPENAI_API_KEY. Set it before running." >&2
  echo "  export OPENAI_API_KEY=sk-..." >&2
  exit 1
fi

scenario_header "5" "LIGHT AGENT WITH LIVE LLM" "Real Agent · LLM Reasoning · Full Governance"

printf "${DIM}"
printf "  Pain point:  A real AI agent with an LLM can reason, choose tools,\n"
printf "               and iterate — but without governance it runs unchecked.\n"
printf "\n"
printf "  OARR proves  both llm.request and tool.call flow through the harness.\n"
printf "               Policy governs model usage and tool budget (max_tool_calls).\n"
printf "${NC}\n"

pause_for_effect

# ── Step 1: Direct mode (no harness) ────────────────────────────────────────
print_step "1" "WITHOUT OARR — AGENT RUNS UNCHECKED"
print_label "Agent calls OpenAI directly, uses clinicApiClient for tools. No policy."
echo ""
print_warn "Agent sends request to OpenAI..."
print_warn "Model chooses db.read_patients..."
print_warn "Agent calls clinic API directly — no mediation"
echo ""
npm run s5:direct
echo ""
print_danger "DIRECT MODE COMPLETE — LLM + tools executed with no governance"

pause_for_effect

# ── Step 2: Governed mode ────────────────────────────────────────────────────
print_step "2" "WITH OARR — FULL GOVERNANCE"
print_label "Policy: allowed_tools=[db.read_patients]   max_tool_calls=5"
echo ""
print_ok "Agent sends llm.request    →  OARR: governs model call"
print_ok "Agent sends tool.call      →  OARR: allows (in policy)"
print_ok "Agent receives tool.result →  continues loop"
print_info "If agent exceeds 5 tool calls → OARR: BLOCKED"
echo ""
npm run s5:governed
echo ""

pause_for_effect

# ── Step 3: Audit trail ──────────────────────────────────────────────────────
print_step "3" "AUDIT TRAIL — OARR TRACE"
print_label "The trace shows llm.request, llm.response, tool.call, tool.result events."
echo ""
npm run audit:beautify

# ── Result ───────────────────────────────────────────────────────────────────
print_proof "RESULT: REAL LLM AGENT GOVERNED · ULTIMATE RUNTIME PROOF"
