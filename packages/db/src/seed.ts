import { Client } from "pg";
const url = process.env.DATABASE_URL!;
async function main() {
  const client = new Client({ connectionString: url });
  await client.connect();
  await client.query(`
    INSERT INTO "users" (id, email, created_at)
    VALUES (gen_random_uuid(), 'founder@kaizenedge.org', NOW())
    ON CONFLICT DO NOTHING;
  `);
  await client.end();
  console.log("Seeded founder@kaizenedge.org");
}
main().catch((e)=>{console.error(e);process.exit(1);});
