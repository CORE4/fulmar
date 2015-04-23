# Fulmar

Fulmar is a task manager for deployments. It is build on top of rake to use its powerful
task system and adds host and environment configuration. It provides methods to easily
access the current deployment configuration and simplifies especially file transfers and
remote shell execution.

A deployment can create a new version folder on the remote system in which you can warm up
the cache and the publish via a symlink. This avoids an inconsistent state on the production
machine and allows a quick revert to the old version, as long as other dependencies are
compatible (i.e. database).

It has (yet limited) support for MySQL / MariaDB and git. Remote databases can be accessed
through an ssh tunnel. 

## Prerequisites

Fulmar currently requires the [mysql2](https://github.com/brianmario/mysql2) gem which
requires the mysql header files. So on a linux system, you want to install
libmariadbclient-dev/libmysqlclient-dev or similar.

You also need cmake to build the dependencies.

- OSX: brew install mariadb cmake
- Ubuntu: apt-get install libmariadbclient-dev build-essential 

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fulmar'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install fulmar

## Usage

Fulmar works similar to Rake. 