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
  const msg = { id, type: messageType, timestamp: nowIso(), payload };
  process.stdout.write(`${JSON.stringify(msg)}\n`);
}

async function readMessage() {
  return new Promise((resolve) => {
    const onLine = (line) => {
      const trimmed = line.trim();
      if (!trimmed) return;
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

  // The agent intends to call db.read_patients 8 times.
  // Policy max_tool_calls: 3 will cut it off on the 4th attempt.
  const INTENDED_CALLS = 8;
  let completedCalls = 0;
  let budgetExceededAt = null;
  let denialMessage = "";

  for (let i = 1; i <= INTENDED_CALLS; i++) {
    send("tool.call", { name: "db.read_patients", arguments: {} }, `audit_read_${i}`);
    const response = await readMessage();

    if (response?.type === "error") {
      const reason = String(response.payload?.reason ?? "");
      const isBudgetExceeded =
        reason.includes("policy_violation") ||
        reason.includes("budget") ||
        reason.includes("max_tool_calls") ||
        reason.includes("not allowed");

      if (isBudgetExceeded) {
        budgetExceededAt = i;
        denialMessage = (response.payload?.error ?? reason) || "budget exceeded";
        break;
      }

      // Unexpected error — surface it
      throw new Error(`unexpected error on call ${i}: ${JSON.stringify(response.payload)}`);
    }

    if (response?.type !== "tool.result") {
      throw new Error(`expected tool.result on call ${i}, got: ${response?.type}`);
    }

    completedCalls++;
  }

  send(
    "agent.result",
    {
      result: budgetExceededAt !== null ? "budget_exceeded" : "completed",
      intended_calls: INTENDED_CALLS,
      calls_completed: completedCalls,
      budget_exceeded_at: budgetExceededAt,
      denial_reason: denialMessage
    },
    "agent_result"
  );
}

const DEBUG_LOG =
  process.env.OARR_DEBUG_AGENT_LOG ||
  path.join(process.cwd(), "temp", "governed-audit-debug.log");

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
