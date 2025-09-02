#!/bin/zsh
set -e

ts=$(date +"%Y-%m-%d_%H-%M-%S")
mkdir -p docs
out="docs/system_audit_${ts}.md"

echo "# KaizenEdge Audit ($ts)" > $out
echo "" >> $out
echo "## Tools" >> $out
for c in git bun node; do
  if command -v $c >/dev/null 2>&1; then
    echo "| $c | OK | $($c --version | head -n1) |" >> $out
  else
    echo "| $c | MISSING | install required |" >> $out
  fi
done

echo "" >> $out
echo "## Repo Layout" >> $out
[[ -d apps && -d packages ]] && echo "| monorepo | OK | apps/ + packages/ found |" >> $out || echo "| monorepo | MISSING | expected apps/, packages/ |" >> $out

[[ -f turbo.json ]] && echo "| turborepo | OK | turbo.json present |" >> $out || echo "| turborepo | MISSING | add turbo.json |" >> $out

echo "" >> $out
echo "Report written to $out"
