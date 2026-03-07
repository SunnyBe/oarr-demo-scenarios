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

resolve_run_id() {
  local requested="${1:-}"
  if [ -n "${requested}" ]; then
    echo "${requested}"
    return
  fi

  python3 - <<'PY'
import sqlite3
conn=sqlite3.connect('.oarr/traces.db')
cur=conn.cursor()
cur.execute("SELECT run_id FROM trace_events WHERE event_type='run.started' ORDER BY id DESC LIMIT 1")
row=cur.fetchone()
print(row[0] if row else '')
PY
}

OARR_BIN_RESOLVED="$(resolve_oarr_bin)"
RUN_ID="$(resolve_run_id "${1:-}")"

if [ -z "${RUN_ID}" ]; then
  echo "error: no run id found in .oarr/traces.db and none provided." >&2
  exit 1
fi

echo "audit.run_id ${RUN_ID}"
"${OARR_BIN_RESOLVED}" trace "${RUN_ID}"
