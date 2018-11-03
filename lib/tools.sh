#!/usr/bin/env bash

function fail() {
    message="$1"
    red='\033[0;31m'
    nc='\033[0m'
    echo -e "${red}$message $nc"
    echo ""
    exit 1;
}

function warn() {
    message="$1"
    blue='\033[93m'
    nc='\033[0m'
    echo -e "${blue}$message $nc"
}

function info() {
    message="$1"
    blue='\033[96m'
    nc='\033[0m'
    echo -e "${blue}$message $nc"
}

function success() {
    message="$1"
    green='\033[92m'
    nc='\033[0m'
    echo -e "${green}$message $nc"
}

function highlight() {
    message="$1"
    bold='\033[01m'
    nc='\033[0m'
    echo -e "${bold}$message $nc"
}

function continue() {
    result="$1"
    message="$2"
    if [ $result -ne 0 ]; then
        get_stack
        fail "$message in: $STACK"
    fi
}

function checkvar() {
    expr="echo \$$1"
    value="$(eval $expr)"
    get_stack
    if [ -z "$value" ]; then fail "$1 variable not specified in: $STACK"; fi
}

function get_stack() {
   STACK=""
   local i message="${1:-""}"
   local stack_size=${#FUNCNAME[@]}
   # to avoid noise we start with 1 to skip the get_stack function
   for (( i=1; i<$stack_size; i++ )); do
      local func="${FUNCNAME[$i]}"
      [ x$func = x ] && func=MAIN
      local linen="${BASH_LINENO[$(( i - 1 ))]}"
      local src="${BASH_SOURCE[$i]}"
      [ x"$src" = x ] && src=non_file_source

      STACK+=$'\n'"   at: "$func" "$src" "$linen
   done
   STACK="${message}${STACK}"
}

_LOADED_MODULES_BASH_CD=()
function required() {
    module="$1"
#    if [ ! -z "$2" ]; then
#        expr="echo \$$2"
#        value="$(eval $expr)"
#        if [ ! -z "$value" ]; then module=""; fi
#    fi
    for loaded in "${_LOADED_MODULES_BASH_CD[@]}"; do
        if [ "$loaded" == "$module" ]; then
            info "Already loaded: $module"
            module="";
        fi
    done

    if [ ! -z "$module" ]; then
        _LOADED_MODULES_BASH_CD+=($module)
        source "$( dirname "${BASH_SOURCE[0]}" )/$module/include.sh"
    fi
}

function checksum() {
    if [ -d "$1" ]; then
        if [ "$1" == ".git" ]; then
            echo "0"
        elif [ -z "$(command -v md5sum)" ]; then
            find $1 -type f -exec md5 {} \; | sort -k 2 | md5
        else
            find $1 -type f -exec md5sum {} \; | sort -k 2 | md5sum
        fi
    elif [ -f "$1" ]; then
        #TODO add file permissions to the hash (and use it recursively for directory)
        if [ -z "$(command -v md5sum)" ]; then cat $1 | md5; else cat $1 | md5sum; fi
    fi
}

function func_modified() {
    checkvar BUILD_DIR
    func_name="$1"
    clear_flag="$2"
    if [ "$(type -t $func_name)" == "function" ]; then
        if [ -z "$(command -v md5sum)" ]; then
            def_hash=$(type $func_name | md5)
        else
            def_hash=$(type $func_name | md5sum)
        fi
        def_hash_file="$BUILD_DIR/_$func_name"
        if [ -f "$def_hash_file" ]; then
            prev_hash=$(cat "$def_hash_file")
        fi
        if [ ! -z "$clear_flag" ]; then
            echo "$def_hash" > "$def_hash_file"
        elif [ "$def_hash" != "$prev_hash" ]; then
            return 0
        fi
    fi
    return 1
}

function expand() {
    leadsymbol="$1"
    env=`printenv | cut -d= -f1 | paste -sd "," -`
    params=$(echo $env | tr "," "\n")
    declare line
    expand_line() {
        for varname in ${params[@]}; do
            if [[ $line = *"$varname"* ]]; then
                value="${!varname//\\/_=|=_}" #backslashes in variables need to be masked before the replacement
                line="$( echo "$line" | sed -e "s^$leadsymbol$varname^$value^g" | sed "s/_=|=_n/\\`echo -e '\n\r'`/g" | sed "s/_=|=_/\\`echo -e '\\'`/g")"
            fi
        done
        printf "%s\n" "$line"
    }
    while IFS= read -r line; do expand_line; done; expand_line
}

function expand_dir() {
    shells=(".sh" ".bat" ".bash" ".zsh")
    artifacts=(".jar" ".tar" ".war" ".a" ".so" ".so.1" ".bin" ".exe" ".gz"  ".tgz" ".7z" ".bz2" ".rar" ".zip" ".zipx" ".static.json" ".static.xml")
    env=`printenv | cut -d= -f1 | paste -sd "," -`
    params=$(echo $env | tr "," "\n")
    for varname in ${params[@]}; do
        if [ -z "${!varname}" ]; then
            warn "undefined variable: $varname"
        fi
    done;
    for file in $1/$2/*; do
        filename=$(basename "$file")
        if [ -f "$file" ] && [ ! -z "$2" ]; then
            mkdir -p "$BUILD_DIR/$2"
            is_artifact=0
            for a in "${artifacts[@]}"; do if [[ $filename == *"$a" ]]; then is_artifact=1; break; fi; done
            is_shell=0
            for a in "${shells[@]}"; do if [[ $filename == *"$a" ]]; then is_shell=1; break; fi; done
            if [[ is_artifact -eq 1 ]]; then
                echo "[ARCHIVE ] $2/$filename"
                cat "$file" > "$BUILD_DIR/$2/$filename"
            elif [[ is_shell -eq 1 ]]; then
                echo "[ SCRIPT ] $2/$filename"
                cat "$file" | expand '\$\$' > "$BUILD_DIR/$2/$filename"
            else
                echo "[TEMPLATE] $2/$filename"
                cat "$file" | expand '\$' > "$BUILD_DIR/$2/$filename"
            fi
            continue $? "Could process file $FILE"
            #the chmod with reference file works only in POSIX so muting for OSX
            chmod --reference="$file" "$BUILD_DIR/$2/$filename" > /dev/null 2>&1
        elif [ -d "$file" ]; then
            expand_dir "$1" "$2/$filename"
        fi
    done
}


function diff_cp() {
    for src_file in $1/*; do
        filename=$(basename "$src_file")
        dest_file="$2/$filename"
        if [ -d "$src_file" ]; then
            if [ "$src_file" != ".git" ]; then
                mkdir -p "$dest_file"
                diff_cp "$src_file" "$dest_file" "$3"
            fi
        elif [ -f "$src_file" ] && [[ "$dest_file" != //_* ]]; then
            #TODO if [ -L "$src_file" ]; then create ln and calculate the target path instead cp; fi
            if [ ! -f "$dest_file" ] || [ "$(checksum $src_file)" != "$(checksum $dest_file)" ]; then
                if [ "$3" == "info" ]; then info "$dest_file"; fi
                if [ "$3" == "warn" ]; then warn "$dest_file"; fi
                mkdir -p "$(dirname "$dest_file")"
                cp -f "$src_file" "$dest_file"
            fi
        fi
    done
}

function download() {
    url=$1
    file_name="$(basename $1)"
    dest_dir=$2
    local_tarball="$dest_dir/$(basename $url)"
    local="$dest_dir/$file_name"
    if [ ! -f "$local" ]; then
        info "Downloading $(basename $url)"
        mkdir -p $(dirname $local)
        curl -Ls "$url" > "${local}.tmp"
        mv "${local}.tmp" "$local"
        if [ "$3" == "md5" ]; then
            info "Downloading $(basename $url).md5"
            curl -Ls "$url.md5" > "$local.md5"
            if [ $? -ne 0 ]; then
                rm $local
                fail "md5 checksum download failed: $url.md5"
            fi
            local_md5="$(checksum "$dest_dir/$file_name")"
            remote_md5=$(cat "$dest_dir/$file_name.md5")
            if [[ "$local_md5" != $remote_md5* ]]; then
             rm $local
             fail "download checksum failed for $url"
            fi
        fi
    fi
}

function clone() {
    url=$1
    dest_dir=$2
    branch=$3
    if [ ! -d "$dest_dir" ]; then
        git clone "$url" $dest_dir
    fi
    cd "$dest_dir"
    git fetch
    git reset --hard
    git checkout "$branch"

}

function git_local_revision() {
    branch=$(git rev-parse --abbrev-ref HEAD)
    git rev-parse $branch
}

function git_remote_revision() {
    git remote update &> /dev/null
    branch=$(git rev-parse --abbrev-ref HEAD)
    git rev-parse origin/$branch
}


function git_clone_or_update() {
    git_url="$1"
    local_dir="$2"
    branch="$3"

    cd "$local_dir"

    checkbranch() {
        checkvar branch
        git fetch
        continue $? "COULD NOT EXECUTE: git fetch"
        git reset --hard
        continue $? "COULD NOT EXECUTE: git reset --hard"
        git checkout $branch
        continue $? "COULD NOT EXECUTE: git checkout \"$branch\""
    }

    git rev-parse -q --verify "refs/tags/$branch" &> /dev/null;
    if [ $? -eq 0 ]; then
        echo "CLONING TAG $branch INTO $local_dir"
        clone "$git_url" "$local_dir" "$branch"
    else
        echo "CLONING BRANCH $branch INTO $local_dir"
        if [ ! -d "$local_dir/.git" ]; then
            mkdir -p "$local_dir"
            git clone "$git_url" "$local_dir"
            continue $? "COULD NOT EXECUTE: git clone \"$git_url\"  \"$local_dir\""
            checkbranch
        else
            checkbranch
            echo "CHECKING FOR UPDATES IN: $local_dir"
            if [ "$(git_local_revision)" != "$(git_remote_revision)" ]; then
                git pull
                continue $? "COULD NOT PULL LATEST CHANGES FROM $git_url INTO $local_dir"
            fi
        fi
    fi
}

wait_for_ports() {
    while IFS=',' read -r address
    do
        if [[ $address == *"://"* ]]; then
            Y=(${address//\// })
            address=${Y[1]}
        fi
        IN=(${address//:/ })
        host=${IN[0]}
        port=${IN[1]}
        WAIT=30
        while ! nc -z $host $port 1>/dev/null 2>&1; do
            echo -en "\rWaiting for HOST $host PORT:$port ... $WAIT    ";
            sleep 1
            let WAIT=WAIT-1
            if [ $WAIT -eq 0 ]; then
                fail "Failed waiting for HOST:$host PORT:$port"
            fi
        done
        echo -en "\n"

    done <<< "$1"
}

wait_for_endpoint() {
    URL=$1
    EXPECTED=$2
    MAX_WAIT=$3
    while [  $MAX_WAIT -gt 0 ]; do
         echo -en "\r$URL $MAX_WAIT";
         RESPONSE_STATUS=$(curl --stderr /dev/null GET -i "$URL" | head -1 | cut -d' ' -f2)
         if [ ! -z $RESPONSE_STATUS ] ; then
            if [ "$RESPONSE_STATUS" != "$EXPECTED" ]; then
                fail "\rUNEXPECTED RESPONSE_STATUS $RESPONSE_STATUS FOR $URL"
            else
                echo -en "\r"
                return 0;
            fi
         fi
         let MAX_WAIT=MAX_WAIT-1
         sleep 1
    done
    fail "TIMEOUT WHILE WAITING FOR ENDPOINT: $URL"
}