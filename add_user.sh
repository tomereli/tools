#!/bin/bash

run() {
    echo "$*"
    "$@" || exit $?
}

confirm() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

if [[ $EUID -ne 0 ]]; then
   echo "This script must be run as root" 
   exit 1
fi

confirm "Add user $1? [y/n]" && {
    run adduser $1
    run usermod -aG docker $1
    run usermod -aG wireshark $1

    run cd /home/$1
    run su -c "git clone https://github.com/tomereli/bashtools.git /home/$1/bashtools" $1
    run su -c "cp /home/$1/bashtools/.gitconfig /home/$1/" $1
    run su -c "cp /home/$1/bashtools/.bashrc /home/$1/" $1
    run su -c "cp /home/$1/bashtools/.bashrc.user /home/$1/.bashrc.$1" $1
    run su -c "cp /home/$1/bashtools/.netrc /home/$1/" $1
    run su -c "cp /home/$1/bashtools/.tmux.conf /home/$1/" $1
    run su -c "cp /home/$1/bashtools/git-proxy /home/$1/" $1
    run su -c "cp -r /home/$1/bashtools/.docker /home/$1/" $1
    run su -c "mkdir -p /home/$1/work/dev1" $1

    echo "Done"
}
