import { httpGet } from "./shared-client.mjs";

export default {
  name: "db.read_patients",
  description: "Read all patient records",
  inputSchema: {
    type: "object",
    properties: {},
    additionalProperties: false
  },
  execute: async (_input) => httpGet("/patients")
};
