import { migrate } from "drizzle-orm/node-postgres/migrator";
import { db } from "./client";

async function main() {
  await migrate(db, { migrationsFolder: "./drizzle" });
  console.log("Database migrations applied");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
