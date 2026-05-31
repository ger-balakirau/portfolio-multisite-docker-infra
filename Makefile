SHELL := /usr/bin/env bash
.DEFAULT_GOAL := help

COMPOSE ?= docker compose
LOCAL_COMPOSE ?= $(COMPOSE) -f docker-compose.yml -f docker-compose.local.yml
SERVICE ?= site-a-site
INFRA_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
ROOT_DIR := $(abspath $(INFRA_DIR)/..)
PHP_IMAGE_NAME ?= portfolio-multisite-php:8.5
PHP_VERSION ?= 8.5

SITE_A_PROJECT_PATH ?= $(ROOT_DIR)/site-a
SITE_B_PROJECT_PATH ?= $(ROOT_DIR)/site-b
SITE_C_PROJECT_PATH ?= $(ROOT_DIR)/site-c

.PHONY: help pull up up-build down restart ps logs sh local-up local-build local-down local-logs render-host-nginx issue-cert renew-cert self-signed-cert check-layout validate

help:
	@echo "Основное:"
	@echo "  make pull        # скачать неизменяемые PHP-FPM images"
	@echo "  make up          # docker compose up -d mysql + PHP-FPM"
	@echo "  make up-build    # псевдоним make up; production images неизменяемые"
	@echo "  make down        # docker compose down"
	@echo "  make restart     # docker compose restart"
	@echo "  make ps          # docker compose ps"
	@echo "  make logs        # docker compose logs -f SERVICE=site-a-site"
	@echo "  make sh SERVICE=site-a-site"
	@echo ""
	@echo "Локальная разработка:"
	@echo "  make local-up     # http://localhost:8081, :8082, :8083"
	@echo "  make local-build  # пересобрать base/local images и запустить локальный стек"
	@echo "  make local-down"
	@echo "  make local-logs"
	@echo ""
	@echo "Примеры host nginx:"
	@echo "  make render-host-nginx  # отрендерить обезличенные nginx-шаблоны в build/nginx"
	@echo "  make self-signed-cert"
	@echo "  make issue-cert"
	@echo "  make renew-cert"
	@echo ""
	@echo "Проверки:"
	@echo "  make check-layout"
	@echo "  make validate"

pull:
	$(COMPOSE) pull site-a-site site-b-site site-c-site

up:
	$(COMPOSE) up -d site-a-mysql site-a-site site-b-site site-c-site

up-build:
	$(MAKE) up

down:
	$(COMPOSE) down

restart:
	$(COMPOSE) restart

ps:
	$(COMPOSE) ps

logs:
	$(COMPOSE) logs -f $(SERVICE)

sh:
	$(COMPOSE) exec $(SERVICE) sh

local-up:
	SITE_A_PROJECT_PATH="$(SITE_A_PROJECT_PATH)" \
	SITE_B_PROJECT_PATH="$(SITE_B_PROJECT_PATH)" \
	SITE_C_PROJECT_PATH="$(SITE_C_PROJECT_PATH)" \
	$(LOCAL_COMPOSE) --profile local up -d site-a-mysql site-a-site site-b-site site-c-site nginx-local

local-build:
	docker build \
		--build-arg PHP_VERSION="$(PHP_VERSION)" \
		--build-arg PUID="$${PUID:-1000}" \
		--build-arg PGID="$${PGID:-1000}" \
		-f docker/php/Dockerfile \
		-t "$(PHP_IMAGE_NAME)" \
		.
	SITE_A_PROJECT_PATH="$(SITE_A_PROJECT_PATH)" \
	SITE_B_PROJECT_PATH="$(SITE_B_PROJECT_PATH)" \
	SITE_C_PROJECT_PATH="$(SITE_C_PROJECT_PATH)" \
	$(LOCAL_COMPOSE) --profile local up -d --build site-a-mysql site-a-site site-b-site site-c-site nginx-local

local-down:
	$(LOCAL_COMPOSE) --profile local down

local-logs:
	$(LOCAL_COMPOSE) logs -f nginx-local

render-host-nginx:
	./scripts/render-host-nginx.sh

issue-cert:
	./scripts/issue-cert.sh

self-signed-cert:
	./scripts/self-signed-cert.sh

renew-cert:
	./scripts/renew-cert.sh

check-layout:
	./scripts/check-layout.sh

validate:
	bash -n scripts/*.sh
	$(COMPOSE) --env-file .env.example config >/dev/null
	$(LOCAL_COMPOSE) --env-file .env.example --profile local config >/dev/null
