# clinic-records-agent

Single v1 demo agent for clinic record operations.

This agent is used in two modes across the demo:

- direct unsafe mode (`Agent -> Clinic Service`)
- governed mode (`Agent -> OARR -> Clinic Service`)

Contract-required files are present for OARR runtime compatibility:

- `agent.yaml`
- `prompts/system.txt`
- `schemas/input.schema.json`
- `schemas/output.schema.json`
- `input.json`
