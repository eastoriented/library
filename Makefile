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

install: $(call locate,docker) bin/php bin/composer git Makefile .do_not_touch/Makefile VERSION LICENCE README.md src/. tests/units/runner.php .travis.yml

.PHONY: git
git: .git .gitignore .gitattributes .git/hooks/pre-commit

.git: $(call locate,git)
	git init

.git%:
	cp $(RESOURCES_DIR)/git/$@ $@

.git/hooks/pre-commit:
	$(call write,$@,'#!/usr/bin/env sh')
	$(call write,$@,make tests/units)
	chmod u+x $@

.env:
	$(call write,$@,"HOME=$(HOME)")
	$(call write,$@,"USER_ID=$$(id -u):$$(id -g)")

.atoum.php:
	cp $(RESOURCES_DIR)/atoum/$@ $@

Makefile:
	$(call write,$@,include .do_not_touch/Makefile)

.do_not_touch/Makefile: $(RESOURCES_DIR)/Makefile | .do_not_touch/.
	cp $(RESOURCES_DIR)/Makefile $@

README.md:
	cp $(RESOURCES_DIR)/$@ $@

LICENCE:
	cp $(RESOURCES_DIR)/$@ $@

.travis.yml:
	cp $(RESOURCES_DIR)/$@ $@

VERSION:
	$(call write,$@,\$$Format:%ai\$$ \$$Format:%d\$$ \$$Format:%H\$$)

bin/php: | docker-compose.yml bin/. $(DOCKER_COMPOSE)
	$(call binary,$@,php-cli,php)

bin/atoum: | docker-compose.yml bin/. .atoum.php bin/composer $(DOCKER_COMPOSE)
	bin/composer require --dev --no-suggest atoum/atoum ^3
	$(call binary,$@,php-cli,/src/vendor/$@)

bin/composer: | docker-compose.yml bin/. .env $(DOCKER_COMPOSE)
	$(call binary,$@,composer,composer)

docker-compose.yml: $(THIS_DIR)/docker-compose.yml
	cp $(THIS_DIR)/docker-compose.yml $@

bin/docker-compose: | $(call locate,curl) bin/. .env docker-compose.yml
	curl -L --fail https://github.com/docker/compose/releases/download/$(DOCKER_COMPOSE_VERSION)/run.sh -o $@
	chmod u+x $@

tests/units/runner.php: | bin/atoum tests/units/src/.
	cp -r $(RESOURCES_DIR)/atoum/tests .
