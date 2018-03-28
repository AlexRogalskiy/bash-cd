# BASH-CD

Incremental Continuous Deployment server which listens on port 7480 for HTTP webhook events.

It can be used to __build__ deployment recipes on most UNIX-like systems that can run Bash Version 3+ 
So, say on your development osx, you can run `./apply.sh build <HOST-VAR>` to simulate how the build will
manifest on a particular machine and inspect `./build` directory. 

The __install__ phase currently requires Bash Version 4 and was tested on Ubuntu but should work on most
Linux distributions but the `env/setup.sh` script has to be modified appropriately.  


# Quick Start 
 
To try bash-cd, fork it and modify the contents of [`/env`](env) directory. (Remeber that forks are public so may want to mirror the repo instead.)

On the target machines you will have to have `git` command available and you must enable the root account
to be able to programmatically pull the changes from bash-cd and any other application that you will be 
deploying from git sources so use appropriate github automation method for your case, i.e. personal tokens, 
deploy keys or machine users and configure the root account for it. 

On each target machine clone bash-cd it into `/opt/bash-cd` and inside run the following sripts: 
 
    sudo ./env/setup.sh
    sudo ./apply.sh install
    #You may need to REBOOT at this point, depnding what you did in setup.sh
    
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

## How it works

Whenever _any_ push event occurs on your bash-cd repository or any other git repos that are part of your build
and configured with webhooks, the `/opt/bash-cd/lib/cd/server.sh` receives a notification.


For `POST /push` events which come only from bash-cd repostiory, the first the server does is to check whether the local 
branch is behind its remote - if not nothing happens, if yes it invokes `./apply.sh install`

For `POST /install` events which come from your applictaions that you want to deploy from sources, the check for branch updates is skipped and `./apply.sh install` is invoked unconditionally - this way any changes to appliction repostiory
will still trigger deployment. The build is still incremental so only affected services get installed.

Once `./apply.sh install` is triggered, it first compiles a list of APPLICABLE_SERVICES which are attached to the 
current host - for this reasons it is best to identify the hosts by primary ip addresses, i.e. the most stable
ip addresses which are visible on the whole enivronment, e.g. your environment's private network.  
The next thing it does, it uses a dry build and checksum to determine which services are __actually affected__
and need to be built and re-installed. When it has the list of AFFECTED_SERVICES, it  builds them again but 
this time against the root of the filesystem `/` followed by invoking the install_ function for each service.

Each target machine has to be configured first time with the `./env/setup.sh` which you can modify to install 
required system packages that you will be using for your builds. Whenever this script is modified, the webhook
will run it again automatically afterwards if you need to evolve your setup. When this happens, a clean install
is also triggered without incrementailiy - everything is fully built and installed again.

Environment is described in `./env/var.sh` and must define specific variables and arrays to describe the hosts,
 services and which hosts are the individual services attached to. 

**Project Structure**

- `./build/        ` - this is the dry-built target directory used by the `./apply.sh build` phase
- `./env/          ` - this is the directory that describes your environment and any additional custom modules
- `./env/../       ` - custom modules for you applications and services can be added here 
- `./env/setup.sh  ` - this is the installation script which is also executed whenever modified automatically
- `./env/var.sh    ` - environment definition variables
- `./lib/          ` - reusable modules (PRs welcome!)
- `./lib/tools.sh  ` - a small toolset of functions used across the codebase 
- `./lib/cd/       ` - the first module that installs bash-cd server as an upstart service
- `./lib/cd/etc/init/bash-cd.conf` - upstart config for the service
- `./lib/cd/include.sh           ` - every module must have include.sh with specifically named functions, see below
- `./lib/cd/server.sh            ` - the bash-cd http server that listens for webhook events
- `./lib/../                     ` - see contents of the directory for other available modules
- `./apply.sh                    ` - script that takes (build|install) argument - build does a dry build, install a real one
- `./deploy.sh                   ` - use this from your development machine if you will be using branch-per-environment strategy
- `./ssh.sh                      ` - helper script that takes <HOST-VAR> and opens an ssh session to the target machine


## What makes up a service

Services are defined as modules directories under 2 separate locations:
- `./lib/<service>/..` - see examples in [`/lib`](lib) - these are fully reusable 
- `./env/<service>/..` - see [`/env/example-app`](env/example-app) - these are your additional modules
 
Structure of the module:

1. Module must have an `include.sh` file that defines the requirements and decides whether the service is attached to target host. Any exported variables for use in templates or other modules must be exported in this file.

2. Module can have any subdirectories, containing *environment-templates* that will be mapped to `/` on the target, all the files will pass through `expand()` function which will replace all exported environment variables for their values.

3. Module can optionally define any of the following functions which will be triggered by the `apply.sh`
- `stop_<service>()` - how the service is stopped on a target machine
- `build_<service>()` - this method must output everything into `$BUILD_DIR` which will differ for `build` and `install` 
- `install_<service>()` - this function will do everything after a service was selected for installation by the build
- `stop_<service>()` - how the service is started on a target machine

Modules can depend on other modules, e.g. an `example-app` requires KAFKA_CONNECTION which is defined and exported in the `lib/kafka/include.sh` so that any module or template may use it.

## Environment Configuration Model

There are specific bash variables which must be defined globally and any variable that can be used in the 
*environment-templates* must also be *exported*.

The best way is to checkout the example [`/env/var.sh`](env/var.sh) and try running `./apply.sh build --host HOST0`
and then look at the `./build` output.
 
...
