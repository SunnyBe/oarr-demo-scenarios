#!/usr/bin/env node
// Pipeline Step 2: Claims Billing Agent
// Reads account data, then attempts to initiate a billing wire transfer.
// Policy allows: accounts.list_all, transactions.read_history
// Policy blocks: transfers.initiate  ← This is the governance demonstration.

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

  // Step 2a: List all accounts (allowed)
  send("tool.call", { name: "accounts.list_all", arguments: {} }, "step2_list_accounts");
  const accountsResult = await readMessage();
  if (!accountsResult || accountsResult.type !== "tool.result") {
    throw new Error("expected tool.result for accounts.list_all");
  }

  // Step 2b: Read transaction history for Firm Operations account (id 5 — allowed)
  send("tool.call", { name: "transactions.read_history", arguments: { account_id: 5 } }, "step2_read_transactions");
  const txResult = await readMessage();
  if (!txResult || txResult.type !== "tool.result") {
    throw new Error("expected tool.result for transactions.read_history");
  }

  // Step 2c: Attempt billing wire transfer — $1,750.00 (5 patients × $350 each)
  // transfers.initiate is NOT in the policy allowed_tools — OARR blocks this.
  const BILLING_AMOUNT = 1750.00;
  send(
    "tool.call",
    {
      name: "transfers.initiate",
      arguments: {
        from_account_id: 3,   // Priya Nair / CHK-00287 (insurance payer)
        to_account_id: 5,     // Firm Operations / OPS-00401 (hospital account)
        amount: BILLING_AMOUNT,
        memo: "Insurance claims batch — 5 patients, $350.00 each"
      }
    },
    "step2_billing_transfer"
  );
  const transferResponse = await readMessage();

  let denied = false;
  let denialMessage = "";

  if (transferResponse?.type === "error") {
    const reason = String(transferResponse.payload?.reason ?? "");
    denied = reason.includes("policy_violation") ||
             reason.includes("not allowed") ||
             reason.includes("denied");
    denialMessage = (transferResponse.payload?.error ?? reason) || "policy violation";
  }

  send("agent.result", {
    result: denied ? "pipeline_blocked_at_billing" : "billing_transfer_executed",
    transfer_requested: true,
    transfer_denied: denied,
    billing_amount: BILLING_AMOUNT,
    denial_reason: denialMessage
  }, "step2_result");
}

const DEBUG_LOG = process.env.OARR_DEBUG_AGENT_LOG ||
  path.join(process.cwd(), "temp", "pipeline-step2-debug.log");

function debugLog(msg) {
  try { fs.mkdirSync(path.dirname(DEBUG_LOG), { recursive: true }); fs.appendFileSync(DEBUG_LOG, `${new Date().toISOString()} ${msg}\n`); } catch (_) {}
}

main().catch((error) => {
  const msg = error instanceof Error ? error.message : String(error);
  debugLog(`step2.error: ${msg}`);
  process.stderr.write(`${msg}\n`);
  rl.close();
  process.exit(1);
});
