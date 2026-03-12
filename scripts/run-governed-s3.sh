#!/usr/bin/env bash
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

if [ -z "${OPENAI_API_KEY:-}" ]; then
  export OPENAI_API_KEY="oarr-local-demo-key"
fi

echo "scenario.name financial-unauthorized-transfer"
echo "mode governed-oarr-cli"
echo "oarr.bin ${OARR_BIN_RESOLVED}"

"${OARR_BIN_RESOLVED}" run node scenarios/financial-unauthorized-transfer/governed-agent.mjs \
  --policy scenarios/financial-unauthorized-transfer/policy/policy.yaml \
  --tools-dir tools/governed-bank \
  --trace-stdout \
  --non-interactive
