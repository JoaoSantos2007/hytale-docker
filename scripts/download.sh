#!/bin/bash

SERVER_DIR="${SERVER_DIR:-/data}"
DOWNLOADER_DIR="${DOWNLOADER_DIR:-/home/hytale/downloader}"
GAME_DOWNLOAD_DIR="${GAME_DOWNLOAD_DIR:-/home/hytale/game}"
DOWNLOADER_CMD="${DOWNLOADER_CMD:-./hytale_downloader}"
CREDENTIALS_FILE_SERVER="$SERVER_DIR/credentials.json"
CREDENTIALS_FILE_DOWNLOADER="$DOWNLOADER_DIR/.hytale-downloader-credentials.json"
VERSION_FILE_SERVER="$SERVER_DIR/version.txt"
VERSION_FILE_DOWNLOADER="$DOWNLOADER_DIR/version.txt"
latest_version=""
current_version=""

download_server() {
  echo "Downloading server files (this may take a while)..."
  cd "$DOWNLOADER_DIR" || exit 1

  # Download game.zip
  eval "$DOWNLOADER_CMD -download-path '$GAME_DOWNLOAD_DIR/game.zip'" || {
    echo "Failed to download server files"
    return 1
  }
  
  # Check if authentication was successful
  if [ -f "$CREDENTIALS_FILE_DOWNLOADER" ]; then
    echo "Hytale Authentication Successful"
    cp -f "$CREDENTIALS_FILE_DOWNLOADER" "$CREDENTIALS_FILE_SERVER"
  fi
  
  # Extract the files
  echo "Extracting server files..."
  cd "$GAME_DOWNLOAD_DIR" || exit 1
  unzip -o -q game.zip || {
    echo "Failed to extract server files"
    return 1
  }
  rm game.zip

  # Copy game files to 
  cp -f "$GAME_DOWNLOAD_DIR/Assets.zip" "$SERVER_DIR/Assets.zip"
  cp -f "$GAME_DOWNLOAD_DIR/Server/HytaleServer.jar" "$SERVER_DIR/HytaleServer.jar"
  cp -f "$GAME_DOWNLOAD_DIR/Server/HytaleServer.aot" "$SERVER_DIR/HytaleServer.aot"
  
  # Verify files exist
  if [ ! -f "$SERVER_DIR/HytaleServer.jar" ]; then
    echo "HytaleServer.jar not found after download"
    return 1
  fi

  # Get version if we don't have it yet (first boot)
  if [ -z "$latest_version" ]; then
    latest_version=$(eval "$DOWNLOADER_CMD -print-version" 2>/dev/null)
  fi

  # Remove outdated AOT cache only if this was an update
  if [ -n "$current_version" ] && [ "$current_version" != "$latest_version" ]; then
    if [ -f "$SERVER_DIR/HytaleServer.aot" ]; then
      echo "Removing outdated AOT cache file (HytaleServer.aot) after update"
      rm -f "$SERVER_DIR/HytaleServer.aot"
    fi
  fi

  # Save version in volume
  if [ -n "$latest_version" ]; then
    echo "$latest_version" > "$VERSION_FILE_DOWNLOADER"
    cp -f "$VERSION_FILE_DOWNLOADER" "$VERSION_FILE_SERVER"
  fi

  echo "Server download completed!"
}

check_server() {
  echo "Checking server version..."

  mkdir -p "$DOWNLOADER_DIR"
  mkdir -p "$GAME_DOWNLOAD_DIR"
  mkdir -p "$SERVER_DIR"


  # Sync credentials file in volume with container downloader
  if [ -f "$CREDENTIALS_FILE_SERVER" ]; then
    cp -f "$CREDENTIALS_FILE_SERVER" "$CREDENTIALS_FILE_DOWNLOADER"
  else
    rm -f "$CREDENTIALS_FILE_DOWNLOADER"
  fi

  # Sync version file in volume with container downloader
  if [ -f "$VERSION_FILE_SERVER" ]; then
    cp -f "$VERSION_FILE_SERVER" "$VERSION_FILE_DOWNLOADER"
  else
    rm -f "$VERSION_FILE_DOWNLOADER"
  fi

  # First boot
  if [ ! -f "$CREDENTIALS_FILE_DOWNLOADER" ]; then
    echo "First time, authentication is required!"
    download_server || return 1
    return 0
  fi

  cd "$DOWNLOADER_DIR" || exit 1

  # Get latest version
  latest_version=$(eval "$DOWNLOADER_CMD -print-version" 2>/dev/null)
  if [ -z "$latest_version" ]; then
    echo "Failed to get latest version"
    return 1
  fi

  # Get current installed version
  if [ -f "$VERSION_FILE_DOWNLOADER" ]; then
    current_version=$(cat "$VERSION_FILE_DOWNLOADER")
  else
    current_version=""
  fi

  # Already up to date
  if [ -f "$SERVER_DIR/HytaleServer.jar" ] && [ "$current_version" = "$latest_version" ]; then
    echo "Server is up to date (version $latest_version)"
    return 0
  fi

  # Needs install/update
  if [ -f "$SERVER_DIR/HytaleServer.jar" ]; then
    echo "Update available: $current_version -> $latest_version"
  else
    echo "Server not installed"
  fi

  download_server || return 1
  return 0
}