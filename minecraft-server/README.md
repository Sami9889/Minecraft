# Minecraft Server - Paper + GeyserMC + ViaVersion

Minecraft server with Bedrock support, running on GitHub Actions (no self-hosted runner required).

## Components

- **Paper 26.2** - High-performance Minecraft server (plugin support)
- **GeyserMC 2.11.1** - Bedrock to Java bridge
- **ViaVersion 5.11.0** - Protocol translation

## Setup

1. Push this repository to GitHub
2. Go to **Actions** → **Minecraft Server - GitHub Hosted** → **Run workflow**
3. Select **deploy** and click run

The workflow will:
- Download Paper 26.2 from PaperMC
- Download GeyserMC Spigot plugin
- Download ViaVersion plugin
- Configure `server.properties`
- Configure GeyserMC for Bedrock on port 19132
- Start the server

## Features

- **No self-hosted runner required**: Runs entirely on GitHub-hosted runners
- **Auto-restart**: Server restarts automatically if it crashes (within the job runtime)
- **Auto-update**: Daily checks for new versions at 4:00 AM
- **Backup**: Automatic world backups before updates
- **Manual trigger**: Run anytime via Actions tab

## Required GitHub Secrets

None required for GitHub-hosted runners.

## File Structure

```
.github/workflows/
│   └── minecraft-server.yml    # GitHub Actions workflow
minecraft-server/
├── configs/
│   └── minecraft-server.service # Systemd unit (for self-hosted fallback)
├── scripts/
│   ├── start.sh                 # Main server startup
│   ├── update.sh                # Version checker & updater
│   └── setup-backend.sh         # VPS full setup (for self-hosted fallback)
├── server/
│   ├── paper.jar                # Paper server
│   ├── server.properties        # Server config
│   ├── eula.txt                 # EULA accepted
│   ├── world/                   # World data
│   └── plugins/
│       ├── Geyser-Spigot.jar    # Bedrock support
│       ├── ViaVersion.jar       # Protocol support
│       └── Geyser-Spigot/
│           └── config.yml       # Geyser config
└── README.md
```

## Management

View logs in the Actions run output.

## Auto-Update Schedule

- **Daily**: Checks for Paper, GeyserMC, ViaVersion updates at 4:00 AM
- **On Update**: Creates world backup, downloads new versions, restarts server

## Requirements

- **GitHub Actions** enabled on your repository
- **Java**: Temurin 21 (automatically installed by workflow)

## Limitations (GitHub-Hosted Runners)

- Maximum runtime: **6 hours** per workflow run
- Server data is ephemeral (world resets between runs unless using persistent storage)
- Ports are not exposed to the public internet (for local/testing use only)
- For 24/7 public hosting, use a self-hosted runner or VPS

## Security

- Online mode enabled (authenticated Minecraft accounts)
- Secure profile enforcement enabled

## License

By running this server you agree to:
- [Minecraft EULA](https://www.minecraft.net/eula)
- [Minecraft Privacy Policy](https://www.microsoft.com/privacy)
