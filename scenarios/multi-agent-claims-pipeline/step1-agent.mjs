#!/usr/bin/env node
// Pipeline Step 1: Patient Records Agent
// Reads patient records from the clinic system.
// Governed by: tool_allowlist = [db.read_patients], max_tool_calls = 5

import readline from "node:readline";
import fs from "node:fs";
import path from "node:path";

const rl = readline.createInterface({ input: process.stdin, crlfDelay: Infinity });

function nowIso() { return new Date().toISOString(); }

function send(messageType, payload, id) {
  process.stdout.write(`${JSON.stringify({ id, type: messageType, timestamp: nowIso(), payload })}\n`);
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
  if (!start || start.type !== "runtime.start") throw new Error("expected runtime.start");

  send("tool.call", { name: "db.read_patients", arguments: {} }, "step1_read_patients");
  const result = await readMessage();
  if (!result || result.type !== "tool.result") {
    throw new Error("expected tool.result for db.read_patients");
  }

  const payload = result.payload ?? {};
  const candidates = [payload, payload.result, payload.output];
  let patientCount = 0;
  let patientNames = [];
  for (const c of candidates) {
    if (Array.isArray(c?.patients)) {
      patientCount = c.patients.length;
      patientNames = c.patients.map((p) => p.name);
      break;
    }
  }

  send("agent.result", {
    result: `${patientCount}_patients_retrieved:${patientNames.join(",")}`
  }, "step1_result");
}

const DEBUG_LOG = process.env.OARR_DEBUG_AGENT_LOG ||
  path.join(process.cwd(), "temp", "pipeline-step1-debug.log");

function debugLog(msg) {
  try { fs.mkdirSync(path.dirname(DEBUG_LOG), { recursive: true }); fs.appendFileSync(DEBUG_LOG, `${new Date().toISOString()} ${msg}\n`); } catch (_) {}
}

main().catch((error) => {
  const msg = error instanceof Error ? error.message : String(error);
  debugLog(`step1.error: ${msg}`);
  process.stderr.write(`${msg}\n`);
  rl.close();
  process.exit(1);
});
