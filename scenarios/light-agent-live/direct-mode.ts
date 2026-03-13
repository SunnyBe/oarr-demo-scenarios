/**
 * Scenario 5 — Light Agent with Live LLM (Direct Mode)
 *
 * Same agent logic as governed-agent.mjs, but:
 * - Calls OpenAI API directly (no OARR)
 * - Uses clinicApiClient for tools — no harness mediation
 *
 * Requires: OPENAI_API_KEY
 */

import OpenAI from "openai";
import { readPatients } from "../../tools/direct/clinicApiClient";

const USER_GOAL = "List the patients in the clinic and summarize how many there are.";
const MODEL = process.env.OARR_LIVE_MODEL ?? "gpt-4o-mini";
const MAX_ITERATIONS = 10;

const TOOLS: OpenAI.Chat.Completions.ChatCompletionTool[] = [
  {
    type: "function",
    function: {
      name: "db_read_patients",
      description: "Read all patient records from the clinic system",
      parameters: { type: "object", properties: {}, additionalProperties: false }
    }
  }
];

async function run() {
  console.log("scenario.name light-agent-live");
  console.log("mode direct-unsafe");

  const apiKey = process.env.OPENAI_API_KEY;
  if (!apiKey || apiKey === "oarr-local-demo-key") {
    console.error("error: OPENAI_API_KEY required for direct mode. Set it before running.");
    process.exit(1);
  }

  const openai = new OpenAI({ apiKey });

  const messages: OpenAI.Chat.Completions.ChatCompletionMessageParam[] = [
    {
      role: "system",
      content:
        "You are a clinic assistant. Use the available tools to help the user. When you have the information, provide a brief summary."
    },
    { role: "user", content: USER_GOAL }
  ];

  let toolCallsTotal = 0;
  let finalContent = "";

  for (let i = 0; i < MAX_ITERATIONS; i++) {
    const completion = await openai.chat.completions.create({
      model: MODEL,
      messages,
      max_tokens: 512,
      tools: TOOLS,
      tool_choice: "auto"
    });

    const choice = completion.choices[0];
    if (!choice?.message) {
      throw new Error("No message in completion");
    }

    const msg = choice.message;
    messages.push(msg);

    if (!msg.tool_calls || msg.tool_calls.length === 0) {
      finalContent = msg.content ?? "";
      break;
    }

    for (const tc of msg.tool_calls) {
      toolCallsTotal++;
      if (tc.function.name === "db_read_patients") {
        const result = await readPatients();
        messages.push({
          role: "tool",
          tool_call_id: tc.id,
          content: JSON.stringify(result)
        });
      } else {
        messages.push({
          role: "tool",
          tool_call_id: tc.id,
          content: JSON.stringify({ error: `Unknown tool: ${tc.function.name}` })
        });
      }
    }
  }

  const patientCount = await readPatients().then((r) => r.patients.length);
  console.log(`agent.result completed`);
  console.log(`agent.tool_calls ${toolCallsTotal}`);
  console.log(`agent.final_summary ${finalContent.slice(0, 200).replace(/\n/g, " ")}...`);
  console.log(`verification.patient_count ${patientCount}`);
  console.log(`verification.governed false`);
}

run().catch((error) => {
  console.error("scenario.failed", error instanceof Error ? error.message : error);
  process.exit(1);
});
