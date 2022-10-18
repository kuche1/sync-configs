#! /usr/bin/env python3

import argparse
import subprocess

out = subprocess.run(['mpstat', '--dec=0', '1', '1'], capture_output=True)
out = out.stdout.decode()

tmp = 'Average:'
idx = out.index(tmp)
out = out[idx+len(tmp):]

out = out.strip()

while '  ' in out:
    out = out.replace('  ', ' ')

out = out.split(' ')[4]

print(out)
