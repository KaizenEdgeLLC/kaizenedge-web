import argparse, json, pathlib
def build(user_id: str, out: str):
    p=pathlib.Path(out); p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(f"Cookbook for user {user_id}\\n(placeholder)", encoding="utf-8")
    print("Wrote", p)
if __name__=="__main__":
    ap=argparse.ArgumentParser(); ap.add_argument("--user", required=True); ap.add_argument("--out", required=True)
    a=ap.parse_args(); build(a.user, a.out)
