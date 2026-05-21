import { db } from "./client";
import { activities, users } from "./schema";

async function main() {
  const [user] = await db
    .insert(users)
    .values({
      email: "demo@forge.local",
      displayName: "Demo Athlete"
    })
    .onConflictDoNothing({ target: users.email })
    .returning();

  if (!user) {
    console.log("Demo user already exists, skipping seed inserts");
    return;
  }

  await db.insert(activities).values([
    {
      userId: user.id,
      name: "Morning Run",
      type: "running",
      notes: "Easy pace warm-up",
      startedAt: new Date(),
      durationSeconds: 1800
    },
    {
      userId: user.id,
      name: "Evening Walk",
      type: "walking",
      notes: "Recovery walk",
      startedAt: new Date(),
      durationSeconds: 2400
    }
  ]);

  console.log("Database seed complete");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
