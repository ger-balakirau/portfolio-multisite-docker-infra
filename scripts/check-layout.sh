#!/usr/bin/env bash
set -Eeuo pipefail

cd "$(dirname "$0")/.."

if [[ -f .env ]]; then
  set -a
  # shellcheck source=/dev/null
  source .env
  set +a
fi

SITE_A_PROJECT_PATH="${SITE_A_PROJECT_PATH:-/opt/portfolio-multisite/site-a}"
SITE_B_PROJECT_PATH="${SITE_B_PROJECT_PATH:-/opt/portfolio-multisite/site-b}"
SITE_C_PROJECT_PATH="${SITE_C_PROJECT_PATH:-/opt/portfolio-multisite/site-c}"
INFRA_PROJECT_PATH="$(pwd)"

fail=0

check_repo() {
  local name="$1"
  local path="$2"

  if [[ ! -d "$path/.git" ]]; then
    echo "нет git-репозитория: ${name} по пути ${path}"
    fail=1
    return
  fi

  echo "ok: ${name} repo по пути ${path}"
}

check_path() {
  local label="$1"
  local path="$2"

  if [[ ! -e "$path" ]]; then
    echo "нет пути: ${label} по пути ${path}"
    fail=1
    return
  fi

  echo "ok: ${label} по пути ${path}"
}

check_repo "infra" "$INFRA_PROJECT_PATH"
check_repo "site-a" "$SITE_A_PROJECT_PATH"
check_repo "site-b" "$SITE_B_PROJECT_PATH"
check_repo "site-c" "$SITE_C_PROJECT_PATH"

check_path "site-a files" "$SITE_A_PROJECT_PATH/site/www"
check_path "site-a env example" "$SITE_A_PROJECT_PATH/.env.example"
check_path "site-b files" "$SITE_B_PROJECT_PATH/site/www"
check_path "site-b env example" "$SITE_B_PROJECT_PATH/.env.example"
check_path "site-c files" "$SITE_C_PROJECT_PATH/site/www"
check_path "site-c env example" "$SITE_C_PROJECT_PATH/.env.example"

exit "$fail"
