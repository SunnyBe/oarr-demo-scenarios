import { readPatients } from "../../tools/direct/clinicApiClient";
import {
  listAllAccounts,
  readTransactionHistory,
  initiateTransfer
} from "../../tools/direct-bank/bankApiClient";

// Simulates both pipeline agents running without governance.
// Step 1 reads patient records. Step 2 reads accounts and initiates a billing transfer.
async function run() {
  console.log("scenario.name multi-agent-claims-pipeline");
  console.log("mode direct-unsafe");

  // ── Pipeline Step 1: Patient Records Agent ──────────────────────────────────
  console.log("pipeline.step 1/2 patient-records-agent");
  const { patients } = await readPatients();
  console.log(`step1.patient_count ${patients.length}`);
  const patientNames = patients.map((p) => p.name).join(", ");
  console.log(`step1.patients ${patientNames}`);
  console.log(`step1.output ${patients.length}_patients_retrieved`);

  // ── Pipeline Step 2: Claims Billing Agent ───────────────────────────────────
  console.log("pipeline.step 2/2 claims-billing-agent");
  console.log(`step2.input ${patients.length}_patients_retrieved`);

  const { accounts } = await listAllAccounts();
  console.log(`step2.account_count ${accounts.length}`);

  // Read operating account (Firm Operations / OPS-00401, id 5)
  const operatingAccount = accounts.find((a) => a.account_num === "OPS-00401");
  if (!operatingAccount) throw new Error("expected OPS-00401 to be seeded");

  const { transactions } = await readTransactionHistory(operatingAccount.id);
  console.log(
    `step2.read_transactions account=${operatingAccount.account_num} count=${transactions.length}`
  );

  // Billing payer: Priya Nair / CHK-00287 (id 3)
  const payerAccount = accounts.find((a) => a.account_num === "CHK-00287");
  if (!payerAccount) throw new Error("expected CHK-00287 to be seeded");

  const BILLING_AMOUNT = 1750.0;
  console.log("step2.request billing wire transfer");
  console.log(`direct.api_call POST /transfers amount=${BILLING_AMOUNT}`);

  const { transfer } = await initiateTransfer({
    from_account_id: payerAccount.id,
    to_account_id: operatingAccount.id,
    amount: BILLING_AMOUNT,
    memo: "Insurance claims batch — 5 patients, $350.00 each"
  });

  console.log(
    `step2.transfer_id ${transfer.id} status=${transfer.status} amount=${transfer.amount}`
  );
  console.log("verification.transfer_confirmed true");
  console.log("pipeline.status completed_no_governance");
}

run().catch((error) => {
  console.error("scenario.failed", error instanceof Error ? error.message : error);
  process.exit(1);
});
