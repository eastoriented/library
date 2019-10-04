#
# This file is part of eastoriented/library.
#
# For the sake of mankind, DO NOT MODIFY IT!
#
# Have a good day!
#
THIS_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
RESOURCES_DIR := $(THIS_DIR)/resources
MKDIR=mkdir -p
RM=rm -rf
DOCKER_COMPOSE=$(shell which docker-compose || echo 'bin/docker-compose')
DOCKER_COMPOSE_VERSION=1.23.2
CURRENT_VERSION?=$(shell git describe --tags --abbrev=0 2>/dev/null || echo 0.0.0)

define locate
$(or $(shell which $1),$(error \`$1\` is not in \`$(PATH)\`, please install it!))
endef

define binary
$(call write,$1,'#!/usr/bin/env sh')
$(call write,$1,'set -e')
$(call write,$1,'exec $(DOCKER_COMPOSE) run --rm $2 $3 "$$@"')
chmod u+x $1
endef

define semver
git tag $$(bin/docker-compose run --rm semver semver -c -i $1 $$(git describe --tags --abbrev=0 2>/dev/null || echo 0.0.0))
endef

define write
echo $2 >> $1
endef

.SILENT:

.SUFFIXES:

.DELETE_ON_ERROR:

.PRECIOUS: %/.

## The help, because if no help, no RTFM

.PHONY: help
help: ## Display this help.
	@printf "$$(cat $(MAKEFILE_LIST) | egrep -h '^[^:]+:[^#]+## .+$$' | sed -e 's/:[^#]*##/:/' -e 's/\(.*\):/\\033[92m\1\\033[0m:/' | sort -d | column -c2 -t -s :)\n"

%/.:
	$(MKDIR) $@

install: $(call locate,docker) bin/php bin/composer ## Install development environment

.env:
	$(call write,$@,"HOME=$(HOME)")
	$(call write,$@,"USER_ID=$$(id -u):$$(id -g)")

bin/php: | docker-compose.yml bin/. $(DOCKER_COMPOSE) ## Create wrapper for `php` using `docker`
	$(call binary,$@,php-cli,php)

bin/atoum: | docker-compose.yml bin/. .atoum.php vendor $(DOCKER_COMPOSE) ## Create wrapper for `atoum` using `docker`
	$(call binary,$@,php-cli,/src/vendor/$@)

bin/composer: | docker-compose.yml bin/. .env $(DOCKER_COMPOSE) ## Create wrapper for `composer` using `docker`
	$(call binary,$@,composer,composer)

bin/docker-compose: | $(call locate,curl) bin/. .env docker-compose.yml ## Create wrapper for `docker-compose` using `docker`
	curl -L --fail https://github.com/docker/compose/releases/download/$(DOCKER_COMPOSE_VERSION)/run.sh -o $@
	chmod u+x $@

vendor: composer.json | bin/composer ## Create `vendor` directory
	bin/composer install --no-suggest

vendor/update: | bin/composer ## Update `vendor` directory
	bin/composer update --no-suggest
	./vendor/bin/eastoriented-library install

composer.lock: composer.json | bin/composer ## Update `composer.lock` according to `composer.json\`
	bin/composer update

.PHONY: autoload
autoload: composer.json | bin/composer ## Generate autoload files
	bin/composer dump-autoload

.PHONY: unit-tests
unit-tests: | bin/php tests/units/runner.php vendor ## Run unit tests
	bin/php tests/units/runner.php

.PHONY: version/new/major
version/new/major: | bin/docker-compose ## Create tag for new major version
	$(call semver,major)

.PHONY: version/new/minor
version/new/minor: | bin/docker-compose ## Create tag for new minor version
	$(call semver,minor)

.PHONY: version/new/patch
version/new/patch: | bin/docker-compose ## Create tag for new patch version
	$(call semver,patch)
