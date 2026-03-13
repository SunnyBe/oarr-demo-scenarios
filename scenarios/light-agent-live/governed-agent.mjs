#!/usr/bin/env node
/**
 * Scenario 5 — Light Agent with Live LLM (Governed)
 *
 * A real agent: LLM reasons, selects tools, iterates based on results.
 * All LLM and tool calls go through OARR — full governance.
 */

import readline from "node:readline";
import fs from "node:fs";
import path from "node:path";

const rl = readline.createInterface({
  input: process.stdin,
  crlfDelay: Infinity
});

const MODEL = process.env.OARR_LIVE_MODEL ?? "gpt-4o-mini";
const USER_GOAL = "List the patients in the clinic and summarize how many there are.";
const MAX_MESSAGE_TURNS = 12;

const TOOLS = [
  {
    type: "function",
    function: {
      name: "db.read_patients",
      description: "Read all patient records from the clinic system",
      parameters: { type: "object", properties: {}, additionalProperties: false }
    }
  }
];

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

function extractToolResultPayload(msg) {
  const p = msg?.payload ?? {};
  for (const candidate of [p, p.result, p.output]) {
    if (candidate && typeof candidate === "object") return candidate;
  }
  if (typeof p === "string") {
    try {
      return JSON.parse(p);
    } catch {
      return p;
    }
  }
  return p;
}

async function main() {
  const start = await readMessage();
  if (!start || start.type !== "runtime.start") {
    throw new Error("expected runtime.start");
  }

  const messages = [
    {
      role: "system",
      content: "You are a clinic assistant. Use the available tools to help the user. When you have the information, provide a brief summary."
    },
    { role: "user", content: USER_GOAL }
  ];

  let toolCallsTotal = 0;
  let finalContent = null;
  let policyViolation = null;
  let llmCallCount = 0;

  while (messages.length < MAX_MESSAGE_TURNS) {
    llmCallCount++;

    send(
      "llm.request",
      {
        model: MODEL,
        messages,
        max_tokens: 512,
        tools: TOOLS,
        tool_choice: "auto"
      },
      `llm_req_${llmCallCount}`
    );

    const llmResp = await readMessage();

    if (llmResp?.type === "error") {
      const reason = String(llmResp.payload?.reason ?? llmResp.payload?.error ?? "");
      policyViolation = reason.includes("policy_violation") || reason.includes("not allowed") || reason.includes("budget");
      break;
    }

    if (!llmResp || llmResp.type !== "llm.response") {
      throw new Error(`expected llm.response, got: ${llmResp?.type}`);
    }

    const payload = llmResp.payload ?? {};
    // Handle both flat payload and OpenAI-style choices[0].message
    const msg = payload.choices?.[0]?.message ?? payload;
    const content = msg.content ?? payload.content ?? null;
    const toolCalls = msg.tool_calls ?? payload.tool_calls ?? payload.toolCalls ?? [];

    if (toolCalls.length === 0) {
      finalContent = content || "";
      break;
    }

    const assistantMsg = {
      role: "assistant",
      content: content || null,
      tool_calls: toolCalls.map((tc) => ({
        id: tc.id,
        type: "function",
        function: { name: tc.function?.name ?? tc.name, arguments: tc.function?.arguments ?? tc.arguments ?? "{}" }
      }))
    };
    messages.push(assistantMsg);

    for (const tc of assistantMsg.tool_calls) {
      let args = {};
      try {
        args = typeof tc.function.arguments === "string" ? JSON.parse(tc.function.arguments) : tc.function.arguments ?? {};
      } catch (_) {}

      send("tool.call", { name: tc.function.name, arguments: args }, `tool_${toolCallsTotal}`);
      toolCallsTotal++;

      const toolResp = await readMessage();

      if (toolResp?.type === "error") {
        const reason = String(toolResp.payload?.reason ?? toolResp.payload?.error ?? "");
        policyViolation = reason.includes("policy_violation") || reason.includes("max_tool_calls") || reason.includes("not allowed");
        const errContent = JSON.stringify({ error: reason, denied: true });
        messages.push({ role: "tool", tool_call_id: tc.id, content: errContent });
        break;
      }

      if (!toolResp || toolResp.type !== "tool.result") {
        throw new Error(`expected tool.result, got: ${toolResp?.type}`);
      }

      const resultPayload = extractToolResultPayload(toolResp);
      const resultContent = typeof resultPayload === "string" ? resultPayload : JSON.stringify(resultPayload);
      messages.push({ role: "tool", tool_call_id: tc.id, content: resultContent });
    }

    if (policyViolation) break;
  }

  const result = policyViolation
    ? "policy_violation"
    : finalContent !== null
      ? "completed"
      : "max_turns_exceeded";

  send(
    "agent.result",
    {
      result,
      goal: USER_GOAL,
      final_content: finalContent,
      llm_calls: llmCallCount,
      tool_calls: toolCallsTotal,
      policy_violation: !!policyViolation
    },
    "agent_result"
  );
}

const DEBUG_LOG =
  process.env.OARR_DEBUG_AGENT_LOG ||
  path.join(process.cwd(), "temp", "light-agent-debug.log");

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
