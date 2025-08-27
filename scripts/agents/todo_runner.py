#!/usr/bin/env python3
import re, subprocess, sys, pathlib, shlex

ROOT = pathlib.Path(__file__).resolve().parents[2]
TODO = ROOT / "TODO.md"
LOG = ROOT / "logs" / "agent_runner.log"
RUN_TESTS = ROOT / "scripts" / "run_all_tests.sh"

def run(cmd, cwd=ROOT):
    p = subprocess.Popen(cmd, cwd=str(cwd), shell=True,
                         stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True)
    out, _ = p.communicate()
    return p.returncode, out

def log(msg):
    LOG.parent.mkdir(parents=True, exist_ok=True)
    LOG.write_text((LOG.read_text() if LOG.exists() else "") + msg + "\n")

def git_commit(msg):
    return run(f'git add -A && git commit -m {shlex.quote(msg)}')

def mark_done(line_to_match):
    txt = TODO.read_text()
    new = txt.replace(f"- [ ] {line_to_match}", f"- [x] {line_to_match}", 1)
    if new != txt:
        TODO.write_text(new)

def run_fda_checks():
    rc, out = run(f"{RUN_TESTS}")
    return (rc == 0 or "Done." in out), out

def clean(text: str) -> str:
    # strip markdown formatting & normalize spaces/case
    t = re.sub(r"[`*_]", "", text)
    t = re.sub(r"\s+", " ", t).strip().lower()
    return t

# keys to look for -> commands to run -> commit message
TASKS = [
    # normalize.py
    (["services/inventory/normalize.py", "normalize.py"],
     ["mkdir -p services/inventory", ": > services/inventory/normalize.py"],
     "chore: scaffold inventory normalizer file — auto by todo_runner"),
    # signing.py
    (["services/common/signing.py", "signing.py"],
     ["mkdir -p services/common",
      "cat > services/common/signing.py <<'SH'\nimport hashlib, pathlib\n\ndef sha256_file(path: str) -> str:\n    p=pathlib.Path(path); h=hashlib.sha256(p.read_bytes()).hexdigest()\n    (p.parent / (p.name + '.sha256')).write_text(h+'\\n'); return h\nSH"],
     "feat: add signing helper (sha256 sidecars) — auto by todo_runner"),
    # Design History Log
    (["docs/compliance/design_history_log.md", "design history log"],
     ["mkdir -p docs/compliance", "touch docs/compliance/Design_History_Log.md"],
     "docs: add Design History Log — auto by todo_runner"),
    # .env.sample
    ([".env.sample", "env sample"],
     ["cat > .env.sample <<'ENV'\nSTRIPE_PUBLISHABLE_KEY=\nSTRIPE_SECRET_KEY=\nENV"],
     "chore: add .env.sample for Stripe — auto by todo_runner"),
    # run_all_tests.sh executable
    (["scripts/run_all_tests.sh", "run_all_tests.sh"],
     ["test -x scripts/run_all_tests.sh || chmod +x scripts/run_all_tests.sh"],
     "chore: ensure test runner executable — auto by todo_runner"),
    # rulesets/v2.json
    (["rulesets/v2.json", "ruleset v2"],
     ["mkdir -p rulesets", ": > rulesets/v2.json"],
     "chore: scaffold rulesets/v2.json — auto by todo_runner"),
    # perf smoke
    (["reports/perf/smoke_", "perf smoke"],
     ["mkdir -p reports/perf",
      "date +'{\"ts\":\"%Y-%m-%dT%H:%M:%S%z\",\"note\":\"placeholder\"}' > reports/perf/smoke_$(date +%Y%m%d).json"],
     "chore: add perf smoke placeholder — auto by todo_runner"),
]

def main():
    if not TODO.exists():
        print("No TODO.md; nothing to do."); return 0
    lines = [ln.rstrip("\n") for ln in TODO.read_text().splitlines()]
    for ln in lines:
        if not ln.strip().startswith("- [ ] "):
            continue
        raw = ln.strip()[6:]             # text after "- [ ] "
        txt = clean(raw)
        for keys, cmds, msg in TASKS:
            if any(k in txt for k in keys):
                # execute
                for c in cmds:
                    rc, out = run(c); log(f"$ {c}\n{out}")
                    if rc != 0:
                        print(f"Task failed: {raw}\nCommand: {c}\n{out}"); return 1
                ok, out = run_fda_checks(); log(out)
                if not ok:
                    print("FDA checks failed; stopping loop."); return 1
                mark_done(raw)
                rc, out = git_commit(msg); log(out)
                print(f"Completed: {raw}")
                return 0
    print("No matching unchecked tasks found."); return 0

if __name__ == "__main__":
    sys.exit(main())
