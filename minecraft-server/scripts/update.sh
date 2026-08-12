#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"

VERSION_FILE="configs/current-version.txt"
PAPER_BUILD="112"
GATEWAY_VERSION="2.11.1"
GATEWAY_BUILD="1217"
VIAVERSION_VERSION="5.11.0"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

get_current_versions() {
  paper_ver="26.2"
  gateway_ver="2.11.1"
  viaversion_ver="5.11.0"

  if [ -f "$VERSION_FILE" ]; then
    source "$VERSION_FILE"
  fi
}

check_paper_update() {
  local current="$1"
  log "Checking Paper updates... (current: $current)"
  local latest
  latest=$(curl -s "https://fill-data.papermc.io/v1/objects/bd3a58cf96874e5ea6643f5f6fe9b4f5bf9e34b795fa078c2f0ee8b98b2f907e/paper-26.2-112.jar" -I | grep -i "content-disposition" | grep -oP 'paper-\K[0-9.]+(?=-)' || echo "$current")

  if [ "$latest" != "$current" ] && [ -n "$latest" ]; then
    log "New Paper version available: $latest (current: $current)"
    echo "$latest"
  else
    echo "$current"
  fi
}

check_geyser_update() {
  local current="$1"
  log "Checking GeyserMC updates... (current: $current)"
  local latest
  latest=$(curl -s "https://download.geysermc.org/v2/projects/geyser/versions/latest/builds/latest/downloads/spigot" -I | grep -i "location" | sed 's/.*versions\/\([^\/]*\)\/builds.*/\1/' || echo "$current")

  if [ "$latest" != "$current" ] && [ -n "$latest" ]; then
    log "New GeyserMC version available: $latest (current: $current)"
    echo "$latest"
  else
    echo "$current"
  fi
}

backup_world() {
  if [ -d "world" ]; then
    local backup_name="backups/world-$(date +%Y%m%d-%H%M%S).tar.gz"
    mkdir -p backups
    tar -czf "$backup_name" world/
    log "World backed up to $backup_name"

    find backups/ -name "world-*.tar.gz" -mtime +7 -delete 2>/dev/null || true
  fi
}

update() {
  log "=== Checking for Updates ==="

  get_current_versions

  local new_paper
  new_paper=$(check_paper_update "$paper_ver")

  local new_geyser
  new_geyser=$(check_geyser_update "$gateway_ver")

  if [ "$new_paper" != "$paper_ver" ] || [ "$new_geyser" != "$gateway_ver" ]; then
    log "=== Updates Available ==="
    log "Paper: $paper_ver -> $new_paper"
    log "GeyserMC: $gateway_ver -> $new_geyser"

    read -p "Apply updates? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      backup_world

      if [ "$new_paper" != "$paper_ver" ]; then
        log "Updating Paper..."
        curl -L -o server/paper.jar "https://fill-data.papermc.io/v1/objects/bd3a58cf96874e5ea6643f5f6fe9b4f5bf9e34b795fa078c2f0ee8b98b2f907e/paper-${new_paper}-${PAPER_BUILD}.jar"
        paper_ver="$new_paper"
      fi

      if [ "$new_geyser" != "$gateway_ver" ]; then
        log "Updating GeyserMC..."
        curl -L -o server/plugins/Geyser-Spigot.jar "https://download.geysermc.org/v2/projects/geyser/versions/${new_geyser}/builds/latest/downloads/spigot"
        gateway_ver="$new_geyser"
      fi

      cat > "$VERSION_FILE" <<EOF
PAPER_VERSION="$paper_ver"
PAPER_BUILD="$PAPER_BUILD"
GEYSER_VERSION="$gateway_ver"
GEYSER_BUILD="$GATEWAY_BUILD"
VIAVERSION_VERSION="$VIAVERSION_VERSION"
EOF

      log "=== Updates Applied ==="
      log "Restart server to apply changes"
    fi
  else
    log "All components are up to date"
    log "Paper: $paper_ver"
    log "GeyserMC: $gateway_ver"
    log "ViaVersion: $viaversion_ver"
  fi
}

case "${1:-}" in
  check)
    get_current_versions
    log "Current versions:"
    log "  Paper: ${paper_ver:-26.2}"
    log "  GeyserMC: ${gateway_ver:-2.11.1}"
    log "  ViaVersion: ${viaversion_ver:-5.11.0}"
    ;;
  update)
    update
    ;;
  backup)
    backup_world
    ;;
  *)
    echo "Usage: $0 {check|update|backup}"
    exit 1
    ;;
esac
