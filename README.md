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
- `tool.denied`

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

## Bring your own agent

This section is for engineers who want to test their own agent against the OARR runtime, using this demo's infrastructure as a sandbox.

The clinic service (Express + Postgres) is already set up here. You can point your own agent at it, define your own tools, write a policy, and run it through OARR — without building any backend.

---

### How the agent protocol works

OARR launches your agent as a subprocess and communicates over **stdin/stdout using newline-delimited JSON**. Your agent does not call tools directly — it requests them from the runtime, and OARR decides whether to allow or deny them based on your policy.

The message flow:

```text
OARR  → agent    runtime.start
agent → OARR     tool.call       { name, arguments }
OARR  → agent    tool.result     { ... }   or   error  { reason, ... }
agent → OARR     llm.request     { model, messages, ... }   (optional)
OARR  → agent    llm.response    { content, ... }
agent → OARR     agent.result    { ... }
```

Your agent reads from `process.stdin` and writes to `process.stdout`. See [scenarios/healthcare-data-wipe/governed-agent.mjs](scenarios/healthcare-data-wipe/governed-agent.mjs) for a complete working example of this pattern.

---

### Write a tool module

Each tool is a `.mjs` file that exports a default object with `name`, `description`, `inputSchema`, and `execute`:

```js
// my-tool.mjs
export default {
  name: "my.tool_name",
  description: "What this tool does",
  inputSchema: {
    type: "object",
    properties: {
      id: { type: "string" }
    },
    required: ["id"],
    additionalProperties: false
  },
  execute: async (input) => {
    // do the work, return a plain object
    return { result: "ok", id: input.id };
  }
};
```

The clinic service runs at `http://localhost:3000` and exposes these endpoints you can call from any tool:

| Endpoint | Description |
| --- | --- |
| `GET /patients` | List all patient records |
| `DELETE /patients` | Delete all patient records |
| `DELETE /patients/:id` | Delete one patient by ID |
| `GET /health` | Health check |

See [tools/governed/db.read_patients.mjs](tools/governed/db.read_patients.mjs) for a minimal working example.

---

### Declare your tools

Create a `tools.yaml` in any directory and point OARR at it with `--tools-dir`:

```yaml
tools:
  - name: my.tool_name
    module: ./my-tool.mjs
    description: What this tool does
    input_schema:
      type: object
      properties:
        id:
          type: string
      required:
        - id
      additionalProperties: false
```

See [tools/governed/tools.yaml](tools/governed/tools.yaml) for a working reference.

---

### Write a policy

Policies control what your agent is allowed to do at runtime. Create a `policy.yaml`:

```yaml
runtime:
  allowed_models:
    - gpt-4o-mini        # which LLM models the agent may request
  allowed_tools:
    - my.tool_name       # tools not listed here are denied by default
  max_tool_calls: 10     # hard cap per run
  timeout: 30s           # max run duration
```

Omit `allowed_tools` entirely to allow all tools. Leave `allowed_models` empty to allow any model.

See [scenarios/healthcare-data-wipe/policy/policy.yaml](scenarios/healthcare-data-wipe/policy/policy.yaml) for a working reference.

---

### Run your agent through OARR

The CLI validates the LLM provider API key at startup — before your agent runs. Choose the mode that fits your situation.

#### Test mode — your agent makes no LLM calls (OpenAI provider, dummy key)

The default provider is OpenAI. It checks that `OPENAI_API_KEY` is non-empty on startup, even if your agent never sends an `llm.request`. Any non-empty value satisfies the check:

```bash
export OPENAI_API_KEY=any-placeholder
oarr run node path/to/your-agent.mjs \
  --policy path/to/policy.yaml \
  --tools-dir path/to/tools-dir \
  --trace-stdout \
  --non-interactive
```

#### Test mode — no API key at all (Ollama)

Ollama is the only provider that requires no API key. Ollama must be running locally on port 11434:

```bash
oarr run node path/to/your-agent.mjs \
  --provider ollama \
  --policy path/to/policy.yaml \
  --tools-dir path/to/tools-dir \
  --trace-stdout \
  --non-interactive
```

#### Live mode — real LLM calls via OpenAI

```bash
export OPENAI_API_KEY=sk-...
oarr run node path/to/your-agent.mjs \
  --policy path/to/policy.yaml \
  --tools-dir path/to/tools-dir \
  --trace-stdout \
  --non-interactive
```

#### Live mode — real LLM calls via Anthropic

```bash
export ANTHROPIC_API_KEY=sk-ant-...
oarr run node path/to/your-agent.mjs \
  --provider anthropic \
  --policy path/to/policy.yaml \
  --tools-dir path/to/tools-dir \
  --trace-stdout \
  --non-interactive
```

To confirm your `oarr` binary supports all required flags:

```bash
oarr run --help
```

Look for: `--tools`, `--tools-dir`, `--policy`, `--trace-stdout`.

---

### Audit the trace from your run

After any run, OARR stores a trace in `.oarr/traces.db`. View the latest:

```bash
npm run audit
npm run audit:beautify
```

Or pass a specific run ID:

```bash
bash scripts/audit-oarr.sh <run_id>
bash scripts/audit-oarr-pretty.sh <run_id>
```

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
