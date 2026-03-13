#!/usr/bin/env bash
# Scenario 5: Light Agent with Live LLM
# Requires: OPENAI_API_KEY (real key), OARR CLI, clinic service running
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

resolve_oarr_bin() {
  if command -v oarr >/dev/null 2>&1; then
    command -v oarr
    return
  fi
  if [ -n "${OARR_BIN:-}" ] && [ -x "${OARR_BIN}" ]; then
    echo "${OARR_BIN}"
    return
  fi
  echo "error: oarr CLI not found. Set OARR_BIN or install oarr in PATH." >&2
  exit 1
}

OARR_BIN_RESOLVED="$(resolve_oarr_bin)"

if [ -z "${OPENAI_API_KEY:-}" ] || [ "${OPENAI_API_KEY}" = "oarr-local-demo-key" ]; then
  echo "error: Scenario 5 requires a real OPENAI_API_KEY. Set it before running." >&2
  echo "  export OPENAI_API_KEY=sk-..." >&2
  exit 1
fi

echo "scenario.name light-agent-live"
echo "mode governed-oarr-cli"
echo "oarr.bin ${OARR_BIN_RESOLVED}"

"${OARR_BIN_RESOLVED}" run node scenarios/light-agent-live/governed-agent.mjs \
  --policy scenarios/light-agent-live/policy/policy.yaml \
  --tools-dir tools/governed \
  --trace-stdout \
  --non-interactive
