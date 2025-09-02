"use client";
import { useEffect, useMemo, useRef, useState } from "react";
import { getSupabase } from "@/lib/supabase-browser";

type Role = "user" | "assistant";
type Msg = { role: Role; content: string; ts: number };
type HistoryMsg = { role: Role; content: string; ts: number };

const LS_KEY  = "ke.chat.history.v1";
const LS_SYS  = "ke.chat.system.v1";
const LS_MOD  = "ke.chat.model";

function now() { return Date.now(); }
function errMsg(err: unknown): string {
  return err instanceof Error ? err.message : String(err);
}

export default function ChatPage() {
  const [prompt, setPrompt] = useState("");
  const [busy, setBusy]     = useState(false);
  const [error, setError]   = useState<string>("");
  const [models, setModels] = useState<string[]>([]);
  const [email, setEmail]   = useState("");

  const supabase = getSupabase();
  const [userId, setUserId] = useState<string | null>(null);

  // Auth: read session user (if Supabase configured)
  useEffect(() => {
    if (!supabase) return;
    supabase.auth.getUser().then(({ data }) => {
      const id = data?.user?.id ?? null;
      setUserId(id);
    });
    const { data: sub } = supabase.auth.onAuthStateChange((_event, session) => {
      setUserId(session?.user?.id ?? null);
    });
    return () => sub?.subscription?.unsubscribe?.();
  }, [supabase]);

  const [system, setSystem] = useState<string>(() => {
    if (typeof window === "undefined") return "";
    return localStorage.getItem(LS_SYS) ?? "You are KaizenEdge: concise, practical, FDA-grade guidance.";
  });

  const [msgs, setMsgs] = useState<Msg[]>(() => {
    if (typeof window === "undefined") return [];
    try { const raw = localStorage.getItem(LS_KEY); return raw ? (JSON.parse(raw) as Msg[]) : []; }
    catch { return []; }
  });

  const [model, setModel]   = useState<string>(() => {
    if (typeof window === "undefined") return "meta-llama-3.1-70b-instruct";
    return localStorage.getItem(LS_MOD) || "meta-llama-3.1-70b-instruct";
  });

  useEffect(() => { if (typeof window !== "undefined") localStorage.setItem(LS_SYS, system); }, [system]);
  useEffect(() => { if (typeof window !== "undefined") localStorage.setItem(LS_KEY, JSON.stringify(msgs)); }, [msgs]);
  useEffect(() => { if (typeof window !== "undefined") localStorage.setItem(LS_MOD, model); }, [model]);

  // Load available models from API
  useEffect(() => {
    (async () => {
      try {
        const r = await fetch("/api/local-llm", { method: "GET" });
        const j = (await r.json()) as { ok?: boolean; models?: string[] };
        const list = Array.isArray(j?.models) ? j.models : [];
        setModels(list.length ? list : ["meta-llama-3.1-70b-instruct", "deepseek-r1-distill-qwen-14b"]);
      } catch {
        setModels(["meta-llama-3.1-70b-instruct", "deepseek-r1-distill-qwen-14b"]);
      }
    })();
  }, []);

  // Load DB history for this session on first load
  useEffect(() => {
    (async () => {
      try {
        const r = await fetch("/api/history");
        const j = (await r.json()) as { ok?: boolean; messages?: HistoryMsg[] };
        if (Array.isArray(j?.messages) && j.messages.length) {
          setMsgs(j.messages.map((m) => ({ role: m.role, content: m.content, ts: Math.floor(m.ts) })));
        }
      } catch {
        /* ignore */
      }
    })();
  }, []);

  const endRef = useRef<HTMLDivElement | null>(null);
  useEffect(() => { endRef.current?.scrollIntoView({ behavior: "smooth" }); }, [msgs]);

  const canSend = useMemo(() => prompt.trim().length > 0 && !busy, [prompt, busy]);

  async function send() {
    const text = prompt.trim();
    if (!text || busy) return;
    setError("");
    setBusy(true);
    setPrompt("");
    setMsgs((m) => [...m, { role: "user", content: text, ts: now() }]);

    try {
      const r = await fetch("/api/local-llm", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          ...(userId ? { "x-ke-user-id": userId } : {}),
        },
        body: JSON.stringify({
          prompt: system ? `${system}\n\nUser: ${text}` : text,
          model,
        }),
      });
      const j = (await r.json()) as {
        ok?: boolean;
        error?: string;
        data?: { choices?: { message?: { content?: string } }[] };
      };
      const content =
        j?.data?.choices?.[0]?.message?.content ??
        (j?.ok ? "No content" : `Error: ${j?.error || "Unknown"}`);

      if (j?.ok) {
        setMsgs((m) => [...m, { role: "assistant", content, ts: now() }]);
      } else {
        const em = typeof content === "string" ? content : "Request failed.";
        setError(em);
        setMsgs((m) => [...m, { role: "assistant", content: "[error] " + em, ts: now() }]);
      }
    } catch (e: unknown) {
      const msg = errMsg(e);
      setError(msg);
      setMsgs((m) => [...m, { role: "assistant", content: "[error] " + msg, ts: now() }]);
    } finally {
      setBusy(false);
    }
  }

  async function signInMagic() {
    if (!getSupabase || !supabase || !email.trim()) return;
    setError("");
    const { error } = await supabase.auth.signInWithOtp({ email: email.trim() });
    if (error) setError(error.message);
  }
  async function signOut() {
    if (!supabase) return;
    await supabase.auth.signOut();
  }

  function newChat() { setMsgs([]); setError(""); setPrompt(""); }
  function clearHistory() { localStorage.removeItem(LS_KEY); setMsgs([]); }
  function exportTxt() {
    const lines = msgs.map((m) => `${new Date(m.ts).toISOString()}  [${m.role}]  ${m.content}`).join("\n\n");
    const blob = new Blob([lines], { type: "text/plain;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a"); a.href = url;
    a.download = `kaizenedge_chat_${new Date().toISOString().slice(0,19).replace(/[:T]/g,"-")}.txt`;
    document.body.appendChild(a); a.click(); a.remove(); URL.revokeObjectURL(url);
  }

  return (
    <div className="grid grid-cols-1 gap-6 lg:grid-cols-12">
      {/* Sidebar */}
      <aside className="lg:col-span-3 space-y-4">
        <div className="ke-card p-4">
          <h2 className="text-lg font-semibold mb-2">Session</h2>
          <div className="flex gap-2">
            <button className="ke-btn" onClick={newChat}>New Chat</button>
            <button className="ke-btn" onClick={clearHistory}>Clear</button>
          </div>
          <button className="ke-btn mt-2 w-full" onClick={exportTxt}>Export (.txt)</button>
        </div>

        <div className="ke-card p-4">
          <h2 className="text-lg font-semibold mb-2">System Prompt</h2>
          <textarea
            className="ke-input min-h-[120px]"
            value={system}
            onChange={(e) => setSystem(e.target.value)}
            placeholder="How the assistant should behave…"
          />
          <p className="ke-muted mt-2 text-sm">Tip: keep it short and action-oriented.</p>
        </div>

        {/* Auth (optional; shows only if Supabase envs exist) */}
        {supabase ? (
          <div className="ke-card p-4">
            <h2 className="text-lg font-semibold mb-2">Account</h2>
            {userId ? (
              <>
                <p className="ke-muted text-sm mb-2">Signed in</p>
                <button className="ke-btn w-full" onClick={signOut}>Sign out</button>
              </>
            ) : (
              <>
                <input
                  className="ke-input mb-2"
                  placeholder="you@example.com"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                />
                <button className="ke-btn w-full" onClick={signInMagic}>Email me a magic link</button>
                <p className="ke-muted text-xs mt-2">Supabase URL/Anon key required in .env.local</p>
              </>
            )}
          </div>
        ) : null}
      </aside>

      {/* Main */}
      <section className="lg:col-span-9">
        <div className="mb-2">
          <h1 className="text-3xl font-semibold">Chat with Local LLM</h1>
          <p className="ke-muted mt-1">Local model(s) via LM Studio.</p>
        </div>

        {error && (
          <div className="mb-3 rounded-lg border border-red-200 bg-red-50 px-3 py-2 text-sm text-red-800">
            {error}
          </div>
        )}

        <div className="ke-card p-4 sm:p-6">
          {/* Model switcher */}
          <div className="mb-3 flex flex-wrap items-center gap-3">
            <label className="text-sm ke-muted">Model</label>
            <select className="ke-input max-w-xs" value={model} onChange={(e) => setModel(e.target.value)}>
              {models.length ? (
                models.map((m) => <option key={m} value={m}>{m}</option>)
              ) : (
                <>
                  <option value="meta-llama-3.1-70b-instruct">meta-llama-3.1-70b-instruct</option>
                  <option value="deepseek-r1-distill-qwen-14b">deepseek-r1-distill-qwen-14b</option>
                </>
              )}
            </select>
          </div>

          {/* History */}
          <div className="mb-4 max-h-[55vh] overflow-y-auto space-y-3 pr-1">
            {msgs.length === 0 && (
              <div className="rounded-lg border border-ke-border bg-white p-3 ke-muted">
                Start by typing a message below.
              </div>
            )}
            {msgs.map((m, i) => (
              <div key={m.ts + "-" + i} className={"flex " + (m.role === "user" ? "justify-end" : "justify-start")}>
                <div
                  className={
                    "max-w-[85%] whitespace-pre-wrap leading-relaxed " +
                    (m.role === "user"
                      ? "rounded-xl rounded-br-md bg-ke-primary-600 text-white px-4 py-2"
                      : "rounded-xl rounded-bl-md bg-white ring-1 ring-ke-border px-4 py-2")
                  }
                >
                  {m.content}
                </div>
              </div>
            ))}
            {busy && (
              <div className="flex justify-start">
                <div className="rounded-xl rounded-bl-md bg-white ring-1 ring-ke-border px-4 py-2 text-ke-subtext">
                  …thinking
                </div>
              </div>
            )}
            <div ref={endRef} />
          </div>

          {/* Composer */}
          <div className="flex gap-3">
            <input
              className="ke-input"
              value={prompt}
              onChange={(e) => setPrompt(e.target.value)}
              placeholder="Ask KaizenEdge anything…"
              onKeyDown={(e) => e.key === "Enter" && send()}
              disabled={busy}
            />
            <button className="ke-btn shrink-0" onClick={send} disabled={!canSend}>
              {busy ? "Working…" : "Ask"}
            </button>
          </div>
        </div>
      </section>
    </div>
  );
}
