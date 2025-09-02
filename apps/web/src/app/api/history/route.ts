import { NextResponse } from "next/server";
import { cookies } from "next/headers";
import { withPg } from "@/lib/db";
export const runtime = "nodejs";

export async function GET() {
  // compatible wrapper
  const jar: any = await (async () => {
    const c = cookies();
    return typeof (c as any).then === "function" ? await (c as any) : c;
  })();
  const sid = jar.get("ke_sid")?.value;
  if (!sid) return NextResponse.json({ ok: true, messages: [] });

  const messages = await withPg(async (c) => {
    const r = await c.query(
      `SELECT role, content, extract(epoch from created_at)*1000 AS ts
         FROM chat_messages
        WHERE session_id=$1
     ORDER BY created_at ASC
        LIMIT 500`,
      [sid]
    );
    return r.rows;
  });

  return NextResponse.json({ ok: true, messages });
}
