# Complete Jellyfin Automated Media Stack Guide

## Overview

This guide sets up a fully automated home media server. You request a movie
or TV show once, and the system finds, downloads, organizes, adds subtitles,
and makes it available in Jellyfin automatically.

### How It Works
```
Seerr (Request) -> Radarr/Sonarr (Find) -> Prowlarr (Search) -> qBittorrent (Download) -> Bazarr (Subtitles) -> Jellyfin (Stream)
```

### Services Included

| Service | Purpose | Port |
|---|---|---|
| Jellyfin | Stream movies & TV shows | 8096 |
| Seerr | Request movies & TV shows | 5055 |
| Radarr | Auto manage & download movies | 7878 |
| Sonarr | Auto manage & download TV shows | 8989 |
| Prowlarr | Search torrent indexers | 9696 |
| qBittorrent | Download torrents | 8080 |
| Bazarr | Auto download subtitles | 6767 |
| FlareSolverr | Bypass Cloudflare on indexers | 8191 |

> Seerr is the unified successor to Jellyseerr and Overseerr,
> combining both projects into one. It supports Jellyfin, Emby and Plex.

---

## Prerequisites

- Ubuntu Server (20.04 or later)
- Docker installed
- At least 50GB free storage

### Install Docker (if not already installed)
```bash
sudo apt update && sudo apt upgrade -y
curl -fsSL https://get.docker.com | sudo sh
sudo usermod -aG docker $USER
newgrp docker
docker --version
```

---

## Step 1: Create Folder Structure
```bash
mkdir -p ~/media-stack
mkdir -p /mnt/ssd/jellyfin/media/Movies
mkdir -p /mnt/ssd/jellyfin/media/tv
mkdir -p /mnt/ssd/jellyfin/media/downloads
```

> Change `/mnt/ssd/jellyfin/media` to your actual media storage path.

---

## Step 2: Create Docker Compose File

Save the `docker-compose.yml` into `~/media-stack/` then run:
```bash
cd ~/media-stack
docker compose up -d
docker ps
hostname -I
```

You should see all 8 containers running:
jellyfin, prowlarr, radarr, sonarr, qbittorrent, bazarr, seerr, flaresolverr

---

## Step 3: Fix Seerr Permissions

Run this immediately after first startup to prevent permission errors:
```bash
sudo chown -R 1000:1000 ~/media-stack/seerr
sudo chmod -R 755 ~/media-stack/seerr
docker restart seerr
```

---

## Step 4: Configure qBittorrent — http://YOUR_IP:8080

1. Get temp password:
```bash
docker logs qbittorrent | grep password
```
2. Login with username `admin` and temp password
3. Tools -> Options -> WebUI -> change password to something secure
4. Tools -> Options -> Downloads -> set Default Save Path to `/downloads`
5. Save

---

## Step 5: Configure Prowlarr — http://YOUR_IP:9696

### Add FlareSolverr Proxy
1. Settings -> Indexers -> click + under Proxies
2. Select FlareSolverr and fill in:
   - Name: `FlareSolverr`
   - Host: `http://flaresolverr:8191`
   - Tag: `flaresolverr`
3. Test -> Save

### Add Indexers
Go to Indexers -> Add Indexer and add the following:

| Indexer | Best For | FlareSolverr Tag Needed |
|---|---|---|
| YTS | Movies (small size) | No |
| EZTV | TV Shows | No |
| 1337x | Movies & TV | Yes |
| The Pirate Bay | General | Yes |
| Nyaa | Anime | No |

For each: search by name -> select Base URL -> add flaresolverr tag if needed -> Test -> Save

### Link to Radarr & Sonarr
1. Settings -> Apps -> + -> Radarr:
   - Prowlarr Server: `http://prowlarr:9696`
   - Radarr Server: `http://radarr:7878`
   - API Key: from Radarr -> Settings -> General -> Security
   - Test -> Save
2. Settings -> Apps -> + -> Sonarr:
   - Prowlarr Server: `http://prowlarr:9696`
   - Sonarr Server: `http://sonarr:8989`
   - API Key: from Sonarr -> Settings -> General -> Security
   - Test -> Save
3. Click Sync App Indexers

---

## Step 6: Configure Radarr — http://YOUR_IP:7878

1. Settings -> Media Management:
   - Enable Rename Movies
   - Add Root Folder: `/media/Movies`
2. Settings -> Download Clients -> + -> qBittorrent:
   - Host: `qbittorrent`
   - Port: `8080`
   - Username: `admin` / Password: your password
   - Test -> Save
3. Settings -> Indexers — verify indexers are listed

---

## Step 7: Configure Sonarr — http://YOUR_IP:8989

1. Settings -> Media Management:
   - Enable Rename Episodes
   - Add Root Folder: `/media/tv`
2. Settings -> Download Clients -> + -> qBittorrent:
   - Host: `qbittorrent`
   - Port: `8080`
   - Username: `admin` / Password: your password
   - Test -> Save

---

## Step 8: Configure Bazarr — http://YOUR_IP:6767

### Add Subtitle Providers
1. Go to Settings -> Providers -> +
2. Recommended free providers:

| Provider | Good For |
|---|---|
| OpenSubtitles.com | General — requires free account |
| OpenSubtitles.org | General — large database |
| Subscene | Asian content |
| Addic7ed | TV shows |

3. Create a free account on each provider site first
4. Enter your credentials for each provider
5. Save

### Set Your Languages
1. Settings -> Languages -> + Add Profile
2. Name it `My Languages`
3. Add `English` as first choice
4. Add `Malay` or any other language as fallback
5. Save

### Connect to Radarr
1. Settings -> Radarr -> toggle Enable on
2. Fill in:
   - Host: `radarr`
   - Port: `7878`
   - API Key: from Radarr -> Settings -> General -> Security
   - Test -> Save
3. Set Default Profile to your language profile
4. Set Root Folder to `/media/Movies`

### Connect to Sonarr
1. Settings -> Sonarr -> toggle Enable on
2. Fill in:
   - Host: `sonarr`
   - Port: `8989`
   - API Key: from Sonarr -> Settings -> General -> Security
   - Test -> Save
3. Set Default Profile to your language profile
4. Set Root Folder to `/media/tv`

### Download Subtitles for Existing Library
1. Movies tab -> click Download All
2. Series tab -> click Download All

Bazarr will scan your entire library and download missing subtitles.
From now on, every new download gets subtitles automatically.

---

## Step 9: Configure Jellyfin — http://YOUR_IP:8096

1. Follow setup wizard
2. Add Media Library -> Movies -> folder: `/media/Movies`
3. Add Media Library -> TV Shows -> folder: `/media/tv`
4. Dashboard -> API Keys -> + -> name it `seerr` -> copy the key

> Jellyfin config is stored in `~/media-stack/jellyfin/config` on your
> server. Back this folder up to preserve users, libraries, watch history
> and settings.

---

## Step 10: Configure Seerr — http://YOUR_IP:5055

1. Select Jellyfin as media server
2. Fill in:
   - Hostname: `jellyfin` (container name, not IP)
   - Port: `8096`
   - Use SSL: Off
   - URL Base: leave empty
3. Sign in with Jellyfin admin credentials
4. Select Movies and tv libraries -> Continue
5. Add Radarr:
   - Hostname: `radarr` / Port: `7878`
   - API Key: from Radarr -> Settings -> General -> Security
   - Quality Profile: `HD-1080p`
   - Root Folder: `/media/Movies`
   - Enable -> Test -> Save
6. Add Sonarr:
   - Hostname: `sonarr` / Port: `8989`
   - API Key: from Sonarr -> Settings -> General -> Security
   - Quality Profile: `HD-1080p`
   - Root Folder: `/media/tv`
   - Enable -> Test -> Save
7. Finish Setup

### Optional Seerr Features to Enable
- Settings -> Metadata Providers -> enable TVDB for better TV/anime matching
- Settings -> Network -> enable DNS Cache for large libraries

---

## Step 11: Final Test

1. Open Seerr -> search for any movie -> click Request
2. Check Radarr -> Activity tab (searching)
3. Check qBittorrent (downloading)
4. Check Bazarr -> check subtitle is downloaded after movie completes
5. Check Jellyfin — movie appears with subtitles automatically ✅

---

## How Auto-Move Works

1. qBittorrent downloads file to `/downloads`
2. qBittorrent notifies Radarr the download is complete
3. Radarr accesses `/downloads` (mounted into Radarr container)
4. Radarr renames and moves file to `/media/Movies`
5. Bazarr detects new movie and downloads subtitles automatically
6. Jellyfin detects new file and adds it to library with subtitles

All containers share the same physical folder `/mnt/ssd/jellyfin/media`
on your server — just mounted at different paths inside each container.

---

## Manually Import Already-Downloaded Movies

If movies are stuck in `/downloads`:

1. Radarr -> Movies -> Manual Import
2. Set path to `/downloads`
3. Match movies and click Import

Or retry from Radarr -> Activity -> Queue -> click retry icon.

---

## Folder Structure on Your Server
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

## Internal Container URLs Reference

Always use container names when services talk to each other:

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

Use your server IP only when accessing from your browser.

---

## Useful Commands
```bash
docker compose up -d                         # Start all
docker compose down                          # Stop all
docker restart radarr                        # Restart one service
docker logs radarr --tail 50                 # View logs
docker logs radarr -f                        # Live logs
docker compose up -d --force-recreate        # Apply compose changes
docker compose down --remove-orphans         # Remove old/renamed containers
docker ps                                    # Check running containers
docker network inspect media-stack_medianet  # Check network
docker logs qbittorrent | grep password      # Get qBittorrent temp password
```

---

## Troubleshooting

| Problem | Fix |
|---|---|
| Indexer test times out | DNS blocking — dns entries in compose fix this |
| Indexer blocked by Cloudflare | Add flaresolverr tag to that indexer |
| Containers can't reach each other | All must be on medianet network |
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

## Tips and Next Steps

- Invite users — Add family/friends in Seerr to request content
- Watchlists — Connect Radarr to IMDb or Trakt for fully automatic downloads
- 4K — Add a second Radarr instance for 4K with separate quality profile
- VPN — Add Gluetun to route qBittorrent through a VPN for privacy
- TVDB metadata — Enable in Seerr settings for better TV/anime matching
- DNS Cache — Enable in Seerr network settings for large Jellyfin libraries