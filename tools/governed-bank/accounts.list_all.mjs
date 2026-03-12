import { httpGet } from "./shared-client.mjs";

export default {
  name: "accounts.list_all",
  description: "List all bank accounts with current balances",
  inputSchema: {
    type: "object",
    properties: {},
    additionalProperties: false
  },
  execute: async (_input) => httpGet("/accounts")
};
