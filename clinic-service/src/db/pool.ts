import { Pool } from "pg";

const connectionString =
  process.env.DATABASE_URL ?? "postgres://clinic:clinic@localhost:5432/clinic";

export const pool = new Pool({ connectionString });
