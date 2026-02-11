make_startup () {
    SERVER_DIR="${SERVER_DIR:-/data}"
    cd "$SERVER_DIR" || exit

    # Set defaults if not provided
    PORT="${PORT:-5520}"
    ENABLE_BACKUPS="${ENABLE_BACKUPS:-false}"
    BACKUP_FREQUENCY="${BACKUP_FREQUENCY:-30}"
    BACKUP_DIR="${BACKUP_DIR:-/data/backups}"
    DISABLE_SENTRY="${DISABLE_SENTRY:-true}"
    USE_AOT_CACHE="${USE_AOT_CACHE:-true}"
    AUTH_MODE="${AUTH_MODE:-authenticated}"
    ACCEPT_EARLY_PLUGINS="${ACCEPT_EARLY_PLUGINS:-false}"
    MAX_MEMORY="${MAX_MEMORY:-2048M}"

    # Check if HytaleServer.jar exists
    SERVER_JAR="$SERVER_DIR/Server/HytaleServer.jar"
    if [ ! -f "$SERVER_JAR" ]; then
        echo "Please ensure the server files are properly downloaded."
        exit 1
    fi

    echo "Starting Hytale Dedicated Server on port ${PORT}"

    # Build the startup command
    JVM_MEMORY="-Xmx$MAX_MEMORY"
    STARTUP_CMD="java ${JVM_MEMORY}"

    # Add AOT cache if enabled
    if [ "${USE_AOT_CACHE}" = "true" ] && [ -f "${SERVER_DIR}/Server/HytaleServer.aot" ]; then
        STARTUP_CMD="${STARTUP_CMD} -XX:AOTCache=${SERVER_DIR}/Server/HytaleServer.aot"
        echo "Using AOT cache for faster startup"
    fi

    # Add custom JVM arguments if provided
    if [ -n "${JVM_ARGS}" ]; then
        STARTUP_CMD="${STARTUP_CMD} ${JVM_ARGS}"
    fi

    # GSP token passthrough (if provided)
    if [ -n "${SESSION_TOKEN}" ] && [ -n "${IDENTITY_TOKEN}" ]; then
        export HYTALE_SERVER_SESSION_TOKEN="${SESSION_TOKEN}"
        export HYTALE_SERVER_IDENTITY_TOKEN="${IDENTITY_TOKEN}"
        [ -n "${OWNER_UUID}" ] && STARTUP_CMD="${STARTUP_CMD} --owner-uuid ${OWNER_UUID}"
    fi

    # Add the JAR and required arguments
    STARTUP_CMD="${STARTUP_CMD} -jar ${SERVER_JAR}"
    STARTUP_CMD="${STARTUP_CMD} --assets ${SERVER_DIR}/Assets.zip"
    STARTUP_CMD="${STARTUP_CMD} --bind 0.0.0.0:${PORT}"
    STARTUP_CMD="${STARTUP_CMD} --auth-mode ${AUTH_MODE}"

    # Add optional arguments
    if [ "${DISABLE_SENTRY}" = "true" ]; then
        STARTUP_CMD="${STARTUP_CMD} --disable-sentry"
    fi

    if [ "${ACCEPT_EARLY_PLUGINS}" = "true" ]; then
        STARTUP_CMD="${STARTUP_CMD} --accept-early-plugins"
    fi

    if [ "${ENABLE_BACKUPS}" = "true" ]; then
        STARTUP_CMD="${STARTUP_CMD} --backup --backup-dir $BACKUP_DIR --backup-frequency $BACKUP_FREQUENCY"
        echo "Automatic backups enabled (every ${BACKUP_FREQUENCY} minutes to ${BACKUP_DIR})"
    fi

    export STARTUP_CMD
}

set_logs () {
    # Monitor logs and send auth command when ready
    (
        sleep 5
        LOG_FILE=$(ls -t /data/logs/*_server.log 2>/dev/null | head -1)
        if [ -n "$LOG_FILE" ]; then
            tail -f "$LOG_FILE" | while read -r line; do
                if echo "$line" | grep -q "Hytale Server Booted!"; then
                    sleep 2
                    echo "/auth login device" >&3
                    echo "Sent auth command to server"
                fi
                
                if echo "$line" | grep -qE "Authentication successful!|Server is already authenticated."; then
                    sleep 1
                    echo "/auth persistence Encrypted" >&3
                    echo "Sent persistence command to server"
                    break
                fi
            done
        fi
    ) &
}