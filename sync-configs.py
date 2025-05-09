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

FILE_ENV = '/etc/environment'
FILE_PROFILE = os.path.expanduser('~/.profile')

def get_name_for_deletion(file):
    now = datetime.datetime.now().strftime('%Y.%m.%d.%H.%M.%S')
    now = f'{now}.{time.time()}'
    new_name = f'{file}.deleted.{now}'
    return new_name

def safely_delete(node):
    if not os.path.exists(node) and not os.path.islink(node):
        return
    new_name = get_name_for_deletion(node)
    print(f'renaming `{node}` to `{new_name}`')
    os.rename(node, new_name)

def safely_symlink(dest, source):
    if os.path.islink(dest):
        link_target = os.readlink(dest)
        if link_target == source:
            return
    safely_delete(dest)

    print(f'symlinking `{dest}` to point to `{source}`')

    # try:
    #     os.symlink(source, dest)
    # except:
    #     print(f'ERROR: could not symlink')
    os.symlink(source, dest)

def sudo_safely_delete(file):
    # TODO implement check functionality from `safely_delete`
    new_name = get_name_for_deletion(file)
    print(f'sudo safely deleting `{file}` to `{new_name}`')
    with tempfile.NamedTemporaryFile(mode='w', delete=False) as f_exec:
        f_exec_name = shlex.quote(f_exec.name)
        f_exec.write('#! /usr/bin/env python3\n')
        f_exec.write('import os\n')
        
        assert '"' not in file
        assert '\\' not in file # is this needed? same goes for the bottom line

        assert '"' not in new_name
        assert '\\' not in new_name

        f_exec.write(f'os.rename(r"{file}", r"{new_name}")\n')
    subprocess.run(['sudo', 'python3', f_exec_name], check=True) # for some fucking reason using `env` instead of `python3` drops the permissions

def sudo_safely_copy(from_, to):
    from_ = os.path.realpath(from_)
    to = os.path.realpath(to)


    if os.path.exists(to):

        with open(from_, 'rb') as f_from:
            with open(to, 'rb') as f_to:
                if f_from.read() == f_to.read():
                    return

        sudo_safely_delete(to)

    print(f'copying {from_} to {to}')

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

def sudo_enable_and_start_service(service):
    subprocess.run(['sudo', 'systemctl', 'daemon-reload'], check=True)

    print('checking if serivce is enabled...')
    if subprocess.run(['systemctl', 'is-enabled', service]).returncode == 0:
        return

    subprocess.run(['sudo', 'systemctl', 'enable', '--now', service], check=True)

def main(user, sync_location):
    try:
        pwd.getpwnam(user)
    except KeyError:
        raise Exception(f'User `{user}` does not exist')

    home = f'/home/{user}/'

    sync_location = os.path.realpath(sync_location)

    # sync home folder

    for d_repo, fols, fils in os.walk(os.path.join(sync_location, 'home')):

        for fil in fils:
            real_file = os.path.join(home, fil)
            file_to_be_symlinked = os.path.join(d_repo, fil)
            safely_symlink(real_file, file_to_be_symlinked)

        for fol in fols:

            folder_path_home = os.path.join(home, fol)
            folder_path_repo = os.path.join(d_repo, fol)

            if fol in ['.mozilla', '.minecraft', '.tlauncher', '.zen']: # just symlink
                safely_symlink(folder_path_home, folder_path_repo)

            elif fol == '.config':
                for d, sub_fols, sub_fils in os.walk(os.path.join(d_repo, fol)):
                    assert len(sub_fils) == 0

                    for symlink_target in sub_fols+sub_fils:
                        real_path = os.path.join(home, fol, symlink_target)
                        to_be_symlinked = os.path.join(d, symlink_target)
                        safely_symlink(real_path, to_be_symlinked)
                    break

            elif fol == '.steam':
                compdata_path_repo = os.path.join(folder_path_repo, 'steam', 'steamapps', 'compatdata')
                compdata_path_home = os.path.join(folder_path_home, 'steam', 'steamapps', 'compatdata')
                assert os.path.isdir(compdata_path_repo)
                safely_symlink(compdata_path_home, compdata_path_repo)

            elif fol == '.unison':
                os.makedirs(folder_path_home, exist_ok=True)

                for d, _, sub_fils in os.walk(folder_path_repo):
                    for fil in sub_fils:
                        if not fil.endswith('.prf'):
                            continue
                        file_path_home = os.path.join(folder_path_home, fil)
                        file_path_repo = os.path.join(d, fil)
                        safely_symlink(file_path_home, file_path_repo)
                    break

            else: # unknown
                assert False, f'unknown folder: `{fol}` ({folder_path_repo})'

        break
    
    # sync senvironment

    sync_location_env_file = os.path.join(sync_location, 'environment')

    if os.path.isfile(sync_location_env_file):

        # print('WARNING: syncing the envorinment is currently disabled, use profile instead')

        new_vars_for_env = []

        with open(FILE_ENV, 'r') as f: # TODO what if env doesn't exist (example nixos)
            environment = f.read()
        environment = environment.splitlines()

        with open(sync_location_env_file) as f:
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
                # to_append += '\n'
            sudo_append_to_file(FILE_ENV, to_append)

    # sync profile

#     # old code that copies profile
# 
#     sync_location_profile_file = os.path.join(sync_location, 'profile')
# 
#     if os.path.isfile(sync_location_profile_file):
# 
#         print('syncing the envorinment is currently disabled, use profile instead')
# 
#         with open(sync_location_profile_file, 'r') as f:
#             data = f.read()
#         data = '\n# autogenerated: begin\n' + data + '\n# autogenerated: end\n'
# 
#         with open(FILE_PROFILE, 'a') as f:
#             f.write(data)

    #safely_symlink(FILE_PROFILE, os.path.join(sync_location, 'profile'))
 
    # sync mouse

    sync_location_mouse_file = os.path.join(sync_location, 'mouse')

    if os.path.isfile(sync_location_mouse_file):
        tmp = '/usr/share/X11/xorg.conf.d/90-mouse-accel.conf'
        sudo_safely_copy(sync_location_mouse_file, tmp)
    
    # copy systemd services

    sync_location_systemd_services = os.path.join(sync_location, 'systemd')

    if os.path.isdir(sync_location_systemd_services):
        for path, _, files in os.walk(sync_location_systemd_services):
            for file in files:
                file_path = os.path.join(path, file)
                dest_path = os.path.join('/etc/systemd/system', file)
                sudo_safely_copy(file_path, dest_path)
                sudo_enable_and_start_service(file)
            break

    # done

    print('Done')

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Utility for syncing the config files')
    parser.add_argument(
        'user',
        choices=[i[0] for i in pwd.getpwall()],
        help='User to set up the config files for. If in doubt, you can use `$USER`.',
    )
    parser.add_argument(
        'sync_location',
        help=f'Location to sync configs from. If in doubt, you can use `{os.path.join(HERE, "sync-location")}`.',
    )
    args = parser.parse_args()

    main(args.user, args.sync_location)
