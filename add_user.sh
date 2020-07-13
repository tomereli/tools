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
    run usermod -aG pcap $1

    run cd /home/$1
    run su -c "git clone https://github.com/tomereli/tools.git /home/$1/tools" $1
    run su -c "cp /home/$1/tools/.gitconfig /home/$1/" $1
    run su -c "cp /home/$1/tools/.bashrc /home/$1/" $1
    run su -c "cp /home/$1/tools/.bashrc.user /home/$1/.bashrc.$1" $1
    run su -c "cp /home/$1/tools/.netrc /home/$1/" $1
    run su -c "cp /home/$1/tools/.tmux.conf /home/$1/" $1
    run su -c "cp /home/$1/tools/git-proxy /home/$1/" $1
    run su -c "cp -r /home/$1/tools/.docker /home/$1/" $1
    run su -c "mkdir -p /home/$1/work/dev1" $1

    echo "Done"
}
