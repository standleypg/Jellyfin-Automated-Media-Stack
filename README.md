# Jellyfin Automated Media Stack

A fully automated self-hosted media server stack running on Docker. Request a movie or TV show once — the system finds, downloads, adds subtitles, and streams it automatically.

---

## Quick Start
```bash
# 1. Create your stack folder
mkdir -p ~/media-stack && cd ~/media-stack

# 2. Create media folders
mkdir -p /mnt/ssd/jellyfin/media/Movies
mkdir -p /mnt/ssd/jellyfin/media/tv
mkdir -p /mnt/ssd/jellyfin/media/downloads

# 3. Start the stack
docker compose up -d

# 4. Fix Seerr permissions
sudo chown -R 1000:1000 ~/media-stack/seerr
sudo chmod -R 755 ~/media-stack/seerr
docker restart seerr
```

See the full guide in [jellyfin-media-stack-guide.md](./jellyfin-media-stack-guide.md) for complete configuration steps.

---

## Services

| Service | Purpose | Port | Web UI |
|---|---|---|---|
| Jellyfin | Stream movies & TV shows | 8096 | `http://YOUR_IP:8096` |
| Seerr | Request movies & TV shows | 5055 | `http://YOUR_IP:5055` |
| Radarr | Auto manage & download movies | 7878 | `http://YOUR_IP:7878` |
| Sonarr | Auto manage & download TV shows | 8989 | `http://YOUR_IP:8989` |
| Prowlarr | Search torrent indexers | 9696 | `http://YOUR_IP:9696` |
| qBittorrent | Download torrents | 8080 | `http://YOUR_IP:8080` |
| Bazarr | Auto download subtitles | 6767 | `http://YOUR_IP:6767` |
| FlareSolverr | Bypass Cloudflare on indexers | 8191 | No UI |

---

## How It Works
```
You -> Seerr -> Radarr/Sonarr -> Prowlarr -> qBittorrent -> Bazarr -> Jellyfin
      Request    Find it          Search       Download     Subtitles   Stream
```

1. You open Seerr and request a movie or TV show
2. Radarr (movies) or Sonarr (TV) searches Prowlarr for a torrent
3. Prowlarr queries your configured indexers (YTS, 1337x, etc.)
4. FlareSolverr bypasses any Cloudflare protection on indexers
5. qBittorrent downloads the torrent
6. Radarr/Sonarr renames and moves the file to your media folder
7. Bazarr automatically downloads subtitles for the new file
8. Jellyfin detects the new file and it appears in your library with subtitles

---

## Folder Structure
```
~/media-stack/
├── docker-compose.yml
├── README.md
├── jellyfin-media-stack-guide.md
├── jellyfin/
│   ├── config/          <- Jellyfin config, users, watch history
│   └── cache/           <- Jellyfin cache
├── prowlarr/            <- Prowlarr config
├── radarr/              <- Radarr config
├── sonarr/              <- Sonarr config
├── qbittorrent/         <- qBittorrent config
├── bazarr/              <- Bazarr config
├── seerr/               <- Seerr config
└── flaresolverr/        <- FlareSolverr config

/mnt/ssd/jellyfin/media/
├── Movies/              <- Final movie files with subtitles
├── tv/                  <- Final TV show files with subtitles
└── downloads/           <- Temporary download folder
```

---

## Internal Container URLs

When configuring services to talk to each other, always use container names:

| Connection | URL |
|---|---|
| Prowlarr -> Radarr | `http://radarr:7878` |
| Prowlarr -> Sonarr | `http://sonarr:8989` |
| Prowlarr -> FlareSolverr | `http://flaresolverr:8191` |
| Seerr -> Jellyfin | `http://jellyfin:8096` |
| Seerr -> Radarr | `http://radarr:7878` |
| Seerr -> Sonarr | `http://sonarr:8989` |
| Radarr -> qBittorrent | `http://qbittorrent:8080` |
| Sonarr -> qBittorrent | `http://qbittorrent:8080` |
| Bazarr -> Radarr | `http://radarr:7878` |
| Bazarr -> Sonarr | `http://sonarr:8989` |

Use your actual server IP only when accessing from your browser.

---

## Common Commands
```bash
# Start all services
docker compose up -d

# Stop all services
docker compose down

# Restart a single service
docker restart radarr

# View logs
docker logs radarr --tail 50

# Apply compose file changes
docker compose up -d --force-recreate

# Remove old/renamed containers
docker compose down --remove-orphans

# Check all running containers
docker ps

# Get qBittorrent temp password
docker logs qbittorrent | grep password

# Check container network
docker network inspect media-stack_medianet
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Indexer test times out | DNS blocking — `dns: 8.8.8.8` in compose fixes this |
| Indexer blocked by Cloudflare | Add `flaresolverr` tag to that indexer in Prowlarr |
| Containers can't reach each other | All must be on `medianet` network |
| Seerr 404 sign in error | Use container name `jellyfin` not IP, port in its own field |
| Seerr permission denied / restart loop | `sudo chown -R 1000:1000 ~/media-stack/seerr` then restart |
| Radarr shows movies as missing (red) | Normal — check indexers synced and qBittorrent connected |
| Radarr can't import downloaded file | Ensure `/downloads` is mounted in Radarr volumes |
| Prowlarr sync button stuck | `docker restart prowlarr` |
| qBittorrent password unknown | `docker logs qbittorrent \| grep password` |
| Container name conflict on recreate | `docker compose down --remove-orphans` first |
| Bazarr not finding subtitles | Check provider credentials and language profile is set |
| Subtitles not showing in Jellyfin | Rescan library in Jellyfin Dashboard -> Libraries |

---

## Prerequisites

- Ubuntu Server 20.04 or later
- Docker installed
- At least 50GB free storage

### Install Docker
```bash
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
```

---

## Full Setup Guide

See [jellyfin-media-stack-guide.md](./jellyfin-media-stack-guide.md) for the complete step-by-step configuration of every service.

---

## Tips and Next Steps

- Invite users — Add family/friends in Seerr so they can request content
- Watchlists — Connect Radarr to IMDb or Trakt for fully automatic downloads
- 4K — Add a second Radarr instance dedicated to 4K with a separate quality profile
- VPN — Add Gluetun to route qBittorrent through a VPN for privacy
- TVDB metadata — Enable in Seerr settings for better TV/anime matching with Sonarr
- DNS Cache — Enable in Seerr network settings for large Jellyfin libraries

---

## Disclaimer

This stack is intended for downloading and streaming content you own or have
the right to access. Please respect copyright laws in your country.