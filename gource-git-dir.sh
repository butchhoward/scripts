#!/usr/bin/env bash


function show_help()
{

cat<<EOF


Present pretty OpenGL display of activity in git repositories.

Requires:
    gource http://gource.io/ 
    bash version >= 4.x to get associate array support

    A folder with folders beneath it which are git repositories

Usage:
    gource-git-dir.sh [-p ProjectName] [-r RemoteOrigin] [-b BranchesToDisplay] [-i [PollingInterval] [-- GOURCE_OPTIONS]
        -p ProjectName - defaults to "Base"
            This is a name to aide gource in displaying multiple branches
            It will also be displayed in the lower left of the window

        -r RemoteOrigin - defaults to "origin"
            This is the git remote for fetching and displaying logs from

        -b BranchesToDisplay - defaults to "master"
            A comma-delimited list of branch names that will be used to display logs
            Example: "master,develop"
            It's best if all the branches listed exist in all the repos. If that is not true, 
              it will not stop the script from gathering the logs from the branches that
              do exist. You will see some error output about the problems.

        -i PollingInterval - defaults to 10
            The delay between polling cycles for fetching new commit logs

    Pass gource options to the gource invocation by putting '--' after all the options for gource-git-dir
    and then the gource options. gource is run with some options already set:
        gource --title "${TITLE}" --key \
                                --fullscreen \
                                --hide root,usernames,filenames,mouse \
                                --log-format custom \
                                --file-idle-time 0 \
                                --max-files 0
                                
    See the gource wiki for listings of its options.

Example:

Given the folder structure below where all of the folders under ./prpl are git repositories
And ./prpl is the current directory
And the script is run as 
    gource-git-dir.sh -p Loop -r origin -b master,develop -i 10 -- --background-colour FFFFFF

Then a beautiful display graphic of changes to the repositories will be displayed.
The display is fullscreen. Press <esc> to exit. See the gource wiki for shortcut keys to modify
The display while it is running.

./prpl
  |-pRpl
  |-pRpl-CAN
  |-pRpl-dev-tools
  |-pRpl-MOST
  |-pRpl-rest-client

The display will first show how the repositories evolved over time from the initial commits. When
it catches up to the current state, then it will poll each interval for new commits to display.

Inspired by a similar display at a client site.
Some script ideas based on code at https://github.com/whitewhidow/gource-live
EOF

}

echoerr() 
{ 
    printf "%s\n" "$*" >&2
}

function gource_consume()
{
    local TITLE=$1
    shift
    gource --title "${TITLE}" --key \
                              --fullscreen \
                              --hide root,usernames,filenames,mouse \
                              --log-format custom \
                              --file-idle-time 0 \
                              --max-files 0 \
                              $@ \
                              - <&0
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
                            echo "$PREFIX$(prepend_base_to_path ${PROJECT_BASE}/${d}/${B} ${SUFFIX})" >> $STAGE_FILE
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

# A POSIX variable
OPTIND=1         # Reset in case getopts has been used previously in the shell.

PROJECT_BASE="BASE"
REMOTE="origin"
BRANCH="master"
INTERVAL=10

while getopts "hp:r:b:i:" opt; do
    case "$opt" in
    h|\?)
        show_help
        exit 0
        ;;
    p)  PROJECT_BASE=$OPTARG
        ;;
    r)  REMOTE=$OPTARG
        ;;
    b)  BRANCH=$OPTARG
        ;;
    i)  INTERVAL=$OPTARG
        ;;
    esac
done

shift $((OPTIND-1))
[ "$1" = "--" ] && shift

git_supply $PROJECT_BASE $REMOTE $BRANCH $INTERVAL | gource_consume $PROJECT_BASE "$@"
