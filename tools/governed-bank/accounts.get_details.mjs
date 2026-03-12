import { httpGet } from "./shared-client.mjs";

export default {
  name: "accounts.get_details",
  description: "Get details for a specific account by id",
  inputSchema: {
    type: "object",
    properties: {
      id: {
        anyOf: [{ type: "number" }, { type: "string" }],
        description: "Account id"
      }
    },
    required: ["id"],
    additionalProperties: false
  },
  execute: async (input) => {
    const id = Number(input.id);
    if (!Number.isInteger(id) || id <= 0) {
      throw new Error("invalid account id");
    }
    return httpGet(`/accounts/${id}`);
  }
};
