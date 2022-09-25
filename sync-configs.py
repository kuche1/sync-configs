#! /usr/bin/env python3

import argparse
import datetime
import os
import pwd
import time

HERE = os.path.dirname(os.path.realpath(__file__))

def safely_delete(file):
    now = datetime.datetime.now().strftime('%Y.%m.%d.%H.%M.%S')
    now = f'{now}.{time.time()}'

    new_name = f'{file}.deleted.{now}'

    print(f'renaming `{file}` to `{new_name}`')
    os.rename(file, new_name)

def safely_symlink(dest, source):
    if os.path.islink(dest):
        link_target = os.readlink(dest)
        if link_target == source:
            return
    if os.path.exists(dest):
        safely_delete(dest)
    print(f'symlinking `{dest}` to point to `{source}`')
    os.symlink(source, dest)

def main(user):
    try:
        pwd.getpwnam(user)
    except KeyError:
        raise Exception(f'User `{user}` does not exist')

    home = f'/home/{user}/'

    for d, fols, fils in os.walk(os.path.join(HERE, 'home')):
        for fil in fils:
            real_file = os.path.join(home, fil)
            file_to_be_symlinked = os.path.join(d, fil)
            safely_symlink(real_file, file_to_be_symlinked)
        for fol in fols:
            if fol != '.config':
                raise Exception(f'Undefined case')
            for d, sub_fols, sub_fils in os.walk(os.path.join(d, fol)):
                for symlink_target in sub_fols+sub_fils:
                    real_path = os.path.join(home, fol, symlink_target)
                    to_be_symlinked = os.path.join(d, symlink_target)
                    safely_symlink(real_path, to_be_symlinked)
                break
        break
    
    print('Done')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Utility for syncing the config files')
    parser.add_argument(
        'user',
        choices=[i[0] for i in pwd.getpwall()],
        help='User to set up the config files for',
    )
    args = parser.parse_args()

    main(args.user)
