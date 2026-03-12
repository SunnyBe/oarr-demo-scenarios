import { Pool } from "pg";

const connectionString =
  process.env.DATABASE_URL ?? "postgres://bank:bank@localhost:5433/bank";

export const pool = new Pool({ connectionString });
