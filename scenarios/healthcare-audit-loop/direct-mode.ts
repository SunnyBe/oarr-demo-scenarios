import { readPatients } from "../../tools/direct/clinicApiClient";

// Simulates a compliance audit agent that spirals into repeated reads.
// No budget limit applied — all 8 calls succeed unimpeded.
const INTENDED_CALLS = 8;

async function run() {
  console.log("scenario.name healthcare-audit-loop");
  console.log("mode direct-unsafe");
  console.log(`audit.intended_calls ${INTENDED_CALLS}`);

  let completedCalls = 0;

  for (let i = 1; i <= INTENDED_CALLS; i++) {
    const result = await readPatients();
    completedCalls++;
    console.log(`audit.call.${i} patient_count=${result.patients.length} status=completed`);
  }

  console.log(`audit.calls_completed ${completedCalls}`);
  console.log("audit.budget_enforced false");
  console.log("audit.status runaway_completed_no_limit");
}

run().catch((error) => {
  console.error("scenario.failed", error instanceof Error ? error.message : error);
  process.exit(1);
});
