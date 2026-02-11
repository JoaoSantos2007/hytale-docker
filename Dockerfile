FROM eclipse-temurin:25-jre

RUN apt-get update && \
    apt-get install -y curl unzip ca-certificates && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create user/group
RUN userdel -r ubuntu 2>/dev/null || true && \
    groupadd -g 1000 hytale && \
    useradd -u 1000 -g 1000 -m -d /home/hytale -s /bin/bash hytale

ENV PUID=1000 \
    PGID=1000 \
    DOWNLOAD_ON_START=true \
    SERVER_DIR="/data" \
    BACKUP_DIR="/data/backups" \
    DOWNLOADER_DIR="/home/hytale/downloader" \
    GAME_DOWNLOAD_DIR="/home/hytale/game" \
    DOWNLOADER_CMD="./hytale_downloader" \
    PORT=5520 \
    ENABLE_BACKUPS=true \
    BACKUP_FREQUENCY=30 \
    DISABLE_SENTRY=true \
    USE_AOT_CACHE=true \
    AUTH_MODE=authenticated \
    ACCEPT_EARLY_PLUGINS=false \
    MAX_MEMORY=2048M \
    JVM_ARGS="" \
    SESSION_TOKEN="" \
    IDENTITY_TOKEN="" \
    OWNER_UUID=""

COPY ./scripts /home/hytale/scripts
COPY ./hytale_downloader /home/hytale/downloader/hytale_downloader

RUN chmod +x /home/hytale/scripts/*.sh && \
    chown -R 1000:1000 /home/hytale

WORKDIR /home/hytale

VOLUME ["/data"]

EXPOSE 5520

# Health check to ensure the server is running
HEALTHCHECK --start-period=5m \
            --interval=30s \
            --timeout=10s \
            CMD pgrep -f "HytaleServer.jar" > /dev/null || exit 1

ENTRYPOINT ["/home/hytale/scripts/init.sh"]