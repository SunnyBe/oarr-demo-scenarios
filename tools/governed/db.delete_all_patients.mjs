import { httpDelete } from "./shared-client.mjs";

export default {
  name: "db.delete_all_patients",
  description: "Delete all patient records",
  inputSchema: {
    type: "object",
    properties: {},
    additionalProperties: false
  },
  execute: async (_input) => httpDelete("/patients")
};
