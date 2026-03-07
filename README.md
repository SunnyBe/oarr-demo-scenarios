# OARR Demo Scenarios v1

This repository is a safety proof demo for OARR (Open Agent Runtime and Registry).

It demonstrates one clear contrast:

- without governance, an agent can wipe production-like records
- with OARR governance, the same destructive intent is denied before execution

## Architecture

**Direct Mode (Unsafe)**

```text
Agent
│
▼
Clinic Service
│
▼
Database
```

Direct mode allows destructive operations. The agent talks to the clinic service directly; any tool call reaches the service.

**Governed Mode (OARR)**

```text
Agent
│
▼
OARR Runtime
│
▼
Policy Engine
│
▼
External Tool
│
▼
Clinic Service
│
▼
Database
```

Governed mode blocks them via policy. OARR intercepts tool calls before they reach the service; the policy engine denies unsafe operations.

## What This Demo Proves

1. **Agents can perform destructive operations.** Given a goal like "delete all patients," an agent will attempt to execute it.

2. **Without governance the system is vulnerable.** In direct mode, the agent sends `DELETE /patients` to the clinic service and wipes all records.

3. **OARR intercepts tool calls.** In governed mode, the agent's tool requests go through OARR instead of directly to the service.

4. **Policies prevent unsafe execution.** The policy allowlist permits only `db.read_patients`; `db.delete_all_patients` is denied by omission.

5. **The service never receives the destructive request.** When the policy blocks a tool call, the clinic service is never contacted. The proof script verifies: direct mode sends delete requests; governed mode sends zero.

## Scope (Intentionally Small)

- one standalone clinic service (Express + Postgres)
- one agent (`clinic-records-agent`)
- one destructive scenario (`healthcare-data-wipe`)
- two execution paths (direct vs governed)

## Prerequisites

- Docker Desktop running
- Node.js 20+
- OARR CLI installed and available in PATH (`oarr`). See the [OARR CLI repository](https://github.com/SunnyBe/oarr) for the implementation.

If `oarr` is not on PATH, you can still run the demo by setting:

```bash
export OARR_BIN=/absolute/path/to/oarr
```

Install root dependencies:

```bash
npm install
```

Install clinic service dependencies (for local build checks):

```bash
cd clinic-service && npm install && cd ..
```

## One-Command Demo

Run the entire demo sequence automatically (reset → direct → verify wipe → reset → governed → verify survival → prove paths):

```bash
npm run demo
```

For video recordings, use beautified output so patient data is displayed in an organized table:

```bash
npm run demo:beautify
```

For live demos or recordings where you want to pause between steps, use the interactive mode. It shows the next command and prompts "Continue? (Y/N)" before each step so results can sink in:

```bash
npm run demo:interactive
npm run demo:interactive:beautify   # with beautified patient tables
```

Requires infrastructure running (`docker compose up -d`) and `oarr` on PATH.

## Start Infrastructure

```bash
docker compose up --build -d
```

Check health:

```bash
curl -sS http://localhost:3000/health
```

## Verify Initial Data

```bash
npm run verify:patients
```

Demo-friendly table view:

```bash
npm run verify:patients:beautify
```

Expected: `verify.patient_count 5`

## Run Direct Unsafe Mode

```bash
npm run scenario:direct
```

Expected direct-mode highlights:

- `agent.request delete all patients`
- `direct.api_call DELETE /patients`
- `result.success deleted=5`
- `verification.wipe_confirmed true`

## Verify Wipe Occurred

```bash
npm run verify:patients
```

Demo-friendly table view:

```bash
npm run verify:patients:beautify
```

Expected: `verify.patient_count 0`

## Reset / Reseed Database

```bash
npm run reset:db
```

Then verify:

```bash
npm run verify:patients
```

Demo-friendly table view:

```bash
npm run verify:patients:beautify
```

Expected: `verify.patient_count 5`

## Run Governed OARR Mode

```bash
npm run scenario:governed
```

Live governed run (uses real `OPENAI_API_KEY` and performs an `llm.request`):

```bash
npm run scenario:governed:live
```

Preflight check (recommended):

```bash
oarr run --help
```

Confirm these flags are available:

- `--tools`
- `--tools-dir`
- `--policy`
- `--trace-stdout`

Baseline governed command (from project root):

```bash
oarr run node scenarios/healthcare-data-wipe/governed-agent.mjs \
  --policy scenarios/healthcare-data-wipe/policy/policy.yaml \
  --tools-dir tools/governed \
  --trace-stdout
```

`--tools-dir tools/governed` expects `tools/governed/tools.yaml`.

Expected governed-mode highlights:

- `tool.call ... db.delete_all_patients`
- `policy.violation ... db.delete_all_patients is not allowed by policy`
- `execution.denied`
- `run.completed`

Live mode additionally includes an `llm.request`/`llm.response` exchange before the governed tool calls.

## Verify Data Survived

```bash
npm run verify:patients
```

Demo-friendly table view:

```bash
npm run verify:patients:beautify
```

Expected: `verify.patient_count 5`

## Explicit Request-Path Proof

This checks service logs to prove:

- direct mode sent `DELETE /patients` to clinic service
- governed mode sent zero `DELETE /patients` requests

```bash
npm run prove:paths
```

Expected:

- `proof.direct.delete_calls_to_service 1` (or more)
- `proof.governed.delete_calls_to_service 0`
- `proof.result passed`

## OARR Runtime Audit

Raw OARR trace for latest run:

```bash
npm run audit
```

Beautified OARR audit summary:

```bash
npm run audit:beautify
```

Audit scripts use `oarr trace <run_id>` under the hood and default to the latest run in `.oarr/traces.db`.  
Optional: pass a specific run id:

```bash
bash scripts/audit-oarr.sh <run_id>
bash scripts/audit-oarr-pretty.sh <run_id>
```

## Trace Visualization

Convert OARR trace output into a simple readable flow:

```bash
npm run scenario:governed 2>&1 | bash scripts/visualize-run.sh
```

Or from a saved log:

```bash
bash scripts/visualize-run.sh < trace.log
```

Example output:

```text
Agent
│
▼
OARR Runtime
│
▼
Policy Check
│
▼
Tool Request: db.delete_all_patients
│
▼
Policy Violation
│
▼
Execution Denied
```

## Key Files For Review

- `docker-compose.yml`
- `clinic-service/src/routes/patients.ts`
- `scenarios/healthcare-data-wipe/direct-mode.ts`
- `scenarios/healthcare-data-wipe/governed-agent.mjs`
- `scenarios/healthcare-data-wipe/policy/policy.yaml`
- `tools/governed/tools.yaml`
