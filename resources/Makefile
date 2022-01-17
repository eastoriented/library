#
# This file is part of eastoriented/library.
#
# For the sake of mankind, DO NOT MODIFY IT!
#
# Have a good day!
#
#
# Disable builtin rules and variables, because they are useless in our context and add lot of noise when `make -d` is used to debug the macfly.
MAKEFLAGS+= --no-builtin-rules
MAKEFLAGS+= --no-builtin-variables

.DEFAULT_GOAL:=help

ifeq "$(firstword $(MAKECMDGOALS))" "verbose"

.PHONY: verbose
verbose: ## <Debug> Display all executed commands during targets building
	$(MAKE) $(filter-out verbose,$(MAKECMDGOALS)) WITH_DEBUG=TRUE

%:
	true

else

include .do_not_touch/config.mk

THIS_DIR:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
THIS_MAKEFILE=$(firstword $(MAKEFILE_LIST))
RESOURCES_DIR:=$(THIS_DIR)/resources
MKDIR:=mkdir -p
CP:=cp -r
RM:=rm -rf
MV:=mv -f
DOCKER_COMPOSE:=$(shell which docker-compose || echo 'bin/docker-compose')
CURRENT_VERSION:=$(shell git describe --tags --abbrev=0 2>/dev/null || echo 0.0.0)
INSTALLED_PHP_VERSION:=$(shell grep -e "^\s\+php-\([^:]\+\)" docker-compose.yml docker-compose.override.yml 2>/dev/null | cut -d: -f2 | cut -d- -f2 | sort | uniq || true)

DOCKER_COMPOSE_YML:=$(shell find .do_not_touch -type f -name "docker-compose.*yml" | sort -r)

define locate
$(or $(shell which $1),$(error \`$1\` is not in \`$(PATH)\`, please install it!))
endef

define bin
$(RM) $1
$(call write,$1,'#!/usr/bin/env sh')
$(call write,$1,'set -e')
$(call write,$1,$4)
$(call write,$1,'exec $(DOCKER_COMPOSE) run --rm $2 $3 "$$@" 2>/dev/null')
chmod u+x $1
endef

define uniq
cat $1 | sort | uniq | tee $1 > /dev/null
endef

define semver
semver=$$($(DOCKER_COMPOSE) run --rm semver semver -c -i $1 $$(git describe --tags --abbrev=0 2>/dev/null || echo 0.0.0)) && \
git tag $$($$semver)
endef

define write
echo $2 >> $1
endef

define switch-php
cat .env | grep -v PHP_VERSION | tee .env > /dev/null
$(call write,.env,"PHP_VERSION=$1");
$(RM) docker-compose.yml && $(MAKE) docker-compose.yml
bin/composer install
endef

ifneq ($(WITH_DEBUG),)
OLD_SHELL:=$(SHELL)
SHELL=$(warning $(if $@, Update target $@)$(if $<, from $<)$(if $?, due to $?))$(OLD_SHELL) -x
else
.SILENT:
endif

.SUFFIXES:

.DELETE_ON_ERROR:

.PRECIOUS: %/.

%/.:
	$(MKDIR) $@

install: $(call locate,docker) vendor bin/php bin/composer ## <Install> Install development environment

.env:
	$(call write,$@,"HOME=$(HOME)")
	$(call write,$@,"USER_ID=$$(id -u):$$(id -g)")
	$(call write,$@,"NETWORK_NAME=$$(pwd | awk -F / '{print $NF}')")
	$(call uniq,$@)

docker-compose.yml: $(THIS_MAKEFILE) .env $(DOCKER_COMPOSE_YML)
	$(RM) $@
	$(CP) $(DOCKER_COMPOSE_YML) .
	echo "# DO NOT MODIFY THIS FILE, please put your specific docker-compose configuration in docker-compose.override.yml" > $@.tmp
	$(DOCKER_COMPOSE) -f $$(echo $(DOCKER_COMPOSE_YML) | sed -e 's#.do_not_touch/##g' -e 's/ / -f /g') --env-file $$(pwd)/.env config >> $@.tmp
	$(RM) docker-compose.*yml
	cat $@.tmp >> $@ && $(RM) $@.tmp

bin/php: $(THIS_MAKEFILE) | docker-compose.yml bin/. $(DOCKER_COMPOSE) ## <Binaries> Create wrapper for `php` using `docker`
	$(call bin,$@,php,php)

bin/atoum: $(THIS_MAKEFILE) | docker-compose.yml bin/. .atoum.php vendor $(DOCKER_COMPOSE) ## <Binaries> Create wrapper for `atoum` using `docker`
	$(call bin,$@,php,/src/vendor/$@)

bin/composer: $(THIS_MAKEFILE) | docker-compose.yml bin/. .env $(DOCKER_COMPOSE) ## <Binaries> Create wrapper for `composer` using `docker`
	$(call bin,$@,composer,composer,$(MKDIR) \$$HOME/.composer)

bin/docker-compose: DOCKER_COMPOSE_VERSION:=$(shell curl --silent "https://api.github.com/repos/docker/compose/releases/latest" | grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/')
bin/docker-compose: | $(call locate,curl) bin/. .env docker-compose.yml  ## <Binaries> Create wrapper for `docker-compose` using `docker`
	curl -L --fail https://github.com/docker/compose/releases/download/$(DOCKER_COMPOSE_VERSION)/run.sh -o $@
	chmod u+x $@

vendor: composer.lock composer.json | bin/composer ## <Install> Create or recreate `vendor` directory
	bin/composer install
	touch $@

.PHONY: vendor/update
vendor/update: | bin/composer ## <Update> Update `vendor` directory
	bin/composer update
	./vendor/bin/eastoriented-library install
	touch $@

.PHONY: autoload
autoload: composer.json composer.lock | bin/composer ## <Update> Generate autoload files
	bin/composer dump-autoload

.PHONY: tests/units
tests/units: | bin/php tests/units/runner.php vendor ## <Quality> Run unit tests
	bin/php tests/units/runner.php

.PHONY: version/new/major
version/new/major: | $(DOCKER_COMPOSE) ## <Versioning> Create tag for new major version
	$(call semver,major)

.PHONY: version/new/minor
version/new/minor: | $(DOCKER_COMPOSE) ## <Versioning> Create tag for new minor version
	$(call semver,minor)

.PHONY: version/new/patch
version/new/patch: | $(DOCKER_COMPOSE) ## <Versioning> Create tag for new patch version
	$(call semver,patch)

.PHONY: release
release: releases/$(VERSION).tgz

releases/$(VERSION).tgz: VERSION:=$(shell git describe --exact-match --tags 2> /dev/null || git rev-parse --short HEAD)
releases/$(VERSION).tgz: ./.git/HEAD | ./bin/composer ./releases. ## Create a tarball in `./releases` directory according to current tag or commit
	$(RM) ./releases/tmp && $(MKDIR) ./releases/tmp
	git archive --format=tar HEAD | tar -x -C ./releases/tmp
	cd ./releases/tmp && tar czpf ../$(VERSION).tgz .
	$(RM) ./tmp

.PHONY: docker/pull
docker/pull: $(DOCKER_COMPOSE)
	$(DOCKER_COMPOSE) pull

.PHONY: php/%
php/%: | bin/composer ## <Environment> Switch PHP version, for example `make php/7.2`
	@: $(if $(findstring $*,$(INSTALLED_PHP_VERSION)),,$(error PHP version $* is invalid, valid versions are $(INSTALLED_PHP_VERSION)))
	$(call switch-php,$*)

.PHONY: php/versions
php/versions: ## <Environment> Display all available PHP versions
	echo "Available PHP versions are $(INSTALLED_PHP_VERSION)"

.PHONY: session
session:
	echo 'export PATH=$$(pwd)/bin:$$PATH'

.PHONY: help
help: ## <Help> Display this help.
	sed -e '/#\{2\} /!d; s/[?=:][^#]*##/:/; s/#\s*\([^#]\+\)##/\1:/; s/\([^:?]*\):\s<\([^>]*\)>\s\(.*\)/\2:\1:\3/; s/\([^:]*\):\s\([^<]*.*\)/Misc.:\1:\2/' $(MAKEFILE_LIST) | \
	sort -t: -d | \
	awk 'BEGIN{FS=":"; section=""} { if ($$1 != section) { section=$$1; printf "\n\033[1m%s\033[0m\n", $$1 } printf "\t\033[92m%s\033[0m:%s\n", $$2, $$3 }' | \
	column -c2 -t -s :

.PHONY: verbose
verbose:
	$(error Verbose syntax is `make verbose <target>`, not `make <target> verbose`)
endif
