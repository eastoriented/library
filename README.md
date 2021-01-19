# A PHP developement environment based upon docker to create some libraries

The objective of `eastoriented/library` is to provide a PHP development environment to develop classes using `docker`.  
It provide some default git files as `.gitignore`, a skeleton for `README.md`, a MIT licence file, a `bin` directory which contains scripts to use `php`, `composer`, `docker-compose` and `atoum` using `docker`.  
Moreover, it setup a test environment using [`atoum`](http://docs.atoum.org), and it allow the user to switch PHP version easily and update vendor accordingly.  
And finaly, it provide a `Makefile` to execute tests, update vendor, manage version, regenerate autoload and so on.

## Features

- Easy install;
- Setup a PHP development environment using docker, so it is totally independant from software installed on the workstation;
- Allow the user to swith PHP version "on the fly" (support PHP 7.1, 7.2, 7.3, 7.4 and 8 out of the box) and automaticaly update `vendor` directory accordingly;
- Can tag version automaticaly according to previous version using [semver](https://semver.org);
- Setup a test environment using [atoum](http://atoum.org);
- Provide configuration file for various CI (currently Github Action, Travis-CI and Gitlab CI);
- Setup a pre-commit hook to run unit tests;
- Provide docker wrapper for `composer`, `php`, `atoum` and `docker-compose` in the `bin`directory;
- Allow the user to make easily releases according to current commit or tag;
- Define configuration to transparently use SSH keys with `composer` in a docker context;
- Provide support for `.Lvimrc` file used by VIM plugin [`localvimrc`](https://github.com/embear/vim-localvimrc);
- Initialize a git repository;
- Provide default `.gitattributes` and `.gitognore` files;
- Provide default MIT licence fil;
- Provide default README.md;
- Provide default VERSION file;
- Works on OSX and Linux;
- Easy to update.

# Requirements

The only requirement to use `eastoriented/library` is [docker](https://docs.docker.com/install/).

# Installation

Execute the following command in a terminal:

```
wget -O - https://raw.githubusercontent.com/eastoriented/library/master/install.sh | sh
```

At end of process, you obtains an arborescence which contains all files needed to develop a PHP class:
By default, a github action workflow will be defined, but if you want a `.gitlab-ci.yml`, just do:

```
wget -O - https://raw.githubusercontent.com/eastoriented/library/master/install.sh | env WITH_GITLAB=true sh
```

Travis-CI is also supported:

```
wget -O - https://raw.githubusercontent.com/eastoriented/library/master/install.sh | env WITH_TRAVIS=true sh
```

If you use Github Action, you must define `COVERALLS_REPO_TOKEN` as a [repository secret](https://docs.github.com/en/free-pro-team@latest/actions/reference/encrypted-secrets#creating-encrypted-secrets-for-a-repository).  
If you use [vim](https://www.vim.org) and [localvimrc](https://github.com/embear/vim-localvimrc), you can do:

```
wget -O - https://raw.githubusercontent.com/eastoriented/library/master/install.sh | env WITH_VIM=true sh
```

In this case, you must edit `./.lvimrc` to define PHP namespace, see contents of `.lvimrc` for more informations.

And if you want that `composer` has SSH access on some repositories using your SSH credentials, just do:

```
wget -O - https://raw.githubusercontent.com/eastoriented/library/master/install.sh | env WITH_SSH=true sh
```

It is possible to mix all `WITH_*` variables:

```
wget -O - https://raw.githubusercontent.com/eastoriented/library/master/install.sh | env WITH_VIM=true WITH_SSH=true WITH_TRAVIS=true sh
```

# Update

To retrive the last version, just do `make vendor/update` and commit all updated files in your git repository.

# How to use it?

Just do `make help` in a terminal.
