#! /usr/bin/env python3

PACMAN_CONF_PATH = '/etc/pacman.conf'

# include 32bit repo
sudo_replace_string(
    PACMAN_CONF_PATH,
    '\n#[multilib]\n#Include = /etc/pacman.d/mirrorlist\n',
    '\n[multilib]\nInclude = /etc/pacman.d/mirrorlist\n',
)
term(['sudo', 'pacman', '-Syuu'])

# TODO add chaotic AUR ?

# color
sudo_replace_string(
    PACMAN_CONF_PATH,
    '\n#Color\n',
    '\nColor\n',
)

# verbose
sudo_replace_string(
    PACMAN_CONF_PATH,
    '\n#VerbosePkgLists\n',
    '\nVerbosePkgLists\n',
)

# parallel downloads
sudo_replace_string(
    PACMAN_CONF_PATH,
    '\n#ParallelDownloads = 5\n',
    '\nParallelDownloads = 5\n',
)
