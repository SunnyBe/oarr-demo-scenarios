Below is a **clear, complete Agent Contract document** you can give to a coder model so it can build agents that are **fully compatible with the current OARR runtime**.

This document is written so that **any model with only this file** can produce valid agents for your demos.

Save it as something like:

```text
OARR_AGENT_CONTRACT.md
```

---

# OARR_AGENT_CONTRACT.md

## Agent Specification for OARR Runtime

This document defines the **agent contract required by the OARR runtime**.

Any agent used with the runtime must follow this structure so it can be:

* loaded
* validated
* executed
* governed by policy
* packaged and signed

This contract applies to:

* demo agents
* production agents
* packaged agents (`.oarrpkg`)
* registry-installed agents

---

# 1. Agent Directory Layout

An agent is a **directory with a specific structure**.

Example:

```
agent/
├── agent.yaml
├── input.json
├── prompts/
│   └── system.txt
└── schemas/
    ├── input.schema.json
    └── output.schema.json
```

Required files:

| File                         | Purpose                  |
| ---------------------------- | ------------------------ |
| `agent.yaml`                 | Agent manifest           |
| `prompts/system.txt`         | System prompt            |
| `schemas/input.schema.json`  | Input validation schema  |
| `schemas/output.schema.json` | Output validation schema |

Optional files may be added but the above are required.

---

# 2. Agent Manifest

The agent manifest defines how the runtime executes the agent.

File:

```
agent.yaml
```

Example:

```yaml
name: patient-cleanup-agent
version: "1.0.0"

model: gpt-4o-mini

system_prompt_file: prompts/system.txt

input_schema_file: schemas/input.schema.json
output_schema_file: schemas/output.schema.json
```

---

## Manifest Fields

### name

Human-readable agent name.

Example:

```
name: healthcare-cleanup-agent
```

---

### version

Agent version.

Must be a string.

Example:

```
version: "1.0.0"
```

---

### model

LLM model used for the agent.

Example:

```
model: gpt-4o-mini
```

The runtime may restrict allowed models via policy.

---

### system_prompt_file

Path to the system prompt.

Example:

```
system_prompt_file: prompts/system.txt
```

This file contains the core instructions for the agent.

---

### input_schema_file

Path to the JSON schema describing the agent's expected input.

Example:

```
input_schema_file: schemas/input.schema.json
```

---

### output_schema_file

Path to the JSON schema describing the agent's output.

Example:

```
output_schema_file: schemas/output.schema.json
```

The runtime validates the agent's output against this schema.

---

# 3. System Prompt

The system prompt defines the agent's behavior.

File:

```
prompts/system.txt
```

Example:

```
You are a healthcare database assistant.

You help manage patient records and maintain database hygiene.

You may use tools to read or modify patient records when necessary.

Always follow safety guidelines and explain your actions clearly.
```

This prompt guides the LLM when deciding which tools to call.

---

# 4. Input Schema

Input schemas are JSON Schema documents that define what input the agent accepts.

Example:

```
schemas/input.schema.json
```

Example schema:

```json
{
  "type": "object",
  "properties": {
    "task": {
      "type": "string",
      "description": "The task the agent should perform"
    }
  },
  "required": ["task"],
  "additionalProperties": false
}
```

The runtime validates input against this schema before executing the agent.

---

# 5. Output Schema

The output schema defines the structure of the agent's final output.

Example:

```
schemas/output.schema.json
```

Example:

```json
{
  "type": "object",
  "properties": {
    "result": {
      "type": "string"
    }
  },
  "required": ["result"],
  "additionalProperties": false
}
```

The runtime validates the final agent output.

---

# 6. Input File

When running an agent locally, the runtime expects an input file.

Example:

```
input.json
```

Example:

```json
{
  "task": "Clean up outdated patient records"
}
```

The runtime loads this input and validates it against the input schema.

---

# 7. Tool Invocation Model

Agents do not execute system commands directly.

Instead they call **tools**.

Example tool names:

```
db.read_patients
db.delete_all_patients
slack.post_message
filesystem.clean_tmp
```

The runtime intercepts all tool calls and applies governance rules.

---

# 8. Runtime Execution Flow

The execution flow is:

```
load agent manifest
↓
load system prompt
↓
validate input
↓
LLM reasoning
↓
tool invocation request
↓
runtime policy validation
↓
tool execution (if allowed)
↓
final response validation
```

Policies may block actions.

Example runtime event:

```
policy_violation: tool db.delete_all_patients not allowed
```

---

# 9. Runtime Policies

Policies can restrict:

* models
* tools
* tool call limits
* trusted publishers

Example policy:

```yaml
runtime:
  allowed_tools:
    - db.read_patients

  max_tool_calls: 3
```

If an agent attempts a disallowed tool call, execution stops.

---

# 10. Packaging

Agents can be packaged for distribution.

Command:

```
oarr agent package <agent-dir>
```

This produces:

```
agent.oarrpkg
```

Packages are deterministic archives containing the agent directory.

---

# 11. Signing

Packages can be cryptographically signed.

Commands:

```
oarr keygen
oarr agent sign agent.oarrpkg
```

This produces:

```
agent.oarrpkg.sig
```

Signatures use **Ed25519**.

The runtime verifies signatures when installing agents from the registry.

---

# 12. Running Agents

Agents can be executed locally.

Example:

```
oarr run agent-dir
```

With explicit input:

```
oarr run agent-dir --input input.json
```

---

# 13. Agent References

Agents can also be installed from the registry and referenced by version.

Example:

```
oarr run summarizer@1.2.0
```

The runtime resolves the installed package and executes it.

---

# 14. Trace Events

The runtime emits trace events during execution.

Examples:

```
llm.request
tool.call
policy.violation
execution.denied
run.completed
```

These traces are stored in SQLite.

---

# 15. Demo Agent Design Guidance

Agents built for demo scenarios should:

* attempt realistic tasks
* occasionally request dangerous tools
* rely on the runtime to enforce safety

Example demo task:

```
Clean up outdated patient records.
```

Example dangerous tool request:

```
db.delete_all_patients
```

The runtime should block this action based on policy.

---

# 16. Summary

To create a valid OARR agent, implement:

```
agent.yaml
prompts/system.txt
schemas/input.schema.json
schemas/output.schema.json
input.json
```

Ensure the manifest references the correct files and the schemas validate correctly.

Once created, the agent can be:

```
run
packaged
signed
published
installed
```

under the OARR runtime governance model.

---

If you'd like, I can also provide a **ready-to-copy minimal agent template** that your coder model can reuse to generate **all demo agents automatically**.
