
import subprocess
import sys

def run_program(*candidates:list[list[str]]):
    for candidate in candidates:
        print(f'run_program: trying {candidate}')
        try:
            ret = subprocess.run(candidate + sys.argv[1:], check=True)
        except FileNotFoundError: # program doesn't exist
            print(f'run_program: failure: program doesn\'t exist')
            continue
        print(f'run_program: success')
        sys.exit(ret.returncode)
    sys.exit(1)
