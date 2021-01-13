# Disable builtin rules and variables, because they are useless in our context and add lot of noise when `make -d` is used to debug the macfly.
MAKEFLAGS+= --no-builtin-rules
MAKEFLAGS+= --no-builtin-variables

.DEFAULT_GOAL:=help

THIS_DIR:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
THIS_MAKEFILE=$(word $(words $(MAKEFILE_LIST)),$(MAKEFILE_LIST))
RESOURCES_DIR:=$(THIS_DIR)/resources
MKDIR:=mkdir -p
RM:=rm -rf
DOCKER_COMPOSE:=$(shell which docker-compose || echo 'bin/docker-compose')
CI?=github
PHP_EDITOR?=unsupported

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

define write
echo $2 >> $1
endef

define uniq
cat $1 | sort | uniq | tee $1 > /dev/null
endef

.SILENT:

.SUFFIXES:

.DELETE_ON_ERROR:

.PRECIOUS: %/.

%/.:
	$(MKDIR) $@

install: $(call locate,docker) bin/php bin/composer git Makefile .do_not_touch/Makefile VERSION LICENCE README.md src/. tests/units $(CI) $(PHP_EDITOR)

.PHONY: git
git: .git .gitignore .gitattributes .git/hooks/pre-commit

.git: $(call locate,git)
	git init

.git%: $(RESOURCES_DIR)/git/.git%
	cat $(RESOURCES_DIR)/git/$@ >> $@ && $(call uniq,$@)

.git/hooks/pre-commit:
	$(call write,$@,'#!/usr/bin/env sh')
	$(call write,$@,make tests/units)
	chmod u+x $@

.env:
	$(call write,$@,"HOME=$(HOME)")
	$(call write,$@,"USER_ID=$$(id -u):$$(id -g)")

Makefile:
	$(call write,$@,include .do_not_touch/Makefile)

.do_not_touch/Makefile: $(RESOURCES_DIR)/Makefile | .do_not_touch/config.mk
	cp $(RESOURCES_DIR)/Makefile $@

.do_not_touch/config.mk: | .do_not_touch/.
	$(call write,$@,"CI=$(CI)")

README.md:
	cp $(RESOURCES_DIR)/$@ $@

LICENCE:
	cp $(RESOURCES_DIR)/$@ $@

.PHONY: travis
travis: .travis.yml .atoum.php .gitattributes $(THIS_MAKEFILE)
	echo ".travis.yml export-ignore" >> .gitattributes && $(call uniq,.gitattributes)

.travis.yml:
	cp $(RESOURCES_DIR)/ci/travis/$@ $@

.PHONY: github
github: .github/workflows/tests.yml .atoum.php .gitattributes $(THIS_MAKEFILE)
	echo ".github export-ignore" >> .gitattributes && $(call uniq,.gitattributes)

.github/workflows/tests.yml: .github/workflows/.
	cp $(RESOURCES_DIR)/ci/github/tests.yml $^

.PHONY: gitlab
gitlab: .gitlab-ci.yml .gitattributes $(THIS_MAKEFILE)
	echo ".gitlab-ci.yml export-ignore" >> .gitattributes && $(call uniq,.gitattributes)

.gitlab-ci.yml:
	cp $(RESOURCES_DIR)/ci/gitlab/$@ $@

.atoum.php:
	cp $(RESOURCES_DIR)/ci/$(CI)/$@ $@

.PHONY: unsupported
unsupported:
	true

.PHONY: vim
vim: .lvimrc .atoum.php.vim

.lvimrc: $(RESOURCES_DIR)/.lvimrc
	cp $(RESOURCES_DIR)/$@ $@

.atoum.php.vim: $(RESOURCES_DIR)/.atoum.php.vim
	cp $(RESOURCES_DIR)/$@ $@

VERSION:
	$(call write,$@,\$$Format:%ai\$$ \$$Format:%d\$$ \$$Format:%H\$$)

bin/php: $(THIS_MAKEFILE) | docker-compose.yml bin/. $(DOCKER_COMPOSE)
	$(call bin,$@,php,php)

bin/atoum: $(THIS_MAKEFILE) | bin/. .atoum.php bin/composer $(DOCKER_COMPOSE)
	bin/composer require --dev atoum/atoum ^4
	$(call bin,$@,php,/src/vendor/$@)

bin/composer: $(THIS_MAKEFILE) | docker-compose.yml bin/. .env $(DOCKER_COMPOSE)
	$(call bin,$@,composer,composer,$(MKDIR) \$$HOME/.composer)

bin/docker-compose: DOCKER_COMPOSE_VERSION=$(shell curl --silent "https://api.github.com/repos/docker/compose/releases/latest" | grep '"tag_name":' |  sed -E 's/.*"([^"]+)".*/\1/')
bin/docker-compose: | $(call locate,curl) bin/. .env docker-compose.yml
	curl -L --fail https://github.com/docker/compose/releases/download/$(DOCKER_COMPOSE_VERSION)/run.sh -o $@
	chmod u+x $@

docker-compose.yml: $(DOCKER_COMPOSE_DEPENDENCIES) .env docker-compose.override.yml
	echo "# DO NOT MODIFY THIS FILE, please put your specific docker-compose configuration in docker-compose.override.yml" > $@
	$(DOCKER_COMPOSE) -f .do_not_touch/docker-compose.yml $$(find .do_not_touch -type f -name "docker-compose.*.yml" -exec echo "-f {}" \; | xargs) config >> $@

docker-compose.override.yml:
	cp $(RESOURCES_DIR)/$@ $@

tests/units: tests/units/runner.php tests/units/test.php tests/units/src

tests/units/src: tests/units/src/.

tests/units/runner.php: | bin/atoum tests/units/.
	cp -r $(RESOURCES_DIR)/atoum/$@ $@

tests/units/test.php: | bin/atoum tests/units/.
	cp -r $(RESOURCES_DIR)/atoum/$@ $@
