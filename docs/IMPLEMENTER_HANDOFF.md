Perfect. Here is the **corrected v1 coding-model handoff** with the right architecture and tighter scope.

````md
# OARR Demo Scenarios v1 orrected Coding Model Handof \

## Purpose

Build the first clear product-proof demo for **OARR (Open Agent Runtime & Registry)**.

The demo must prove this exact story:

> A normal agent interacting with a normal backend service can cause catastrophic damage when run directly.  
> The same agent behavior, when routed through OARR, is governed and the destructive action is blocked.

This is the key comparison:

```text
Without OARR:
Agent -> Clinic Service

With OARR:
Agent -> OARR -> Clinic Service
````

That comparison is the product.

---

# 1. Critical Architectural Model

This must be implemented with the following mental model:

## The clinic service is standalone

The clinic service is a normal backend service that exists independently of OARR.

It should have:

* no OARR-specific logic
* no awareness of agents
* no awareness of governed vs unguided callers

It is just a normal service with HTTP endpoints.

## The agent is a separate client

A clinic records/admin agent interacts with the clinic service.

That agent can be executed in two ways:

### Unsafe direct mode

```text
Agent -> Clinic Service
```

The agent uses direct access to the clinic API and can execute dangerous actions.

### Safe governed mode

```text
Agent -> OARR -> Clinic Service
```

The same style of agent execution goes through OARR, where tool access is mediated and policy is enforced.

## Important

Do **not** architect the clinic service as if OARR sits inside it.

OARR is not part of the clinic service internals.

OARR is a governance/runtime layer wrapped around agent execution.

---

# 2. v1 Demo Goal

Build one flagship scenario that demonstrates:

## Scenario

A clinic records/admin agent attempts a destructive bulk delete of patient records.

### In unsafe direct mode

The destructive action succeeds.

### In governed OARR mode

The destructive action is blocked before it reaches the clinic service.

This gives a clear before/after demo.

---

# 3. Locked Tech Decisions

Use these choices:

* **Language:** TypeScript
* **Runtime:** Node.js
* **API framework:** Express
* **Database:** PostgreSQL
* **Environment:** Docker / Docker Compose
* **Transport to clinic service:** HTTP
* **Auth:** none for v1
* **Scope:** one service, one agent, one destructive scenario, two execution modes

---

# 4. Scope Discipline

## Optimize for

* clarity
* reproducibility
* low setup friction
* obvious comparison between unsafe and governed modes
* deterministic demo behavior
* easy architecture review

## Do NOT optimize for

* production security
* auth
* multiple agents
* multiple scenarios
* dashboards
* advanced approval workflows
* signatures
* registry features
* sophisticated packaging
* framework-heavy abstractions
* medical domain realism beyond what is needed for the demo

Keep v1 small and convincing.

---

# 5. Required Deliverables

Build the following pieces.

## A. Standalone Clinic Service

A small Express service backed by Postgres.

This service must be completely independent from OARR.

### Required endpoints

* `GET /health`
* `GET /patients`
* `DELETE /patients/:id`
* `DELETE /patients`

### Behavior

* `GET /patients` returns seeded patient records
* `DELETE /patients/:id` deletes one patient
* `DELETE /patients` deletes all patients
* simple JSON responses are fine

---

## B. PostgreSQL schema + seed

Use one table only for v1.

### `patients`

Columns:

* `id`
* `name`
* `dob`
* `diagnosis`
* `treatment`
* `created_at`

### Seed data

Include several clearly fake patient records.

Enough data should exist so the delete effect is obvious during the demo.

---

## C. One simple agent

Create **one agent only** for v1.

Suggested name:

```text
clinic-records-agent
```

This agent should represent an agent that can operate on clinic records.

The agent should be able to:

* read patients
* delete one patient
* attempt bulk deletion of all patients

Do not build multiple agent personas yet.

Do not build triage or onboarding agents in v1.

---

## D. Two execution modes

### 1. Direct unsafe mode

A direct execution path where the agent interacts with the clinic service without OARR mediation.

This path should be able to call the clinic API directly and successfully wipe the patient table.

This proves the catastrophe is real.

### 2. Governed OARR mode

A governed execution path where the same agent behavior goes through OARR-mediated tools.

In this path:

* OARR inspects tool usage
* OARR policy denies destructive bulk delete
* the clinic service does not receive the destructive action

This proves OARR value.

---

## E. Direct client/tool path for unsafe mode

Implement a simple direct client path for the unsafe mode.

This can be:

* a direct HTTP client used by the agent
* direct non-governed tool wrappers
* or the simplest equivalent

The important part is that this path does **not** go through OARR governance.

When the destructive command is attempted in this mode, it should succeed.

---

## F. OARR-governed tool adapters

Implement governed tools that target the clinic service over HTTP.

Required governed tools:

* `db.read_patients`
* `db.delete_patient`
* `db.delete_all_patients`

### Mapping

* `db.read_patients` -> HTTP GET `/patients`
* `db.delete_patient` -> HTTP DELETE `/patients/:id`
* `db.delete_all_patients` -> HTTP DELETE `/patients`

### Important

These are the governed tools used in the OARR path.

Do not bypass the clinic API by talking directly to Postgres from the governed tools.

The service boundary must remain real.

---

## G. One destructive scenario

Create one scenario only.

Suggested name:

```text
healthcare-data-wipe
```

This scenario should produce the same destructive intent in both modes:

> delete all patient records

### Expected results

* in direct mode: records are wiped
* in governed mode: the attempted bulk delete is denied

---

## H. Policy for governed mode

Create the smallest policy representation necessary for the demo.

The policy should:

* allow safe reads
* optionally allow single-record delete
* deny bulk patient wipe

At minimum:

### Allowed

```text
db.read_patients
db.delete_patient
```

### Denied

```text
db.delete_all_patients
```

If OARR already has a policy hook, integrate with it.
If not, implement only the thinnest temporary policy mechanism needed for this demo.

---

## I. Reset / reseed flow

Provide a simple way to reset the DB after unsafe execution wipes the records.

This can be:

* a reset script
* a reseed command
* a DB recreate flow

It should be quick and repeatable.

---

# 6. Required Demo Sequence

The repo should support this exact narrative:

## Step 1

Start the clinic service and database.

## Step 2

Show seeded patients exist.

## Step 3

Run the scenario in **direct unsafe mode**.

## Step 4

The agent successfully deletes all patients.

## Step 5

Verify patients are gone.

## Step 6

Reset/reseed the database.

## Step 7

Run the same scenario in **governed OARR mode**.

## Step 8

OARR blocks the destructive bulk delete.

## Step 9

Verify patients still exist.

This comparison is the centerpiece of the demo.

---

# 7. Suggested Repository Structure

Use something close to this:

```text
oarr-demo-scenarios/
  docker-compose.yml
  package.json
  tsconfig.json
  .env.example
  README.md

  clinic-service/
    src/
      server.ts
      app.ts
      routes/
        health.ts
        patients.ts
      db/
        pool.ts
    package.json
    tsconfig.json
    Dockerfile

  db/
    schema.sql
    seed.sql

  agents/
    clinic-records-agent/
      README.md
      prompts/
        instruction.txt
      agent.yaml

  scenarios/
    healthcare-data-wipe/
      README.md
      direct-mode.ts
      governed-mode.ts
      policy/
        policy.yaml

  tools/
    governed/
      db.read_patients.ts
      db.delete_patient.ts
      db.delete_all_patients.ts
    direct/
      clinicApiClient.ts

  scripts/
    reset-db.sh
    verify-patients.sh

  docs/
    demo-flow.md
```

This does not need to be exact, but keep it tidy and easy to review.

---

# 8. Behavior Expectations

## Clinic service

The clinic service is just a normal service.

It should:

* expose the required endpoints
* serve patient data
* allow deletions when called
* remain unaware of whether the caller is direct or governed

---

## Direct unsafe mode

This path should demonstrate the danger of running the agent without OARR.

Expected outcome:

* agent attempts destructive action
* destructive API call is sent
* clinic service accepts it
* patient records are deleted

This mode must succeed so that the comparison is real.

---

## Governed OARR mode

This path should demonstrate OARR’s value.

Expected outcome:

* agent attempts the same destructive action
* OARR routes execution through governed tool mediation
* policy evaluation happens before destructive call is sent
* bulk delete is denied
* clinic service never receives the bulk delete
* patient data remains intact

---

# 9. Acceptance Criteria

The implementation is successful only if all of the following are true.

## Infrastructure

* Docker Compose starts Postgres and clinic service successfully
* seeded patients exist after startup or reset

## Clinic service

* `GET /health` works
* `GET /patients` returns patients
* `DELETE /patients/:id` works
* `DELETE /patients` works

## Direct mode

* a direct execution path exists
* running the destructive scenario in direct mode wipes all patients
* post-run verification shows patients are gone

## Governed mode

* governed tools exist and use HTTP against the clinic service
* destructive scenario in governed mode attempts `db.delete_all_patients`
* OARR denies the action
* post-run verification shows patients still exist

## Reset

* there is a simple reset/reseed flow between direct and governed runs

## Documentation

* README explains how to run both modes and verify the results

---

# 10. Logging / Trace Expectations

The demo output must make the contrast obvious.

## Direct mode should visibly communicate something like:

```text
agent.request delete all patients
direct.api_call DELETE /patients
result success
```

Exact wording can vary.

## Governed mode should visibly communicate something like:

```text
llm.request
tool.call db.delete_all_patients
policy.violation
execution.denied
```

If possible, include a clear denial reason, for example:

```text
db.delete_all_patients is not allowed by policy
```

Do not build a large tracing system unless it already exists.

---

# 11. Implementation Guidance

## Keep the clinic service boring

It should feel like a normal backend service.

## Keep the direct mode simple

This is the unsafe comparison path, not a framework.

## Keep governed mode close to OARR’s real model

If OARR runtime hooks already exist, use them.
Do not build a fake replacement runtime unless absolutely necessary.

## Prefer obvious code over abstract code

This repo is for product demos and review.

## Do not overbuild agent infrastructure

One agent, one scenario, two execution paths.

## Keep the comparison sharp

The user should instantly understand:

* direct = dangerous
* OARR = governed

---

# 12. README Requirements

The README must explain:

## What this demo proves

A concise explanation of the product value.

## Architecture

Show the two paths:

```text
Without OARR:
Agent -> Clinic Service

With OARR:
Agent -> OARR -> Clinic Service
```

## How to run infrastructure

Example:

```bash
docker compose up --build
```

## How to verify initial data

Explain how to inspect patients before running scenarios.

## How to run direct unsafe mode

Exact command.

## How to verify wipe occurred

Exact command or check.

## How to reset

Exact command.

## How to run governed OARR mode

Exact command.

## How to verify data survived

Exact command or check.

Keep instructions crisp and reproducible.

---

# 13. Out of Scope

Do not include these in v1 unless absolutely required by existing OARR code:

* multiple agents
* triage agent
* onboarding agent
* notifications
* auth / API keys
* human approval handoff
* signatures
* registry
* advanced policy DSL
* UI/dashboard
* additional clinic tables
* multiple destructive scenarios
* complex packaging work

---

# 14. Expected Final Output From Coding Model

After implementation, provide an **update handoff** that includes:

## What was added

* files created
* main modules implemented
* assumptions made

## How direct mode works

* how the agent reaches the clinic service
* how the wipe succeeds

## How governed mode works

* how the agent goes through OARR
* how tool mediation happens
* how policy blocks the wipe

## Run instructions

* exact commands to start infra
* exact commands to run direct mode
* exact commands to verify wipe
* exact commands to reset
* exact commands to run governed mode
* exact commands to verify data survived

## Review hotspots

List the most important files for architecture review first.

Recommended review categories:

* `docker-compose.yml`
* clinic service server and routes
* DB schema and seed
* direct-mode implementation
* governed tool adapters
* scenario definition
* policy definition
* README

---

# 15. Preferred Mindset

This is not just a CRUD demo.

This is a **before-vs-after safety proof** for agent governance.

The implementation should help a developer instantly understand:

> running an agent directly against real systems is dangerous
> routing the agent through OARR makes those interactions governable and safer

That clarity is more important than extra features.

```

When the coding model comes back with its update handoff, paste it here and we’ll review it like a proper architecture gate.
```

======= REAL OARR HANDOFF =====


Below is a **clean, copyable handoff** you can give directly to the coder-model.
It explains **what to change, why, and how**, while preserving the current demo behavior.

This moves the demo from **simulated OARR runtime → real OARR CLI platform integration**.

---

# Coder Handoff — Milestone 6

## Replace Mock Governance With Real OARR CLI Integration

### Objective

Remove the **mock OARR runtime implemented inside this repo** and instead run the governed scenario through the **real OARR CLI platform**.

The demo should prove:

```
Direct Mode:
Agent -> Clinic Service

Governed Mode:
Agent -> OARR CLI -> Policy -> Tool -> Clinic Service
```

The scenario project must **use the real OARR platform**, not simulate it.

---

# Key Architectural Rule

The **scenario repo must not implement OARR logic**.

This repo should only contain:

```
clinic service
agent definition
policy file
scenario inputs
verification scripts
demo docs
```

All governance behavior must come from the **real OARR CLI runtime**.

---

# Required Changes

## 1 Remove Mock OARR Runtime

Delete the internal governance and agent execution scaffolding.

Remove these files:

```
runtime/governance/policy.ts
runtime/governance/runtime.ts
runtime/agent/contract.ts
runtime/agent/execute.ts
```

These were temporary scaffolding and must not remain.

---

# 2 Install Real OARR CLI

The scenario project must depend on the **OARR CLI package built in the main OARR project**.

### Expected OARR package interface

The OARR project should expose:

```
package.json
{
  "name": "oarr",
  "bin": {
    "oarr": "dist/cli.js"
  }
}
```

After installation, the CLI must be callable:

```
oarr --help
```

---

### Install method (preferred for development)

Use **local dependency linking**.

Example:

```
cd oarr-project
npm run build
npm link
```

Then inside the demo repo:

```
npm link oarr
```

Alternative:

```
npm pack
npm install ../oarr/oarr-x.x.x.tgz
```

---

# 3 Replace Governed Scenario Execution

The governed scenario should no longer call runtime functions.

Instead it should call the **OARR CLI**.

### Replace current behavior

Old:

```
executeAgentWithGovernance()
runtime.invokeTool()
```

New:

```
oarr run agents/clinic-records-agent --input agents/clinic-records-agent/input.json
```

---

### Update npm script

Update `package.json`:

```
"scripts": {
  "scenario:governed": "oarr run agents/clinic-records-agent --input agents/clinic-records-agent/input.json"
}
```

If policy flags are required:

```
"scenario:governed": "oarr run agents/clinic-records-agent --input agents/clinic-records-agent/input.json --policy scenarios/healthcare-data-wipe/policy/policy.yaml"
```

Use the correct CLI flags according to the OARR CLI implementation.

---

# 4 Ensure Tools Are Available To OARR

The OARR runtime must be able to execute the clinic tools.

Existing tool adapters should remain:

```
tools/governed/db.read_patients.ts
tools/governed/db.delete_patient.ts
tools/governed/db.delete_all_patients.ts
```

But they must now be **registered through OARR's tool registration mechanism**, not through local runtime code.

If OARR expects:

```
tool manifest
tool directory
or runtime plugin registration
```

adapt the repo accordingly.

---

# 5 Preserve Proof Scripts

Do **not change** these scripts.

They remain valid and must continue to pass:

```
scripts/reset-db.sh
scripts/prove-request-paths.sh
```

The expected results remain:

```
Direct Mode:
clinic.request DELETE /patients >= 1

Governed Mode:
clinic.request DELETE /patients == 0
```

---

# 6 Expected Execution Flow

## Direct Mode

```
npm run scenario:direct
```

Flow:

```
agent -> clinic service
DELETE /patients
database wipe
```

---

## Governed Mode

```
npm run scenario:governed
```

Flow:

```
agent
-> OARR CLI
-> policy evaluation
-> tool request: db.delete_all_patients
-> policy denial
-> tool never executed
-> clinic service never receives DELETE
```

---

# 7 Success Criteria

The migration is complete when:

### CLI availability

```
oarr --help
```

works inside the scenario repo.

---

### Governed run

```
npm run scenario:governed
```

shows a **policy denial from the OARR runtime**.

---

### Service proof

```
npm run prove:paths
```

still outputs:

```
proof.direct.delete_calls_to_service >= 1
proof.governed.delete_calls_to_service == 0
proof.result passed
```

---

# 8 Final Repo Architecture

After this milestone the repo should look like:

```
oarr-demo-scenarios/
  clinic-service/
  agents/
  scenarios/
  tools/
  scripts/
  docs/
```

No internal runtime implementation.

Governance must come **only from OARR CLI**.

---

# Important Notes

Do **not duplicate OARR runtime code** in this repo.

The demo project must behave exactly like a **real external user of the OARR platform**.

This strengthens the demo and prevents architectural drift.

---

# Deliverable

Provide updated code where:

```
scenario:governed
```

uses the **real OARR CLI** and all mock governance code is removed.

Ensure all existing demo scripts and proofs still pass.


---------- Improvement handoffs ---------

HANDOFF 1 — Demo Project Coder-Model
# Reviewer Direction — Demo Project Next Improvements
Project: oarr-demo-scenarios

## Context

The demo project has successfully migrated from mock governance to the **real OARR CLI runtime**.

Current architecture:

Direct mode
Agent -> Clinic Service

Governed mode
Agent -> OARR CLI -> Policy -> Tool -> Clinic Service

The service-boundary proof still passes:

direct mode delete calls >= 1  
governed mode delete calls = 0

This is correct and must remain intact.

The next improvements are **demo usability and narrative clarity**, not architectural changes.

Do not modify the core architecture.

---

# Goal of This Task

Improve the **demo usability and presentation quality** for:

- demo videos
- engineers evaluating the platform
- cofounders / technical reviewers
- visa / research review contexts

Focus on **demo flow clarity**, **visual trace readability**, and **reproducibility**.

---

# Task 1 — Add Unified Demo Command

Add a single command that runs the **entire demo sequence automatically**.

Add script:

scripts/demo.sh

Behavior:

1) reset database
2) verify seeded patients
3) run direct unsafe scenario
4) verify wipe occurred
5) reset database
6) verify reseed
7) run governed scenario
8) verify data survived
9) run service boundary proof

Example flow:


bash scripts/reset-db.sh
npm run verify:patients
npm run scenario:direct
npm run verify:patients
bash scripts/reset-db.sh
npm run verify:patients
npm run scenario:governed
npm run verify:patients
npm run prove:paths


Add npm alias:


npm run demo


This allows a **one-command demonstration**.

---

# Task 2 — Improve CLI Visualization

Add a **lightweight trace visualization helper**.

New script:

scripts/visualize-run.sh

Purpose:

Convert OARR trace output into a **simple readable flow**.

Example output format:


Agent
↓
OARR Runtime
↓
Policy Check
↓
Tool Request: db.delete_all_patients
↓
Policy Violation
↓
Execution Denied


This script should read stdout logs and map key events:


llm.request
tool.call
policy.violation
execution.denied
run.completed


Do not modify OARR itself.

Only transform the CLI output.

---

# Task 3 — Add Architecture Diagram

Update README.md with a simple architecture diagram.

Add section:

## Architecture


Direct Mode (Unsafe)

Agent
│
▼
Clinic Service
│
▼
Database

Governed Mode (OARR)

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


Also explain:

Direct mode allows destructive operations.  
Governed mode blocks them via policy.

---

# Task 4 — Add Scenario Explanation Section

Add section to README:

## What This Demo Proves

Explain:

1) Agents can perform destructive operations.
2) Without governance the system is vulnerable.
3) OARR intercepts tool calls.
4) Policies prevent unsafe execution.
5) The service never receives the destructive request.

Keep explanation simple and clear.

---

# Task 5 — Preserve Existing Proof Script

Do not modify:


scripts/prove-request-paths.sh


This script is the **canonical proof artifact**.

It verifies:

direct mode -> delete request reached clinic service  
governed mode -> delete request never reached clinic service

This must remain the authoritative verification.

---

# Scope Rules

Do not change:

- OARR CLI invocation
- policy behavior
- external tool structure
- clinic service logic
- agent behavior

Only improve **demo usability and presentation**.

---

# Deliverables

After implementation provide reviewer handoff with:

- new files created
- scripts added
- README sections updated
- example output from `npm run demo`
- confirmation that `npm run prove:paths` still passes
