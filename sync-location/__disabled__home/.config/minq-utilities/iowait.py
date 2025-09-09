#! /usr/bin/env python3

import re
import subprocess
import time

LOG_ENTRIES = 3 # 1 entry == 1 second

def collect_data_and_print(process):
    records = []
    records_max_len = LOG_ENTRIES

    while True:
        line = process.stdout.readline()
        if line == b'':
            time.sleep(1)
            continue
        line = line.decode()

        tmp = 'all'
        if tmp not in line:
            continue
        idx = line.index(tmp)
        line = line[idx+len(tmp):]

        line = line.strip()

        line = re.sub(' +', ' ', line)

        iowait = line.split(' ')[3]
        iowait = iowait.replace(',', '.') # on ubuntu `,` is used instead of `.`
        iowait = float(iowait)

        records.append(iowait)
        if len(records) > records_max_len:
            del records[0]

        items = len(records)
        avg = sum(records) / items

        print(f'{items}s{avg:6.2f}', flush=True)

def main():
    process = subprocess.Popen(['mpstat', '--dec=2', '1'], stdout=subprocess.PIPE) # sudo pacman -S sysstat
    # can use `--dec=0` to limit to `0` decimal places. default is 2

    try:
        collect_data_and_print(process)
    finally:
        process.terminate()

if __name__ == '__main__':
    main()
