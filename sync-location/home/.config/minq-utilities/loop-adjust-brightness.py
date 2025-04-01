#! /usr/bin/env python3

import i3ipc
import time
import os
import subprocess

HERE = os.path.dirname(__file__)

CYCLE_SLEEP = 0.5

def term(args):
    subprocess.run(args, check=True)

currently_bright = False

def brightness_on():
    global currently_bright
    if not currently_bright:
        currently_bright = True
        term([f'{HERE}/brightness.sh', 'set', '1.2']) # 1.4

def brightness_off():
    global currently_bright
    if currently_bright:
        currently_bright = False
        term([f'{HERE}/brightness.sh', 'set', '1.0'])

currently_bright = False
def on_window_focus(a, b):
    global currently_bright

    window_name = b.container.name

    if window_name == None:
        return

    window_name = window_name.strip()

    #print(f'{window_name=}')

    if window_name == 'DeadByDaylight':
        brightness_on()
    else:
        brightness_off()

i3 = i3ipc.Connection()
i3.on("window::focus", on_window_focus)
i3.main()
i3.main_quit()
