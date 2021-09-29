import os
import sys
import subprocess
import shutil

K = [i for i, a in enumerate(sys.argv) if a == '--'][0]
replace = [a for i, a in enumerate(sys.argv) if 1 <= i < K]

copy = [(r, sys.argv[i]) for i in range(1 + K, len(sys.argv)) if sys.argv[i - 1] == '-o' for r in replace if os.path.basename(sys.argv[i]) == os.path.basename(r)]

if copy:
    dirname = os.path.dirname(copy[0][1])
    if dirname:
        os.makedirs(dirname, exist_ok = True)
    shutil.copy2(*copy[0])
    sys.exit(0)
else:
    sys.exit(subprocess.call(sys.argv[1 + K:]))
