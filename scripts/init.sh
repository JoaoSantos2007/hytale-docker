#!/bin/bash
source /home/hytale/scripts/machine.sh
source /home/hytale/scripts/download.sh
source /home/hytale/scripts/start.sh
source /home/hytale/scripts/stop.sh

set -e

# Set file permissions
PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Using UID: $PUID  GID: $PGID"
groupmod -o -g "$PGID" hytale
usermod  -o -u "$PUID" hytale
chown -R "$PUID:$PGID" /home/hytale /data 2>/dev/null || true

# Set up persistent machine-id for encrypted auth
setup_machine-id

# Check server and download on start
if [ "${DOWNLOAD_ON_START:-true}" = "true" ]; then
    check_server
else
    echo "DOWNLOAD_ON_START is set to false, skipping server download"
fi

# Create a named pipe for sending commands to the server
export FIFO="/tmp/hytale_input_$$"
SERVER_PID=""

make_startup || exit 1
mkfifo "$FIFO"

term_handler() {
    echo "SIGTERM received, shutting down Hytale server..."

    if ! shutdown_server; then
        echo "Graceful shutdown failed, forcing kill..."
        pkill -9 -f HytaleServer.jar
    fi

    wait "$SERVER_PID"
}
trap term_handler SIGTERM

# Start the server as hytale user and  with the fifo as stdin
su hytale -c "export PATH=\"$PATH\"; cd $SERVER_DIR && exec $STARTUP_CMD" < "$FIFO" &
SERVER_PID=$!
exec 3>"$FIFO" # Open the fifo for writing (keeps it open)

set_logs

# Wait for the server process
wait $SERVER_PID
EXIT_CODE=$?

# Cleanup
exec 3>&-
rm -f "$FIFO"

exit $EXIT_CODE
