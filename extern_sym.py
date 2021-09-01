import sys;

lines = []

with open(sys.argv[1]) as f:
    for l in f:
        if any(' ' + sym + '  ;' in l for sym in sys.argv[2:]):
            lines.append(l.replace('EXTERN', 'extern'))
        else:
            lines.append(l)

with open(sys.argv[1], 'w') as f:
    f.writelines(lines)
