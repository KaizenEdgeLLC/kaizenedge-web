import { NextResponse } from "next/server";
export const runtime = "nodejs";

function envOrThrow(name: string): string {
  const v = process.env[name];
  if (!v || !v.trim()) throw new Error(`Missing env: ${name}`);
  return v.trim();
}

type LMModel = { id?: string };
type LMModelsResponse = { data?: LMModel[] };

const isProd = !!process.env.VERCEL;

export async function GET() {
  if (isProd) {
    return NextResponse.json({
      ok: false,
      error: "Local LM Studio is not available in Vercel production.",
      action: "Configure a cloud model provider and update this route.",
    }, { status: 501 });
  }
  try {
    const base  = envOrThrow("LOCAL_OPENAI_BASE_URL");
    const key   = process.env.LOCAL_OPENAI_API_KEY || "lmstudio-local";
    const r = await fetch(`${base}/models`, { headers: { Authorization: `Bearer ${key}` } });
    const json = (await r.json().catch(() => ({}))) as LMModelsResponse;
    const models = (json.data ?? [])
      .map((m) => m.id)
      .filter((id): id is string => typeof id === "string" && id.length > 0);
    return NextResponse.json({ ok: r.ok, models, raw: json }, { status: r.ok ? 200 : 502 });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return NextResponse.json({ ok:false, error: msg }, { status: 500 });
  }
}

export async function POST(req: Request) {
  if (isProd) {
    return NextResponse.json({
      ok: false,
      error: "Local LM Studio is not available in Vercel production.",
      action: "Configure a cloud model provider (e.g., OpenAI/Together) and update this route to call it."
    }, { status: 501 });
  }
  try {
    const body = (await req.json().catch(() => ({}))) as { prompt?: unknown; model?: unknown };
    const prompt = typeof body?.prompt === "string" ? body.prompt.trim() : "";
    const requestedModel = typeof body?.model === "string" ? body.model.trim() : "";
    if (!prompt) return NextResponse.json({ ok:false, error:"Empty prompt" }, { status: 400 });

    const base  = envOrThrow("LOCAL_OPENAI_BASE_URL");
    const key   = process.env.LOCAL_OPENAI_API_KEY || "lmstudio-local";
    const model = requestedModel || process.env.LOCAL_OPENAI_MODEL || "meta-llama-3.1-70b-instruct";

    const probe = await fetch(`${base}/models`, { headers: { Authorization: `Bearer ${key}` } });
    if (!probe.ok) {
      const text = await probe.text().catch(() => "");
      return NextResponse.json({ ok:false, step:"probe", status: probe.status, error: text || "LM Studio /models failed" }, { status: 502 });
    }

    const r = await fetch(`${base}/chat/completions`, {
      method: "POST",
      headers: { "Content-Type": "application/json", Authorization: `Bearer ${key}` },
      body: JSON.stringify({ model, messages: [{ role: "user", content: prompt }] }),
    });
    if (!r.ok) {
      const text = await r.text().catch(() => "");
      return NextResponse.json({ ok:false, step:"chat", status:r.status, error:text || "LM Studio /chat/completions failed" }, { status: 502 });
    }

    type ChatResp = { choices?: { message?: { content?: string } }[] };
    const json = (await r.json()) as ChatResp;
    return NextResponse.json({ ok: true, model, data: json }, { status: 200 });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    return NextResponse.json({ ok:false, step:"server", error: msg }, { status: 500 });
  }
}
