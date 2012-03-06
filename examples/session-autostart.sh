#!/bin/bash

# Autostart daemons only if no other session pertaining to the current user are opened.
# This requires the consolekit and dbus-core packages.
# The dbus deamon must have been started.

# You can execute this file for instance in your .bash_profile or when your DE is starting.

# Test if the current ConsoleKit session is the only session pertaining to the current user
isTheOnlyUserSession() {
  local currentSession=""
  local -a sessions=()
  local line=""
  local -r sessionRE='^object path "(.+)"$'

  # Get current session
  while read line; do
    [[ "$line" =~ $sessionRE ]] &&
    currentSession="${BASH_REMATCH[1]}"
  done < <(dbus-send --system --print-reply --dest=org.freedesktop.ConsoleKit \
                     /org/freedesktop/ConsoleKit/Manager                      \
                     org.freedesktop.ConsoleKit.Manager.GetCurrentSession)

  # Not in a ConsoleKit session
  [[ -z "$currentSession" ]] && return 2

  # Get all user sessions
  while read line; do
    [[ "$line" =~ $sessionRE ]] &&
    sessions+=("${BASH_REMATCH[1]}")
  done < <(dbus-send --system --print-reply --dest=org.freedesktop.ConsoleKit \
                     /org/freedesktop/ConsoleKit/Manager                      \
                     org.freedesktop.ConsoleKit.Manager.GetSessionsForUser "uint32:$UID")

  [[ "${#sessions[@]}" -eq 1 ]] &&
  [[ "${sessions[0]}" == "$currentSession" ]] &&
  return 0 ||
  return 1
}

isTheOnlyUserSession &&
/usr/sbin/user-rc.d autostart 