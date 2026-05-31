#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

if [[ ! -f .env ]]; then
  echo "Нет .env. Скопируйте .env.example в .env и сначала заполните CERTBOT_EMAIL."
  exit 1
fi

set -a
# shellcheck source=/dev/null
source .env
set +a

if [[ -z "${CERTBOT_EMAIL:-}" || "${CERTBOT_EMAIL}" == "admin@example.com" ]]; then
  echo "Перед выпуском сертификатов задайте CERTBOT_EMAIL в .env."
  exit 1
fi

if ! command -v certbot >/dev/null 2>&1; then
  echo "certbot не установлен на хосте." >&2
  exit 1
fi

run_as_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

CERTBOT_ROOT="${CERTBOT_ROOT:-/var/www/certbot}"
run_as_root install -d -m 0755 "$CERTBOT_ROOT"

issue_webroot_cert() {
  local cert_name="$1"
  shift

  run_as_root certbot certonly \
    --webroot \
    --webroot-path "$CERTBOT_ROOT" \
    --email "${CERTBOT_EMAIL}" \
    --agree-tos \
    --no-eff-email \
    --keep-until-expiring \
    --cert-name "$cert_name" \
    "$@"
}

issue_webroot_cert site-a.example.com \
  -d site-a.example.com \
  -d www.site-a.example.com

issue_webroot_cert site-b.example.com \
  -d site-b.example.com \
  -d www.site-b.example.com

issue_webroot_cert site-c.example.com \
  -d site-c.example.com \
  -d www.site-c.example.com

TARGET_DIR="${TARGET_DIR:-/etc/nginx/conf.d}" RELOAD_NGINX=1 ./scripts/render-host-nginx.sh
