"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";

const nav = [
  { href: "/", label: "Dashboard" },
  { href: "/chat", label: "LLM Chat" },
  { href: "/admin", label: "Admin" },
];

export default function Navbar() {
  const pathname = usePathname();
  return (
    <header className="sticky top-0 z-10 border-b border-ke-border bg-white/90 backdrop-blur">
      <nav className="ke-container flex h-14 items-center justify-between">
        <Link href="/" className="font-semibold text-ke-text">KaizenEdge</Link>
        <ul className="flex items-center gap-6 text-sm">
          {nav.map(i => {
            const active = pathname === i.href;
            return (
              <li key={i.href}>
                <Link
                  href={i.href}
                  className={active
                    ? "text-ke-primary-700 font-medium"
                    : "text-ke-text/80 hover:text-ke-text"}
                >
                  {i.label}
                </Link>
              </li>
            );
          })}
        </ul>
      </nav>
    </header>
  );
}
