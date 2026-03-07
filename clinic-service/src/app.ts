import express from "express";
import { healthRouter } from "./routes/health";
import { patientsRouter } from "./routes/patients";

export function createApp() {
  const app = express();

  app.use(express.json());
  app.use((req, _res, next) => {
    console.log(`clinic.request ${req.method} ${req.path}`);
    next();
  });
  app.use("/health", healthRouter);
  app.use("/patients", patientsRouter);

  return app;
}
