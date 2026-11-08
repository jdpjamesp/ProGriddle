"""Regenerates cuber-art.md and every cuber-*.png.

Needs Python 3 and Pillow (pip install pillow). From this folder:
    python run_all.py            writes into the parent folder (docs/design)
    python run_all.py some/dir   writes into some/dir
"""
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
os.chdir(HERE)
sys.path.insert(0, HERE)
out = os.path.abspath(sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, '..'))

import preview
import check

preview.main(out)
check.colour_check(os.path.join(out, 'cuber-colour-check.png'))
bad = check.validate()
print('sprite check:', 'passed' if not bad else bad)
print('palette:', check.count_distinct(), 'distinct colours')
subprocess.check_call([sys.executable, 'doc.py', os.path.join(out, 'cuber-art.md')])
print('written to', out)
