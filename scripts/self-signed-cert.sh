#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

days="${SELF_SIGNED_CERT_DAYS:-30}"

if ! [[ "$days" =~ ^[0-9]+$ ]] || [[ "$days" -lt 1 ]]; then
  echo "SELF_SIGNED_CERT_DAYS должен быть положительным целым числом."
  exit 1
fi

issue_cert() {
  local cert_name="$1"
  local common_name="$2"
  local san="$3"
  local cert_dir="certbot/conf/live/${cert_name}"

  mkdir -p "$cert_dir"

  openssl req \
    -x509 \
    -nodes \
    -newkey rsa:2048 \
    -days "$days" \
    -subj "/CN=${common_name}" \
    -addext "subjectAltName=${san}" \
    -keyout "${cert_dir}/privkey.pem" \
    -out "${cert_dir}/fullchain.pem"

  chmod 600 "${cert_dir}/privkey.pem"
  chmod 644 "${cert_dir}/fullchain.pem"
  echo "ok: ${cert_dir}/fullchain.pem"
}

issue_cert "site-a.example.com" \
  "site-a.example.com" \
  "DNS:site-a.example.com,DNS:www.site-a.example.com"

issue_cert "site-b.example.com" \
  "site-b.example.com" \
  "DNS:site-b.example.com,DNS:www.site-b.example.com"

issue_cert "site-c.example.com" \
  "site-c.example.com" \
  "DNS:site-c.example.com,DNS:www.site-c.example.com"

echo "Самоподписанные сертификаты готовы в certbot/conf для локальных экспериментов."
