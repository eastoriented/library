THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
RESOURCES_DIR := $(THIS_DIR)/resources
MKDIR=mkdir -p
RM=rm -rf
DOCKER_COMPOSE=$(shell which docker-compose || echo 'bin/docker-compose')
DOCKER_COMPOSE_VERSION=1.23.2

define locate
$(or $(shell which $1),$(error \`$1\` is not in \`$(PATH)\`, please install it!))
endef

define binary
$(call write,$1,'#!/usr/bin/env sh')
$(call write,$1,'set -e')
$(call write,$1,'exec $(DOCKER_COMPOSE) run --rm $2 $3 "$$@"')
chmod u+x $1
endef

define write
echo $2 >> $1
endef

.SILENT:

.SUFFIXES:

.DELETE_ON_ERROR:

.PRECIOUS: %/.

%/.:
	$(MKDIR) $@

install: $(call locate,docker) bin/php bin/composer

.env:
	$(call write,$@,"HOME=$(HOME)")
	$(call write,$@,"USER_ID=$$(id -u):$$(id -g)")

bin/php: | docker-compose.yml bin/. $(DOCKER_COMPOSE)
	$(call binary,$@,php-cli,php)

bin/atoum: | docker-compose.yml bin/. .atoum.php vendor $(DOCKER_COMPOSE)
	$(call binary,$@,php-cli,/src/vendor/$@)

bin/composer: | docker-compose.yml bin/. .env $(DOCKER_COMPOSE)
	$(call binary,$@,composer,composer)

vendor: composer.json | bin/composer
	bin/composer install --no-suggest

bin/docker-compose: | $(call locate,curl) bin/. .env docker-compose.yml
	curl -L --fail https://github.com/docker/compose/releases/download/$(DOCKER_COMPOSE_VERSION)/run.sh -o $@
	chmod u+x $@

composer.lock: composer.json | bin/composer
	bin/composer update

.PHONY: unit-tests
unit-tests: | bin/php tests/units/runner.php
	bin/php tests/units/runner.php
