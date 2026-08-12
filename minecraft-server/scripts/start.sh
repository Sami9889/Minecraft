#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"
cd "$SERVER_DIR"

JAVA_BIN="${JAVA_BIN:-java}"
PAPER_JAR="server/paper.jar"
MAX_RAM="${MAX_RAM:-4G}"
MIN_RAM="${MIN_RAM:-2G}"

mkdir -p server plugins configs world logs backups

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

download_paper() {
  local url="https://fill-data.papermc.io/v1/objects/bd3a58cf96874e5ea6643f5f6fe9b4f5bf9e34b795fa078c2f0ee8b98b2f907e/paper-26.2-112.jar"
  log "Downloading Paper 26.2..."
  curl -L -o "$PAPER_JAR" "$url"
}

download_geyser() {
  local url="https://download.geysermc.org/v2/projects/geyser/versions/2.11.1/builds/1217/downloads/spigot"
  local dest="server/plugins/Geyser-Spigot.jar"
  log "Downloading GeyserMC..."
  curl -L -o "$dest" "$url"
}

download_viaversion() {
  local url="https://hangarcdn.papermc.io/plugins/ViaVersion/ViaVersion/versions/5.11.0/PAPER/ViaVersion-5.11.0.jar"
  local dest="server/plugins/ViaVersion.jar"
  log "Downloading ViaVersion..."
  curl -L -o "$dest" "$url"
}

accept_eula() {
  if [ ! -f server/eula.txt ] || ! grep -q "eula=true" server/eula.txt 2>/dev/null; then
    log "Accepting EULA..."
    echo "eula=true" > server/eula.txt
  fi
}

configure_server_properties() {
  local props_file="server/server.properties"
  cat > "$props_file" <<EOF
server-port=25565
enable-rcon=false
rcon.password=
max-players=20
online-mode=true
enable-status=true
motd=Paper Server - minecraft.sami-s.dev
difficulty=normal
gamemode=survival
spawn-protection=16
view-distance=10
simulation-distance=8
white-list=false
enforce-secure-profile=true
EOF
  log "Server properties configured"
}

configure_geyser() {
  local config_dir="server/plugins/Geyser-Spigot"
  mkdir -p "$config_dir"
  cat > "$config_dir/config.yml" <<EOF
bedrock:
  address: 0.0.0.0
  port: 19132
  clone-remote-port: false
remote:
  address: 127.0.0.1
  port: 25565
  auth-type: online
EOF
  log "GeyserMC configured for Bedrock on port 19132"
}

setup() {
  log "=== Minecraft Server Setup ==="
  download_paper
  download_geyser
  download_viaversion
  accept_eula
  configure_server_properties
  configure_geyser
  log "=== Setup Complete ==="
  log "Run './scripts/start.sh' to start the server"
}

start() {
  if [ ! -f "$PAPER_JAR" ]; then
    log "Paper server not found. Running setup..."
    setup
  fi

  accept_eula

  log "Starting Minecraft server..."
  log "Java Edition: 100.89.76.72:25565"
  log "Bedrock Edition: minecraft.sami-s.dev:19132"

  while true; do
    log "Launching server..."
    cd server
    "$JAVA_BIN" -Xmx"$MAX_RAM" -Xms"$MIN_RAM" -jar paper.jar nogui || true
    exit_code=$?
    cd "$SERVER_DIR"

    if [ $exit_code -ne 0 ]; then
      log "Server crashed with exit code $exit_code. Restarting in 5 seconds..."
      sleep 5
    else
      log "Server stopped normally."
      break
    fi
  done
}

case "${1:-}" in
  setup)
    setup
    ;;
  start|"")
    start
    ;;
  *)
    echo "Usage: $0 {setup|start}"
    exit 1
    ;;
esac
