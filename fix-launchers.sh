#! /usr/bin/env bash

set -e

fix_launcher(){
    name=$1
    to_replace=$2
    replace_with=$3

    echo "fixing launcher for \`$name\`"

    original=/usr/share/applications/$name.desktop
    local=~/.local/share/applications/$name.desktop

    if [[ "$to_replace" == *"^"* ]];then
        echo "assert failed"
        exit 1
    fi

    if [[ "$replace_with" == *"^"* ]];then
        echo "assert failed"
        exit 1
    fi

    cat -- "$original" | sed -z "s^$to_replace^$replace_with^" > "$local"
}

fix_launcher discord '\nExec=/usr/bin/discord\n' '\nExec=/usr/bin/discord --disable-smooth-scrolling\n'
fix_launcher steam '\nExec=/usr/bin/steam-runtime %U\n' '\nExec=/usr/bin/steam-runtime -silent -nochatui -nofriendsui %U\n'
