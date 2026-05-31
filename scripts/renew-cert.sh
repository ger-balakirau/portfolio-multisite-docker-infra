#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

if ! command -v certbot >/dev/null 2>&1; then
  echo "certbot не установлен на хосте." >&2
  exit 1
fi

if [[ "${EUID}" -eq 0 ]]; then
  certbot renew --quiet
  nginx -t
  nginx -s reload || true
else
  sudo certbot renew --quiet
  sudo nginx -t
  sudo nginx -s reload || true
fi
