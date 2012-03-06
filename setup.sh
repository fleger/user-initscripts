#!/bin/bash

readonly SRC_DIR="$(dirname "$0")"

install -Dm755  "${SRC_DIR}/bin/user-rc.d" \
                "${DEST_DIR}/usr/sbin/user-rc.d"
install -Dm644  "${SRC_DIR}/examples/user-rc.conf" \
                "${DEST_DIR}/usr/share/user-initscripts/examples/user-rc.conf"
install -Dm644  "${SRC_DIR}/hooks/user-initscripts" \
                "${DEST_DIR}/etc/rc.d/functions.d/user-initscripts"
install -Dm644  "${SRC_DIR}/user-rc.d/functions" \
                "${DEST_DIR}/etc/user-rc.d/functions"
install -m775 -d "${DEST_DIR}/run/user-daemons"
