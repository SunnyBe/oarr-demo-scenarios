# Scenario 5 — Light Agent with Live LLM

**Goal:** The ultimate proof that OARR governs real AI agents. A lightweight agent with an actual LLM, small in-memory context, and tool-use loops through the runtime — demonstrating the full agentic flow.

## What This Scenario Proves

- **Real agent:** LLM reasons, selects tools, iterates based on results (not a mock loop)
- **Light footprint:** Small memory (conversation + tool results), minimal system prompt, single model
- **Harness in action:** OARR mediates both `llm.request` and `tool.call` — full governance

## Architecture

```
User goal
    │
    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  Light Agent (Node process)                                              │
│  • System prompt: "You are a clinic assistant. Use tools to help."       │
│  • Memory: messages[] (user + assistant + tool_results), max ~10 turns   │
│  • Loop: llm.request → parse tool_calls → tool.call → tool.result       │
│          → append to memory → repeat until done or max_tool_calls        │
└─────────────────────────────────────────────────────────────────────────┘
    │                    stdin/stdout (ARP protocol)
    │                    • runtime.start
    │                    • llm.request / llm.response
    │                    • tool.call / tool.result
    │                    • agent.result
    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│  OARR Harness                                                            │
│  • Policy: allowed_models, allowed_tools, max_tool_calls                 │
│  • Governs LLM calls and tool invocations                                │
│  • Trace / audit                                                        │
└─────────────────────────────────────────────────────────────────────────┘
    │
    ▼
Tools (db.read_patients, etc.) → HTTP → Clinic / Bank Services
```

## Modes

| Mode    | Agent                  | LLM                    | Tools                     | Services        |
|---------|------------------------|------------------------|---------------------------|-----------------|
| Direct  | Same logic, no harness| Direct OpenAI API call | Direct HTTP (clinicApiClient) | Local Docker |
| Governed| Same logic             | Via OARR `llm.request` | Via OARR `tool.call`      | Local Docker    |

## Requirements

- **OPENAI_API_KEY** — Real key (user provides). No placeholder.
- **Services** — `docker compose up` (clinic + bank) with dev credentials.
- **OARR CLI** — For governed runs.

## Implementation Plan

### 1. Governed agent (`governed-agent.mjs`)

1. Receive `runtime.start`
2. Build initial messages: system + user (e.g. "List the patients in the clinic")
3. Loop:
   - `send("llm.request", { model, messages })` → `readMessage()` for `llm.response`
   - Parse response for `tool_calls[]`
   - If tool_calls: for each, `send("tool.call", ...)` → `readMessage()` for `tool.result`; append tool results to messages
   - If no tool_calls and content: done → `send("agent.result", ...)`; break
   - If policy violation (error): `send("agent.result", { result: "policy_violation", ... })`; break
4. Respect `max_tool_calls` — OARR will enforce; agent should handle `error` type and surface denial

### 2. Direct mode (`direct-mode.ts`)

1. Use OpenAI SDK (or fetch) with function/tool definitions
2. Call `chat.completions` with `tools` and `tool_choice: "auto"`
3. If model returns `tool_calls`, execute via `clinicApiClient` (or governed tool wrappers invoked directly)
4. Append tool results to messages, call model again
5. Loop until model returns final text (no tool_calls)
6. No OARR — agent talks to OpenAI and services directly

### 3. Policy (`policy/policy.yaml`)

- `allowed_models: [gpt-4o-mini]`
- `allowed_tools: [db.read_patients]` (read-only for safety in demo)
- `max_tool_calls: 5`
- `timeout: 60s`

### 4. Scripts

- `run-governed-s5.sh` — OARR run with policy, tools-dir=governed
- `package.json`: `s5:direct`, `s5:governed`

### 5. Demo flow (optional, later)

- `demo-s5.sh` — Direct run (agent uses LLM + tools, no harness) then governed (OARR caps tool calls, governs model)

## Implementation Status

- [x] Scenario folder and SCENARIO.md (this file)
- [x] policy/policy.yaml
- [x] governed-agent.mjs — full LLM loop (llm.request → tool.call → memory → repeat)
- [x] direct-mode.ts — OpenAI SDK + clinicApiClient
- [x] run-governed-s5.sh
- [x] package.json entries (`s5:direct`, `s5:governed`)
- [x] `openai` dependency
