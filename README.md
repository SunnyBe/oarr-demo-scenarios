# OARR Demo Scenarios

> **Heads up:** This is a local demo environment. Everything runs on your machine inside Docker. No data leaves your system.

This repository lets you run a live proof of what happens when an AI agent tries to delete all patient records — once without governance, and once with [OARR](https://oarr-website.vercel.app) in place.

**Without OARR:** the agent calls `DELETE /patients`. The records are gone.
**With OARR:** the policy intercepts the tool call before it reaches the service. The records survive.

Visit [oarr-website.vercel.app](https://oarr-website.vercel.app) to learn more about the project.

---

## What you need before starting

- **Docker Desktop** — running
- **Node.js 20+**
- **The `oarr` CLI** — see [Getting the oarr CLI](#getting-the-oarr-cli) below

---

## Getting the oarr CLI

The `oarr` CLI is currently in **private beta**. To try this demo with real OARR governance, you need access to the binary.

### Option A — Request beta access

Open an issue or reach out via [github.com/SunnyBe/oarr](https://github.com/SunnyBe/oarr) to request access to the private beta. Once approved, you will receive installation instructions.

### Option B — Point to a local binary

If you already have the `oarr` binary built or distributed to you, you can skip installing it system-wide:

```bash
export OARR_BIN=/absolute/path/to/oarr
```

Set this before running any `scenario:governed` commands.

> **Without `oarr`:** You can still run the direct (unsafe) scenario — it has no dependency on the CLI. Only the governed scenario requires `oarr`.

---

## Setup

### 1. Clone this repository

```bash
git clone https://github.com/SunnyBe/oarr-demo-scenarios.git
cd oarr-demo-scenarios
```

### 2. Install dependencies

```bash
npm install
cd clinic-service && npm install && cd ..
```

### 3. Start the infrastructure

This starts a Postgres database and the clinic HTTP service inside Docker:

```bash
docker compose up --build -d
```

Wait a few seconds, then confirm the service is healthy:

```bash
curl -s http://localhost:3000/health
```

You should see a `200 OK` response. If the service isn't up yet, wait 5–10 seconds and try again.

### 4. Verify the seed data

```bash
npm run verify:patients
```

Expected output: `verify.patient_count 5`

---

## Running the demo

### One command (recommended for first run)

This runs the full sequence automatically: reset → direct wipe → verify wipe → reset → governed block → verify survival → proof.

```bash
npm run demo
```

For a nicer table view of patient data:

```bash
npm run demo:beautify
```

For a presentation or recording where you want to pause between steps:

```bash
npm run demo:interactive
npm run demo:interactive:beautify
```

---

### Step by step (if you want to follow along)

#### Step 1 — Run direct unsafe mode

The agent talks directly to the clinic service with no policy in between:

```bash
npm run scenario:direct
```

What to look for:

- `agent.request delete all patients`
- `direct.api_call DELETE /patients`
- `result.success deleted=5`

#### Step 2 — Confirm the data is gone

```bash
npm run verify:patients
```

Expected: `verify.patient_count 0`

#### Step 3 — Reset the database

```bash
npm run reset:db
npm run verify:patients
```

Expected: `verify.patient_count 5` — back to the starting state.

#### Step 4 — Run governed OARR mode

```bash
npm run scenario:governed
```

OARR intercepts `db.delete_all_patients` before it reaches the service. The policy only allows `db.read_patients`, so the deletion is denied.

What to look for:

- `tool.call ... db.delete_all_patients`
- `policy.violation ... db.delete_all_patients is not allowed by policy`
- `execution.denied`

#### Step 5 — Confirm the data survived

```bash
npm run verify:patients
```

Expected: `verify.patient_count 5` — the records are untouched.

#### Step 6 — Prove the service boundary

This checks Docker logs to confirm that in direct mode the service received a `DELETE` request, and in governed mode it received zero:

```bash
npm run prove:paths
```

Expected:

- `proof.direct.delete_calls_to_service 1`
- `proof.governed.delete_calls_to_service 0`
- `proof.result passed`

---

## Live mode (uses a real LLM)

To have the agent make an actual LLM call during the governed scenario, set your OpenAI API key first:

```bash
export OPENAI_API_KEY=sk-...
npm run scenario:governed:live
```

Without this, the governed scenario runs in test mode (the agent logic is exercised but no real LLM request is made).

---

## Extras

### Audit the OARR trace from the last run

```bash
npm run audit
npm run audit:beautify
```

### Visualize the execution flow

```bash
npm run scenario:governed 2>&1 | bash scripts/visualize-run.sh
```

---

## Key files

| File | What it does |
| --- | --- |
| `docker-compose.yml` | Postgres + clinic service |
| `clinic-service/src/routes/patients.ts` | The HTTP API the agent calls |
| `scenarios/healthcare-data-wipe/direct-mode.ts` | Direct (unsafe) scenario |
| `scenarios/healthcare-data-wipe/governed-agent.mjs` | Governed agent (talks to OARR runtime) |
| `scenarios/healthcare-data-wipe/policy/policy.yaml` | Policy that blocks the deletion |
| `tools/governed/tools.yaml` | Tool definitions available to the agent |

---

## A note on credentials

The Postgres credentials in `docker-compose.yml` (`clinic/clinic`) are demo-only and only reachable from your local machine via Docker. Do not use this compose file in any shared or production environment.

---

## Links

- Website: [oarr-website.vercel.app](https://oarr-website.vercel.app)
- Demo scenarios (this repo): [github.com/SunnyBe/oarr-demo-scenarios](https://github.com/SunnyBe/oarr-demo-scenarios)
- OARR CLI (private beta): [github.com/SunnyBe/oarr](https://github.com/SunnyBe/oarr)
