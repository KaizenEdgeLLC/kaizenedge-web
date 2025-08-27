import sys
BANNED = ["just trust me", "probably fine"]
VOICE = "friendly"
def lint(txt: str):
    errs=[]
    for b in BANNED:
        if b.lower() in txt.lower(): errs.append(f"banned phrase: {b}")
    return errs
if __name__=="__main__":
    data=sys.stdin.read()
    errs=lint(data)
    if errs: print("\\n".join(errs)); sys.exit(1)
    print("OK"); sys.exit(0)
