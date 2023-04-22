#! /usr/bin/env python3

import subprocess

def term(cmd:str):
    subprocess.run(cmd, check=True)

def main():
    term('lsblk')

    user_pass = input('Enter password: ')

if __name__ == '__main__':
    main()
