#!/usr/bin/env bash

checkvar PRIMARY_IP
checkvar ZOOKEEPER_CONNECTION
checkvar KAFKA_CONNECTION
checkvar EXAMPLE_APP_SERVERS

EXAMPLE_APP_HOME="/opt/example-app"

for i in "${!EXAMPLE_APP_SERVERS[@]}"
do
   server="${EXAMPLE_APP_SERVERS[$i]}"
   if [ "$server" == "$PRIMARY_IP" ]; then
    required "openjdk8"
    APPLICABLE_SERVICES+=("example-app")
   fi
done

build_example-app() {
    git_clone_or_update https://github.com/my-organizaion/example-app.git $EXAMPLE_APP_HOME
    if [ $? -ne 0 ]; then
        info "COMPILING FROM SOURCES.."
        ./gradlew --no-daemon -q compileScala --exclude-task test
    fi
    diff_cp $EXAMPLE_APP_HOME/build $BUILD_DIR/$EXAMPLE_APP_HOME/build
}

install_example-app() {
    cd $EXAMPLE_APP_HOME
    ./gradlew --no-daemon -q shadowJar --exclude-task test
    systemctl daemon-reload
    systemctl enable example-app.service
}

start_example-app() {
    #start -q example-app
	systemctl start example-app.service
}

stop_example-app() {
    #stop -q example-app
    systemctl stop example-app.service
}

