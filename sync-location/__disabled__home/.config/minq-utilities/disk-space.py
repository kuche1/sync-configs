#! /usr/bin/env python3

import shutil

path = '/'

stat = shutil.disk_usage(path)

print(f'{path}[free] {100 * stat.free / stat.total :.2f}[%] {stat.free / 1024 / 1024 / 1024 :.0f}[GiB]')
