const BANK_BASE_URL = process.env.BANK_BASE_URL ?? "http://localhost:3101";

async function parseJson<T>(response: Response): Promise<T> {
  const text = await response.text();
  if (!response.ok) {
    throw new Error(`bank api error ${response.status}: ${text || response.statusText}`);
  }
  return text ? (JSON.parse(text) as T) : ({} as T);
}

export type Account = {
  id: number;
  holder: string;
  account_num: string;
  type: string;
  balance: string;
  created_at: string;
};

export type Transaction = {
  id: number;
  account_id: number;
  type: string;
  amount: string;
  description: string;
  occurred_at: string;
};

export type Transfer = {
  id: number;
  from_account_id: number;
  to_account_id: number;
  amount: number;
  memo: string;
  status: string;
  initiated_at: string;
};

export async function listAllAccounts(): Promise<{ accounts: Account[] }> {
  const res = await fetch(`${BANK_BASE_URL}/accounts`);
  return parseJson(res);
}

export async function getAccountDetails(id: number): Promise<{ account: Account }> {
  const res = await fetch(`${BANK_BASE_URL}/accounts/${id}`);
  return parseJson(res);
}

export async function readTransactionHistory(
  accountId: number
): Promise<{ transactions: Transaction[] }> {
  const res = await fetch(`${BANK_BASE_URL}/accounts/${accountId}/transactions`);
  return parseJson(res);
}

export async function initiateTransfer(payload: {
  from_account_id: number;
  to_account_id: number;
  amount: number;
  memo: string;
}): Promise<{ transfer: Transfer }> {
  const res = await fetch(`${BANK_BASE_URL}/transfers`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload)
  });
  return parseJson(res);
}
