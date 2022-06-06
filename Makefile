# Disable builtin rules and variables, because they are useless in our context and add lot of noise when `make -d` is used to debug the macfly.
MAKEFLAGS+= --no-builtin-rules
MAKEFLAGS+= --no-builtin-variables

SHELL=/bin/bash -e

.DEFAULT_GOAL:=install

THIS_MAKEFILE=$(firstword $(MAKEFILE_LIST))

ifeq "$(firstword $(MAKECMDGOALS))" "verbose"

.PHONY: verbose
verbose:
	$(info <-- Start of verbose make -->)
	$(MAKE) -f $(THIS_MAKEFILE) $(filter-out verbose,$(MAKECMDGOALS)) WITH_DEBUG=TRUE

%:
	$(info <-- End of verbose make -->)

else

THIS_DIR:=$(dir $(abspath $(lastword $(MAKEFILE_LIST))))
RESOURCES_DIR:=$(THIS_DIR)resources
MKDIR:=mkdir -p
RM:=rm -rf
CP:=cp -r
DOCKER_COMPOSE:=docker-compose

-include .do_not_touch/config.mk

INSTALL_DEPENDENCIES:=$(call locate,docker) $(call locate,git) bin/php bin/composer git Makefile .do_not_touch/Makefile docker-compose.yml VERSION LICENCE README.md CHANGELOG.md src/. tests/units
DOCKER_COMPOSE_YML:=$(RESOURCES_DIR)/docker-compose.yml
DOCKER_COMPOSE_DEPENDENCIES:=

WITH_GITHUB?=true
ifneq ($(strip $(WITH_GITHUB)),)
CI:=github
endif

WITH_GITLAB?=
ifneq ($(strip $(WITH_GITLAB)),)
CI:=gitlab
endif

WITH_TRAVIS?=
ifneq ($(strip $(WITH_TRAVIS)),)
CI:=travis
endif

WITH_VIM?=
ifneq ($(strip $(WITH_VIM)),)
INSTALL_DEPENDENCIES+= vim
endif

WITH_SSH?=
ifneq ($(strip $(WITH_SSH)),)
INSTALL_DEPENDENCIES+= ssh
DOCKER_COMPOSE_DEPENDENCIES+= .passwd
DOCKER_COMPOSE_YML+= $(RESOURCES_DIR)/docker-compose.ssh.yml
endif

WITH_PHP_DOCKERFILES?=
ifneq ($(strip $(WITH_PHP_DOCKERFILES)),)
PHP_DOCKERFILES:=$(shell find resources/docker/php -type f)
DOCKER_COMPOSE_YML+= $(RESOURCES_DIR)/docker-compose.php.yml docker/php
endif

INSTALL_DEPENDENCIES+= $(CI)

NETWORK_NAME?=$(shell pwd | awk -F / '{print $$NF}')

GIT_MAIN_BRANCH?=main

GITIGNORE_FILE?=$(shell git config --global --get core.excludesfile || echo $$HOME/.config/git/ignore)

define locate
$(or $(shell which $1),$(error \`$1\` is not in \`$(PATH)\`, please install it!))
endef

define bin
$(RM) $1
$(call write,$1,'#!/usr/bin/env sh')
$(call write,$1,'set -e')
$(call write,$1,$4)
$(call write,$1,'$(DOCKER_COMPOSE) run --rm $2 $3 "$$@"')
chmod u+x $1
endef

define write
echo $2 >> $1
endef

define uniq
cat $1 | sort | uniq | tee $1 > /dev/null
endef

ifeq ($(strip $(WITH_DEBUG)),)
.SILENT:
else
OLD_SHELL:=$(SHELL)
SHELL=$(warning $(if $@, Update target $@)$(if $<, from $<)$(if $?, due to $?))$(OLD_SHELL) -x
endif

.SUFFIXES:

.DELETE_ON_ERROR:

.PRECIOUS: %/.

%/.:
	$(MKDIR) $@

install: $(INSTALL_DEPENDENCIES) .do_not_touch/config.mk
	$(MAKE) -f $(THIS_MAKEFILE) .git/refs/heads/master

.PHONY: git
git: .git .gitignore .gitattributes .git/hooks/pre-commit

.git: $(call locate,git)
	git init -b $(GIT_MAIN_BRANCH)

.git%: $(RESOURCES_DIR)/git/git%
	cat $(RESOURCES_DIR)/git/git$* >> $@ && $(call uniq,$@)

.git/hooks/pre-commit:
	$(call write,$@,'#!/usr/bin/env sh')
	$(call write,$@,make tests/units)
	chmod u+x $@

.git/refs/heads/master: | .git
	git add -A
	git commit --quiet -n -m "Init done, have a good journey!"

.env: .do_not_touch/docker-compose.yml
	$(RM) $@
	$(call write,$@,"HOME=$(HOME)")
	$(call write,$@,"USER_ID=$$(id -u):$$(id -g)")
	$(call write,$@,"NETWORK_NAME=$(NETWORK_NAME)")

Makefile: $(THIS_MAKEFILE)
	$(RM) $@
	$(call write,$@,include .do_not_touch/Makefile)

.do_not_touch/Makefile: $(RESOURCES_DIR)/Makefile
	$(CP) $(RESOURCES_DIR)/Makefile $@

.do_not_touch/config.mk: $(THIS_MAKEFILE) | .do_not_touch/.
	$(RM) $@
	$(call write,$@,"INSTALL_DEPENDENCIES:=$(INSTALL_DEPENDENCIES)")

.do_not_touch/docker-compose.yml: $(DOCKER_COMPOSE_YML) | .do_not_touch/.
	$(CP) $(DOCKER_COMPOSE_YML) .do_not_touch

.do_not_touch/docker-compose.%.yml: $(RESOURCES_DIR)/docker-compose.%.yml | .do_not_touch/.
	$(CP) $(RESOURCES_DIR)/docker-compose.$*.yml $@

%.md:
	$(CP) $(RESOURCES_DIR)/$*.md $@

LICENCE:
	$(CP) $(RESOURCES_DIR)/$@ $@

docker/php: docker/php/. $(PHP_DOCKERFILES)
	$(CP) $(RESOURCES_DIR)/docker/php/* $^

.PHONY: travis
travis: .travis.yml .atoum.php .gitattributes $(THIS_MAKEFILE)
	echo ".travis.yml export-ignore" >> .gitattributes && $(call uniq,.gitattributes)

.travis.yml:
	$(CP) $(RESOURCES_DIR)/ci/travis/$@ $@

.PHONY: github
github: .github/workflows/tests.yml .atoum.php .gitattributes $(THIS_MAKEFILE)
	echo ".github export-ignore" >> .gitattributes && $(call uniq,.gitattributes)

.github/workflows/tests.yml: .github/workflows/.
	$(CP) $(RESOURCES_DIR)/ci/github/tests.yml $^

.PHONY: gitlab
gitlab: .gitlab-ci.yml .gitattributes $(THIS_MAKEFILE)
	echo ".gitlab-ci.yml export-ignore" >> .gitattributes && $(call uniq,.gitattributes)

.gitlab-ci.yml:
	$(CP) $(RESOURCES_DIR)/ci/gitlab/$@ $@

.atoum.php:
	$(CP) $(RESOURCES_DIR)/ci/$(CI)/$@ $@

.PHONY: vim
vim: .lvimrc

.lvimrc: .atoum.vim.php
	$(CP) $(RESOURCES_DIR)/$@ $@

$(GITIGNORE_FILE):
	$(MKDIR) $(dirname $(GITIGNORE_FILE))
	> $@
	
.atoum.vim.php: $(GITIGNORE_FILE)
	$(CP) $(RESOURCES_DIR)/$@ $@
	grep -q .atoum.vim.php $(GITIGNORE_FILE) || echo '.atoum.vim.php' >> $(GITIGNORE_FILE)

.PHONY: ssh
ssh: .passwd

.passwd:
	$(RM) $@
	$(call write,$@,root:x:$$(id -u):$$(id -g):root:/:/bin/sh)

VERSION:
	$(call write,$@,\$$Format:%ai\$$ \$$Format:%d\$$ \$$Format:%H\$$)

bin/php: $(THIS_MAKEFILE) $(RESOURCES_DIR)/bin/php | .env docker-compose.yml bin/.
	cat $(RESOURCES_DIR)/bin/php > $@
	chmod u+x $@

bin/atoum: $(THIS_MAKEFILE) | .env bin/. .atoum.php bin/composer
	bin/composer require --dev atoum/atoum ^4
	$(call bin,$@,php,/src/vendor/$@)

bin/composer: $(THIS_MAKEFILE) | .env docker-compose.yml bin/. .env
	$(call bin,$@,composer,composer,$(MKDIR) \$$HOME/.composer)

docker-compose.yml: $(THIS_MAKEFILE) .env docker-compose.override.yml $(DOCKER_COMPOSE_YML) $(DOCKER_COMPOSE_DEPENDENCIES)
	$(RM) $@
	$(CP) $(DOCKER_COMPOSE_YML) .
	echo "# DO NOT MODIFY THIS FILE, please put your specific docker-compose configuration in docker-compose.override.yml" > $@.tmp
	$(DOCKER_COMPOSE) -f $$(echo $(DOCKER_COMPOSE_YML) | sed -e 's#$(RESOURCES_DIR)/##g' -e 's/ / -f /g') --env-file $$(pwd)/.env config >> $@.tmp
	$(RM) docker-compose.*yml
	cat $@.tmp >> $@ && $(RM) $@.tmp

docker-compose.override.yml:
	cp $(RESOURCES_DIR)/$@ $@

tests/units: tests/units/runner.php tests/units/test.php tests/units/src
	touch $@

tests/units/src: tests/units/src/.

tests/units/runner.php: $(RESOURCES_DIR)/atoum/$@ | bin/atoum tests/units/.
	$(CP) $(RESOURCES_DIR)/atoum/$@ $@

tests/units/test.php: $(RESOURCES_DIR)/atoum/$@ | bin/atoum tests/units/.
	$(CP) $(RESOURCES_DIR)/atoum/$@ $@

.PHONY: verbose
verbose:
	$(error Verbose syntax is `make verbose <target>`, not `make <target> verbose`)
endif
