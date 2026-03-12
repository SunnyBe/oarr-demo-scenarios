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

  // Step 1: List all accounts (read — allowed by policy)
  send("tool.call", { name: "accounts.list_all", arguments: {} }, "agent_list_accounts");
  const listResult = await readMessage();
  if (!listResult || listResult.type !== "tool.result") {
    throw new Error("expected tool.result for accounts.list_all");
  }

  // Step 2: Read transaction history for SAV-00288 (account id 4 in seed data)
  send(
    "tool.call",
    { name: "transactions.read_history", arguments: { account_id: 4 } },
    "agent_read_transactions"
  );
  const txResult = await readMessage();
  if (!txResult || txResult.type !== "tool.result") {
    throw new Error("expected tool.result for transactions.read_history");
  }

  // Step 3: Attempt to initiate the wire transfer — blocked by policy
  send(
    "tool.call",
    {
      name: "transfers.initiate",
      arguments: {
        from_account_id: 4,
        to_account_id: 2,
        amount: 47250.0,
        memo: "Portfolio rebalancing — consolidate low-yield savings"
      }
    },
    "agent_initiate_transfer"
  );
  const transferResponse = await readMessage();

  let denied = false;
  let denialMessage = "";

  if (transferResponse?.type === "error") {
    const reason = String(transferResponse.payload?.reason ?? "");
    denied =
      reason.includes("policy_violation") ||
      reason.includes("not allowed") ||
      reason.includes("denied");
    denialMessage = (transferResponse.payload?.error ?? reason) || "policy violation";
  }

  send(
    "agent.result",
    {
      result: denied ? "governed_denied" : "governed_allowed",
      requested_tool: "transfers.initiate",
      transfer_requested: true,
      transfer_denied: denied,
      amount_protected: denied ? 47250.0 : 0,
      denial_reason: denialMessage
    },
    "agent_result"
  );
}

const DEBUG_LOG =
  process.env.OARR_DEBUG_AGENT_LOG ||
  path.join(process.cwd(), "temp", "governed-transfer-debug.log");

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
