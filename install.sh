#!/usr/bin/env sh

set -e

if ! [ -x "$(command -v docker)" ]; then
  echo 'Error: `docker` is not installed.' >&2
  exit 1
fi

docker run --rm -v $(pwd):/src -w /src -v  $HOME/.composer:/.composer -e COMPOSER_CACHE_DIR=/.composer -e COMPOSER_ALLOW_SUPERUSER=1 -u $(id -u) composer:latest composer require --dev eastoriented/library "${@:-dev-master}"

./vendor/bin/eastoriented-library install
