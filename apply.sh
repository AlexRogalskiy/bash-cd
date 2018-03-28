#!/usr/bin/env bash

# THIS SCRIPTS EXPECTS env/var.sh TO PROVIDE CORRECT CONFIGURATION, SEE EXAMPLE FOR DOCUMENTATION

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/lib/tools.sh

PHASE="$1"
HOST="$3"

if [ -z "$PHASE" ] ; then
    fail "Usage: (build|install) [--host <host>] [--rebuild]"
fi

source $DIR/env/var.sh

export PRIMARY_IP
if [ -z "$HOST" ]; then
    PRIMARY_IP="$(hostname --ip-address)"
else
    PRIMARY_IP="${!HOST}"
fi
checkvar PRIMARY_IP

highlight "APPLYING TO HOST $PRIMARY_IP"

checkvar SERVICES
for service in "${SERVICES[@]}"
do
    if [ -f "$DIR/lib/$service/include.sh" ]; then source "$DIR/lib/$service/include.sh"; fi
    if [ -f "$DIR/env/$service/include.sh" ]; then source "$DIR/env/$service/include.sh"; fi
done

if [ -z "$APPLICABLE_SERVICES" ]; then
    warn "NO SERVICES APPLICABLE"
    exit 0;
fi

declare BUILD_DIR="$DIR/build"
if [[ "$2" == "--rebuild" ]]; then rm -r "$DIR/build"; fi
mkdir -p $BUILD_DIR
continue $? "Could not create build dir: $BUILD_DIR"

build() {
    checkvar DIFF
    for service in "${APPLICABLE_SERVICES[@]}"
    do
        info "BUILDING SERVICE $service"
        if [ "$DIFF" == "true" ]; then chk1=$(checksum $BUILD_DIR); fi
        if [ "$(type -t build_$service)" == "function" ]; then "build_$service"; fi

        if [ -d "$DIR/lib/$service" ]; then expand_dir "$DIR/lib/$service"; fi
        if [ -d "$DIR/env/$service" ]; then expand_dir "$DIR/env/$service"; fi

        if [ "$DIFF" == "true" ]; then
            chk2=$(checksum $BUILD_DIR)
            if [ "$chk1" != "$chk2" ]; then
              echo "SERVICE MODIFIED ($chk1 > $chk2)"
              AFFECTED_SERVICES+=($service)
            else
              echo "NO DIFF ($chk2)"
            fi
        fi
    done
    if [ "$DIFF" != "true" ]; then
        AFFECTED_SERVICES=$APPLICABLE_SERVICES
    fi
    highlight "APPLIED IN $BUILD_DIR"
}

install() {

    for service in "${AFFECTED_SERVICES[@]}"
    do
        warn "INSTALLING SERVICE $service"

        #first run a dry build - this happens before start to minimize down time
        #it cannot happen after stop because some services use reboot or restart
        #cd so the resuming of the build would enter a loop
        BUILD_DIR="$DIR/build"
        if [ "$(type -t build_$service)" == "function" ]; then "build_$service"; fi
        continue $? "FAILED TO BUILD SERVICE $servie"
        if [ -d "$DIR/lib/$service" ]; then expand_dir "$DIR/lib/$service"; fi
        if [ -d "$DIR/env/$service" ]; then expand_dir "$DIR/env/$service"; fi
        continue $? "FAILED TO UPDATE BUILD FOOTPRINT: $servie"

        #service must be stopped before the real build into / becuase jars or other runtime artifact may be modified
        if [ "$(type -t stop_$service)" == "function" ]; then "stop_$service"; fi

        #now run a real build applying to the root of the filesystem
        BUILD_DIR="/"
        if [ "$(type -t build_$service)" == "function" ]; then "build_$service"; fi
        continue $? "FAILED TO BUILD SERVICE $servie"
        if [ -d "$DIR/lib/$service" ]; then expand_dir "$DIR/lib/$service"; fi
        if [ -d "$DIR/env/$service" ]; then expand_dir "$DIR/env/$service"; fi
        continue $? "FAILED TO EXPAND SERVICE $servie"

        #call install hooks on all modules
        if [ "$(type -t install_$service)" == "function" ]; then "install_$service"; fi
        continue $? "FAILED TO INSTALL SERVICE $servie"

        #finally start the services
        if [ "$(type -t start_$service)" == "function" ]; then "start_$service"; fi
        continue $? "FAILED TO START $service"

    done
    highlight "APPLIED IN /"
}

case $PHASE in
    build*)
        declare DIFF="false"
        build
    ;;
    install*)
        declare DIFF="true"
        declare -a AFFECTED_SERVICES
        rm -rf $DIR/lib/build && cp -r $DIR/build $DIR/lib/
        build
        cp -r $DIR/lib/build $DIR
        if [ ! -z "$AFFECTED_SERVICES" ]; then
            install
        else
            echo "NO SERVICES ON THIS HOST WERE AFFECTED"
        fi
    ;;
    *)
        fail "POSSIBLE PHASES: build, install"
    ;;
esac


