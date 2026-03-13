# OARR Demo Flow Guide

This guide covers the complete narrative sequence for each demo scenario.
Each scenario can run standalone or as part of the full suite.

For the architecture of agent, harness, tools, and services, see [architecture.md](./architecture.md).

---

## Prerequisites

Confirm OARR CLI is installed and infrastructure is running:

```bash
oarr run --help          # must include --tools-dir, --policy, --trace-stdout
docker compose up --build -d
```

Wait for both services to pass health checks:

```bash
curl http://localhost:3100/health   # clinic-service
curl http://localhost:3101/health   # bank-service
```

---

## Quick Start — Full Demo Suite

One command runs all four scenarios in sequence with full color output:

```bash
npm run demo:all
```

Interactive mode — pauses between steps for a live audience:

```bash
npm run demo:all:interactive
```

Run an individual scenario:

```bash
npm run demo:s1      # Healthcare Data Wipe
npm run demo:s2      # Runaway Audit Loop
npm run demo:s3      # Unauthorized Wire Transfer
npm run demo:s4      # Multi-Agent Claims Pipeline
```

---

## Scenario 1 — Healthcare Data Wipe

**Pain point:** An AI agent with access to a healthcare system can delete all patient records with a single tool call.

**What OARR does:** The `allowed_tools` policy blocks `db.delete_all_patients` before the request reaches the clinic service.

### Scenario 1 Steps

```bash
# 1. Reset database
npm run reset:db

# 2. Verify 5 patients exist
npm run verify:patients:beautify

# 3. Run without governance — bulk delete executes
npm run scenario:direct

# 4. Verify wipe (0 patients)
npm run verify:patients:beautify

# 5. Reset database
npm run reset:db

# 6. Run under OARR — bulk delete is blocked
npm run scenario:governed

# 7. Verify data survived (5 patients)
npm run verify:patients:beautify

# 8. Service boundary proof — 0 DELETE calls in governed run
npm run prove:paths

# 9. Audit trail
npm run audit:beautify
```

**Policy:** `scenarios/healthcare-data-wipe/policy/policy.yaml`
**Expected result:** `proof.result passed` — direct had ≥1 DELETE call, governed had 0.

---

## Scenario 2 — Runaway Audit Loop

**Pain point:** A compliance audit agent spirals into repeated tool calls, burning API tokens and database resources with no circuit breaker.

**What OARR does:** The `max_tool_calls: 3` policy stops the agent at the 4th call, emitting a `policy.violation` trace event.

### Scenario 2 Steps

```bash
# 1. Run without governance — 8 tool calls execute
npm run s2:direct

# 2. Run under OARR — stopped at call 4
npm run s2:governed

# 3. Audit trail — shows exactly which call hit the limit
npm run audit:beautify
```

**Policy:** `scenarios/healthcare-audit-loop/policy/policy.yaml`
**Expected result:** `calls_completed: 3`, `budget_exceeded_at: 4`

---

## Scenario 3 — Unauthorized Wire Transfer

**Pain point:** An AI portfolio management agent reads account balances and initiates a $47,250 wire transfer across client accounts without authorization.

**What OARR does:** The `allowed_tools` policy includes read tools but excludes `transfers.initiate`. The bank service never receives the POST request.

### Scenario 3 Steps

```bash
# 1. Check initial account balances
npm run verify:accounts:beautify

# 2. Run without governance — $47,250 transfer executes
npm run s3:direct

# 3. Verify balance change (SAV-00288 drops to $0.00)
npm run verify:accounts:beautify

# 4. Reset bank
npm run reset:bank

# 5. Run under OARR — transfer is blocked
npm run s3:governed

# 6. Verify balances unchanged
npm run verify:accounts:beautify

# 7. Service boundary proof — 0 POST /transfers in governed run
npm run prove:bank:paths

# 8. Audit trail
npm run audit:beautify
```

**Policy:** `scenarios/financial-unauthorized-transfer/policy/policy.yaml`
**Expected result:** `proof.result passed` — direct had ≥1 POST /transfers, governed had 0.

---

## Scenario 4 — Multi-Agent Claims Pipeline

**Pain point:** A two-agent pipeline automates insurance claims. Agent 1 reads patient records. Agent 2 processes billing by initiating a wire transfer. Without governance, the pipeline completes end-to-end — including the unauthorized transfer.

**What OARR does:** Each agent in the pipeline is governed independently. Step 1 reads patients (allowed). Step 2 reads accounts (allowed) but is blocked from initiating the billing transfer.

This is where governance matters most: coordinated agents can chain dangerous actions across domain boundaries.

### Scenario 4 Steps

```bash
# 1. Verify initial state (both services)
npm run verify:patients:beautify
npm run verify:accounts:beautify

# 2. Run without governance — both agents execute freely
npm run s4:direct

# 3. Verify $1,750 billing transfer executed (CHK-00287 balance reduced)
npm run verify:accounts:beautify

# 4. Reset all services
npm run reset:all

# 5. Run under OARR — pipeline governed per step
npm run s4:governed

# 6. Verify data unchanged (patients and accounts)
npm run verify:patients:beautify
npm run verify:accounts:beautify

# 7. Audit trail — Step 1 and Step 2 traces in .oarr/traces.db
npm run audit:beautify
```

**Step 1 policy:** `scenarios/multi-agent-claims-pipeline/step1-policy.yaml`
**Step 2 policy:** `scenarios/multi-agent-claims-pipeline/step2-policy.yaml`
**Pipeline definition (native):** `scenarios/multi-agent-claims-pipeline/pipeline.yaml`
**Expected result:** `pipeline_blocked_at_billing` — Step 1 passes, Step 2 blocked at `transfers.initiate`

---

## Scenario 5 — Light Agent with Live LLM (scaffold)

**Purpose:** The ultimate proof of OARR — a real LLM-based agent with small memory running through the runtime. Uses a live OpenAI API key and dev services.

**What it demonstrates:** A light agent (LLM reasoning, tool selection, conversation memory) operating under OARR. Both `llm.request` and `tool.call` flow through the harness; policy governs model and tool usage.

**Status:** Scaffold only. See `scenarios/light-agent-live/SCENARIO.md` for implementation plan.

### Scenario 5 Steps (once implemented)

```bash
# 1. Set live API key and ensure services are running
export OPENAI_API_KEY=sk-...
docker compose up -d

# 2. Run direct mode — agent calls OpenAI and services directly (no harness)
npm run s5:direct

# 3. Run governed mode — agent runs under OARR, all calls mediated
npm run s5:governed

# 4. Audit trail — llm.request, tool.call, policy.violation events
npm run audit:beautify
```

**Policy:** `scenarios/light-agent-live/policy/policy.yaml` — allows `db.read_patients`, `max_tool_calls: 5`.

---

## Resetting Services

Reset clinic only (Scenarios 1, 2):

```bash
npm run reset:db
```

Reset bank only (Scenario 3):

```bash
npm run reset:bank
```

Reset everything (Scenario 4, or before a full demo run):

```bash
npm run reset:all
```

---

## Audit Trail Reference

Every OARR run writes structured events to `.oarr/traces.db`. View the last run:

```bash
npm run audit:beautify
```

Key events to highlight during a demo:

| Event | Meaning |
| --- | --- |
| `run.started` | OARR began governing this agent |
| `tool.call` | Agent requested a tool |
| `tool.result` | Tool executed and returned data |
| `policy.violation` | OARR blocked a tool call or model request |
| `run.finished` | Run completed (success or governed failure) |
