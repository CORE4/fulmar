# Fulmar

[![Build Status](https://travis-ci.org/CORE4/fulmar.svg?branch=master)](https://travis-ci.org/CORE4/fulmar)

Fulmar is a task manager for deployments. It is build on top of rake to use its powerful
task system and adds host and environment configuration. It provides methods to easily
access the current deployment configuration and simplifies especially file transfers and
remote shell execution.

A deployment can create a new version folder on the remote system in which you can warm up
the cache and publish via a symlink. This avoids an inconsistent state on the production
machine and allows a quick revert to the old version, as long as other dependencies are
compatible (i.e. database).

## Warning

Version 1.10.0 of Fulmar removes some features that we (CORE4) rarely used and which
caused the deployments to slow down. The gems needed to be compiled against the
installed libraries. If you need support to query databases (more than just dumps)
or use dependencies, you will need to explicitly specify version `~> 1.9.0`.
Fulmar 2.0 will support these features via plugins.

## Prerequisites

Fulmar 2.0 runs with Ruby >= 2.2.2. Plugins like [mariadb](https://github.com/CORE4/fulmar-plugin-mariadb) might have
additional requirements.

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

Start by creating a file named "Fulmarfile" in your project root. Then add a Folder "Fulmar" with a project.config.yml
in it. The name of the config file doesn't matter, it just needs to end with .config.yml. All \*.config.yml in the
Fulmar directory are merged so you can split you configuration into
several files.

    $ touch Fulmarfile
    $ mkdir Fulmar
    $ touch Fulmar/project.config.yml

You can now test your configuration.

    $ fulmar test:config

Everything should be fine. With `fulmar -T` you can get a quick overview on the available tasks. That is probably just
one, the fulmar console. We'll come back to this later.

Now let's start with a first configuration. You might want to have a server ready which you can access via ssh and
public key authentication. Add this to you configuration file (Fulmar/project.config.yml):

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

Now you can run a second test: `fulmar test:hosts`. This will test the ssh connection to your remote machine. You can
add a username to the ssh configuration in the files section (below the hostname). However, if you need a finer
grained host configuration, you should use your
[ssh config file](http://www.cyberciti.biz/faq/create-ssh-config-file-on-linux-unix/).

Most fulmar tasks need to run within a configured environment. Within the configuration, environments are split into
targets. So actually, a task works within a target. In our example, we set up an environment named 'my_server' with
a target named 'files'. You might want to use one environment for your development server, one for a preview server
and one for the production machine. Within each environment you might have different hosts for the file and the
database, so each environment can be split up into multiple targets (e.g. 'files' and 'database').

There is one special environment 'all' which contains settings you want to use in all targets of all environements.
These globally configured settings are overwritten with the specific ones from a target if they exist. Useful examples
for this are 'local_path' and 'debug'.

### Tasks

As you can see (`fulmar -T`), you cannot do anything more useful now. So it is time to write a first task. If you are
familiar with rake, this should not be a problem.

```ruby
namespace :deploy do
  task :test do
    configuration.environment = :my_server
    configuration.target = :files
    file_sync.transfer
  end
end
```

This creates a task 'test' within the namespace 'deploy', which means you can access the task by running
`fulmar deploy:test`. The task will load the configuration for 'myserver/files' and start a file sync (via rsync) to
your remote host.

If you log in to your remote machine, you should now see the Fulmar directory and the Fulmarfile in /tmp.
```bash
ssh my-ssh-server "ls -l /tmp | grep Fulmar"
```

This task can be even shorter. Fulmar creates some helper tasks automatically from your configuration. Just like in
rake, you can list them via `fulmar -T -A`:
```
fulmar console                      # Open an interactive terminal within fulmar
fulmar deploy:test                  # Deploy to test system
fulmar environment:my_server        #
fulmar environment:my_server:files  #
fulmar test:config                  #
fulmar test:hosts                   #
```

Fulmar creates task for every environment/target with this scheme. So you can just set a dependency to these tasks to
load the configuration. Your task now only needs one line:

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

If you call one task from another, your configuration will be given to the subtask. If you change the target in the
subtask it will be reverted when returning to your main task unless you did not set any configuration in the main task.
This means the following:
- You can use the dependency to a 'environment:' task to set the target initially (as it will be the first subtask to
  run)
- You can call a subtask and and you don't have to worry it might change your target.

*The configuration object is a singleton. So if you change the actual configuration of a target, it will affect other
tasks*

## Features

So now you can deploy the Fulmarfiles itself which is nice. So what else can you do within a task?

### Shell

Very often you need to call other programs or script from a shell to compile your assets or clear the cache. Within a
task, you can access the local and remote shell:

```ruby
task :tutorial => 'environment:my_server:files' do
  local_shell.run 'echo Wheeeeee'
  remote_shell.run 'ls -l | grep Fulmar'
  puts remote_shell.last_output
end
```

You can run multiple commands. If one fails, everything stops immediately. This is intended to stop the deployment of
broken files.

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

At the moment, there are two ways to synchronize your files to a remote host. The basic rsync and "rsync with versions".
You already know how to set up the simple file sync. You can add a few options, if you like:

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
- **delete**: true/false, Should additional files be deleted from the remote host? The default is "true", as you don't
  want to have legacy files opening security holes on your server.
- **exclude**: regexp, which works with "--exclude" from rsync. Usually, you should prefer the next option
- **exclude_file**: Filename of the exclude file relative to "local_path". If you have a file called .rsyncignore in
  "local_path" this will be used automatically.
- **chown**: chown files on remote machine to this user
- **chmod**: change mode of files on remote machines
- **direction**: up/down, Should the files be uploaded or downloaded? The latter is useful if you want to download
  images created by a cms on the remote machine.

### rsync with versions

When deploying to a production machine, you want your minimize the downtime for the website. Fulmar can help by syncing
different versions which are symlinked after they are set up.

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

You do no necessarily need to set "limit_releases" or "shared". "temp_dir", "releases_dir" and "shared_dir" are
relative to the remote_path and usually do not need to be changed.

So what does this all mean?

If you still have your deploy:test task you can now deploy a first version of your files. Probably create the "data"
dir first and put a file in to see what happens. Fulmar will sync you project into a temporary directory ("temp_dir")
and then copy it the the releases directory with the current timestamp as a directory name. So in this case, a directory
 like "/tmp/releases/2015-04-27_123456" will be created. Fulmar will then look of shared/data exists and if not, copy it
  from the releases directory. Shared directories in releases will be deleted an symlinked to shared. So you want to
  list all directories which are filled by you web application (images uploaded from the cms, etc).

Then you can build up the cache or whatever needs to be done within that directory before putting it live. This last
step is not yet covered in our little deployment task. So:

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

The transfer() method of the file_sync service returns the created release dir and you can do what needs to be done
before calling file_sync.publish to create the symlink (current => releases/2015-04-27_123456).

As you probably figured out, your webserver uses the "current" symlink to get the base directory of your web
application. Here, you would point it to /tmp/current/public or something like that.

### Custom versioning

When deploying via Gitlab CI, the current branch or tag is available in the environment variable `CI_COMMIT_REF_NAME`. You very likely want to use tags here and set something like

```yaml
  only:
    - /^live_\d+\.\d+.\d+/
```

in your .gitlab-ci.yaml. This way, whenever you tag something with e.g. "live_1.2.0" and push it, a deployment will trigger. Fulmar can be configured to read the content of an environment variable and use that as
the version name. So you can add `version_name` to your config and set it to the gitlab env variable:

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
      version_name: CI_COMMIT_REF_NAME
```

This way, fulmar will call the release "live_1.2.0" instead of the current timestamp.

### Configuration templates

Sometimes you need different versions of files on your different environments. An exmaple might be the .htaccess file.
You can use the [Ruby ERB templating engine](http://www.stuartellis.eu/articles/erb/) to generate the different
versions. The configuration of your environment are available via the `@config` variable.

Templates need to be named with the schema `<original_filename>.erb`. All files you want to render need to be listed in
the configuration:

```yaml
environments:
  staging:
    files:
      templates:
        - .htaccess.erb
      application_environment: Production/Live
```

Then add the variable to your template:

```
SetEnv APPLICATION_ENVIRONMENT "<%= @config['application_environment'] %>"
```

## Plugins

Fulmar can be extended with plugins.

```yaml
plugins:
  mariadb:
    # Put mariadb plugin configuration here
  git:
    # Put git plugin configuration here 
```

If you want to add your own plugin, have a look at the [example plugin](https://github.com/CORE4/fulmar-plugin-example).