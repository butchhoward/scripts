#!/usr/bin/env bash
#source this script to get the useful functions


function repo_base_dir()
{
    git rev-parse --show-toplevel 2>/dev/null
}

# The do_it functions apply everything on the command-line as a command in each git folder below the current one
# I have not figured out exaclty how to execute complex things in that command
# So:
#       repo_do_it_to_all git checkout trunk
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
    if [[ count -ne 0 ]]; then
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
    local BRANCH=${1:-"trunk"}

    git fetch --all
    if ! git show-ref --quiet --verify -- "refs/remotes/origin/${BRANCH}" ; then
        echo "'origin/${BRANCH}' does not exist. Nothing to do."
    else
        git checkout "${BRANCH}"
        git reset --hard origin/"${BRANCH}"
    fi
 }

function repo_update_to_trunk()
{
    repo_update_to_branch trunk
}

function repo_update_all_to_trunk()
{
    repo_do_it_to_all repo_update_to_trunk
}

function repo_update_all_to_branch()
{
    local BRANCH=${1:-"trunk"}

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
    local TRUNK_BRANCH=${1:-"trunk"}

    if ! git show-ref --quiet --verify -- "refs/heads/${TRUNK_BRANCH}" ; then
        echo "'${TRUNK_BRANCH}' does not exist. It is not safe to delete all the things."
        return 1
    fi

    git checkout "${TRUNK_BRANCH}"
    for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
        if [ "$branch" != "${TRUNK_BRANCH}" ]; then
            git branch -D "$branch"
        fi
    done
    repo_prune_remote_branches
}

function repo_wip_merge()
{
    git checkout main || return $?
    git merge --ff-only wip || return $?
    git branch -d wip || return $?
}
function repo_wip_rebase()
{
    git branch wip || return $?
    git reset --hard origin/main || return $?
    git checkout wip || return $?
    git rebase main || return $?
    # if there are merge conflicts, resolve them and then
    repo_wip_merge
}
