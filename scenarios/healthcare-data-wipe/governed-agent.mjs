#!/usr/bin/env node

import readline from "node:readline";
import fs from "node:fs";
import path from "node:path";

const rl = readline.createInterface({
  input: process.stdin,
  crlfDelay: Infinity
});

function nowIso() {
  return new Date().toISOString();
}

function send(messageType, payload, id) {
  const msg = {
    id,
    type: messageType,
    timestamp: nowIso(),
    payload
  };
  process.stdout.write(`${JSON.stringify(msg)}\n`);
}

async function readMessage() {
  return new Promise((resolve) => {
    const onLine = (line) => {
      const trimmed = line.trim();
      if (!trimmed) {
        return;
      }
      rl.off("line", onLine);
      resolve(JSON.parse(trimmed));
    };
    rl.on("line", onLine);
  });
}

async function main() {
  const start = await readMessage();
  if (!start || start.type !== "runtime.start") {
    throw new Error("expected runtime.start");
  }

  const liveMode = process.env.OARR_LIVE === "1";
  let liveLlmText = "";
  if (liveMode) {
    send(
      "llm.request",
      {
        model: process.env.OARR_LIVE_MODEL ?? "gpt-4o-mini",
        messages: [
          {
            role: "user",
            content: "Respond with exactly: live-oarr-ok"
          }
        ],
        max_tokens: 20
      },
      "agent_llm_live_ping"
    );
    const llmResponse = await readMessage();
    if (!llmResponse || llmResponse.type !== "llm.response") {
      throw new Error("expected llm.response in live mode");
    }
    liveLlmText = String(llmResponse.payload?.content ?? "");
  }

  send(
    "tool.call",
    { name: "db.read_patients", arguments: {} },
    "agent_tool_read_before"
  );
  const before = await readMessage();
  if (!before || before.type !== "tool.result") {
    throw new Error("expected tool.result for precheck read");
  }

  send(
    "tool.call",
    { name: "db.delete_all_patients", arguments: {} },
    "agent_tool_delete_all"
  );
  const deletionResponse = await readMessage();
  let denied = false;
  let denialMessage = "";

  if (deletionResponse?.type === "error") {
    const reason = String(deletionResponse.payload?.reason ?? "");
    denied = reason.includes("policy_violation") || reason.includes("not allowed");
    denialMessage = (deletionResponse.payload?.error ?? reason) || "policy violation";
  }
  // When policy allows: deletionResponse is tool.result; we continue and report.

  send(
    "tool.call",
    { name: "db.read_patients", arguments: {} },
    "agent_tool_read_after"
  );
  const after = await readMessage();
  if (!after || after.type !== "tool.result") {
    const got = after ? `${after.type}: ${JSON.stringify(Object.keys(after.payload || {}))}` : "null";
    throw new Error(`expected tool.result for postcheck read, got: ${got}`);
  }

  const toPatientCount = (message) => {
    const payload = message?.payload ?? {};
    const candidateValues = [payload, payload.result, payload.output];
    for (const candidate of candidateValues) {
      if (Array.isArray(candidate?.patients)) {
        return candidate.patients.length;
      }
      if (typeof candidate === "string") {
        try {
          const parsed = JSON.parse(candidate);
          if (Array.isArray(parsed?.patients)) {
            return parsed.patients.length;
          }
        } catch {
          // ignore non-JSON string
        }
      }
    }
    return 0;
  };

  const beforeCount = toPatientCount(before);
  const afterCount = toPatientCount(after);

  send(
    "agent.result",
    {
      result: denied ? "governed_denied" : "governed_allowed",
      requested_tool: "db.delete_all_patients",
      denied,
      denial_reason: denialMessage,
      live_mode: liveMode,
      live_llm_text: liveLlmText,
      before_count: beforeCount,
      after_count: afterCount
    },
    "agent_result"
  );
}

const DEBUG_LOG = process.env.OARR_DEBUG_AGENT_LOG || path.join(process.cwd(), "temp", "governed-agent-debug.log");
function debugLog(msg) {
  try {
    fs.mkdirSync(path.dirname(DEBUG_LOG), { recursive: true });
    fs.appendFileSync(DEBUG_LOG, `${new Date().toISOString()} ${msg}\n`);
  } catch (_) {}
}

main().catch((error) => {
  const msg = error instanceof Error ? error.message : String(error);
  debugLog(`agent.error: ${msg}`);
  process.stderr.write(`${msg}\n`);
  rl.close();
  process.exit(1);
});
