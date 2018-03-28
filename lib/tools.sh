#!/usr/bin/env bash

fail() {
    message="$1"
    red='\033[0;31m'
    nc='\033[0m'
    echo -e "${red}$message $nc"
    echo ""
    exit 1;
}

warn() {
    message="$1"
    blue='\033[93m'
    nc='\033[0m'
    echo -e "${blue}$message $nc"
}

info() {
    message="$1"
    blue='\033[96m'
    nc='\033[0m'
    echo -e "${blue}$message $nc"
}

success() {
    message="$1"
    green='\033[92m'
    nc='\033[0m'
    echo -e "${green}$message $nc"
}

highlight() {
    message="$1"
    bold='\033[01m'
    nc='\033[0m'
    echo -e "${bold}$message $nc"
}

continue() {
    result="$1"
    message="$2"
    if [ $result -ne 0 ]; then
        fail "$message"
    fi
}

checkvar() {
    expr="echo \$$1"
    value="$(eval $expr)"
    if [ -z "$value" ]; then fail "$1 variable not specified"; fi
}

checksum() {
    target="$1"
    find $target -type f -exec md5sum {} \; | sort -k 2 | md5sum
}

download() {
    url=$1
    file_name="$(basename $1)"
    dest_dir=$2
    local_tarball="$dest_dir/$(basename $url)"
    local="$dest_dir/$file_name"
    if [ ! -f "$local" ]; then
        info "Downloading $(basename $url)..."
        mkdir -p $(dirname $local)
        curl -s "$url" > "${local}.tmp"
        mv "${local}.tmp" "$local"
    fi
}

clone() {
    url=$1
    dest_dir=$2
    branch=$3
    if [ ! -d "$dest_dir" ]; then
        git clone "$url" $dest_dir
    fi
    cd "$dest_dir"
    git checkout "$branch"

}

expand() {
    env=`printenv | cut -d= -f1 | paste -sd "," -`
    params=$(echo $env | tr "," "\n")
    declare line
    expand_line() {
        for a in ${params[@]}; do
            if [[ $line = *"$a"* ]]; then
                v="${!a}"
                #FIXME there are issues here for example with xmls like logback.xml
                line=$( echo $line | sed -e "s^\$$a^$v^g" )
            fi
        done
        #TODO there might be other cases when printf is not a good idea
        if [[ $line == *"%"* ]]; then
            echo "$line"
        else
            printf "$line\n"
        fi
    }
    IFS=''; while read line; do IFS=$'\n'; expand_line; IFS=''; done; IFS=$'\n'; expand_line
}

expand_dir() {
    for file in $1/$2/*; do
        filename=$(basename "$file")
        if [ -f "$file" ] && [ ! -z "$2" ]; then
            mkdir -p "$BUILD_DIR/$2"
            echo "$2/$filename"
            cat "$file" | expand > "$BUILD_DIR/$2/$filename"
            continue $? "Could process file $FILE"
            if [ "$1" == "/" ]; then chmod --reference="$file" "$BUILD_DIR/$2/$filename"; fi
        elif [ -d "$file" ]; then
            expand_dir "$1" "$2/$filename"
        fi
    done
}