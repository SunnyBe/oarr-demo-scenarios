#!/usr/bin/env bash
# Shared UI functions for OARR demo scripts.
# Source this file: source "$(dirname "${BASH_SOURCE[0]}")/lib/ui.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Full-width separator
SEP="────────────────────────────────────────────────────────────"

oarr_banner() {
  echo ""
  printf "${BOLD}${CYAN}"
  printf '╔══════════════════════════════════════════════════════════════╗\n'
  printf '║                                                              ║\n'
  printf '║     O A R R  ·  Open Agent Runtime & Registry               ║\n'
  printf '║     Governance for AI agents operating on real systems       ║\n'
  printf '║                                                              ║\n'
  printf '╚══════════════════════════════════════════════════════════════╝\n'
  printf "${NC}\n"
}

scenario_header() {
  local scenario_num="$1"
  local title="$2"
  local subtitle="$3"
  echo ""
  printf "${BOLD}${WHITE}"
  printf '╔══════════════════════════════════════════════════════════════╗\n'
  printf "║  SCENARIO %-51s║\n" "${scenario_num}"
  printf "║  %-60s║\n" "${title}"
  printf "║  %-60s║\n" "${subtitle}"
  printf '╚══════════════════════════════════════════════════════════════╝\n'
  printf "${NC}\n"
}

print_step() {
  local num="$1"
  local title="$2"
  echo ""
  printf "${BOLD}${BLUE}${SEP}\n"
  printf "  STEP %s · %s\n" "${num}" "${title}"
  printf "${SEP}${NC}\n"
}

print_ok() {
  printf "${GREEN}  ✓  %s${NC}\n" "$*"
}

print_blocked() {
  printf "${RED}  ✗  %s${NC}\n" "$*"
}

print_warn() {
  printf "${YELLOW}  ⚠  %s${NC}\n" "$*"
}

print_info() {
  printf "${CYAN}  →  %s${NC}\n" "$*"
}

print_label() {
  printf "${DIM}  %s${NC}\n" "$*"
}

print_proof() {
  local msg="$1"
  echo ""
  printf "${BOLD}${GREEN}"
  printf '╔══════════════════════════════════════════════════════════════╗\n'
  printf "║  ✓  %-57s║\n" "${msg}"
  printf '╚══════════════════════════════════════════════════════════════╝\n'
  printf "${NC}\n"
}

print_danger() {
  local msg="$1"
  echo ""
  printf "${BOLD}${RED}"
  printf '╔══════════════════════════════════════════════════════════════╗\n'
  printf "║  ✗  %-57s║\n" "${msg}"
  printf '╚══════════════════════════════════════════════════════════════╝\n'
  printf "${NC}\n"
}

print_section() {
  echo ""
  printf "${BOLD}${MAGENTA}  %s${NC}\n" "$*"
  printf "${DIM}  ${SEP}${NC}\n"
}

pause_for_effect() {
  if [ "${INTERACTIVE:-0}" = "1" ]; then
    echo ""
    printf "${DIM}  ── Press Enter to continue ──${NC}"
    read -r || true
    echo ""
  fi
}

demo_complete_summary() {
  echo ""
  printf "${BOLD}${GREEN}"
  printf '╔══════════════════════════════════════════════════════════════╗\n'
  printf '║                                                              ║\n'
  printf '║     DEMO COMPLETE                                            ║\n'
  printf '║                                                              ║\n'
  while IFS= read -r line; do
    printf "║  ✓  %-57s║\n" "${line}"
  done
  printf '║                                                              ║\n'
  printf '╚══════════════════════════════════════════════════════════════╝\n'
  printf "${NC}\n"
}
