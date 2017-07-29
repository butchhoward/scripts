#!/usr/bin/env bash

echoerr() 
{ 
    printf "%s\n" "$*" >&2
}

function gource_consume()
{
    local TITLE=$1
    gource --title "${TITLE}" --key --hide root,usernames,filenames,mouse --log-format custom --file-idle-time 0 - <&0
}

function prepend_base_to_path()
{
    #A|images/discussions/2017-06-09_CAN-In-A-Box/can-in-a-box.jpg
    local PROJECT_BASE=$1
    local STATUS_AND_PATH=$2
    echo ${STATUS_AND_PATH} | sed -E "s#(.+)\|#\1|${PROJECT_BASE}/#"

}

function git_supply()
{
    local PROJECT_BASE=$1
    local REMOTE=$2
    local BRANCH=$3
    local INTERVAL=$4
  
    local STAGE_FILE="/tmp/gource_staging.txt"
    rm $STAGE_FILE &>/dev/null
  
    #requires Bash 4.x - associative array using directory name as key
    declare -A SHAS=()
    IFS=', ' read -r -a BRANCHES <<< "$BRANCH"

    while true
    do

        for d in `ls -d *`;do 
            if [ -d $d/.git ]; then 

                pushd $d &> /dev/null

                local INITIAL_COMMIT_SHA=$(git rev-list --max-parents=0 HEAD)

                for B in "${BRANCHES[@]}"; do
                    
                    git fetch $REMOTE "${B}" >/dev/null 2>&1

                    local BRANCH_KEY="${d}_${B}"

                    local SHA=${SHAS["$BRANCH_KEY"]:-"${INITIAL_COMMIT_SHA}"}

                    for SHA in $(git rev-list --reverse --first-parent $SHA..$REMOTE/$B)
                    do
                        AUTHOR=$(git log --format=%an $SHA --max-count=1)
                        TIMESTAMP=$(git log --format=%at $SHA --max-count=1)
                        PREFIX="$TIMESTAMP|$AUTHOR|"
                        git diff-tree -r --no-commit-id --name-status $SHA | tr '\t' '|' | while read SUFFIX
                        do
                            echo "$PREFIX$(prepend_base_to_path ${PROJECT_BASE}/${B} ${SUFFIX})" >> $STAGE_FILE
                        done
                    done

                    SHAS["${BRANCH_KEY}"]=$SHA

                done
                popd &> /dev/null

            fi
        done

        #the output from the sort is the output for gource
        if [ -e "${STAGE_FILE}" ]; then
            sort -n "${STAGE_FILE}"
            rm $STAGE_FILE &>/dev/null
        fi

        test $INTERVAL = 0 && break
        sleep $INTERVAL
    done
}

#todo: optags
PROJECT_BASE="${1:-BASE}"
REMOTE=${2:-"origin"}
BRANCH=${3:-"master"}
INTERVAL=${4:-10}

git_supply $PROJECT_BASE $REMOTE $BRANCH $INTERVAL | gource_consume $PROJECT_BASE
