import { z } from "zod";

const healthSchema = z.object({
  status: z.literal("ok"),
  service: z.string()
});

const API_BASE_URL = process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:3001";

export async function getApiHealth() {
  const res = await fetch(`${API_BASE_URL}/api/v1/health`, {
    cache: "no-store"
  });

  if (!res.ok) {
    throw new Error(`Health request failed with status ${res.status}`);
  }

  const json = await res.json();
  return healthSchema.parse(json);
}
