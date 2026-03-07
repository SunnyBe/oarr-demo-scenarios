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

TRACE_RAW="$("${OARR_BIN_RESOLVED}" trace "${RUN_ID}")"

printf '%s' "${TRACE_RAW}" | node -e '
const fs = require("fs");
const input = fs.readFileSync(0, "utf8");
const lines = input.split(/\r?\n/).filter(Boolean);
const events = lines.map((line) => {
  try { return JSON.parse(line); } catch { return null; }
}).filter(Boolean);

if (events.length === 0) {
  console.log("audit.run_id", process.argv[1]);
  console.log("No trace events found.");
  process.exit(0);
}

const runId = events[0].run_id || process.argv[1];
const started = events.find((e) => e.event_type === "run.started");
const finished = events.find((e) => e.event_type === "run.finished");
const policyViolations = events.filter((e) => e.event_type === "policy.violation");
const arpMessages = events
  .filter((e) => e.event_type === "arp.message")
  .map((e) => ({
    at: e.occurred_at,
    direction: e.payload?.direction || "",
    message_type: e.payload?.message_type || ""
  }));

const counts = {};
for (const e of events) counts[e.event_type] = (counts[e.event_type] || 0) + 1;

console.log("audit.run_id", runId);
console.log("audit.events_total", events.length);
if (started) console.log("audit.started_at", started.occurred_at);
if (finished) console.log("audit.finished_at", finished.occurred_at);
console.log("");

console.log("Event Counts:");
console.table(Object.entries(counts).map(([event_type, count]) => ({ event_type, count })));

if (policyViolations.length > 0) {
  console.log("Policy Violations:");
  console.table(policyViolations.map((e) => ({
    at: e.occurred_at,
    scope: e.payload?.scope || "",
    reason: e.payload?.reason || ""
  })));
}

if (arpMessages.length > 0) {
  console.log("ARP Message Timeline:");
  console.table(arpMessages);
}
' "${RUN_ID}"
