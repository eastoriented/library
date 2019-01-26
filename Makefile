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

%/.:
	$(MKDIR) $@

install: bin/php bin/composer git VERSION LICENCE README.md src/. tests/units/runner.php .travis.yml

.PHONY: git
git: .git .gitignore .gitattributes .git/hooks/pre-commit

.git: $(call locate,git)
	git init

.git%:
	cp resources/git/$@ $@

.git/hooks/pre-commit:
	$(call write,$@,'#!/usr/bin/env sh')
	$(call write,$@,make tests/units)
	chmod u+x $@

.env:
	$(call write,$@,"HOME=$(HOME)")
	$(call write,$@,"USER_ID=$$(id -u):$$(id -g)")

.atoum.php:
	cp resources/atoum/$@ $@

README.md:
	cp resources/$@ $@

LICENCE:
	cp resources/$@ $@

.travis.yml:
	cp resources/$@ $@

VERSION:
	$(call write,$@,\$$Format:%ai\$$ \$$Format:%d\$$ \$$Format:%H\$$)

bin/php: | bin/. $(DOCKER_COMPOSE)
	$(call binary,$@,php-cli,php)

bin/atoum: | bin/. .atoum.php vendor $(DOCKER_COMPOSE)
	$(call binary,$@,php-cli,/src/vendor/$@)

bin/composer: | bin/.
	$(call binary,$@,composer,composer)

vendor: composer.json | .env $(DOCKER_COMPOSE)
	$(DOCKER_COMPOSE) run --rm composer composer install

bin/docker-compose: .env | $(call locate,curl) bin/.
	curl -L --fail https://github.com/docker/compose/releases/download/$(DOCKER_COMPOSE_VERSION)/run.sh -o $@
	chmod u+x $@

.PHONY: tests/units
tests/units: | bin/php tests/units/runner.php
	bin/php tests/units/runner.php

tests/units/runner.php: | bin/atoum tests/units/src/.
	cp -r resources/atoum/tests .
