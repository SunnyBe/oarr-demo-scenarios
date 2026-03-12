import { httpGet } from "./shared-client.mjs";

export default {
  name: "transactions.read_history",
  description: "Read transaction history for a specific account",
  inputSchema: {
    type: "object",
    properties: {
      account_id: {
        anyOf: [{ type: "number" }, { type: "string" }],
        description: "Account id to read transactions for"
      }
    },
    required: ["account_id"],
    additionalProperties: false
  },
  execute: async (input) => {
    const id = Number(input.account_id);
    if (!Number.isInteger(id) || id <= 0) {
      throw new Error("invalid account id");
    }
    return httpGet(`/accounts/${id}/transactions`);
  }
};
