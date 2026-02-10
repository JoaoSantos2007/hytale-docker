#!/bin/bash
source /home/hytale/scripts/machine.sh
source /home/hytale/scripts/download.sh

set -e

PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Using UID: $PUID  GID: $PGID"

groupmod -o -g "$PGID" hytale
usermod  -o -u "$PUID" hytale

# Ajusta tudo que o container usa
chown -R "$PUID:$PGID" /home/hytale /data 2>/dev/null || true

# Set up persistent machine-id for encrypted auth
setup_machine-id

check_server

echo "All Done!"
