# Portfolio Multisite Docker Infra

Обезличенный пример актуальной инфраструктуры для трех PHP-проектов на одной VM. Репозиторий повторяет приближенный к production подход из боевого проекта, но без настоящих доменов, меток собственных runners, SSH-целей, workflow для деплоя и приватных deploy hooks.

## Архитектура

Production-like Compose больше не поднимает публичный nginx и certbot в контейнерах. Compose отвечает только за приватный runtime:

| Сервис | Порт на хосте | Назначение |
| --- | --- | --- |
| `site-a-mysql` | `127.0.0.1:33061` | MySQL 8.4 для основного stateful legacy-сайта |
| `site-a-site` | `127.0.0.1:9001` | неизменяемый PHP-FPM image |
| `site-b-site` | `127.0.0.1:9002` | неизменяемый PHP-FPM image |
| `site-c-site` | `127.0.0.1:9003` | неизменяемый PHP-FPM image |

Host nginx обслуживает TLS, HTTP/2, HTTP/3, статические файлы из `current/<site>/site/www` и передает PHP в локальные FPM-порты. Код приложений находится внутри неизменяемых images и не bind-mountится в production-like compose.

```text
/opt/portfolio-multisite/
  infra/              # этот репозиторий
  site-a/             # .env + persistent storage
  site-b/             # .env
  site-c/             # .env
  releases/<id>/      # release bundle со статикой
  current -> releases/<id>
  previous -> releases/<previous-id>
```

## Что Включено

- Docker Compose для MySQL + трех неизменяемых PHP-FPM сервисов.
- Локальный override Compose с bind mounts и nginx-контейнером для разработки.
- Базовый PHP-FPM Dockerfile и app-image Dockerfile для неизменяемых сборок.
- Шаблоны host nginx с FastCGI microcache, HTTP/3-ready listeners и резервными upstreams.
- Обезличенные helper-скрипты для certbot и self-signed сертификатов.
- Layout checks, compose validation и безопасный GitHub Actions workflow на `ubuntu-latest`.

## Чего Здесь Нет

- Реальных GitHub Actions deploy workflows.
- Self-hosted runner labels.
- SSH deploy/rollback scripts.
- Production IP, доменов, registry namespaces или приватных repo names.
- Secrets, dumps, application code и runtime uploads.

## Быстрый Старт Для Проверки Репозитория

Эти команды не требуют доступа к приватным приложениям и реальным container images:

```bash
cp .env.example .env
make validate
make render-host-nginx
```

`make render-host-nginx` по умолчанию пишет обезличенные nginx-конфиги в `build/nginx`, а не в `/etc/nginx`.

## Локальная Разработка

Локальный режим ожидает соседние репозитории приложений:

```text
portfolio-multisite/
  infra/
  site-a/site/www/
  site-b/site/www/
  site-c/site/www/
```

Запуск:

```bash
make check-layout
make local-build
make local-logs
```

Локальные URL:

- `http://localhost:8081`
- `http://localhost:8082`
- `http://localhost:8083`

Если локальные репозитории лежат не рядом с `infra`, передайте пути Make-переменными:

```bash
SITE_A_PROJECT_PATH=/path/to/site-a \
SITE_B_PROJECT_PATH=/path/to/site-b \
SITE_C_PROJECT_PATH=/path/to/site-c \
make local-build
```

Для запуска без пересборки используйте `make local-up`.

## Runtime, Близкий К Production

`make pull` и `make up` имеют смысл, когда в `.env` указаны реальные теги images:

```env
SITE_A_PHP_IMAGE=ghcr.io/example/portfolio-site-a-php:latest
SITE_B_PHP_IMAGE=ghcr.io/example/portfolio-site-b-php:latest
SITE_C_PHP_IMAGE=ghcr.io/example/portfolio-site-c-php:latest
```

Команды:

```bash
make pull
make up
make ps
```

В публичном portfolio-репозитории эти теги оставлены как безопасные placeholders. `scripts/bootstrap.sh` является lab-only helper: он выполняет `check-layout`, рендерит nginx-примеры и запускает production-like Compose, поэтому с placeholder images не является универсальным быстрым стартом.

## Паттерн Неизменяемых Images

`docker/php/Dockerfile` собирает общий базовый PHP-FPM image. `docker/php/Dockerfile.app` копирует одно приложение внутрь неизменяемого app image:

```bash
docker build -f docker/php/Dockerfile \
  --build-arg PHP_VERSION=8.5 \
  -t portfolio-multisite-php:8.5 .

docker build -f docker/php/Dockerfile.app \
  --build-arg BASE_PHP_IMAGE=portfolio-multisite-php:8.5 \
  --build-arg APP_DIR=site-a \
  --build-arg APP_SOURCE=site-a/site/www \
  -t ghcr.io/example/portfolio-site-a-php:latest <release-context>
```

Публичная версия показывает паттерн, но не публикует и не деплоит реальные образы.

## Шаблоны Host Nginx

Отрендерить обезличенные примеры:

```bash
make render-host-nginx
```

Явно установить на lab-хост:

```bash
TARGET_DIR=/etc/nginx/conf.d sudo -E ./scripts/render-host-nginx.sh
```

Локальный путь по умолчанию выбран специально, чтобы просмотр репозитория не менял состояние машины.

`make issue-cert` требует host `certbot`, `nginx`, `sudo`, реальных доменов вместо `site-*.example.com` и меняет системный nginx. Для локальных экспериментов можно создать self-signed сертификаты и отрендерить конфиги с локальным корнем Let's Encrypt:

```bash
make self-signed-cert
LETSENCRYPT_ROOT="$PWD/certbot/conf" make render-host-nginx
```

## Документация

- [docs/immutable-runtime.md](docs/immutable-runtime.md)
- [docs/local-development.md](docs/local-development.md)
