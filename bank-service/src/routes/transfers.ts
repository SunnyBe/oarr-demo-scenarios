import { Router } from "express";
import { pool } from "../db/pool";

export const transfersRouter = Router();

transfersRouter.post("/", async (req, res) => {
  const { from_account_id, to_account_id, amount, memo } = req.body as {
    from_account_id: unknown;
    to_account_id: unknown;
    amount: unknown;
    memo: unknown;
  };

  const fromId = Number(from_account_id);
  const toId = Number(to_account_id);
  const transferAmount = Number(amount);
  const transferMemo = String(memo ?? "");

  if (!Number.isInteger(fromId) || fromId <= 0) {
    res.status(400).json({ error: "invalid from_account_id" });
    return;
  }
  if (!Number.isInteger(toId) || toId <= 0) {
    res.status(400).json({ error: "invalid to_account_id" });
    return;
  }
  if (!Number.isFinite(transferAmount) || transferAmount <= 0) {
    res.status(400).json({ error: "invalid amount" });
    return;
  }
  if (fromId === toId) {
    res.status(400).json({ error: "from and to accounts must differ" });
    return;
  }

  const client = await pool.connect();
  try {
    await client.query("BEGIN");

    const { rows: fromRows } = await client.query<{ balance: string }>(
      "SELECT balance FROM accounts WHERE id = $1 FOR UPDATE",
      [fromId]
    );
    if (fromRows.length === 0) {
      await client.query("ROLLBACK");
      res.status(404).json({ error: "source account not found" });
      return;
    }

    const fromBalance = Number(fromRows[0].balance);
    if (fromBalance < transferAmount) {
      await client.query("ROLLBACK");
      res.status(422).json({ error: "insufficient funds" });
      return;
    }

    const { rows: toRows } = await client.query<{ id: number }>(
      "SELECT id FROM accounts WHERE id = $1 FOR UPDATE",
      [toId]
    );
    if (toRows.length === 0) {
      await client.query("ROLLBACK");
      res.status(404).json({ error: "destination account not found" });
      return;
    }

    await client.query(
      "UPDATE accounts SET balance = balance - $1 WHERE id = $2",
      [transferAmount, fromId]
    );
    await client.query(
      "UPDATE accounts SET balance = balance + $1 WHERE id = $2",
      [transferAmount, toId]
    );

    const { rows: transferRows } = await client.query<{ id: number; initiated_at: string }>(
      `INSERT INTO transfers (from_account_id, to_account_id, amount, memo, status)
       VALUES ($1, $2, $3, $4, 'completed')
       RETURNING id, initiated_at`,
      [fromId, toId, transferAmount, transferMemo]
    );

    await client.query("COMMIT");

    res.json({
      transfer: {
        id: transferRows[0].id,
        from_account_id: fromId,
        to_account_id: toId,
        amount: transferAmount,
        memo: transferMemo,
        status: "completed",
        initiated_at: transferRows[0].initiated_at
      }
    });
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
});
