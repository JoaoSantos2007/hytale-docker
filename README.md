## Hytale Dedicated Server Docker

A Docker container for running a Hytale dedicated server with automatic downloading and updates using the official Hytale Downloader CLI.

## Server Requirements

| Resource | Minimum | Recommended |
|----------|---------|-------------|
| CPU      | 4 cores | 8+ cores    |
| RAM      | 4GB     | 8GB+        |
| Storage  | 10GB    | 20GB        |

> [!NOTE]
> - Hytale requires **Java 25** (included in the Docker image)
> - Server resource usage depends heavily on player count and view distance
> - Higher view distances significantly increase RAM usage
> - Hytale uses **QUIC over UDP** (not TCP) on port **5520**

> [!IMPORTANT]
> **First-Time Setup: Authentication Required**
> 
> On first startup, you'll need to authenticate via your browser. The server will display a URL in the console - just visit it and log in with your Hytale account. You will then need to authorize again from the link that appears once the server has started.

## How to use

### Quick Start

```bash
# 1. Start server
docker-compose up -d

# 2. Check logs for OAuth URL
docker-compose logs -f

# 3. Visit the URL in your browser and authenticate
# Server continues automatically after authentication
```

### Docker Compose

Using `docker compose`:

```yaml
services:
  hytale:
    build: .
    container_name: hytale
    restart: unless-stopped
    stop_grace_period: 30s

    ports:
      - 5520:5520/udp
    
    volumes:
      - ./test:/data

    environment:
      - PUID=1000
      - PGID=1000
      - DOWNLOAD_ON_START=true
      
    stdin_open: true
    tty: true
```

Then run:

```bash
docker-compose up -d
```

## Environment Variables

You can use the following values to change the settings of the server on boot.

| Variable               | Default              | Description                                                                           |
|------------------------|----------------------|---------------------------------------------------------------------------------------|
| PUID                   | 1000                 | User ID for file permissions                                                          |
| PGID                   | 1000                 | Group ID for file permissions                                                         |
| PORT                   | 5520                 | The port the server listens on (UDP only)                                             |
| AUTH_MODE              | authenticated        | Authentication mode: `authenticated` or `offline`                                     |
| ENABLE_BACKUPS         | false                | Enable automatic world backups                                                        |
| BACKUP_FREQUENCY       | 30                   | Backup interval in minutes (if backups are enabled)                                   |
| BACKUP_DIR             | /data/backups        | Directory path for storing backups                                                    |
| DISABLE_SENTRY         | true                 | Disable Sentry crash reporting                                                        |
| USE_AOT_CACHE          | true                 | Use Ahead-of-Time compilation cache for faster startup                                |
| ACCEPT_EARLY_PLUGINS   | false                | Allow early plugins (may cause stability issues)                                      |
| MAX_MEMORY             | 2048M                | Maximum JVM heap size (e.g., 8G, 8192M)                                               |
| JVM_ARGS               |                      | Custom JVM arguments (optional)                                                       |
| DOWNLOAD_ON_START      | true                 | Automatically download/update server files on startup                                 |

## Port Configuration

Hytale uses the **QUIC protocol over UDP** (not TCP). Make sure to:

1. **Open UDP port 5520** (or your custom port) in your firewall
2. **Forward UDP port 5520** in your router if hosting from home
3. Configure firewall rules for UDP only


## File Structure

After first run, the following structure will be created in your `data` directory:

```
data/
├── Server/
│   ├── HytaleServer.jar       # Main server executable
│   └── HytaleServer.aot       # AOT cache for faster startup
├── Assets.zip                 # Game assets
├── downloader/                # Hytale downloader CLI
├── .cache/                    # Optimized file cache
├── logs/                      # Server log files
├── mods/                      # Installed mods (place .jar or .zip files here)
├── universe/                  # World and player save data
│   └── worlds/                # Individual world folders
├── bans.json                  # Banned players
├── config.json                # Server configuration
├── credentials.json           # Hytale downloader credentials
├── permissions.json           # Permission configuration
└── version.txt                # Server version
└── whitelist.json             # Whitelisted players
```

## View Distance & Performance

View distance is the primary driver for RAM usage:

- **Default:** 12 chunks (384 blocks) ≈ 24 Minecraft chunks
- **Recommended Max:** 12 chunks for optimal performance
- **RAM Impact:** Higher view distances exponentially increase memory requirements

Tune `MAX_MEMORY` and `VIEW_DISTANCE` based on:
- Number of concurrent players
- How spread out players are in the world
- Available server resources

## Useful Commands

### View server logs
```bash
docker logs hytale -f
# or
docker-compose logs -f
```

### Stop the server
```bash
docker-compose down
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.