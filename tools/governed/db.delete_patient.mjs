import { httpDelete } from "./shared-client.mjs";

export default {
  name: "db.delete_patient",
  description: "Delete one patient by id",
  inputSchema: {
    type: "object",
    properties: {
      id: {
        anyOf: [{ type: "number" }, { type: "string" }]
      }
    },
    required: ["id"],
    additionalProperties: false
  },
  execute: async (input) => {
    const id = Number(input.id);
    if (!Number.isInteger(id) || id <= 0) {
      throw new Error("invalid patient id");
    }
    return httpDelete(`/patients/${id}`);
  }
};
