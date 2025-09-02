import { NextResponse } from "next/server";

const OPENAI_API_KEY = process.env.OPENAI_API_KEY;
const OPENAI_MODEL = process.env.OPENAI_MODEL || "gpt-4o-mini";

export async function GET() {
  const ok = Boolean(OPENAI_API_KEY);
  const models = ok ? [OPENAI_MODEL] : [];
  return NextResponse.json({ ok, models }, { status: ok ? 200 : 500 });
}

export async function POST(req: Request) {
  if (!OPENAI_API_KEY) {
    return NextResponse.json({ ok: false, error: "Missing OPENAI_API_KEY" }, { status: 500 });
  }
  try {
    const body = await req.json().catch(() => ({}));
    const prompt: string = body.prompt ?? "Say hello from KaizenEdge.";
    const model: string = body.model ?? OPENAI_MODEL;

    const r = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: {
        "Authorization": `Bearer ${OPENAI_API_KEY}`,
        "Content-Type": "application/json"
      },
      body: JSON.stringify({
        model,
        messages: [{ role: "user", content: prompt }],
        temperature: 0.2
      }),
      // Vercel/Edge safe timeout/backoff handled by platform; keep it simple here
    });

    if (!r.ok) {
      const text = await r.text();
      return NextResponse.json({ ok: false, error: `OpenAI ${r.status}: ${text}` }, { status: 502 });
    }
    const data = await r.json();
    return NextResponse.json({ ok: true, data }, { status: 200 });
  } catch (err: any) {
    return NextResponse.json({ ok: false, error: String(err?.message ?? err) }, { status: 500 });
  }
}
