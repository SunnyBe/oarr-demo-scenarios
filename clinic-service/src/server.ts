import { createApp } from "./app";

const port = Number(process.env.PORT ?? 3000);
const app = createApp();

app.listen(port, () => {
  // Keep startup logs explicit for demo setup.
  console.log(`clinic-service listening on port ${port}`);
});
