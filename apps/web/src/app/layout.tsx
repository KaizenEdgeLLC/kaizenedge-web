import "./globals.css";
import type { ReactNode } from "react";
import Link from "next/link";

export const metadata = { title: "KaizenEdge", description: "Local LLM chat" };

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang="en">
      <body className="min-h-screen bg-[#F7F8FA] text-[#0D0E10]">
        <header className="sticky top-0 z-10 border-b border-[#E6E8EB] bg-white/90 backdrop-blur">
          <div className="mx-auto max-w-6xl flex items-center justify-between px-4 py-3">
            <Link href="/" className="font-semibold">KaizenEdge</Link>
          </div>
        </header>
        <main className="mx-auto max-w-6xl px-4 py-6">{children}</main>
      </body>
    </html>
  );
}
