#!/usr/bin/env bash

function fail() {
    message="$1"
    red='\033[0;31m'
    nc='\033[0m'
    echo -e "${red}$message $nc"
    exit 1;
}

function warn() {
    message="$1"
    blue='\033[93m'
    nc='\033[0m'
    echo -e "${blue}$message $nc"
}

function log() {
    echo -e "$1"
}

function logn() {
    echo -en "$1"
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
        fail "exit code: $result\n$message in: $STACK"
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

APPLICABLE_MODULES=()
_APPLYING_MODULES_BASH_CD=()
function apply() {
  if [ "$PRIMARY_IP" == "-" ]; then
    #only loading module definitions
    return
  fi
  local module="$1"
  for appplying  in "${_APPLYING_MODULE_BASH_CD[@]}"; do
    if [ "$module" == "$appplying" ]; then
      return
    fi
  done
  _APPLYING_MODULE_BASH_CD+=("$module")
  for applied in "${APPLICABLE_MODULES[@]}"; do
      if [ "$applied" == "$module" ]; then
          #log "Already applied: $module"
          return
      fi
  done
#  info "going to apply module: $module"
  required $module
  APPLICABLE_MODULES+=("$module")
}

_LOADED_MODULES_BASH_CD=()
function required() {
    local module="$1"
    for loaded in "${_LOADED_MODULES_BASH_CD[@]}"; do
        if [ "$loaded" == "$module" ]; then
            #log "Already loaded: $module"
            module="";
        fi
    done

    if [ ! -z "$module" ]; then
        source "$( dirname "${BASH_SOURCE[0]}" )/$module/include.sh"
        if [ "$PRIMARY_IP" == "-" ]; then
            log "Exporting module definitions: $module"
        else
#          log "Loading module definition: $module"
          _LOADED_MODULES_BASH_CD+=($module)
        fi
    fi
}

function ensure() {
    cmd=$1
    instruction=$2
    if [ -z "$(command -v $cmd)" ]; then
        eval "${instruction}"
    fi
    continue $? "could not install command: $cmd"
}

#usage: eval $(parse_yaml filename.yaml) - will define toplevel yaml values as variables
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
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

_NO_EXPAND_BASH_CD=()
function no_expand() {
    _NO_EXPAND_BASH_CD+=("`dirname ${BASH_SOURCE[1]}`/$1")
}

function expand_dir() {
    if [ ! -z "$2" ]; then
        dir="$1""$2";
        mkdir -p `dirname ${BUILD_DIR}$2`
    else
        dir="$1"
    fi
    for nexp in "${_NO_EXPAND_BASH_CD[@]}"; do
        if [ "$nexp" == "$dir" ]; then
            target=`dirname ${BUILD_DIR}$2`/
            log "[STATIC] $dir"
            cp -r $dir $target
            return
        fi
    done
    shells=(".sh" ".bat" ".bash" ".zsh")
    artifacts=(".crt" ".pem" ".p12" ".key" ".cc" ".c" ".h" ".jks" ".jar" ".java" ".scala" ".class" ".tar" ".war" ".a" ".so" ".so.1" ".bin" ".exe" ".js" ".gz" ".tgz" ".7z" ".bz2" ".rar" ".zip" ".zipx")
    for file in $dir/*; do
        filename=$(basename "$file")
        if [ -f "$file" ] && [ ! -z "$2" ]; then
            mkdir -p "$BUILD_DIR/$2"
            is_artifact=0
            for a in "${artifacts[@]}"; do if [[ $filename == *"$a" ]]; then is_artifact=1; break; fi; done
            is_shell=0
            for a in "${shells[@]}"; do if [[ $filename == *"$a" ]]; then is_shell=1; break; fi; done
            if [[ is_artifact -eq 1 ]]; then
                cp "$file" "$BUILD_DIR/$2/$filename"
            elif [[ is_shell -eq 1 ]]; then
                log "[ SCRIPT ] $2/$filename"
                cat "$file" | expand '\$\$' > "$BUILD_DIR/$2/$filename"
            else
                log "[TEMPLATE] $2/$filename"
                cat "$file" | expand '\$' > "$BUILD_DIR/$2/$filename"
            fi
            continue $? "Could process file $FILE"
            #the chmod with reference file works only in POSIX so muting for OSX
            chmod --reference="$file" "$BUILD_DIR/$2/$filename" > /dev/null 2>&1 || true
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
        info "Downloading $(basename $url) into $local"
        mkdir -p $(dirname $local)
        curl --progress-bar -Ls "$url" > "${local}.tmp"
        continue $? "could not download: $url"
        mv "${local}.tmp" "$local"
        continue $? "cant move download, no such file ${local}.tmp"
        if [ "$3" == "md5" ]; then
            info "Downloading $(basename $url).md5"
            curl -Ls "$url.md5" > "$local.md5"
            if [ $? -ne 0 ]; then
#                rm $local
                fail "md5 checksum download failed: $url.md5"
            fi
            local_md5="$(checksum "$dest_dir/$file_name" | cut -d ' ' -f 1)"
            remote_md5=$(cat "$dest_dir/$file_name.md5" | cut -d ' ' -f 1)
            if [[ "$local_md5" != "$remote_md5" ]]; then
#             rm $local
             fail "download checksum failed for $url"
            fi
        elif [ "$3" == "sha256" ]; then
           local_sha256="$(sha256sum "$local")"
           remote_sha256="$4"
           if [[ "$local_sha256" != $remote_sha256* ]]; then
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
    git checkout "$branch" 2>&1
}

function git_local_revision() {
    branch=$(git rev-parse --abbrev-ref HEAD)
    if [ $? -eq 0 ]; then
        git rev-parse $branch
    else
        echo "--"
    fi
}

function git_remote_revision() {
    branch=$(git rev-parse --abbrev-ref HEAD)
    if [ $? -eq 0 ]; then
        git remote update &> /dev/null
        git rev-parse origin/$branch
    else
        echo "--"
    fi
}

function git_clone_or_update() {
    git_url="$1"
    local_dir="$2"
    branch="$3"

    if [ ! -d "$local_dir/.git" ]; then
        mkdir -p "$local_dir"
        git clone "$git_url" "$local_dir"
        continue $? "COULD NOT EXECUTE: git clone \"$git_url\"  \"$local_dir\""
    fi

    cd "$local_dir"

    checkbranch() {
        checkvar branch
        git fetch
        continue $? "COULD NOT EXECUTE: git fetch in $PWD"
        git reset --hard
        continue $? "COULD NOT EXECUTE: git reset --hard"
        git checkout $branch 2>&1
        continue $? "COULD NOT EXECUTE: git checkout \"$branch\""
    }

    git rev-parse -q --verify "refs/tags/$branch" &> /dev/null;
    if [ $? -eq 0 ]; then
        log "CLONING TAG $branch INTO $local_dir"
        clone "$git_url" "$local_dir" "$branch"
    else
        log "CLONING BRANCH $branch INTO $local_dir"
        if [ ! -d "$local_dir/.git" ]; then
            mkdir -p "$local_dir"
            git clone "$git_url" "$local_dir"
            continue $? "COULD NOT EXECUTE: git clone \"$git_url\"  \"$local_dir\""
            cd "$local_dir"
            checkbranch
        else
            checkbranch
            log "CHECKING FOR UPDATES IN: $local_dir"
            if [ "$(git_local_revision)" != "$(git_remote_revision)" ]; then
                git pull
                continue $? "COULD NOT PULL LATEST CHANGES FROM $git_url INTO $local_dir"
            fi
        fi
    fi
}

wait_for_ports() {
    WAIT=$1
    while IFS=, read -ra addresses
    do
        for address in "${addresses[@]}"; do
            if [[ $address == *"://"* ]]; then
                Y=(${address//\// })
                address=${Y[1]}
            fi
            IN=(${address//:/ })
            host=${IN[0]}
            port=${IN[1]}

            while ! nc -z $host $port 1>/dev/null 2>&1; do
                logn "\rWaiting for HOST $host PORT:$port ... $WAIT    ";
                sleep 1
                let WAIT=WAIT-1
                if [ $WAIT -eq 0 ]; then
                    fail "Failed waiting for HOST:$host PORT:$port"
                fi
            done
            logn  "\n"
        done

    done <<< "$2"
}

wait_for_endpoint() {
    URL=$1
    EXPECTED=$2
    MAX_WAIT=$3
    while [  $MAX_WAIT -gt 0 ]; do
         logn "\r$URL $MAX_WAIT";
         RESPONSE_STATUS=$(curl --stderr /dev/null -X GET -i "$URL" | head -1 | cut -d' ' -f2)
         if [ ! -z $RESPONSE_STATUS ] ; then
            if [[ $EXPECTED == *$RESPONSE_STATUS* ]]; then
                logn "\r"
                return 0;
            fi
         fi
         let MAX_WAIT=MAX_WAIT-1
         sleep 1
    done
    fail "TIMEOUT WHILE WAITING FOR ENDPOINT: $URL"
}


function urlDecocde() {
  local value=${*//+/%20}                   # replace +-spaces by %20 (hex)
  for part in ${value//%/ \\x}; do          # split at % prepend \x for printf
    printf "%b%s" "${part:0:4}" "${part:4}" # output decoded char
  done
}

