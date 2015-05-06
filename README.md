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
- Ubuntu: apt-get install libmariadbclient-dev build-essential cmake

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

Fulmar works like Rake. In fact it is just a collection of services on top of Rake.

## A simple start

Start by creating a file named "Fulmarfile" in your project root. Then add a Folder "Fulmar" with a project.config.yml in it. The name of the config file doesn't matter, it just needs to end with .config.yml. All \*.config.yml in the Fulmar directory are merged so you can split you configuration into
several files.

    $ touch Fulmarfile
    $ mkdir Fulmar
    $ touch Fulmar/project.config.yml

You can now now test your configuration.

    $ fulmar test:config

Everything should be fine. With `fulmar -T` you can get a quick overview on the available tasks. That is probably just one, the fulmar console. We'll come back to this later.

Now let's start with a first configuration. You might want to have a server ready which you can access via ssh and public key authentication. Add this to you configuration file (Fulmar/project.config.yml):

```yaml
environments:
  all:
    local_path: .
  my_server:
    files:
      hostname: my-ssh-server
      remote_path: /tmp
      type: rsync
      rsync:
        delete: false
```

Now you can run a second test: `fulmar test:hosts`. This will test the ssh connection to your remote machine. You can add a username to the ssh configuration in the files section (below the hostname). However, if you need a finer grained host configuration, you should use your [ssh config file](http://www.cyberciti.biz/faq/create-ssh-config-file-on-linux-unix/).

Most fulmar tasks need to run within a configured environment. Within the configuration, environments are split into targets. So actually, a task works within a target. In our example, we set up an environment named 'my_server' with a target named 'files'. You might want to use one environment for your development server, one for a preview server and one for the production machine. Within each environment you might have different hosts for the file and the database, so each environment can be split up into multiple targets (e.g. 'files' and 'database').

There is one special environment 'all' which contains settings you want to use in all targets of all environements. These globally configured settings are overwritten with the specific ones from a target if they exist. Useful examples for this are 'local_path' and 'debug'.

### Tasks

As you can see (`fulmar -T`), you cannot do anything more useful now. So it is time to write a first task. If you are familiar with rake, this should not be a problem.

```ruby
namespace :deploy do
  task :test do
    configuration.environment = :my_server
    configuration.target = :files
    file_sync.transfer
  end
end
```

This creates a task 'test' within the namespace 'deploy', which means you can access the task by running `fulmar deploy:test`. The task will load the configuration for 'myserver/files' and start a file sync (via rsync) to your remote host.

If you log in to your remote machine, you should now see the Fulmar directory and the Fulmarfile in /tmp.
```bash
ssh my-ssh-server "ls -l /tmp | grep Fulmar"
```

This task can be even shorter. Fulmar creates some helper tasks automatically from your configuration. Just like in rake, you can list them via `fulmar -T -A`:
```
fulmar console                      # Open an interactive terminal within fulmar
fulmar deploy:test                  # Deploy to test system
fulmar environment:my_server        #
fulmar environment:my_server:files  #
fulmar test:config                  #
fulmar test:hosts                   #
```

Fulmar creates task for every environment/target with this scheme. So you can just set a dependency to these tasks to load the configuration. Your task now only needs one line:

```ruby
namespace :deploy do
  task :test => 'environment:my_server:files' do
    file_sync.transfer
  end
end
```

Task can have multiple dependencies, just put them into an array:

```ruby
task :test => ['environment:my_server:files', 'prepare_files', 'do_some_more'] do
end
```

If you call one task from another, your configuration will be given to the subtask. If you change the target in the subtask it will be reverted when returning to your main task unless you did not set any configuration in the main task. This means the following:
- You can use the dependency to a 'environment:' task to set the target initially (as it will be the first subtask to run)
- You can call a subtask and and you don't have to worry it might change your target.

*The configuration object is a singleton. So if you change the actual configuration of a target, it will affect other tasks*

## Features

So now you can deploy the Fulmarfiles itself which is nice. So what else can you do within a task?

### Shell

Very often you need to call other programs or script from a shell to compile your assets or clear the cache. Within a task, you can access the local and remote shell:

```ruby
task :tutorial => 'environment:my_server:files' do
  local_shell.run 'echo Wheeeeee'
  remote_shell.run 'ls -l | grep Fulmar'
  puts remote_shell.last_output
end
```

You can run multiple commands. If one fails, everything stops immediately. This is intended to stop the deployment of broken files.

```ruby
task :tutorial => 'environment:my_server:files' do
  local_shell.run [
    'echo Wheeeee',
    'false',
    'echo Does not get executed'
  ]
  info "This does not get executed, either"
end
```

### Output

If you want your tasks to output some status messages, you can call `info`, `warning` or `error`.

```ruby
task :tutorial => 'environment:my_server:files' do
  info "Everything is fine."
  warning "Or probably not."
  error "Yepp, it's borken"
end
```

### File synchronisation

At the moment, there are two ways to synchronize your files to a remote host. The basic rsync and "rsync with versions". You already know how to set up the simple file sync. You can add a few options, if you like:

```yaml
environments:
  all:
    local_path: .
  my_server:
    files:
      hostname: my-ssh-server
      remote_path: /tmp
      type: rsync
      rsync:
        # Default values are:
        delete: true
        exclude: nil,
        exclude_file: .rsyncignore,
        chown: nil,
        chmod: nil,
        direction: up
```

These are:
- **delete**: true/false, Should additional files be deleted from the remote host? The default is "true", as you don't want to have legacy files opening security holes on your server.
- **exclude**: regexp, which works with "--exclude" from rsync. Usually, you should prefer the next option
- **exclude_file**: Filename of the exclude file relative to "local_path". If you have a file called .rsyncignore in "local_path" this will be used automatically.
- **chown**: chown files on remote machine to this user
- **chmod**: change mode of files on remote machines
- **direction**: up/down, Should the files be uploaded or downloaded? The latter is useful if you want to download images created by a cms on the remote machine.

### rsync with versions

When deploying to a production machine, you want your minimize the downtime for the website. Fulmar can help by syncing different versions which are symlinked after they are set up.

```yaml
environments:
  all:
    local_path: .
  my_server:
    files:
      hostname: my-ssh-server
      remote_path: /tmp
      type: rsync_with_versions
      shared:
        - data
      limit_releases: 10
      #temp_dir: temp
      #releases_dir: releases
      #shared_dir: shared
```

You do no necessarily need to set "limit_releases" or "shared". "temp_dir", "releases_dir" and "shared_dir" are relative to the remote_path and usually do not need to be changed.

So what does this all mean?

If you still have your deploy:test task you can now deploy a first version of your files. Probably create the "data" dir first and put a file in to see what happens. Fulmar will sync you project into a temporary directory ("temp_dir") and then copy it the the releases directory with the current timestamp as a directory name. So in this case, a directory like "/tmp/releases/2015-04-27_123456" will be created. Fulmar will then look of shared/data exists and if not, copy it from the releases directory. Shared directories in releases will be deleted an symlinked to shared. So you want to list all directories which are filled by you web application (images uploaded from the cms, etc).

Then you can build up the cache or whatever needs to be done within that directory before putting it live. This last step is not yet covered in our little deployment task. So:

```ruby
namespace :deploy do
  task :test => 'environment:my_server:files' do
    releases_dir = file_sync.transfer
    puts release_dir # Something like 'releases/2015-04-27_123456'
    remote_shell [
      "cd #{release_dir}",
      'php app/console cache:clear --env=dev'
    ]
    file_sync.publish # create
  end
end
```

The transfer() method of the file_sync service returns the created release dir and you can do what needs to be done before calling file_sync.publish to create the symlink (current => releases/2015-04-27_123456).

As you probably figured out, your webserver uses the "current" symlink to get the base directory of your web application. Here, you would point it to /tmp/current/public or something like that.

### Database access

Within a task you can access and update databases (mariadb/mysql at the time of writing). Remote databases do not need to be accessible directly since fulmar uses an ssh tunnel to connect to the host first. So the database host is often just "localhost" (the default value). You can specify a different host if you database server is on another host, which is the case on most simple web spaces.

The field "maria:database" is required for type "maria". The other fields are optional, though you probably need the fields "user" and "password". Below you can see the default values for the optional fields.

```yaml
environments:
  staging:
    database:
      host: project-staging
      type: maria
      maria:
        database: db_name
        user: root
        password:
        port: 3306
        host: localhost
        encoding: utf-8
```

```ruby
require 'pp'

task :database => 'environment:staging:database' do
  database.create 'test_db'
  database.clear # deletes all tables within the database
  remote_file_name = database.dump # dumps the database to the returned file
  database.load_dump(remote_file_name) # loads an sql dump
  local_filename = database.download_dump # downloads an sql dump to your machine
end
```

You can query the database like this:

```ruby
results = database.query 'SELECT name, email FROM users'
results.each do |row|
  puts "#{row['name']} <#{row['email']}>"
end
```

You can use all features of the mysql2 gem via `database.client`.

If you configured more than one database on different environments, fulmar will
create task to sync these databases via mysql_dump. This allows you to update a
staging or preview database with the data from the production system.

```
fulmar database:update:preview:from_live
```

The task to copy data *to* the live database is hidden (it has no description).

### Configuration templates

Sometimes you need different versions of files on your different environments. An exmaple might be the .htaccess file. You can use the [Ruby ERB templating engine](http://www.stuartellis.eu/articles/erb/) to generate the different versions. The configuration of your environment are available via the `@config` variable.

Templates need to be named with the schema `<original_filename>.erb`. All files you want to render need to be listed in the configuration:

```yaml
environments:
  staging:
    files:
      config_templates:
        - .htaccess.erb
      application_environment: Production/Live
```

Then add the variable to your template:

```
SetEnv APPLICATION_ENVIRONMENT "<%= @config['application_environment'] %>"
```
