import sys;

syms = list(filter(bool, sys.argv[2:]))

lines = []
with open(sys.argv[1]) as f:
    for l in f:
        symok = any((' ' + sym) in l for sym in syms)
        if l.startswith('EXTERN') and symok:
            lines.append(l.replace('EXTERN', 'extern'))
        elif symok:
            lines.append(l.replace('  ', '  extern'))
        else:
            lines.append(l)

with open(sys.argv[1], 'w') as f:
    f.writelines(lines)
