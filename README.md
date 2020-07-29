# A PHP developement environment based upon docker to create some libraries

The objective of `eastoriented/library` is to provide a PHP development environment to develop classes using `docker`.  
It provide some default git files as `.gitignore`, a skeleton for `README.md`, a MIT licence file, a `bin` directory which contains scripts to use `php`, `composer`, `docker-compose` and `atoum` using `docker`.  
Moreover, it setup a test environment using [`atoum`](http://docs.atoum.org).  
And finaly, it provide a `Makefile` to execute tests, update vendor, manage version, regenerate autoload and so on.

# Requirements

The only requirement to use `eastoriented/library` is [docker](https://docs.docker.com/install/).

# Installation

Execute the following command in a terminal:

```
wget -O - https://raw.githubusercontent.com/eastoriented/library/master/install.sh | sh
```

At end of process, you obtains an arborescence which contains all files needed to develop a PHP class:
By default, a `.travis.yml` file will be created, but if you want a `.gitlab-ci.yml`, just do:

```
export CI_CONFIG_FILE=.gitlab-ci.yml && wget -O - https://raw.githubusercontent.com/eastoriented/library/master/install.sh | sh
```

# Update

To retrive the last version, just do `make vendor/update` and commit all updated files.

# How to use it?

Just do `make help` in a terminal.
