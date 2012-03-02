#!/bin/bash

NEED_ROOT=0 # this script can be run without be root
. /etc/rc.conf
. /etc/rc.d/functions
. /etc/user-rc.d/functions

USER_DAEMONS=()
[ -f "${USER_CONFIG}/user-rc.conf" ] && . "${USER_CONFIG}/user-rc.conf"

# print usage and exit
usage() {
  local name=${0##*/}
  cat >&2 << EOF
usage: $name <action> [options] [daemons]

options:
  -s, --started     Filter started daemons
  -S, --stopped     Filter stopped daemons
  -a, --auto        Filter auto started daemons
  -A, --noauto      Filter manually started daemons

<daemons> is a space separated list of script in /etc/user-rc.d and ${USER_CONFIG}/user-rc.d
<action> can be a start, stop, restart, reload, status, ...
autostart starts the daemons of the USER_DAEMONS array.
stop_all stops all the running daemons.
WARNING: user-initscripts are free to implement or not the above actions.

e.g: $name list
     $name list sshd gpm
     $name list --started gpm
     $name start sshd gpm
     $name stop_all
     $name autostart
     $name help
EOF
  exit ${1:-1}
}

# filter list of daemons
filter_daemons() {
  local -a new_daemons=()
  for daemon in "${daemons[@]}"; do
    # check if daemons is valid
    if ! have_user_daemon "$daemon"; then
      printf "${C_FAIL}:: ${C_DONE}Daemon script ${C_FAIL}${daemon}${C_DONE} does \
not exist or is not executable.${C_CLEAR}\n" >&2
      exit 2
    fi
    # check filter
    (( ${filter[started]} )) && ck_user_daemon "$daemon" && continue
    (( ${filter[stopped]} )) && ! ck_user_daemon "$daemon" && continue
    (( ${filter[auto]} )) && ck_user_autostart "$daemon" && continue
    (( ${filter[noauto]} )) && ! ck_user_autostart "$daemon" && continue
    new_daemons+=("$daemon")
  done
  daemons=("${new_daemons[@]}")
}

list_all_daemons() {
  [[ -z $daemons ]] && for d in "/etc/user-rc.d/"* "$USER_CONFIG/user-rc.d/"*; do
    have_user_daemon "$(basename "$d")" && ! in_array "$(basename "$d")" "${daemons[@]}" &&
    daemons+=("$(basename "$d")")
  done
}

run_action() {
  for daemon in "${daemons[@]}"; do
    env -u STARTING "$(which_user_daemon "$daemon")" "$1"
    (( ret += !! $? ))  # clamp exit value to 0/1
  done
}

(( $# < 1 )) && usage

# ret store the return code of user-rc.d
declare -i ret=0
# daemons store daemons on which action will be executed
declare -a daemons=()
# filter store current filter mode
declare -A filter=([started]=0 [stopped]=0 [auto]=0 [noauto]=0)

# parse options
argv=$(getopt -l 'started,stopped,auto,noauto' -- 'sSaA' "$@") || usage
eval set -- "$argv"

# create an initial daemon list
while [[ "$1" != -- ]]; do
  case "$1" in
    -s|--started)   filter[started]=1 ;;
    -S|--stopped)   filter[stopped]=1 ;;
    -a|--auto)      filter[auto]=1 ;;
    -A|--noauto)    filter[noauto]=1 ;;
  esac
  shift
done

# remove --
shift
# get action
action=$1
shift

# get initial daemons list
for daemon; do
  daemons+=("$daemon")
done

case $action in
  help)
    usage 0 2>&1
  ;;
  list)
    # list take all daemons by default
    list_all_daemons
    filter_daemons
    for daemon in "${daemons[@]}"; do
      # print running / stopped satus
      if ! ck_user_daemon "$daemon"; then
        s_status="${C_OTHER}[${C_DONE}STARTED${C_OTHER}]"
      else
        s_status="${C_OTHER}[${C_FAIL}STOPPED${C_OTHER}]"
      fi
      # print auto / manual status
      if ! ck_user_autostart "$daemon"; then
        s_auto="${C_OTHER}[${C_DONE}AUTO${C_OTHER}]"
      else
        s_auto="${C_OTHER}[${C_FAIL}    ${C_OTHER}]"
      fi
      printf "$s_status$s_auto${C_CLEAR} $daemon\n"
    done
  ;;
  autostart)
    for daemon in "${USER_DAEMONS[@]}"; do
      case ${daemon:0:1} in
        '!') continue;;     # Skip this daemon.
        '@') start_user_daemon_bkgd "${daemon#@}";;
        *)   start_user_daemon "$daemon";;
      esac
    done
  ;;
  stop_all)
    stop_all_user_daemons
  ;;
  *)
    # other actions need an explicit daemons list
    [[ -z $daemons ]] && usage
    filter_daemons
    run_action "$action"
  ;;
esac

exit $ret

# vim: set ts=2 sw=2 ft=sh noet:
