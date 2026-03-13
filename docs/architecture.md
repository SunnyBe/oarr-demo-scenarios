# OARR Agentic System Architecture

This document describes the relationship between **services**, **light agents**, **tools**, and the **OARR harness** in our demo scenarios.

---

## Architecture Diagram

```
┌─────────────────┐     stdin/stdout      ┌─────────────────┐
│  Light Agent    │◄─────────────────────►│  OARR Harness   │
│  (intent loop)  │   tool.call/result    │  (policy gate)  │
│                 │   llm.request/response                   │
└─────────────────┘                       └────────┬────────┘
                                                   │ invokes
                                          ┌────────▼────────┐
                                          │  Tools         │
                                          │  (HTTP adapters)│
                                          └────────┬────────┘
                                                   │
                                          ┌────────▼────────┐
                                          │  Services       │
                                          │  clinic, bank   │
                                          └─────────────────┘
```

---

## Layer Roles

| Layer | Role |
|-------|------|
| **Light Agent** | Minimal intelligence: selects tools, holds short-term memory (conversation + tool results), loops until goal is met or budget exhausted. May use an LLM for tool choice. |
| **OARR Harness** | Policy gate between agent and tools. Evaluates `allowed_tools`, `max_tool_calls`, `allowed_models`. Blocks disallowed actions before they reach tools. Emits audit traces. |
| **Tools** | Thin adapters that map tool invocations to HTTP calls. Implement the same interface whether invoked directly (uncontrolled) or through OARR (governed). |
| **Services** | Backend systems (clinic API, bank API) running in Docker. Hold the actual data and business logic. |

---

## Data Flow

1. **Agent** sends `tool.call` (or `llm.request`) over stdout.
2. **OARR** receives it, evaluates policy, and either forwards to the tool (or model) or returns `policy_violation`.
3. **Tools** call services over HTTP and return `tool.result`.
4. **Agent** receives results, updates its memory, and may issue more calls or send `agent.result`.

In **direct mode** (no harness), the agent invokes tools (or services) directly — there is no policy gate, so dangerous actions execute unimpeded.

---

## Related

- [Demo Flow Guide](./demo-flow.md) — step-by-step narrative for each scenario
- Scenario 5 (light-agent-live) — real LLM agent with memory, proving the harness with live credentials
