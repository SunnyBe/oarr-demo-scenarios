import express from "express";
import { healthRouter } from "./routes/health";
import { accountsRouter } from "./routes/accounts";
import { transfersRouter } from "./routes/transfers";

export function createApp() {
  const app = express();

  app.use(express.json());
  app.use((req, _res, next) => {
    console.log(`bank.request ${req.method} ${req.path}`);
    next();
  });
  app.use("/health", healthRouter);
  app.use("/accounts", accountsRouter);
  app.use("/transfers", transfersRouter);

  return app;
}
