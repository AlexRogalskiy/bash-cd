#!/usr/bin/env bash

checkvar PRIMARY_IP
checkvar ZOOKEEPER_CONNECTION
checkvar KAFKA_CONNECTION
checkvar EXAMPLE_APP_SERVERS
checkvar EXAMPLE_APP_BRANCH

for i in "${!EXAMPLE_APP_SERVERS[@]}"
do
   server="${EXAMPLE_APP_SERVERS[$i]}"
   if [ "$server" == "$PRIMARY_IP" ]; then
    required "openjdk8"
    APPLICABLE_SERVICES+=("example-app")
   fi
done

build_example-app() {
    export EXAMPLE_APP_HOME="/opt/example-app"
    #git_clone_or_update https://github.com/my-organizaion/example-app.git "$EXAMPLE_APP_HOME" "$EXAMPLE_APP_BRANCH"
    diff_cp "$EXAMPLE_APP_HOME" "$BUILD_DIR/$EXAMPLE_APP_HOME"
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

