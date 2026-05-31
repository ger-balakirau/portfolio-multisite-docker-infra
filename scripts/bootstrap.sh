#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  cp .env.example .env
  echo "Создан .env из .env.example. Перед production-like запуском укажите реальные теги images."
fi

./scripts/check-layout.sh
./scripts/render-host-nginx.sh
docker compose --env-file .env up -d site-a-mysql site-a-site site-b-site site-c-site
