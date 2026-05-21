import cors from "cors";
import express from "express";
import pinoHttp from "pino-http";
import { env } from "./config/env";
import { errorHandler } from "./middleware/error-handler";
import { activitiesRouter } from "./routes/activities";
import { healthRouter } from "./routes/health";

const app = express();

app.use(
  cors({
    origin: true,
    credentials: true
  })
);
app.use(express.json());
app.use(pinoHttp());

app.use("/api/v1", healthRouter);
app.use("/api/v1", activitiesRouter);

app.use(errorHandler);

app.listen(env.PORT, () => {
  console.log(`API listening on port ${env.PORT}`);
});
