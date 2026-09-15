#!/usr/bin/env bash
set -euo pipefail

echo "Pulling latest images..."
docker compose pull

echo "Starting services (detached)..."
docker compose up -d

echo "Done."