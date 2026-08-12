#!/bin/bash
set -e
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVER_DIR="$(dirname "$SCRIPT_DIR")"

DOMAIN="minecraft.sami-s.dev"
IP="100.89.76.72"
JAVA_PORT=25565
BEDROCK_PORT=19132

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

setup_firewall() {
  log "Configuring firewall..."

  if command -v ufw &> /dev/null; then
    log "Using UFW..."
    ufw allow $JAVA_PORT/tcp comment "Minecraft Java Edition"
    ufw allow $BEDROCK_PORT/udp comment "Minecraft Bedrock Edition (GeyserMC)"
    ufw allow 22/tcp comment "SSH"
    ufw --force enable
  elif command -v iptables &> /dev/null; then
    log "Using iptables..."
    iptables -A INPUT -p tcp --dport $JAVA_PORT -j ACCEPT
    iptables -A INPUT -p udp --dport $BEDROCK_PORT -j ACCEPT
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    iptables -P INPUT DROP
  fi

  log "Firewall configured"
}

verify_dns() {
  log "Verifying DNS for $DOMAIN..."
  local resolved
  resolved=$(dig +short "$DOMAIN" 2>/dev/null | tail -n1)

  if [ "$resolved" = "$IP" ]; then
    log "✓ DNS verified: $DOMAIN -> $IP"
  else
    log "⚠ DNS check: $DOMAIN resolves to $resolved (expected $IP)"
    log "  Make sure your DNS A record points to $IP"
  fi
}

test_ports() {
  log "Testing port connectivity..."

  if command -v nc &> /dev/null; then
    if nc -z -w 2 127.0.0.1 $JAVA_PORT 2>/dev/null; then
      log "✓ Java port $JAVA_PORT is listening"
    else
      log "⚠ Java port $JAVA_PORT is not listening (server may not be running)"
    fi
  fi

  log "Port $BEDROCK_PORT/udp should be open for Bedrock connections"
}

setup_systemd() {
  log "Installing systemd service..."
  cp configs/minecraft-server.service /etc/systemd/system/
  systemctl daemon-reload
  systemctl enable minecraft-server
  log "✓ Systemd service installed"
  log "  Start: systemctl start minecraft-server"
  log "  Stop: systemctl stop minecraft-server"
  log "  Status: systemctl status minecraft-server"
  log "  Logs: journalctl -u minecraft-server -f"
}

setup_auto_update() {
  log "Setting up automatic updates..."

  local cron_file="/etc/cron.d/minecraft-updater"
  cat > "$cron_file" <<EOF
0 4 * * * root $SERVER_DIR/scripts/update.sh update >> $SERVER_DIR/logs/updater.log 2>&1
EOF
  chmod 644 "$cron_file"
  log "✓ Auto-update scheduled daily at 4:00 AM"
}

install_dependencies() {
  log "Installing dependencies..."

  if command -v apt-get &> /dev/null; then
    apt-get update
    apt-get install -y curl java-21-jdk iptables ufw dig
  elif command -v yum &> /dev/null; then
    yum install -y curl java-21-openjdk iptables bind-utils
  elif command -v dnf &> /dev/null; then
    dnf install -y curl java-21-openjdk iptables bind-utils
  fi

  log "✓ Dependencies installed"
}

create_user() {
  if ! id "minecraft" &>/dev/null; then
    log "Creating minecraft user..."
    useradd -r -m -d /opt/minecraft-server -s /bin/bash minecraft
    usermod -aG sudo minecraft
  fi
}

main() {
  log "=== Minecraft Server Backend Setup ==="
  log "Domain: $DOMAIN"
  log "IP: $IP"
  log ""

  create_user
  install_dependencies
  setup_firewall
  verify_dns
  setup_systemd
  setup_auto_update

  log ""
  log "=== Setup Complete ==="
  log ""
  log "Next steps:"
  log "1. Copy server files to /opt/minecraft-server"
  log "2. chown -R minecraft:minecraft /opt/minecraft-server"
  log "3. systemctl start minecraft-server"
  log ""
  log "Connect with:"
  log "  Java: $DOMAIN:$JAVA_PORT"
  log "  Bedrock: $DOMAIN:$BEDROCK_PORT"
}

main
