export default function Page(){
  return (
    <section className="space-y-3">
      <h1 className="text-2xl font-semibold">Dashboard</h1>
      <p>Welcome to KaizenEdge. Use the navbar to try the local LLM chat.</p>
      <ul className="list-disc pl-5">
        <li>Health endpoint: <a className="text-blue-600 underline" href="/api/health">/api/health</a></li>
      </ul>
    </section>
  );
}
