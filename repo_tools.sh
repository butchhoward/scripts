#!/usr/bin/env bash
#source this script to get the useful functions


function repo_base_dir()
{
    git rev-parse --show-toplevel 2>/dev/null
}

function repo_current_branch()
{
    git rev-parse --abbrev-ref HEAD
}

# The do_it functions apply everything on the command-line as a command in each git folder below the current one
# I have not figured out exaclty how to execute complex things in that command
# So:
#       repo_do_it_to_all git checkout main
#
# works, but something more complicated will not:
#       repo_do_it_to_all_quietly  if ! repo_is_clean; then git status; fi;

# will fail
#
# You can work around this by putting complicated things in a function and using the function
#       function do_this() { if ! repo_is_clean; then git status; fi; }
#       repo_do_it_to_all_quietly do_this
#
# (anything more complicated than that should be scripted on its own)

function repo_do_it_to_all()
{
    for d in ./*;do
        if [[ -d "$d" ]] && [[ -d "$d"/.git ]]; then
            pushd "$d" &> /dev/null || exit 1
            echo ""
            echo "====$(pwd)===>[$*]"
            "$@"
            popd &> /dev/null || exit 1
        fi;
    done
}

function repo_do_it_to_all_quietly()
{
    for d in ./*;do
        if [[ -d "$d" ]] && [[ -d "$d"/.git ]]; then
            pushd "$d" &> /dev/null || exit 1
            "$@"
            popd &> /dev/null || exit 1
        fi;
    done
}

function repo_do_it_to_all_very_quietly()
{
    for d in ./*;do
        if [[ -d "$d" ]] && [[ -d "$d"/.git ]]; then
            pushd "$d" &> /dev/null || exit 1
            "$@" &> /dev/null
            popd &> /dev/null || exit 1
        fi;
    done
}

repo_is_clean()
{

    #untrack files (and modified and deleted. might be redundant of the other checks)
    local count
    count=$(( $(git ls-files --other --modified  --deleted --directory --exclude-standard | wc -l) ))
    if [[ ${count} -ne 0 ]]; then
        return 3
    fi

    git update-index -q --ignore-submodules --refresh

    # unstaged changes in the working tree
    if ! git diff-files --quiet --ignore-submodules --
    then
        return 1
    fi

    # uncommitted changes in the index
    if ! git diff-index --cached --quiet HEAD --ignore-submodules --
    then
        return 2
    fi

    return 0
}

function repo_fetch_all()
{
    repo_do_it_to_all "git fetch --all"
}

function repo_update_to_branch()
{
    local BRANCH=${1:-"main"}

    git fetch --all
    if ! git show-ref --quiet --verify -- "refs/remotes/origin/${BRANCH}" ; then
        echo "'origin/${BRANCH}' does not exist. Nothing to do."
    else
        git checkout "${BRANCH}"
        git reset --hard origin/"${BRANCH}"
    fi
 }

function repo_update_to_main()
{
    repo_update_to_branch main
}

function repo_update_all_to_main()
{
    repo_do_it_to_all repo_update_to_main
}

function repo_update_all_to_branch()
{
    local BRANCH=${1:-"main"}

    repo_do_it_to_all repo_update_to_branch "${BRANCH}"
}

function repo_status_all()
{
    repo_do_it_to_all git status
}

function repo_clean_fdx()
{
    local -a EXTRA_ARGS
    if [[ $# -eq 0 ]];then
        EXTRA_ARGS=("--exclude=.vscode" "--exclude=.idea")
    else
        EXTRA_ARGS=("$@")
    fi
    git clean -fdx "${EXTRA_ARGS[@]}"
}

function repo_clean_fdx_all()
{
    local -a EXTRA_ARGS
    if [[ $# -eq 0 ]];then
        EXTRA_ARGS=("--exclude=.vscode" "--exclude=.idea")
    else
        EXTRA_ARGS=("$@")
    fi
    repo_do_it_to_all "git clean -fdx ${EXTRA_ARGS[*]}"
}

function repo_prune_remote_branches()
{
    for remote_name in $(git remote); do
        git remote prune "$remote_name"
    done
}

# Have a care, this deletes them ALL it does not check whether they have been pushed or merged.
# It does not remove commits, so you can probably get back to the code (at least until a purge happens)
function repo_delete_all_local_branches()
{
    local MAIN_BRANCH=${1:-"main"}

    if ! git show-ref --quiet --verify -- "refs/heads/${MAIN_BRANCH}" ; then
        echo "'${MAIN_BRANCH}' does not exist. It is not safe to delete all the things."
        return 1
    fi

    git checkout "${MAIN_BRANCH}"
    for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
        if [ "$branch" != "${MAIN_BRANCH}" ]; then
            git branch -D "$branch"
        fi
    done
    repo_prune_remote_branches
}

function repo_wip_merge()
{
    BASE_BRANCH=${1:-"$(repo_current_branch)"}
    local WIP_BRANCH="__wip__"

    git checkout "${BASE_BRANCH}" || return $?
    git merge --ff-only "${WIP_BRANCH}" || return $?
    git branch -d "${WIP_BRANCH}" || return $?
}

function repo_wip_rebase()
{
    BASE_BRANCH=${1:-"$(repo_current_branch)"}
    local WIP_BRANCH="__wip__"

    git branch -D "${WIP_BRANCH}" &> /dev/null

    git branch "${WIP_BRANCH}" || return $?
    git reset --hard "origin/${BASE_BRANCH}" || return $?
    git checkout "${WIP_BRANCH}" || return $?
    git rebase "${BASE_BRANCH}" || return $?
    # if there are merge conflicts, resolve them and then
    repo_wip_merge "${BASE_BRANCH}"
}

function repo_committers()
{
    local PARENT=${1:-"main"}
    local CURRENT_BRANCH
    CURRENT_BRANCH=${2:-"$(repo_current_branch)"}

    local -A COMMITTERS
    while read -r COMMITTER; do
        COMMITTERS["${COMMITTER}"]=1
    done < <(git log --format='Co-authored-by: %cn <%ce>' "${PARENT}".."${CURRENT_BRANCH}")
    printf "%s\n" "${!COMMITTERS[@]}"
}

function repo_squash_branch()
{
    local COMMIT_SUMMARY=${1:?"commit summary is required!"}
    local PARENT=${2:-"main"}

    local CURRENT_BRANCH
    CURRENT_BRANCH="$(repo_current_branch)"
    echo "Squashing Current Branch '${CURRENT_BRANCH}' relative to '${PARENT}'"

    local COMMIT_MSG
    read -r -d '' COMMIT_MSG <<- EOM
${COMMIT_SUMMARY}

Squashed '${CURRENT_BRANCH}' relative to '${PARENT}'
------------
$(git log --format='%B%n' "${PARENT}".."${CURRENT_BRANCH}")
------------
$(repo_committers "${PARENT}" "${CURRENT_BRANCH}")

Files Modified
--------------
$(git diff --name-status "${PARENT}".."${CURRENT_BRANCH}")

EOM

    git reset "$(git merge-base "${PARENT}" "${CURRENT_BRANCH}")" || return 2
    git add -A
    git commit -m "${COMMIT_MSG}"
}
