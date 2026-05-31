# Неизменяемый Runtime

Этот документ описывает production-like runtime, который демонстрирует portfolio-версия.

## Разделение Ответственности

Compose запускает только приватные runtime-сервисы:

- один MySQL service для stateful legacy-сайта;
- три PHP-FPM сервиса, собранные из неизменяемых images;
- без публичного nginx-контейнера в production-like режиме.

Публичный HTTP/TLS слой остается на host nginx. Он общается с PHP-FPM через локальные loopback-порты:

```text
site-a.example.com -> 127.0.0.1:9001
site-b.example.com -> 127.0.0.1:9002
site-c.example.com -> 127.0.0.1:9003
```

## Схема Релизов

Host nginx templates ожидают статические файлы здесь:

```text
${BASE_DIR}/current/site-a/site/www
${BASE_DIR}/current/site-b/site/www
${BASE_DIR}/current/site-c/site/www
```

PHP исполняется по путям внутри контейнеров:

```text
/var/www/html/site-a
/var/www/html/site-b
/var/www/html/site-c
```

Такое разделение позволяет nginx отдавать неизменяемые файлы релиза с хоста, а PHP запускать из images с тем же содержимым релиза.

## Постоянное Хранилище

В примере оставлен один mutable storage mount:

```env
SITE_A_STORAGE_PATH=/opt/portfolio-multisite/site-a/storage
```

Он монтируется в `site-a-site` как `/var/www/html/site-a/storage`. Паттерн подходит для uploads, generated files, exports или пользовательских assets, которые должны переживать замену image и rollback релиза.

## Host Nginx

Шаблоны лежат в `configs/nginx/host/templates` и рендерятся командой:

```bash
make render-host-nginx
```

По умолчанию результат попадает в `build/nginx`. Для установки в системный nginx нужно явно указать `TARGET_DIR=/etc/nginx/conf.d`.

В шаблонах показаны:

- HTTPS vhosts с HTTP/2 и HTTP/3-ready listeners;
- FastCGI upstreams на `127.0.0.1:9001-9003`;
- backup upstreams на `127.0.0.1:9011-9013`;
- FastCGI microcache с bypass для admin/API/health routes;
- webroot path для ACME challenge.

Backup upstreams в публичных шаблонах оставлены как placeholder-паттерн для миграции с legacy FPM. Compose в этом репозитории не поднимает сервисы на `9011-9013`; в реальном окружении эти порты нужно заменить на свои или убрать backup upstreams перед установкой в host nginx.

`scripts/issue-cert.sh` тоже демонстрационный: он использует домены `site-*.example.com`, требует host `certbot`/`nginx`/`sudo` и при `TARGET_DIR=/etc/nginx/conf.d` меняет конфигурацию хоста. Для локальных проверок безопаснее использовать `make render-host-nginx`, который пишет результат в `build/nginx`.

## Обезличенный Объем

Репозиторий намеренно останавливается до реальной deploy-автоматизации. В production-системе поверх этого слоя обычно нужны:

- упаковка release artifact;
- сборка и публикация неизменяемых images;
- доставка release bundle на сервер;
- predeploy dump базы данных;
- переключение symlink `previous`/`current`;
- миграции и прогрев cache;
- health checks и rollback.

В portfolio-версии эти части описаны как архитектурный паттерн, но не привязаны к реальной инфраструктуре.
