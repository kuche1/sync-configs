#! /usr/bin/env python3

import subprocess
import json

VOL_GR_NAME = 'myVolGr'
LV_NAME = 'myRootVol'

def term(cmd:list[str], *a, **kw):
    cmd = [str(c) for c in cmd]
    print(f'+ running `{" ".join(cmd)}`')
    return subprocess.run(cmd, check=True, *a, **kw)

def term_out(cmd:list[str]):
    return term(cmd, capture_output=True).stdout.decode()

out = term_out(['lsblk', '--json'])
devices = json.loads(out)
block_devices = devices['blockdevices']

devices = []
for dev in block_devices:
    name = dev['name']
    dev = f'/dev/{name}'
    devices.append(dev)

selected_devices = []
while True:
    print(f'Select device (leave empty when done): {devices}')
    dev = input('> ')
    if dev == '':
        break

    devices.remove(dev)
    selected_devices.append(dev)

devs = selected_devices
assert len(devs) > 0

print(' '.join(devs))
