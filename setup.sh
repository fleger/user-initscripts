#!/bin/bash

readonly SRC_DIR="$(dirname "$0")"

install -Dm755  "${SRC_DIR}/bin/user-rc.d" \
                "${DEST_DIR}/usr/sbin/user-rc.d"

install -Dm644  "${SRC_DIR}/examples/user-rc.conf" \
                "${DEST_DIR}/usr/share/user-initscripts/examples/user-rc.conf"

for i in "${SRC_DIR}/examples/"*.sh; do
  install -Dm755 "$i" "${DEST_DIR}/usr/share/user-initscripts/examples/$(basename "$i")"
done

install -Dm644  "${SRC_DIR}/hooks/user-initscripts" \
                "${DEST_DIR}/etc/rc.d/functions.d/user-initscripts"

install -Dm644  "${SRC_DIR}/user-rc.d/functions" \
                "${DEST_DIR}/etc/user-rc.d/functions"

install -Dm644  "${SRC_DIR}/tmpfiles.d/user-initscripts.conf" \
                "${DEST_DIR}/usr/lib/tmpfiles.d/user-initscripts.conf"

install -m775 -d "${DEST_DIR}/run/user-daemons"
