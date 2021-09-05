import sys

syms = set(filter(bool, sys.argv[2:]))

with open(sys.argv[1], 'r+') as f:
    lines = list(f)
    f.seek(0)
    f.writelines(l.replace('EXTERN', 'extern') if any((' ' + sym + ' ') in l for sym in syms) and l.startswith('EXTERN') else l for l in lines)
