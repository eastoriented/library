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

install: bin/php bin/atoum bin/composer .git

.git:
	git init

.env:
	$(call write,$@,"HOME=$(HOME)")
	$(call write,$@,"USER_ID=$$(id -u):$$(id -g)")

bin/php: | bin/. $(DOCKER_COMPOSE)
	$(call binary,$@,php-cli,php)

bin/atoum: | bin/. vendor $(DOCKER_COMPOSE)
	$(call binary,$@,php-cli,/src/vendor/$@)

bin/composer: | bin/.
	$(call binary,$@,composer,composer)

vendor: composer.json | .env $(DOCKER_COMPOSE)
	$(DOCKER_COMPOSE) run --rm composer composer install

bin/docker-compose: .env | $(call locate,curl) bin/.
	curl -L --fail https://github.com/docker/compose/releases/download/$(DOCKER_COMPOSE_VERSION)/run.sh -o $@
	chmod u+x $@

uninstall:
	$(RM) .env bin vendor

clean: uninstall
	$(RM) .git
