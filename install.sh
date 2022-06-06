#!/usr/bin/env sh

set -e

if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: `docker` is not installed.' >&2
  exit 1
fi

mkdir -p $HOME/.composer

docker run --rm -u $(id -u):$(id -g) -v "$(pwd)":/src -w /src -v "$HOME/.composer":/.composer -e COMPOSER_CACHE_DIR=/.composer -e COMPOSER_ALLOW_SUPERUSER=1 composer:latest composer require --dev eastoriented/library "${@:-dev-master}"

./vendor/bin/eastoriented-library install
