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
RUN_HELP="$("${OARR_BIN_RESOLVED}" run --help 2>&1 || true)"
for required_flag in "--tools" "--tools-dir" "--policy" "--trace-stdout"; do
  if [[ "${RUN_HELP}" != *"${required_flag}"* ]]; then
    echo "error: current oarr binary is missing required flag ${required_flag}" >&2
    exit 1
  fi
done

if [ "${OARR_LIVE:-0}" = "1" ]; then
  if [ -z "${OPENAI_API_KEY:-}" ]; then
    echo "error: OPENAI_API_KEY is required for live governed runs (OARR_LIVE=1)." >&2
    exit 1
  fi
else
  if [ -z "${OPENAI_API_KEY:-}" ]; then
    export OPENAI_API_KEY="oarr-local-demo-key"
  fi
fi

echo "scenario.name healthcare-data-wipe"
if [ "${OARR_LIVE:-0}" = "1" ]; then
  echo "mode governed-oarr-cli-live"
else
  echo "mode governed-oarr-cli-test"
fi
echo "oarr.bin ${OARR_BIN_RESOLVED}"

"${OARR_BIN_RESOLVED}" run node scenarios/healthcare-data-wipe/governed-agent.mjs \
  --policy scenarios/healthcare-data-wipe/policy/policy.yaml \
  --tools-dir tools/governed \
  --trace-stdout \
  --non-interactive
