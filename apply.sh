#!/usr/bin/env bash

# THIS SCRIPTS EXPECTS env/var.sh TO PROVIDE CORRECT CONFIGURATION, SEE EXAMPLE FOR DOCUMENTATION

PHASE="$1"
OPTION="$2"
HOST="$3"

if [ -z "$PHASE" ] ; then
    fail "Usage: (build|install) [--host <host>] [--rebuild]"
fi


DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/lib/tools.sh
source $DIR/env/var.sh
BRANCH="$(cd $DIR && git rev-parse --abbrev-ref HEAD)"

export PRIMARY_IP
if [ -z "$HOST" ]; then
    PRIMARY_IP="$(hostname --ip-address)"
elif [ -z "$PRIMARY_IP" ]; then
    PRIMARY_IP="${!HOST}"
fi
checkvar PRIMARY_IP

checkvar SERVICES
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

DEDUPLICATED_APPLICABLE_SERVICES=$( for i in "${!APPLICABLE_SERVICES[@]}"; do printf "%s\t%s\n" "$i" "${APPLICABLE_SERVICES[$i]}"; done  | sort -k2 -k1n | uniq -f1 | sort -nk1,1 | cut -f2-  | paste -sd " " - )
APPLICABLE_SERVICES=($DEDUPLICATED_APPLICABLE_SERVICES)

highlight "APPLYING BRANCH $BRANCH TO HOST $PRIMARY_IP: $PHASE"

echo "GOING TO APPLY IN ORDER: ${APPLICABLE_SERVICES[@]}"

declare BUILD_DIR="$DIR/build"
mkdir -p $BUILD_DIR
continue $? "COULD NOT CREATE BUILD DIR: $BUILD_DIR"

case $PHASE in
    setup*)
        mkdir -p $BUILD_DIR
        for service in "${APPLICABLE_SERVICES[@]}"
        do
            if (func_modified "setup_$service") ; then
                warn "[$(date)] SERVICE SETUP MODIFIED: $service"
                setup_$service
                continue $? "[$(date)] SETUP FAILED, SERVICE: $service"
                func_modified "setup_$service" "clear"
            fi
        done
    ;;
    build*)
        if [ "$OPTION" == "--rebuild" ] && [ "$BUILD_DIR" != "/" ]; then
            echo "--REBUILD PURGING $BUILD_DIR"
            rm -rf $BUILD_DIR/**
        fi
        for service in "${APPLICABLE_SERVICES[@]}"
        do
            info "BUILDING SERVICE $service INTO $BUILD_DIR"

            if [ -d "$DIR/lib/$service" ]; then expand_dir "$DIR/lib/$service"; fi
            if [ "$(type -t build_$service)" == "function" ]; then "build_$service"; fi
            func_modified "build_$service" "clear"

        done
        highlight "APPLIED IN $BUILD_DIR"
    ;;
    install*)
        let num_services_affected=0
        for service in "${APPLICABLE_SERVICES[@]}"
        do
            #build and determine the whether the service was affected
            info "BUILDING SERVICE: $service"
            chk1=$(checksum $BUILD_DIR)
            if [ -d "$DIR/lib/$service" ]; then expand_dir "$DIR/lib/$service"; fi
            continue $? "[$(date)] FAILED TO EXPAND SERVICE $servie"

            if [ "$(type -t build_$service)" == "function" ]; then "build_$service"; fi
            continue $? "[$(date)] FAILED TO BUILD SERVICE $servie"

            func_modified "build_$service" "clear"
            func_modified "install_$service" "clear"

            chk2=$(checksum $BUILD_DIR)
            if [ "$chk1" == "$chk2" ]; then
                info "- no diff: $chk2"
                if [ "$(type -t stop_$service)" == "function" ]; then
                    if (func_modified "stop_$service") ; then
                        let num_services_affected=(num_services_affected+1)
                        warn "stop_$service"
                        func_modified "stop_$service" "clear"
                        "stop_$service"
                    fi
                fi
                if [ "$(type -t start_$service)" == "function" ]; then
                    if (func_modified "start_$service") ; then
                        let num_services_affected=(num_services_affected+1)
                        warn "start_$service"
                        func_modified "start_$service" "clear"
                    fi
                fi
            else

                let num_services_affected=(num_services_affected+1)
                warn "[$(date)] INSTALLING SERVICE $service ($chk1 -> $chk2)"

                #service must be stopped before the real build into / becuase jars or other runtime artifact may be modified
                if [ "$(type -t stop_$service)" == "function" ]; then
                    func_modified "stop_$service" "clear"
                    "stop_$service";
                fi

                #now apply the build result to the root of the filesystem
                diff_cp "$BUILD_DIR" "/" "warn"

                #call install hooks on all modules
                if [ "$(type -t install_$service)" == "function" ]; then "install_$service"; fi
                continue $? "[$(date)] FAILED TO INSTALL SERVICE $service"

                #finally start the services
                if [ "$(type -t start_$service)" == "function" ]; then
                    func_modified "start_$service" "clear"
                    "start_$service";
                fi
                continue $? "[$(date)] FAILED TO START $service"
            fi
        done
        if [ "$num_services_affected" == "0" ]; then
            success "[$(date)] NO SERVICES ON THIS HOST WERE AFFECTED"
        else
            success "[$(date)] APPLIED IN /"
        fi
    ;;
    *)
        fail "POSSIBLE PHASES: build, install"
    ;;
esac

