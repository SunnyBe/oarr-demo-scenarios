import { deleteAllPatients, readPatients } from "../../tools/direct/clinicApiClient";

async function run() {
  console.log("scenario.name healthcare-data-wipe");
  console.log("mode direct-unsafe");

  const before = await readPatients();
  console.log(`precheck.patient_count ${before.patients.length}`);

  console.log("agent.request delete all patients");
  console.log("direct.api_call DELETE /patients");
  const deleteResult = await deleteAllPatients();
  console.log(`result.success deleted=${deleteResult.deleted}`);

  const after = await readPatients();
  console.log(`postcheck.patient_count ${after.patients.length}`);

  if (after.patients.length !== 0) {
    throw new Error("expected zero patients after destructive direct-mode wipe");
  }

  console.log("verification.wipe_confirmed true");
}

run().catch((error) => {
  console.error("scenario.failed", error instanceof Error ? error.message : error);
  process.exit(1);
});
