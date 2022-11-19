#! /usr/bin/env python3

import argparse
import datetime
import os
import pwd
import shlex
import stat
import subprocess
import tempfile
import time
from typing import List

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

def sudo_safely_copy(from_, to):
    from_ = os.path.realpath(from_)
    to = os.path.realpath(to)

    if os.path.exists(to):
        safely_delete(to) # sudo_safely_delete ?

    with tempfile.NamedTemporaryFile(mode='w', delete=False) as f:
        f.write('import shutil\n')
        f.write(f'shutil.copyfile("{from_}", "{to}")\n')
        script_name = f.name
    subprocess.run(['sudo', 'python3', script_name])

def sudo_append_to_file(file, data):
    file = shlex.quote(file)
    with tempfile.NamedTemporaryFile(mode='w') as f_data:
        f_data_name = shlex.quote(f_data.name)
        f_data.write(data)
        f_data.flush()

        with tempfile.NamedTemporaryFile(mode='w', delete=False) as f_exec:
            f_exec_name = shlex.quote(f_exec.name)
            f_exec.write('#! /usr/bin/env bash\n') # TODO rewrite in python3
            f_exec.write(f'cat {f_data_name} >> {file}\n')
            f_exec.flush()

            st = os.stat(f_exec.name)
            os.chmod(f_exec.name, st.st_mode | stat.S_IEXEC)
        subprocess.run(['sudo', 'env', f_exec_name], check=True)

def main(user):
    try:
        pwd.getpwnam(user)
    except KeyError:
        raise Exception(f'User `{user}` does not exist')

    home = f'/home/{user}/'

    # sync home folder

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
    
    # sync senvironment

    new_vars_for_env = []

    with open('/etc/environment', 'r') as f:
        environment = f.read()
    environment = environment.splitlines()

    with open(os.path.join(HERE, 'environment')) as f:
        additions_to_env = f.read()
    additions_to_env = additions_to_env.splitlines()

    for var in additions_to_env:
        ws = var.count(' ') + var.count('\t')
        if len(var) == ws:
            continue
        if var not in environment:
            print(f'adding environment variable `{var}`')
            new_vars_for_env.append(var)
    
    if new_vars_for_env:
        to_append = ''
        for var in new_vars_for_env:
            to_append += '\n'
            to_append += '# autogenerated\n'
            to_append += f'{var}\n'
            to_append += '\n'
        sudo_append_to_file('/etc/environment', to_append)

    # sync mouse

    tmp = '/usr/share/X11/xorg.conf.d/90-mouse-accel.conf'
    print(f'setting file {tmp}')
    sudo_safely_copy(os.path.join(HERE, 'mouse'), tmp)

    print('Done')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Utility for syncing the config files')
    parser.add_argument(
        'user',
        choices=[i[0] for i in pwd.getpwall()],
        help='User to set up the config files for. If in doubt, you can use `$USER`.',
    )
    args = parser.parse_args()

    main(args.user)
