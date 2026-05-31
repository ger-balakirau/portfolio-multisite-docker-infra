#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

run_as_root() {
  if [[ "${EUID}" -eq 0 ]]; then
    "$@"
  else
    sudo "$@"
  fi
}

escape_sed() {
  printf '%s' "$1" | sed -e 's/[\/&]/\\&/g'
}

render_template() {
  local src="$1"
  local dst="$2"

  sed \
    -e "s/__RELEASE_ROOT__/$(escape_sed "${RELEASE_ROOT}")/g" \
    -e "s/__CERTBOT_ROOT__/$(escape_sed "${CERTBOT_ROOT}")/g" \
    -e "s/__LETSENCRYPT_ROOT__/$(escape_sed "${LETSENCRYPT_ROOT}")/g" \
    -e "s/__SITE_A_FPM_UPSTREAM__/$(escape_sed "${SITE_A_FPM_UPSTREAM}")/g" \
    -e "s/__SITE_B_FPM_UPSTREAM__/$(escape_sed "${SITE_B_FPM_UPSTREAM}")/g" \
    -e "s/__SITE_C_FPM_UPSTREAM__/$(escape_sed "${SITE_C_FPM_UPSTREAM}")/g" \
    -e "s/__SITE_A_LEGACY_FPM_UPSTREAM__/$(escape_sed "${SITE_A_LEGACY_FPM_UPSTREAM}")/g" \
    -e "s/__SITE_B_LEGACY_FPM_UPSTREAM__/$(escape_sed "${SITE_B_LEGACY_FPM_UPSTREAM}")/g" \
    -e "s/__SITE_C_LEGACY_FPM_UPSTREAM__/$(escape_sed "${SITE_C_LEGACY_FPM_UPSTREAM}")/g" \
    -e "s/__GZIP_HTTP_CONFIG__/$(escape_sed "${GZIP_HTTP_CONFIG}")/g" \
    -e "s/__BROTLI_HTTP_CONFIG__/$(escape_sed "${BROTLI_HTTP_CONFIG}")/g" \
    "$src" > "$dst"
}

nginx_runtime_user() {
  local user
  user="$(awk '/^[[:space:]]*user[[:space:]]+/ {gsub(/;/, "", $2); print $2; exit}' /etc/nginx/nginx.conf 2>/dev/null || true)"
  if [[ -n "$user" && "$user" != "root" ]] && id "$user" >/dev/null 2>&1; then
    printf '%s\n' "$user"
  elif id nginx >/dev/null 2>&1; then
    printf '%s\n' nginx
  elif id www-data >/dev/null 2>&1; then
    printf '%s\n' www-data
  else
    printf '%s\n' root
  fi
}

ensure_cache_permissions() {
  local user="$1"

  if ! run_as_root install -d -m 0750 -o "$user" -g "$user" "$CACHE_DIR" 2>/dev/null; then
    run_as_root install -d -m 0750 "$CACHE_DIR"
    return
  fi
  run_as_root chown -R "$user:$user" "$CACHE_DIR"
}

if [[ -f .env ]]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi

BASE_DIR="${BASE_DIR:-/opt/portfolio-multisite}"
RELEASE_ROOT="${RELEASE_ROOT:-${BASE_DIR}/current}"
CERTBOT_ROOT="${CERTBOT_ROOT:-/var/www/certbot}"
LETSENCRYPT_ROOT="${LETSENCRYPT_ROOT:-/etc/letsencrypt}"
TARGET_DIR="${TARGET_DIR:-build/nginx}"
TARGET_PREFIX="${TARGET_PREFIX:-portfolio-}"
TEMPLATE_DIR="${TEMPLATE_DIR:-configs/nginx/host/templates}"
CACHE_DIR="${CACHE_DIR:-/var/cache/nginx/portfolio-multisite}"
GZIP_HTTP_CONFIG="${GZIP_HTTP_CONFIG:-}"
BROTLI_HTTP_CONFIG="${BROTLI_HTTP_CONFIG:-}"

SITE_A_FPM_UPSTREAM="${SITE_A_FPM_UPSTREAM:-127.0.0.1:9001}"
SITE_B_FPM_UPSTREAM="${SITE_B_FPM_UPSTREAM:-127.0.0.1:9002}"
SITE_C_FPM_UPSTREAM="${SITE_C_FPM_UPSTREAM:-127.0.0.1:9003}"

SITE_A_LEGACY_FPM_UPSTREAM="${SITE_A_LEGACY_FPM_UPSTREAM:-127.0.0.1:9011}"
SITE_B_LEGACY_FPM_UPSTREAM="${SITE_B_LEGACY_FPM_UPSTREAM:-127.0.0.1:9012}"
SITE_C_LEGACY_FPM_UPSTREAM="${SITE_C_LEGACY_FPM_UPSTREAM:-127.0.0.1:9013}"

tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

if [[ -z "$GZIP_HTTP_CONFIG" ]]; then
  GZIP_HTTP_CONFIG='gzip on; gzip_comp_level 5; gzip_min_length 1024; gzip_vary on; gzip_proxied any; gzip_types text/plain text/css text/xml application/xml application/rss+xml application/json application/javascript image/svg+xml;'
fi

if [[ -z "$BROTLI_HTTP_CONFIG" ]] && command -v nginx >/dev/null 2>&1 && nginx -V 2>&1 | grep -qi brotli; then
  BROTLI_HTTP_CONFIG='brotli on; brotli_comp_level 5; brotli_types text/plain text/css text/xml application/xml application/rss+xml application/json application/javascript image/svg+xml;'
fi

for template in "${TEMPLATE_DIR}"/*.conf.template; do
  name="$(basename "${template%.template}")"
  render_template "$template" "${tmp_dir}/${TARGET_PREFIX}${name}"
done

if [[ "$TARGET_DIR" == /etc/nginx/* ]]; then
  run_as_root install -d -m 0755 "$TARGET_DIR" "$CERTBOT_ROOT"
  ensure_cache_permissions "$(nginx_runtime_user)"
  for rendered in "${tmp_dir}"/*.conf; do
    run_as_root install -m 0644 "$rendered" "${TARGET_DIR}/$(basename "$rendered")"
  done
  run_as_root nginx -t
  if [[ "${RELOAD_NGINX:-0}" == "1" ]]; then
    if command -v systemctl >/dev/null 2>&1; then
      run_as_root systemctl reload nginx || run_as_root systemctl start nginx
    else
      run_as_root nginx -s reload
    fi
  fi
  echo "ok: host nginx config отрендерен в ${TARGET_DIR}"
else
  rm -rf "$TARGET_DIR"
  install -d -m 0755 "$TARGET_DIR"
  cp "${tmp_dir}"/*.conf "$TARGET_DIR"/
  echo "ok: примеры host nginx отрендерены в ${TARGET_DIR}"
fi
