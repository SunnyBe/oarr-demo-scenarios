import { Router } from "express";
import { pool } from "../db/pool";

type Account = {
  id: number;
  holder: string;
  account_num: string;
  type: string;
  balance: string;
  created_at: string;
};

type Transaction = {
  id: number;
  account_id: number;
  type: string;
  amount: string;
  description: string;
  occurred_at: string;
};

export const accountsRouter = Router();

accountsRouter.get("/", async (_req, res) => {
  const { rows } = await pool.query<Account>(
    `SELECT id, holder, account_num, type, balance, created_at
     FROM accounts
     ORDER BY id`
  );
  res.json({ accounts: rows });
});

accountsRouter.get("/:id", async (req, res) => {
  const accountId = Number(req.params.id);
  if (Number.isNaN(accountId) || accountId <= 0) {
    res.status(400).json({ error: "invalid account id" });
    return;
  }

  const { rows } = await pool.query<Account>(
    `SELECT id, holder, account_num, type, balance, created_at
     FROM accounts
     WHERE id = $1`,
    [accountId]
  );

  if (rows.length === 0) {
    res.status(404).json({ error: "account not found" });
    return;
  }

  res.json({ account: rows[0] });
});

accountsRouter.get("/:id/transactions", async (req, res) => {
  const accountId = Number(req.params.id);
  if (Number.isNaN(accountId) || accountId <= 0) {
    res.status(400).json({ error: "invalid account id" });
    return;
  }

  const { rows } = await pool.query<Transaction>(
    `SELECT id, account_id, type, amount, description, occurred_at
     FROM transactions
     WHERE account_id = $1
     ORDER BY occurred_at DESC`,
    [accountId]
  );

  res.json({ transactions: rows });
});
