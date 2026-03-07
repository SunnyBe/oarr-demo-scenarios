#!/usr/bin/env bash
# Converts OARR trace output into a simple readable flow.
# Usage: npm run scenario:governed 2>&1 | bash scripts/visualize-run.sh
#    or: bash scripts/visualize-run.sh < trace.log

set -euo pipefail

echo "Agent"
echo "│"
echo "▼"

seen_llm=0
seen_tool=0
seen_policy=0
seen_denied=0
seen_completed=0
last_tool=""

while IFS= read -r line; do
  if [[ "$line" == *"llm.request"* ]] && [[ $seen_llm -eq 0 ]]; then
    echo "OARR Runtime"
    echo "│"
    echo "▼"
    echo "LLM Request"
    echo "│"
    echo "▼"
    seen_llm=1
  fi
  if [[ "$line" == *"tool.call"* ]] || [[ "$line" == *"tool.requested"* ]]; then
    if [[ "$line" =~ db\.(read_patients|delete_patient|delete_all_patients) ]]; then
      last_tool="${BASH_REMATCH[0]}"
    fi
    if [[ $seen_tool -eq 0 ]] || [[ -n "$last_tool" ]]; then
      echo "Policy Check"
      echo "│"
      echo "▼"
      echo "Tool Request: ${last_tool:-tool}"
      echo "│"
      echo "▼"
      seen_tool=1
    fi
  fi
  if [[ "$line" == *"policy.violation"* ]] && [[ $seen_policy -eq 0 ]]; then
    echo "Policy Violation"
    echo "│"
    echo "▼"
    seen_policy=1
  fi
  if [[ "$line" == *"execution.denied"* ]] || [[ "$line" == *"tool.denied"* ]] && [[ $seen_denied -eq 0 ]]; then
    echo "Execution Denied"
    echo "│"
    echo "▼"
    seen_denied=1
  fi
  if [[ "$line" == *"run.completed"* ]] && [[ $seen_completed -eq 0 ]]; then
    echo "Run Completed"
    seen_completed=1
  fi
done

if [[ $seen_completed -eq 0 ]] && [[ $seen_denied -eq 0 ]] && [[ $seen_tool -eq 0 ]]; then
  echo "OARR Runtime"
  echo "│"
  echo "▼"
  echo "(No trace events captured - run with --trace-stdout)"
fi
