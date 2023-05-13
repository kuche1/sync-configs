#! /usr/bin/env python3

# NOTE
# this is fucking stupid
# uses way too much CPU & electricity for what it does

import signal
import os
import time
import subprocess
from enum import IntEnum

HERE = os.path.dirname(os.path.realpath(__file__))
PIDFILE = os.path.join(HERE, 'volume_controller.pid')
VOLUME_SETTER = os.path.join(HERE, 'volume-set.sh')
VOLUME_GETTER = os.path.join(HERE, 'volume-get.sh')
DELAY_FIX_VOL = 0.8 # in seconds
    # this is OK for desktop but might waste a bit too much battery for laptop

class Request_vol(IntEnum):
    INC = 1
    DEC = 2

def volume_increase():
    subprocess.run([VOLUME_SETTER, 'inc-small'], check=True)

def volume_decrease():
    subprocess.run([VOLUME_SETTER, 'dec-small'], check=True)

def volume_set(amount):
    assert type(amount) in [int, float]
    amount = f'{amount}%'
    print(f'setting to {amount}')
    subprocess.run([VOLUME_SETTER, 'amount', amount], check=True)

def volume_get():
    vol = subprocess.run([VOLUME_GETTER], check=True, capture_output=True)
    vol = vol.stdout.decode().strip()
    return float(vol)

def main():
    try:
        vol_fix_cycle = 1 # retarded shit doesn't work with values lower than 1 (and possibly floats in general)

        vol_requests = []
        signal.signal(signal.SIGUSR1, lambda: vol_requests.append(Request_vol.INC))
        signal.signal(signal.SIGUSR2, lambda: vol_requests.append(Request_vol.DEC))

        while True:
            time.sleep(DELAY_FIX_VOL)

            while vol_requests:
                req = vol_requests.pop(0)
                match req:
                    case Request_vol.INC:
                        volume_increase()
                    case Request_vol.DEC:
                        volume_decrease()
                    case other:
                        # TODO do what on error?
                        # play a sound?
                        ...

            vol = volume_get()
            volume_set(vol + vol_fix_cycle)
            vol_fix_cycle *= -1
    finally:
        pass

if __name__ == '__main__':
    main()
