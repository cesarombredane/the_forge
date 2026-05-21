import { desc } from "drizzle-orm";
import { Router } from "express";
import { db } from "../db/client";
import { activities } from "../db/schema";

export const activitiesRouter = Router();

activitiesRouter.get("/activities", async (_req, res, next) => {
  try {
    const rows = await db.select().from(activities).orderBy(desc(activities.startedAt)).limit(25);
    res.status(200).json({ data: rows });
  } catch (error) {
    next(error);
  }
});
