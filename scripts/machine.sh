#!/bin/bash

setup_machine-id () {
  PUID=${PUID:-1000}
  PGID=${PGID:-1000}
  SERVER_DIR="${SERVER_DIR:-/data}"
  MACHINE_ID_DIR="$SERVER_DIR/.machine-id"
  mkdir -p "$MACHINE_ID_DIR"

  if [ ! -f "$MACHINE_ID_DIR/uuid" ]; then
    echo "Generating persistent machine-id for encrypted auth..."
    MACHINE_UUID=$(cat /proc/sys/kernel/random/uuid)
    MACHINE_UUID_NO_DASH=$(echo "$MACHINE_UUID" | tr -d '-' | tr '[:upper:]' '[:lower:]')
        
    echo "$MACHINE_UUID_NO_DASH" > "$MACHINE_ID_DIR/machine-id"
    echo "$MACHINE_UUID_NO_DASH" > "$MACHINE_ID_DIR/dbus-machine-id"
    echo "$MACHINE_UUID" > "$MACHINE_ID_DIR/product_uuid"
    echo "$MACHINE_UUID" > "$MACHINE_ID_DIR/uuid"
        
    chown -R ${PUID}:${PGID} "$MACHINE_ID_DIR"
  fi

  # Copy to system locations
  cp "$MACHINE_ID_DIR/machine-id" /etc/machine-id
  mkdir -p /var/lib/dbus
  cp "$MACHINE_ID_DIR/dbus-machine-id" /var/lib/dbus/machine-id

  echo "Machine ID configured for encrypted auth persistence"
}
