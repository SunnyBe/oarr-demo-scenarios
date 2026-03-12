#!/usr/bin/env bash
# Multi-agent claims pipeline — governed execution.
# Runs Step 1 (patient-records) and Step 2 (claims-billing) as two separate
# OARR-governed agents in sequence, demonstrating per-step policy enforcement.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${PROJECT_ROOT}"

resolve_oarr_bin() {
  if command -v oarr >/dev/null 2>&1; then
    command -v oarr; return
  fi
  if [ -n "${OARR_BIN:-}" ] && [ -x "${OARR_BIN}" ]; then
    echo "${OARR_BIN}"; return
  fi
  echo "error: oarr CLI not found. Set OARR_BIN or install oarr in PATH." >&2
  exit 1
}

OARR_BIN_RESOLVED="$(resolve_oarr_bin)"

if [ -z "${OPENAI_API_KEY:-}" ]; then
  export OPENAI_API_KEY="oarr-local-demo-key"
fi

echo "pipeline.name medical-claims-pipeline"
echo "pipeline.mode governed-oarr-cli"
echo ""

echo "pipeline.step 1/2 patient-records-agent"
echo "pipeline.step1.policy allowed_tools=[db.read_patients] max_tool_calls=5"
"${OARR_BIN_RESOLVED}" run node scenarios/multi-agent-claims-pipeline/step1-agent.mjs \
  --policy scenarios/multi-agent-claims-pipeline/step1-policy.yaml \
  --tools-dir tools/governed \
  --trace-stdout \
  --non-interactive
echo ""

echo "pipeline.step 2/2 claims-billing-agent"
echo "pipeline.step2.policy allowed_tools=[accounts.list_all,transactions.read_history]"
"${OARR_BIN_RESOLVED}" run node scenarios/multi-agent-claims-pipeline/step2-agent.mjs \
  --policy scenarios/multi-agent-claims-pipeline/step2-policy.yaml \
  --tools-dir tools/governed-bank \
  --trace-stdout \
  --non-interactive
