# BASH-CD

Incremental Continuous Deployment server which listens on port 7480 for HTTP webhook events.

https://github.com/amient/bash-cd

It can be used to __build__ deployment recipes on most UNIX-like systems that can run Bash Version 3+ 
So, say on your development osx, you can run `./apply.sh build <HOST-VAR>` to simulate how the build will
manifest on a particular machine and inspect `./build` directory. 

The __install__ phase can run on Ubuntu 16.04 out of the box. The modules
use systemd and aptitude. It is possible to make it run on other Linux distributions and Unix systems,
but it requires the setup/install/stop/start functions of each module to be modified to use appropriate
package manager and init system.


# Quick Start

To try bash-cd, fork it and modify the contents of [`/env/var.sh`](env/var.sh) file - this file describes
your environment and which components are installed where. Remeber that forks are public so may want to mirror the repo instead.

If you need to add new services and applications add them in [`/lib`](lib)

On the target machines you will have to have `git` command available and you must enable the root account
to be able to programmatically pull the changes from bash-cd and any other application that you will be
deploying from git sources so use appropriate github automation method for your case, i.e. personal tokens,
deploy keys or machine users and configure the root account for it.

On each target machine clone bash-cd it into `/opt/bash-cd` and inside run the following sripts:

    sudo ./apply.sh setup
    sudo ./apply.sh install
    #You may need to REBOOT at this point, depnding on what the setup has done

On the bash-cd github repository, under settings, add a webhook for each target machine, using
defaults for push-events-only and the following URL:

    http://<target-machine-public-hostname>:7480/push

There are different branching strategies you can use, depending on how many environments you have and how
critical is the deployment:

1. **master** - you just use master everywhere and any push to master will trigger deployment.
    Good for start, it still uses incremental builds so not every commit to master will actually trigger
    installation of services, unless affected by the commit.

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

## How it works

Whenever _any_ push event occurs on your bash-cd repository or any other git repos that are part of your build
and configured with webhooks, the `/opt/bash-cd-server.sh` receives a notification.


For `POST /push` events which come only from bash-cd repostiory, the first the server does is to check whether the local
branch is behind its remote - if not nothing happens, if yes it invokes `./apply.sh install`

For `POST /install` events which come from your applictaions that you want to deploy from sources, the check for branch updates is skipped and `./apply.sh install` is invoked unconditionally - this way any changes to appliction repostiory
will still trigger deployment. The build is still incremental so only affected services get installed.

Once `./apply.sh install` is triggered, it first compiles a list of APPLICABLE_SERVICES which are attached to the
current host - for this reasons it is best to identify the hosts by primary ip addresses, i.e. the most stable
ip addresses which are visible on the whole enivronment, e.g. your environment's private network.

For all APPLICABLE_SERVICES it checks whether the setup_ function has been modified and if it did, it applies
the new setup to the system.

The next thing it does, it uses a dry build and checksum the output diff to determine which services are __actually affected__
and need to be built and re-installed. When it has the list of AFFECTED_SERVICES, it  builds them again but
this time against the root of the filesystem `/` followed by invoking the install_ function for each service.

Environment is described in `./env/var.sh` and must define specific variables and arrays to describe the hosts,
 services and which hosts are the individual services attached to.

**Project Structure**

- `./env/var.sh    ` - environment definitions - this file will vary between environments
- `./build/        ` - this is the dry-build target directory used by the `./apply.sh build` phase
- `./lib/          ` - reusable modules - see the section below about the structure that service modules have
- `./lib/tools.sh  ` - a small toolset of functions used across the codebase
- `./lib/cd/       ` - the service module that installs bash-cd service
- `./apply.sh      ` - script that takes (setup|build|install) argument and applies the changes to the local environment
- `./deploy.sh     ` - helper script for simplified triggering of deployment when using branch-per-environment strategy
- `./ssh.sh        ` - helper script that takes <HOST-VAR> and opens an ssh session to the target machine

## What order are services applied

Services are iterated over in the order as they are declared in the SERVICES array.
Each service may declare dependencies on other services using the `required` function.
All required dependencies must be declared before the service adds itself to the list
of APPLICABLE_SERVICES to ensure that its dependencies are installed first.


## What makes up a service

Services are defined as modules directories under `./lib/<service>/..` - see examples in [`/lib`](lib)  - these should
be fully reusable but may need modifying if the configuration you require is very different
from the ones provided.

Structure of the module:

1. Module must have an `include.sh` file that defines the requirements and decides whether the service is attached to target host. Any exported variables for use in templates or other modules must be exported in this file.

2. Module can have any subdirectories, containing *templates* that will be mapped to `/` on the target, all the files will pass through `expand()` function which will replace all exported environment variables for their values.

3. Module can optionally define any of the following functions which will be triggered by the `apply.sh`
- `setup_<service>()` - how the os needs to be configured before it can be built and installed
- `stop_<service>()` - how the service is stopped on a target machine
- `build_<service>()` - this method must output everything into `$BUILD_DIR` which will differ for `build` and `install`
- `install_<service>()` - this function will do everything after a service was selected for installation by the build
- `start_<service>()` - how the service is started on a target machine

Modules can depend on other modules, e.g. an `example-app` requires KAFKA_CONNECTION which is defined and exported in the `lib/kafka/include.sh` so that any module or template may use it.

## How are changes to service detected

Installation is triggered for any applicable service when either of the following occurs:

- any of the service templates are modified
- build_<service> function is modified
- start_<service> function is modified
- stop_<service> function is modified

Whenever `setup_<servie>` function is modified, before installation it is invoked to apply any changes
to the os that are required for the service installation.


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

It is possible to also do rolling upgrades. Each service that consists of multiple instances has
typically an array of hosts defined in var.sh. Each individual host is detected from the `hostname --ip-address`.
When this selection is done, the service may also store the index of the host in the array and
multiply it by arbitrary number of seconds to sleep. This way a very simple rolling upgrade
can be done automatically without complicated coordination.

