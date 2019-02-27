#!/bin/bash

# COLORS:
CLR_FG_RED='\033[0;31m'
CLR_FG_GRN='\033[0;32m'
CLR_FG_YLW='\033[0;33m'
CLR_FG_BLU='\033[0;34m'
CLR_FG_MAG='\033[0;35m'
CLR_FG_CYN='\033[0;36m'
CLR_RST='\033[0m'

SCRIPT_NAME="$(basename ${BASH_SOURCE[0]})"
SCRIPT_PATH="$(realpath ${BASH_SOURCE[0]})"

function error()
{
    echo -e "${CLR_FG_RED}${SCRIPT_PATH}: ERROR: $@${CLR_RST}"
}

function info()
{
    echo -e "${CLR_FG_GRN}${SCRIPT_PATH}: INFO: $@${CLR_RST}"
}

function warning()
{
    echo -e "${CLR_FG_YLW}${SCRIPT_PATH}: WARNING: $@${CLR_RST}"
}

function debug()
{
    [ -n "$VERBOSE" ] && echo -e "${SCRIPT_PATH}: DEBUG: $@"
}

SOURCED=
POSITIONAL=()
MOUNT_DIRS=(/opt)
TELNET_PORT=23
SSH_PORT=22
LD_LIBRARY_PATH=/tmp/usr/lib
FORCE=
VERBOSE=

function test_is_script_sourced()
{
    # Do this check inside a function to avoid funcname
    # array not being initialized on some shells before
    # there's a function other than source...

    # use funcname[1] because we pushed another function
    # [0]: pumaSetup_test_is_script_sourced
    # [1]: what we need to check!
    if [ "${FUNCNAME[1]}" == "source" ] ; then
        SOURCED=1
    fi
}
test_is_script_sourced

function usage()
{
    echo -e "Usage: $SCRIPT_NAME [-m <dir1,dir2,...> [-t <port>] [-s <port>] [-flvh] <enable/disable> <all/telnet/ssh/mount>"
}

function help()
{
     echo -e "Usage: $SCRIPT_NAME [-m <dir1,dir2,...> [-t <port>] [-s <port>] [-flvh] <enable/disable> <all/telnet/ssh/mount>>
Positional:
    enable                            - enable debug mode - enables ssh, telnet, mount-copybind /opt,
                                        export LD_LIBRARY_PATH=/tmp/usr/lib, and some aliases.
                                        Note - script needs to be sourced
    disable                           - disable debug mode

Options:
    -m|--mount <dir>                  - mount-copybind /tmp/<dir> on <dir> unless mounted and processes are running from the mountpoint.
    -f|--force                        - kills all processes running on the mountpoint when mounting, restarts telnet and ssh, etc.
    -t|--telnet-port <port>           - enable/disable telnet on port <port> (default 23)
    -s|--ssh-port <port>              - enable/disable ssh on port <port>    (default 22)
    -l|--ld-library <path>            - mount will use different path for export LD_LIBRARY_PATH=<path>. Default is /tmp/usr/lib (Note - script needs to be sourced)
    -v|--verbose                      - print additional messages during setup.
    -h|--help                         - print this message and exit."
}

function umount_dir()
{
    local dir="$1"
    local force="$2"
    local pids=($(lsof | grep $dir | awk '{print $1}'))
    local pids_uniq=($(printf "%s\n" "${pids[@]}" | sort -u | tr '\n' ' '))

    if ! mountpoint -q "$dir"; then
        debug "$dir not mounted, skipping umount"
        return 0
    fi

    if [ -n "$pids" ]; then
        [ -z $FORCE ] && error "umount $dir requires killing of running process but force not set, aborting!" && return 1
        warning "killing all pids using $dir"
	    for p in ${pids_uniq[@]}; do
		    echo "kill -9 $p"
		    kill -9 $p
	    done
    fi
    debug "umount $dir"
    umount $dir
}

function mount_copybind_dir()
{
    local dir="$1"
    if umount_dir $dir; then
        info "mount-copybind /tmp/$dir $dir"
        mount-copybind /tmp/$dir $dir
    fi
}

function firewall_port_enable()
{
    local total=$(syscfg get GeneralPurposeFirewallRuleCount)
    local num=$((total+1))
    debug "Add firewall rule #${num}: \" -I INPUT -i brlan0 -p tcp --dport $1 -j ACCEPT\""
    syscfg set GeneralPurposeFirewallRule_${num} " -I INPUT -i brlan0 -p tcp --dport $1 -j ACCEPT"
    syscfg set GeneralPurposeFirewallRuleCount ${num}
	sysevent set firewall-restart
}

function enable_telnet()
{
    local enable=${1-1}
    local port=${2-23}
    local ip=$(ifconfig brlan0 | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}')
    # Telnet binary location (use nvram if not in filesystem)
    local telnetd=
    if [ -e /usr/sbin/telnetd ]; then
        telnetd=/usr/sbin/telnetd
    elif [ -e /nvram/bin/telnetd ]; then
        telnetd=/nvram/bin/telnetd
    else
        error "no telnetd binary found in /usr/sbin and /nvram/bin, telnet disabled!"
        return 1
    fi

    [ $enable -eq 0 ] && info "Disable telnet" || info "Enable telnet $ip:$port"

    debug "Stop telnetd"
    killall telnetd
    [ $enable -eq 0 ] && return 0

    debug "$telnetd -l /bin/ash $ip -p $port"
    $telnetd -l /bin/ash $ip -p $port
}

function enable_ssh()
{
    local enable=${1-1}
    local port=${2-22}
    local ip=$(ifconfig brlan0 | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk '{ print $1}')
    # Telnet binary location (use nvram if not in filesystem)
    local sshd=
    if [ -e /usr/sbin/dropbear ]; then
        sshd=/usr/sbin/dropbear
    elif [ -e /nvram/bin/dropbear ]; then
        sshd=/nvram/bin/dropbear
    else
        error "no dropbear binary found in /usr/sbin and /nvram/bin, ssh disabled!"
        return 1
    fi

    [ $enable -eq 0 ] && info "Disable ssh" || info "Enable ssh $ip:$port"

    debug "Stop dropbear ssh daemon"
    killall dropbear
    [ $enable -eq 0 ] && return 0

    [ -e /nvram/etc/dropbear -a -e /nvram/etc/shadow ] && {

        umount /etc/dropbear
        umount /etc/shadow
        
        mount -o bind /nvram/etc/dropbear /etc/dropbear
        mount -o bind /nvram/etc/shadow /etc/shadow
        
        debug "$sshd -R -E -B -a -p $port"
        $sshd -R -E -B -a -p $port
        # -R -- Create hostkeys as required
        # -E -- Log to stderr rather than syslog
        # -B -- allow root login with empty password
        # -a -- Allow connections to forwarded ports from any host
        # -p -- specify custom port
    } || error "SSH/SCP DISABLED\n/nvram/etc/dropbear and /nvram/etc/shadow must exist for ssh to work"
}

function enable_aliases()
{
    debug "Setting aliases"
    alias ll='ls -la'
    alias ..='cd ..'
    alias r='cd /'
    alias t='cd /tmp'
    alias map='cd /opt/beerocks'
}

function enable_ld_library_path()
{
    local path="$1"
    debug "export LD_LIBRARY_PATH=${path}"
    export LD_LIBRARY_PATH=${path}
    mkdir -p ${path}
}

#######################################################
##                       MAIN                        ##
#######################################################
# Parse optional agruments
while [[ $# -gt 0 ]]
do
    key="$1"
    
    case $key in
        -m|--mount)
            IFS=',' read -ra MOUNT_DIRS <<< "$2"
            shift
            shift
            ;;
        -f|--force)
            FORCE=1
            shift
            ;;
        -t|--telnet-port)
            TELNET_PORT="$2"
            shift
            shift
            ;;
        -l|--ld-library)
            LD_LIBRARY_PATH="$2"
            shift
            shift
            ;;
        -s|--ssh-port)
            SSH_PORT="$2"
            shift
            shift
            ;;
        -v|--verbose)
            VERBOSE=1
            shift
            ;;
        -h|--help)
            help
            [ -n "$SOURCED" ]  && return 0 || exit 0
            ;;
        *)
            POSITIONAL+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL[@]}" # restore positional parameters
debug "Debug mode configuration:
SOURCED=${SOURCED}
MOUNT_DIRS=${MOUNT_DIRS[@]}
LD_LIBRARY_PATH=${LD_LIBRARY_PATH}
TELNET_PORT=${TELNET_PORT}
SSH_PORT=${SSH_PORT}
FORCE=${FORCE}
ALIASES=${ALIASES}
VERBOSE=${VERBOSE}
OPERATION=${1}
FEATURE=${2}"

case "$1" in
    enable|ENABLE|Enable|1)
        case "$2" in
            telnet)
                echo "Enable telnet"
                enable_telnet 1 $TELNET_PORT
                firewall_port_enable $TELNET_PORT
                ;;
            ssh)
                echo "Enable ssh"
                enable_ssh 1 $SSH_PORT
                firewall_port_enable $SSH_PORT
                ;;
            mount)
                echo "Enable mount"
                for d in ${MOUNT_DIRS[@]}; do mount_copybind_dir $d; done
                ;;
            all)
                echo "Enable all"
                enable_telnet 1 $TELNET_PORT
                enable_ssh 1 $SSH_PORT
                for d in ${MOUNT_DIRS[@]}; do mount_copybind_dir $d; done
                [ -n "$SOURCED" ] && {
                    enable_aliases
                    enable_ld_library_path $LD_LIBRARY_PATH
                }
                firewall_port_enable $TELNET_PORT
                firewall_port_enable $SSH_PORT
                ;;
            *)
                error "Invalid feature \"$2\"" && usage
                [ -n "$SOURCED" ]  && return 1 || exit 1
                ;;
        esac
        ;;
    disable|DISABLE|Disable|0)
        case "$2" in
            telnet)
                echo "Disable telnet"
                enable_telnet 0 $TELNET_PORT
                ;;
            ssh)
                echo "Disable ssh"
                enable_ssh 0 $SSH_PORT
                ;;
            mount)
                echo "Disable mount"
                for d in ${MOUNT_DIRS[@]}; do umount_dir $d; done
                ;;
            all)
                echo "Disable all"
                enable_telnet 0 $TELNET_PORT
                enable_ssh 0 $SSH_PORT
                [ -n "$SOURCED" ] && {
                    enable_ld_library_path ""
                }
                ;;
            *)
                error "Invalid feature \"$2\"" && usage
                [ -n "$SOURCED" ]  && return 1 || exit 1
                ;;
        esac
        ;;
    *)
        error "Invalid operation \"$1\"" && usage
        [ -n "$SOURCED" ]  && return 1 || exit 1
        ;;
esac

shift
shift
while [[ $# -gt 0 ]]; do warning "ignoring positional argument \"$1\""; shift; done