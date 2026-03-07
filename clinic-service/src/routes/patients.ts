import { Router } from "express";
import { pool } from "../db/pool";

type PatientRecord = {
  id: number;
  name: string;
  dob: string;
  diagnosis: string;
  treatment: string;
  created_at: string;
};

export const patientsRouter = Router();

patientsRouter.get("/", async (_req, res) => {
  const { rows } = await pool.query<PatientRecord>(
    `SELECT id, name, dob, diagnosis, treatment, created_at
     FROM patients
     ORDER BY id`
  );

  res.json({ patients: rows });
});

patientsRouter.delete("/:id", async (req, res) => {
  const patientId = Number(req.params.id);
  if (Number.isNaN(patientId) || patientId <= 0) {
    res.status(400).json({ error: "invalid patient id" });
    return;
  }

  const result = await pool.query(
    `DELETE FROM patients
     WHERE id = $1`,
    [patientId]
  );

  if (result.rowCount === 0) {
    res.status(404).json({ error: "patient not found" });
    return;
  }

  res.json({ deleted: 1, patientId });
});

patientsRouter.delete("/", async (_req, res) => {
  const result = await pool.query("DELETE FROM patients");
  res.json({ deleted: result.rowCount ?? 0 });
});
