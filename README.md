# BASH-CD

Incremental Continuous Deployment Framework written purely in BASH which operates
similary to ansible but doesn't require anything to be installed on the target hosts. 

https://github.com/amient/bash-cd

It can be used to __build__ deployment recipes on most UNIX-like systems that can run Bash Version 3+ 
So, say on your development osx, you can run `./apply.sh build <HOST-VAR>` to simulate how the build will
manifest on a particular machine and inspect `./build` directory. 

The __install__ phase can run on Debian Stretch out of the box. It is possible to make it run on other Linux 
distributions, but it requires the setup/install/stop/start functions of each module to be 
modified to use appropriate package manager and service manager. Notably, there is a maintained centos branch 
which does this by switching to yum instead of aptitude.


# Quick Start

To try it out, bash-cd comes with local vagrant file that can be used as a test host to be managed.
Bash cd can be applied from your development machine using a single ssh entry point into the cluster you
are wanting to manage.

    vagrant up
    
The above will launch a single debian-stretch virtual machine with private addresss 172.17.0.2 and various
ports exposed for testing of each module.
    
    ./apply.sh root@localhost:2222

This using the provided  "env/var.sh".

## How it works

When you execute `./apply.sh` from your local machine you provide it with a controller host.
First an ssh hop is made onto this controller host and from there a series of ssh and pssh commands
executes `lib/apply.sh` against all of the target hosts. 

Once `./apply.sh install` is triggered, it first compiles a list of APPLICABLE_MODULES which are attached to the
current host - for this reasons it is best to identify the hosts by primary ip addresses, i.e. the most stable
ip addresses which are visible on the whole enivronment, e.g. your environment's private network.

For all APPLICABLE_MODULES it checks whether the setup_ function has been modified and if it did, it applies
the new setup to the system.

The next thing it does, it uses a dry build and checksum the output diff to determine which modules are __actually affected__
and need to be built and re-installed. When it has the list of AFFECTED_SERVICES, it  builds them again but
this time against the root of the filesystem `/` followed by invoking the install_ function for each module.

Environment is described in `./env/var.sh` and must define specific variables and arrays to describe the hosts,
 modules and which hosts are the individual modules attached to.
 
**Modules** are iterated over in the order as they are declared in the MODUELS array.
Each module may declare dependencies on other modules using the `required` function.
All required dependencies must be declared before the module adds itself to the list
of APPLICABLE_MODULES to ensure that its dependencies are installed first.

Each module is implemented under [`/lib`](lib)


# Applying to your own system

Since BASH-CD relies heavily on ssh, on order for evrything to work, you'll have to enable an ssh-agent 
on your local machine from which you are applying and add to it all necessary keys that have root access 
on the target hosts. 

When managing mutliple environments, there are different branching strategies you can use, depending on 
how many environments you have and how critical is the deployment:

1. **master** - you just use master everywhere and any push to master will trigger deployment.
    Good for start, it still uses incremental builds so not every commit to master will actually trigger
    installation of modules, unless affected by the commit.

2. **master-develop** is mode in which you checkout `master` branch on your target machines but you prepare
    changes to the environment in development branch and then merge it to master to trigger the deployment.
    This is good enough if you are targetting only one environment but which is rather complex.

3. **branch-per-environment** in this mode master is used for development and whenever you want to apply
    the latest changes to a given environment you merge master into the environment branch.
    On each environment, you clone a bash-cd from the branch for that environment on each machine.
    You can use `./deploy.sh <environment>` script which simply merges master into a branch identified by `<environment>`
    and switches back to master - WARN: run this script only from outside the environment because you want
    your environment bash-cd clones to stay on their branches.

    NOTE: set your `git config --global merge.ours.driver true` - this will preserve the `env/var.sh` file untouched
    by merges.


## Project Structure

- `./apply.sh      ` - entry point script used to launch from a local machine
- `./lib/apply.sh  ` - the main apply script used to apply changes over ssh on the target hosts
- `./lib/tools.sh  ` - a small toolset of functions used across the codebase
- `./env/var.sh    ` - environment definitions - this file will vary between environments
- `./build/        ` - this is the dry-build target directory used by the `./apply.sh build` phase
- `./lib/<module>  ` - reusable module implementations - see the section below about the module structure

## What makes up a module

Modules are defined as modules directories under `./lib/<module>/..` - see examples in [`/lib`](lib)  - these should
be fully reusable but may need modifying if the configuration you require is very different
from the ones provided.

Structure of the module and how it is applied:

1. Module must have an `include.sh` file that defines the requirements and decides whether the module is attached to target host. Any exported variables for use in templates or other modules must be exported in this file.

2. Module may define build and setup functions which will be called first depending on the phase being executed:
- `setup_<module>()` - how the os needs to be configured before it can be built and installed
- `build_<module>()` - this method may outupt additional files into `$BUILD_DIR` which will contribute to the checksum diff besides the module templates

3. Module can provide *templates* in its subdirectories that will be mapped to `/` on the target, all the files will pass through `expand()` function which will replace all exported environment variables for their values.

4. If the module was selected for installation during build phase (2.) installation will be executed by a combination of the following methods:
- `stop_<module>()` - how the module is stopped on a target machine
- `install_<module>()` - this function will do everything after a module was selected for installation by the build
- `start_<module>()` - how the module is started on a target machine

5. Module can chose whether updates to it will be applied in parallel (default behaviour) or for rolling updates, serially:
- `rolling_<module() { return 1; }`

Modules can depend on other modules, e.g. an `example-app` requires KAFKA_CONNECTION which is defined and exported in the `lib/kafka/include.sh` so that any module or template may use it.

## How are changes to module detected

Installation is triggered for any applicable module when either of the following occurs:

- any of the module templates are modified
- build_<module> function is modified
- start_<module> function is modified
- stop_<module> function is modified

Whenever `setup_<module>` function is modified, before installation it is invoked to apply any changes
to the os that are required for the module installation.


## Environment Configuration Model

There are specific bash variables which must be declared globally and any variable that are used in *templates* must
also be *exported*.

The best way is to checkout the example [`/env/var.sh`](env/var.sh) and try running `./apply.sh build --host HOST0`
and then look at the `./build` output.

### Templates

Modules are defined under `./lib`. Each module can have subdirectories containing template files which will be expanded
and copied to the target system root directory.

Most text files will be treated as templates and any string prepended with a single dollar symbol $ will be
replaced for any environment variable, e.g. $PRIMARY_IP.

Shell scripts (`.sh`, `.bash`, `.bat`) are also treated as templates but  variables to be expanded must have leading
dobule dollar sing, e.g. $$KAFKA_REPL_FACTOR

Archive files will not be expanded - the list of file types can be extended in the function `expand_dir()` in `lib/tools.sh`.


## Rolling Upgrades

It is possible to also do rolling upgrades. Each module that consists of multiple instances has
typically an array of hosts defined in var.sh. Each individual host is detected from the `hostname --ip-address`.
When this selection is done, the module may also store the index of the host in the array and
multiply it by arbitrary number of seconds to sleep. This way a very simple rolling upgrade
can be done automatically without complicated coordination.

