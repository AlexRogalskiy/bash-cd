#!/usr/bin/env bash

checkvar PRIMARY_IP
checkvar ZOOKEEPER_CONNECTION
checkvar KAFKA_CONNECTION
checkvar EXAMPLE_APP_SERVERS

for i in "${!EXAMPLE_APP_SERVERS[@]}"
do
   server="${EXAMPLE_APP_SERVERS[$i]}"
   if [ "$server" == "$PRIMARY_IP" ]; then
    APPLICABLE_SERVICES+=("example-app")
   fi
done

build_example-app() {
    if [ ! -d "/opt/example-app" ]; then
        mkdir -p $BUILD_DIR/opt
        #git clone ...
    fi
    cd "/opt/example-app"
    git pull
    info "Compiling example-app from sources"
    #./gradlew --no-daemon -q compileScala --exclude-task test
    if [ "$BUILD_DIR" != "/" ]; then
        mkdir -p "$BUILD_DIR/opt/example-app/build"
        #cp -r /opt/example-app/build/classes "$BUILD_DIR/opt/example-app/build"
        #cp -r /opt/example-app/*.gradle "$BUILD_DIR/opt/example-app"
    fi
}

install_example-app() {
    cd "/opt/example-app"
    #./gradlew --no-daemon -q shadowJar --exclude-task test
}

start_example-app() {
    start -q example-app
}

stop_example-app() {
    stop -q example-app
}

