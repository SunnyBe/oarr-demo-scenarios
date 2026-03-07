# OARR Demo Scenarios v1

This repository is a safety proof demo for OARR (Open Agent Runtime and Registry).

It demonstrates one clear contrast:

- without governance, an agent can wipe production-like records
- with OARR governance, the same destructive intent is denied before execution

Architecture comparison:

```text
Without OARR:
Agent -> Clinic Service

With OARR:
Agent -> OARR -> Clinic Service
```

## What This Demo Proves

The same scenario is run in two modes:

- direct unsafe mode sends `DELETE /patients` and wipes records
- governed mode requests `db.delete_all_patients`, then policy blocks it

This proves direct agent access is dangerous and governed mediation is safer.

## Scope (Intentionally Small)

- one standalone clinic service (Express + Postgres)
- one agent (`clinic-records-agent`)
- one destructive scenario (`healthcare-data-wipe`)
- two execution paths (direct vs governed)

## Prerequisites

- Docker Desktop running
- Node.js 20+
- OARR CLI installed and available in PATH (`oarr`)

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

## Key Files For Review

- `docker-compose.yml`
- `clinic-service/src/routes/patients.ts`
- `scenarios/healthcare-data-wipe/direct-mode.ts`
- `scenarios/healthcare-data-wipe/governed-agent.mjs`
- `scenarios/healthcare-data-wipe/policy/policy.yaml`
- `tools/governed/tools.yaml`
