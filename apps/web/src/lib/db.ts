import { Client } from "pg";

export function getPgClient() {
  const cs = process.env.DATABASE_URL;
  if (!cs) throw new Error("Missing env: DATABASE_URL");
  return new Client({ connectionString: cs });
}

export async function withPg<T>(fn: (c: Client) => Promise<T>) {
  const c = getPgClient();
  await c.connect();
  try { return await fn(c); }
  finally { await c.end(); }
}
