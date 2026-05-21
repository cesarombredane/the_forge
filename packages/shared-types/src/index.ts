export type ActivityType =
  | "running"
  | "cycling"
  | "swimming"
  | "strength"
  | "walking"
  | "other";

export type ActivityDto = {
  id: string;
  name: string;
  type: ActivityType;
  notes: string | null;
  startedAt: string;
  durationSeconds: number;
};
