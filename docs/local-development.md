# Локальная Разработка

Локальный режим сохраняет production-like имена сервисов, но заменяет неизменяемые images на bind-mounted деревья исходников.

## Ожидаемая Структура

```text
portfolio-multisite/
  infra/
  site-a/
    .env.example
    site/www/
  site-b/
    .env.example
    site/www/
  site-c/
    .env.example
    site/www/
```

`make local-up` и `make local-build` по умолчанию ищут приложения рядом с каталогом `infra`. Если локальное дерево отличается, передайте пути Make-переменными:

```bash
SITE_A_PROJECT_PATH=/path/to/site-a \
SITE_B_PROJECT_PATH=/path/to/site-b \
SITE_C_PROJECT_PATH=/path/to/site-c \
make local-build
```

`make check-layout` запускает `scripts/check-layout.sh`; этот скрипт также умеет читать `SITE_*_PROJECT_PATH` из `.env`, если файл существует.

## Команды

```bash
make check-layout
make local-build
make local-logs
```

Если локальные images уже собраны, стек можно поднять без пересборки:

```bash
make local-up
```

Локальный nginx слушает:

```text
http://localhost:8081
http://localhost:8082
http://localhost:8083
```

Остановить локальный стек:

```bash
make local-down
```

## Compose-Файлы

`docker-compose.yml` описывает production-like runtime. `docker-compose.local.yml` добавляет:

- локальные сборки app images через `docker/php/Dockerfile.local`;
- bind mounts из локальных репозиториев приложений;
- `nginx-local` для быстрой проверки в браузере.

## Проверки Без Приложений

CI и читатели portfolio могут выполнить:

```bash
make validate
```

Эта команда проверяет shell-синтаксис скриптов и валидность production/local compose configs без доступа к реальным репозиториям приложений.
