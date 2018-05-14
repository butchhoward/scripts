#source this script to get the useful functions


function repo_base_dir()
{
    echo $(git rev-parse --show-toplevel 2>/dev/null)
}

# The do_it functions apply everything on the command-line as a command in each git folder below the current one
# I have not figured out exaclty how to execute complex things in that command
# So:
#       repo_do_it_to_all git checkout master
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
    for d in `ls -d *`;do 
        if [ -d $d/.git ]; then 
            pushd $d &> /dev/null
            echo ""
            echo "====$(pwd)===>[$@]"
            $@
            popd &> /dev/null
        fi;
    done
}

function repo_do_it_to_all_quietly()
{
    for d in `ls -d *`;do 
        if [ -d $d/.git ]; then 
            pushd $d &> /dev/null
            $@
            popd &> /dev/null
        fi;
    done
}

function repo_do_it_to_all_very_quietly()
{
    for d in `ls -d *`;do 
        if [ -d $d/.git ]; then 
            pushd $d &> /dev/null
            $@ &> /dev/null
            popd &> /dev/null
        fi;
    done
}

repo_is_clean() 
{
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
    local BRANCH=${1:-"master"}

    git fetch --all
    if ! git show-ref --quiet --verify -- "refs/remotes/origin/${BRANCH}" ; then
        echo "'origin/${BRANCH}' does not exist. Nothing to do."
    else
        git checkout ${BRANCH}
        git reset --hard origin/${BRANCH}
    fi
 }

function repo_update_to_master()
{
    repo_update_to_branch master
}

function repo_update_all_to_master()
{
    repo_do_it_to_all repo_update_to_master
}

function repo_update_all_to_branch()
{
    local BRANCH=${1:-"master"}

    repo_do_it_to_all repo_update_to_branch "${BRANCH}"
}

function repo_status_all()
{
    repo_do_it_to_all "git status"
}

function repo_clean_fdx()
{
    local EXTRA_ARGS=${@:-"--exclude=.vscode --exclude=.idea"}
    git clean -fdx ${EXTRA_ARGS}
}

function repo_clean_fdx_all()
{
    local EXTRA_ARGS=${@:-"--exclude=.vscode --exclude=.idea"}
    repo_do_it_to_all "git clean -fdx ${EXTRA_ARGS}"
}

function repo_prune_remote_branches()
{
    for remote_name in $(git remote); do 
        git remote prune $remote_name
    done
}

# Have a care, this deletes them ALL it does not check whether they have been pushed or merged.
# It does not remove commits, so you can probably get back to the code (at least until a purge happens)
function repo_delete_all_local_branches()
{
    local MASTER_BRANCH=${1:-"master"}

    if ! git show-ref --quiet --verify -- "refs/heads/${MASTER_BRANCH}" ; then
        echo "'${MASTER_BRANCH}' does not exist. It is not safe to delete all the things."
        return 1
    fi

    git checkout "${MASTER_BRANCH}"
    for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
        if [ "$branch" != "${MASTER_BRANCH}" ]; then
            git branch -D "$branch"
        fi
    done
    repo_prune_remote_branches
}


