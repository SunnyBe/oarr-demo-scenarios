# OARR Demo Scenarios

> This is a local demo environment. Everything runs on your machine inside Docker. No data leaves your system.

This repository contains four production-grade demo scenarios that prove what OARR — Open Agent Runtime & Registry — does when AI agents operate on real systems.

Each scenario shows the same pattern: the agent runs once without governance (the damage happens), then again under OARR (the damage is blocked). The proof is always structural — Docker logs, database state, and OARR's own audit trail confirm what occurred.

---

## The Four Scenarios

### Scenario 1 — Healthcare Data Wipe

An AI agent is given access to a clinic records system. Its task: delete all patient records. Without governance, it does exactly that. Under OARR, the `db.delete_all_patients` tool call is intercepted before it reaches the service. The clinic database never receives a DELETE request.

**What it demonstrates:** `allowed_tools` enforcement. One policy line blocks a destructive action at the runtime boundary.

### Scenario 2 — Runaway Audit Loop

A compliance audit agent spirals into repeated reads — re-reading the same patient records to "verify" and "cross-reference" in a loop. In production, every tool call costs API tokens and database load. Without governance, all 8 calls succeed. Under OARR, the `max_tool_calls: 3` policy stops the agent at the 4th call, emitting a `policy.violation` trace event.

**What it demonstrates:** Budget enforcement. OARR tracks every call and cuts the agent off at the configured limit.

### Scenario 3 — Unauthorized Wire Transfer

A portfolio management agent reads client account balances and initiates a $47,250 wire transfer across client accounts — without authorization. Under OARR, read tools are allowed while `transfers.initiate` is not. The bank service never receives the POST request. Account balances are unchanged.

**What it demonstrates:** Data exfiltration and fund movement prevention. Read access can be granted without granting write access — even to the same agent.

### Scenario 4 — Multi-Agent Claims Pipeline

A hospital deploys a two-agent pipeline to automate insurance claims. Agent 1 reads patient records from the clinic system. Agent 2 receives that data and initiates a $1,750 billing transfer. Without governance, the pipeline completes end-to-end. Under OARR, each agent is governed independently: Step 1 passes, Step 2 is blocked at the billing transfer call.

**What it demonstrates:** Cross-domain, multi-agent governance. OARR applies policy per agent and per step — even in coordinated pipelines that span domain boundaries.

---

## Requirements

- **Docker Desktop** running
- **Node.js 20+**
- **The `oarr` CLI** — see below

---

## Getting the `oarr` CLI

The `oarr` CLI is currently in private beta. To run the governed scenarios you need the binary.

### Option A — Request beta access

Reach out via [github.com/SunnyBe/oarr](https://github.com/SunnyBe/oarr) to request access. Once approved you will receive installation instructions.

### Option B — Point to a local binary

If you already have the binary:

```bash
export OARR_BIN=/absolute/path/to/oarr
```

Set this before running any governed scenario commands.

> Without `oarr` you can still run all direct (uncontrolled) scenarios — they have no CLI dependency.

---

## Setup

```bash
git clone https://github.com/SunnyBe/oarr-demo-scenarios.git
cd oarr-demo-scenarios
npm install
```

Start all services (clinic and bank):

```bash
docker compose up --build -d
```

Verify both are healthy:

```bash
curl http://localhost:3100/health   # clinic-service
curl http://localhost:3101/health   # bank-service
```

---

## Running the Demo

### Full suite — all four scenarios

```bash
npm run demo:all
```

With pauses between steps (recommended for live recording):

```bash
npm run demo:all:interactive
```

### Individual scenarios

```bash
npm run demo:s1              # Healthcare Data Wipe
npm run demo:s2              # Runaway Audit Loop
npm run demo:s3              # Unauthorized Wire Transfer
npm run demo:s4              # Multi-Agent Claims Pipeline
```

Add `:interactive` to any scenario for a paused, step-by-step experience:

```bash
npm run demo:s3:interactive
```

### Run components directly

```bash
# Scenario 1
npm run scenario:direct        # direct (uncontrolled) run
npm run scenario:governed      # governed run via OARR

# Scenario 2
npm run s2:direct
npm run s2:governed

# Scenario 3
npm run s3:direct
npm run s3:governed

# Scenario 4
npm run s4:direct
npm run s4:governed
```

---

## Resetting Services

```bash
npm run reset:db       # clinic only (Scenarios 1, 2)
npm run reset:bank     # bank only (Scenario 3)
npm run reset:all      # everything (Scenario 4, or before a full run)
```

---

## Verifying State

```bash
npm run verify:patients:beautify    # table view of clinic patient records
npm run verify:accounts:beautify    # table view of bank account balances
```

---

## Audit Trail

Every OARR run writes structured events to `.oarr/traces.db`. View the latest run:

```bash
npm run audit:beautify
```

This shows event counts, timestamps, policy violations, and the full ARP message timeline. The `policy.violation` event proves the tool call was intercepted — not just logged after the fact.

---

## Service Boundary Proof

For Scenario 1 and Scenario 3, dedicated proof scripts confirm the service never received the blocked request:

```bash
npm run prove:paths           # Scenario 1: counts DELETE /patients in clinic logs
npm run prove:bank:paths      # Scenario 3: counts POST /transfers in bank logs
```

Expected: direct run ≥1 call, governed run 0 calls.

---

## Infrastructure

| Service | Port | Purpose |
| --- | --- | --- |
| clinic-service | 3000 | Express + Postgres — patient records API |
| bank-service | 3001 | Express + Postgres — accounts and transfers API |
| clinic-db | 5432 | Postgres 16 — 5 seeded patient records |
| bank-db | 5433 | Postgres 16 — 6 seeded accounts, transaction history |

---

## Project Layout

```text
scenarios/
├── healthcare-data-wipe/           # Scenario 1
├── healthcare-audit-loop/          # Scenario 2
├── financial-unauthorized-transfer/# Scenario 3
└── multi-agent-claims-pipeline/    # Scenario 4

agents/
├── clinic-records-agent/           # Scenario 1 agent
├── patient-audit-agent/            # Scenario 2 agent
├── account-manager-agent/          # Scenario 3 agent
├── patient-records-agent/          # Scenario 4 Step 1 agent
└── claims-billing-agent/           # Scenario 4 Step 2 agent

tools/
├── governed/                       # OARR-mediated clinic tools
├── governed-bank/                  # OARR-mediated bank tools
├── direct/                         # Direct clinic API client (TypeScript)
└── direct-bank/                    # Direct bank API client (TypeScript)

scripts/
├── lib/ui.sh                       # Shared color and formatting functions
├── demo-s1.sh through demo-s4.sh   # Per-scenario demo scripts
├── demo-all.sh                     # Full suite
├── run-governed.sh through ...     # OARR run wrappers per scenario
├── verify-patients*.sh             # Clinic state verification
├── verify-accounts*.sh             # Bank state verification
├── reset-db.sh / reset-bank-db.sh  # Service resets
├── prove-request-paths.sh          # Scenario 1 service boundary proof
└── prove-bank-paths.sh             # Scenario 3 service boundary proof

docs/
└── demo-flow.md                    # Step-by-step narrative for each scenario
```

---

## Live Mode (real LLM calls)

By default the governed scenarios use a placeholder API key and the agent controls the LLM interaction via ARP messages. To use a real OpenAI model:

```bash
export OPENAI_API_KEY=sk-...
npm run scenario:governed:live
```

Live mode adds a `llm.request` / `llm.response` exchange to the trace, confirming the model call was also governed.
