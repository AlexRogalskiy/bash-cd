#!/usr/bin/env bash

# THIS SCRIPTS EXPECTS env/var.sh TO PROVIDE CORRECT CONFIGURATION, SEE EXAMPLE FOR DOCUMENTATION

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/lib/tools.sh

PHASE="$1"
OPTION="$2"
HOST="$3"

if [ -z "$PHASE" ] ; then
    fail "Usage: (build|install) [--host <host>] [--rebuild]"
fi

source $DIR/env/var.sh
checkvar SERVICES

export PRIMARY_IP
if [ -z "$HOST" ]; then
    PRIMARY_IP="$(hostname --ip-address)"
elif [ -z "$PRIMARY_IP" ]; then
    PRIMARY_IP="${!HOST}"
fi
checkvar PRIMARY_IP

for service in "${SERVICES[@]}"
do
    if [ -f "$DIR/lib/$service/include.sh" ]; then
     source "$DIR/lib/$service/include.sh"
    fi
done

if [ -z "$APPLICABLE_SERVICES" ]; then
    warn "NO SERVICES APPLICABLE"
    exit 0;
fi

#deduplicate applicable services before executing the phase
DEDUPLICATED_APPLICABLE_SERVICES=$( tr ' ' '\n' <<< "${APPLICABLE_SERVICES[@]}" | sort -u | tr '\n' ' ' )
APPLICABLE_SERVICES=($DEDUPLICATED_APPLICABLE_SERVICES)

highlight "APPLYING TO HOST $PRIMARY_IP: $PHASE"

build() {
    checkvar DIFF
    checkvar BUILD_DIR
    mkdir -p $BUILD_DIR
    continue $? "COULD NOT CREATE BUILD DIR: $BUILD_DIR"
    if [ "$OPTION" == "--rebuild" ] && [ "$BUILD_DIR" != "/" ]; then
        echo "--REBUILD PURGING $BUILD_DIR"
        rm -rf $BUILD_DIR/*
    fi
    for service in "${APPLICABLE_SERVICES[@]}"
    do
        info "BUILDING SERVICE $service INTO $BUILD_DIR"
        if [ "$DIFF" == "true" ]; then chk1=$(checksum $BUILD_DIR); fi

        if [ -d "$DIR/lib/$service" ]; then expand_dir "$DIR/lib/$service"; fi
        if [ "$(type -t build_$service)" == "function" ]; then "build_$service"; fi

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

        #service must be stopped before the real build into / becuase jars or other runtime artifact may be modified
        if [ "$(type -t stop_$service)" == "function" ]; then "stop_$service"; fi

        #now run a real build applying to the root of the filesystem
        if [ -d "$DIR/lib/$service" ]; then expand_dir "$DIR/lib/$service"; fi
        continue $? "FAILED TO EXPAND SERVICE $servie"
        if [ "$(type -t build_$service)" == "function" ]; then "build_$service"; fi
        continue $? "FAILED TO BUILD SERVICE $servie"

        diff_cp "$BUILD_DIR" "/" "warn"

        #call install hooks on all modules
        if [ "$(type -t install_$service)" == "function" ]; then "install_$service"; fi
        continue $? "FAILED TO INSTALL SERVICE $servie"

        #finally start the services
        if [ "$(type -t start_$service)" == "function" ]; then "start_$service"; fi
        continue $? "FAILED TO START $service"

    done
    success "APPLIED IN /"
}

case $PHASE in
    setup*)
        mkdir -p "$DIR/lib/build"
        for service in "${APPLICABLE_SERVICES[@]}"
        do
            if [ "$(type -t setup_$service)" == "function" ]; then
                if [ -z "$(command -v md5sum)" ]; then
                    def_hash=$(type "setup_$service" | md5)
                else
                    def_hash=$(type "setup_$service" | md5sum)
                fi
                def_hash_file="$DIR/lib/build/_setup_$service"
                if [ -f "$def_hash_file" ]; then
                    prev_hash=$(cat "$def_hash_file")
                fi
                if [ "$def_hash" != "$prev_hash" ]; then
                    warn "SERVICE SETUP MODIFIED: $service"
                    setup_$service
                    continue $? "SETUP FAILED, SERVICE: $service"
                    echo "$def_hash" > "$def_hash_file"
                fi
            fi
        done
    ;;
    build*)
        declare DIFF="false"
        declare BUILD_DIR="$DIR/build"
        build
    ;;
    install*)
        declare -a AFFECTED_SERVICES
        cp -rf $DIR/build $DIR/env
        declare DIFF="true"
        declare BUILD_DIR="$DIR/env/build"
        build
        rm -rf $DIR/env/build
        if [ ! -z "$AFFECTED_SERVICES" ]; then
            BUILD_DIR="$DIR/build"
            install
        else
            success "NO SERVICES ON THIS HOST WERE AFFECTED"
        fi
    ;;
    *)
        fail "POSSIBLE PHASES: build, install"
    ;;
esac


