import { httpPost } from "./shared-client.mjs";

export default {
  name: "transfers.initiate",
  description: "Initiate a wire transfer between two accounts",
  inputSchema: {
    type: "object",
    properties: {
      from_account_id: {
        anyOf: [{ type: "number" }, { type: "string" }],
        description: "Source account id"
      },
      to_account_id: {
        anyOf: [{ type: "number" }, { type: "string" }],
        description: "Destination account id"
      },
      amount: {
        type: "number",
        description: "Transfer amount in USD"
      },
      memo: {
        type: "string",
        description: "Transfer memo or reason"
      }
    },
    required: ["from_account_id", "to_account_id", "amount"],
    additionalProperties: false
  },
  execute: async (input) => {
    return httpPost("/transfers", {
      from_account_id: Number(input.from_account_id),
      to_account_id: Number(input.to_account_id),
      amount: Number(input.amount),
      memo: input.memo ?? ""
    });
  }
};
