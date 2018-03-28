#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $DIR/lib/tools.sh


BRANCH="$1"

if [ -z "$BRANCH" ]; then
    echo "Usage: ./deploy.sh <branch>"
    exit 1;
fi

cd $DIR
git checkout $BRANCH
continue $? "failed to checkout $BRANCH"
git merge master
continue $? "failed to merge master into $BRANCH"
git push
continue $? "failed to push to remote $BRANCH"
git checkout master

