import { NextResponse } from "next/server";
export async function GET() {
  return NextResponse.json({ ok: true, service: "kaizenedge", env: "prod" }, { status: 200 });
}
