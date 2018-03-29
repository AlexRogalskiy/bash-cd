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
    if [ -d "$1" ]; then
        if [ -z "$(command -v md5sum)" ]; then
            find $1 -type f -exec md5 {} \; | sort -k 2 | md5
        else
            find $1 -type f -exec md5sum {} \; | sort -k 2 | md5sum
        fi
    else
        if [ -z "$(command -v md5sum)" ]; then cat $1 | md5; else cat $1 | md5sum; fi
    fi
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
                line=$( echo $line | sed -e "s^\$$a^$v^g" )
            fi
        done
        printf "%s\n" "$line"
    }
    IFS=''; while read line; do IFS=$'\n'; expand_line; IFS=''; done; IFS=$'\n'; expand_line
}

expand_dir() {
    artifacts=(".sh" ".jar" ".tar" ".war" ".so" ".exe" ".gz"  ".tgz" ".7z" ".bz2" ".rar" ".zip" ".zipx")
    for file in $1/$2/*; do
        filename=$(basename "$file")
        if [ -f "$file" ] && [ ! -z "$2" ]; then
            mkdir -p "$BUILD_DIR/$2"
            is_artifact=0
            for a in "${artifacts[@]}"; do if [[ $filename == *"$a" ]]; then is_artifact=1; break; fi; done
            if [[ is_artifact -eq 1 ]]; then
                echo "[ARTIFACT] $2/$filename"
                cat "$file" > "$BUILD_DIR/$2/$filename"
            else
                echo "[TEMPLATE] $2/$filename"
                cat "$file" | expand > "$BUILD_DIR/$2/$filename"
            fi
            continue $? "Could process file $FILE"
            #the chmod with reference file works only in POSIX so muting for OSX
            chmod --reference="$file" "$BUILD_DIR/$2/$filename" > /dev/null 2>&1
        elif [ -d "$file" ]; then
            expand_dir "$1" "$2/$filename"
        fi
    done
}


diff_cp() {
    for src_file in $1/*; do
        filename=$(basename "$src_file")
        dest_file="$2/$filename"
        if [ -d "$src_file" ]; then
            mkdir -p "$dest_file"
            diff_cp "$src_file" "$dest_file"
        elif [ -f "$src_file" ]; then
            if [ ! -f "$dest_file" ] || [ "$(checksum $src_file)" != "$(checksum $dest_file)" ]; then
                cp -f "$src_file" "$dest_file"
            fi
        fi
    done
}
