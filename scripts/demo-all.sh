#!/usr/bin/env bash
# Full OARR Demo Suite — Scenarios 1–4 (no API key required).
# Scenario 5 (live LLM) runs separately: OPENAI_API_KEY=sk-... npm run demo:s5
# Usage: bash scripts/demo-all.sh
#        INTERACTIVE=1 bash scripts/demo-all.sh  (pause between scenarios)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

source "${SCRIPT_DIR}/lib/ui.sh"

oarr_banner

printf "${DIM}"
printf "  This demo covers four real-world governance failures that OARR\n"
printf "  intercepts before they cause damage.\n"
printf "\n"
printf "  Scenario 1  Healthcare Data Wipe            bulk-delete blocked\n"
printf "  Scenario 2  Runaway Audit Loop              budget enforcement\n"
printf "  Scenario 3  Unauthorized Wire Transfer      fund movement blocked\n"
printf "  Scenario 4  Multi-Agent Claims Pipeline     cross-domain governance\n"
printf "\n"
printf "  Scenario 5  Light Agent with Live LLM       run separately with OPENAI_API_KEY\n"
printf "${NC}\n"

pause_for_effect

# ─── Scenario 1 ──────────────────────────────────────────────────────────────
bash "${SCRIPT_DIR}/demo-s1.sh"

pause_for_effect

# ─── Scenario 2 ──────────────────────────────────────────────────────────────
bash "${SCRIPT_DIR}/demo-s2.sh"

pause_for_effect

# ─── Scenario 3 ──────────────────────────────────────────────────────────────
bash "${SCRIPT_DIR}/demo-s3.sh"

pause_for_effect

# ─── Scenario 4 ──────────────────────────────────────────────────────────────
bash "${SCRIPT_DIR}/demo-s4.sh"

pause_for_effect

# ─── Final summary ───────────────────────────────────────────────────────────
printf "Patient records protected from bulk deletion\nAPI budget enforced — agent stopped at call 4\n\$47,250 wire transfer blocked before funds moved\nCross-domain pipeline governed end-to-end" | \
  demo_complete_summary
