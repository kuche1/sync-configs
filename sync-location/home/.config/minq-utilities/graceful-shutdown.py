#! /usr/bin/env python3

import psutil
import getpass
import time
import argparse

KILLLIST = [
    'code',

    'qbittorrent',

    'steam',

    'zen-bin',
]

# IGNORED_PROCESSES = [
#     # 'i3',
#     # 'i3bar',
#     # 'i3blocks',
#     # 'systemd'
# ]

SLEEP_CHECK_RUNNING_PROCESSES_AGAIN = 1
CHECK_RUNNING_PROCESSES_TIMEOUT = 8

COL_RESET =  '\033[0;0m'
COL_YELLOW = '\033[1;33m'
COL_RED = '\033[1;31m'

USER = getpass.getuser()

def print_yellow(*a, **kw):
    print(COL_YELLOW, end='')
    print(*a, **kw)
    print(COL_RESET, end='')

def print_red(*a, **kw):
    print(COL_RED, end='')
    print(*a, **kw)
    print(COL_RESET, end='')

def get_remaining_processes():

    print('processes not in killlist:')

    interesting = set()

    for process in psutil.process_iter():
        # .parent()
        # .parents()
        # .children()
        # .terminate()
        # .kill()

        if process.username() != USER:
            continue

        # if process.name() in IGNORED_PROCESSES:
        #     continue

        while True:
            parent = process.parent()

            if parent is None:
                break

            if process.name() != parent.name():
                break

            process = parent

        if process.name() not in KILLLIST:
            print(process)
            continue

        interesting.add(process)

    # to_remove = set()

    # for process in interesting.copy():
    #     done = False
    #     for potential_parent in interesting:
    #         for actual_parent in process.parents():
    #             if potential_parent == actual_parent:
    #                 to_remove.add(process)
    #                 done = True
    #                 break
    #         if done:
    #             break

    # for process in to_remove:
    #     interesting.remove(process)

    print()

    return interesting

def terminate_processes(processes, pretend:bool):
    print_yellow('terminating processes:')
    for process in processes:
        print(process)
        if not pretend:
            process.terminate()
    print()

def kill_processes(processes, pretend:bool):
    print_red('killing processes:')
    for process in processes:
        print(process)
        if not pretend:
            process.kill()
    print()

def wait_for_all_to_die(processes):
    time_left = CHECK_RUNNING_PROCESSES_TIMEOUT

    while True:

        if time_left <= 0:
            break

        print(f'time left: {time_left:.2f}s')

        processes = [p for p in processes if p.is_running()]

        processes_left = len(processes)

        print(f'processes left: {processes_left}')
        for process in processes:
            print(process)
        print()

        if processes_left == 0:
            return True

        time.sleep(SLEEP_CHECK_RUNNING_PROCESSES_AGAIN)
        time_left -= SLEEP_CHECK_RUNNING_PROCESSES_AGAIN

def main(pretend:bool):

    processes = get_remaining_processes()

    terminate_processes(processes, pretend)

    if wait_for_all_to_die(processes):
        return

    terminate_processes(processes, pretend)

    if wait_for_all_to_die(processes):
        return

    kill_processes(processes, pretend)

def execute():
    parser = argparse.ArgumentParser()
    parser.add_argument('--pretend', action='store_true')
    args = parser.parse_args()
    main(args.pretend)

if __name__ == '__main__':
    execute()
