#!/usr/bin/env bash
#source this script to get the useful functions

function _repo_help()
{
    echo "Tools to handle common git repository tasks"
}

function repo_base_dir()
{
    git rev-parse --show-toplevel 2>/dev/null
}

function repo_current_branch()
{
    git rev-parse --abbrev-ref HEAD
}

function _repo_do_it_to_all_help()
{
    echo "The do_it functions apply everything on the command-line as a command in each git folder below the current one"
    echo "I have not figured out exaclty how to execute complex things in that command"
    echo "So:"
    echo "      repo_do_it_to_all git checkout main"
    echo
    echo "works, but something more complicated will not:"
    echo "      repo_do_it_to_all_quietly  if ! repo_is_clean; then git status; fi;"
    echo "will fail"
    echo
    echo "(anything more complicated than that should be scripted on its own)"
}

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

function _repo_do_it_to_all_quietly_help()
{
    echo "Same as 'do_it_to_all' except without the separator text between."
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

function _repo_do_it_to_all_very_quietly_help()
{
    echo "Same as 'do_it_to_all_quietly' except with _all_ command output sent to the bit bucket."
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

function _repo_is_clean_help()
{
    echo "Attempt to report whether there are no untracked, unstaged, and uncommitted files"
    echo "returns 3 if untracked files are present"
    echo "returns 2 if uncommitted changes are present"
    echo "returns 1 if unstaged changes are present"
    echo "returns o if the repository appears clean"
}

function repo_is_clean()
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

function _repo_update_to_branch_help()
{
    echo "repo update_to_branch [branch_name]"
    echo "  Perform a hard reset to the origin branch matching the current branch."
    echo "  branch_name defaults to 'main'"
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

function _repo_clean_fdx_help()
{
    echo "repo clean_fdx [...]"
    echo "  Deep clean repository excluding common things that are nice to keep around"
    echo "  If no arguments are given, the defaults will preserve .vscode and .idea folders"
    echo "  If arguments are given, exactly those will be pass to 'git clean --fdx'"
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

function _repo_prune_remote_branches_help()
{
    echo "Remove any local tracking branches from branches that have been deleted from remotes."
}

function repo_prune_remote_branches()
{
    for remote_name in $(git remote); do
        git remote prune "$remote_name"
    done
}

function _repo_delete_all_local_branches_help()
{
    echo "repo delete_all_local_branches [branch_name]"
    echo "  Change to the branch and delete ALL other local branches."
    echo "  branch_name defaults to 'main'"
    echo
    echo "** Have a care, this deletes them ALL it does not check whether they have been pushed or merged. **"
    echo "** It does not remove commits, so you can probably get back to the code (at least until a purge happens) **"
}

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


function _repo_delete_remote_branch_help()
{
    echo "repo delete_remote_branch branch_name [remote_name]"
    echo "  Delete the branch from the remote repository"
    echo "  remote_name defaults to 'origin'"
    echo
    echo "** Have a care, this deletes the branch from the remote. **"
}

function repo_delete_remote_branch()
{
    declare BRANCH=${1:?"remote branch to delete is required"}
    declare REMOTE=${2:-"origin"}

    git push "${REMOTE}" --delete "${BRANCH}"
}

DEFAULT_WIP_BRANCH='__wip__'

function _repo_wip_merge_help()
{
    echo "repo wip_merge [branch] [wip_branch]"
    echo "  branch defaults to the current branch"
    echo "  wip_branch defaults to the ${DEFAULT_WIP_BRANCH} branch"
    echo
    echo "  Merge pending changes in 'wip_branch' into 'branch'."
    echo "  If successful, delete 'wip_branch'."
    echo "  When changes happen after a rebase where there were conflicts to resolve, the pending changes will be in '${DEFAULT_WIP_BRANCH}'."
}

function repo_wip_merge()
{
    local BASE_BRANCH=${1:-"$(repo_current_branch)"}
    local WIP_BRANCH=${2:-"${DEFAULT_WIP_BRANCH}"}

    git checkout "${BASE_BRANCH}" || return $?
    git merge --ff-only "${WIP_BRANCH}" || return $?
    git branch -d "${WIP_BRANCH}" || return $?
}

function _repo_wip_rebase_help()
{
    echo "repo wip_rebase [branch]"
    echo "  branch defaults to the current branch"
    echo
    echo "  Rebase changes in the current working branch onto the named branch"
    echo "  This is usually used when working on a branch that had changes pushed to origin"
    echo "      by someone else working on the same branch. This will combine the changes to the"
    echo "      branch without leaving a merge-commit (i.e. keeping the branch history a straight line)"
    echo "  If the rebase step has merge conflicts, resolve those in the normal way using"
    echo "      git rebase mergetool"
    echo "      git rebase --continue"
    echo "  then use"
    echo "      repo wip_merge"
    echo "  to complete the work started by 'repo wip_rebase'"
    echo "      (wip_rebase uses '${DEFAULT_WIP_BRANCH}' to process the rebase)"
}

function repo_wip_rebase()
{
    local CURRENT_BRANCH
    CURRENT_BRANCH="$(repo_current_branch)"

    local BASE_BRANCH=${1:-"${CURRENT_BRANCH}"}

    # create the wip branch from the current HEAD
    git branch -D "${DEFAULT_WIP_BRANCH}" &> /dev/null
    git branch "${DEFAULT_WIP_BRANCH}" || return $?

    # reset the current branch to origin/[branch] IFF base is the same
    if [[ "${BASE_BRANCH}" == "${CURRENT_BRANCH}" ]]; then
        git reset --hard "origin/${BASE_BRANCH}" || return $?
    else
        #  else is it some other branch, probably main, get local up to date with remote
        git switch "${BASE_BRANCH}" || return $?
        git pull || return $?
        git switch - || return $?
    fi

    # change to the wip branch and rebase wip (which has all the new changes) onto the working branch (which has been reset)
    git checkout "${DEFAULT_WIP_BRANCH}" || return $?
    if ! git rebase "${BASE_BRANCH}"; then
        r=$?
        echo
        echo "=========="
        echo "Resolve all conflicts then 'repo wip_merge ${CURRENT_BRANCH}' to complete"
        echo "=========="
        echo
        return $r
    fi

    # merge the rebased changes into the base branch for a clean merge line
    # if there are merge conflicts, you will have to resolve them and do the wip_merge separately
    repo_wip_merge "${CURRENT_BRANCH}"
}

function _repo_committers_help()
{
    echo "repo committers [parent_branch] [working_branch]"
    echo "  parent_branch defaults to 'main'"
    echo "  working_branch defaults to the current branch"
    echo
    echo "Lists all committers for commits changes between the two branches"
    echo "  in the Github 'Co-authored-by' format"
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

function _repo_squash_summary_help()
{
    echo "repo squash_summary parent_branch current_branch"
    echo "  parent_branch is required, it should be the older branch/commit point"
    echo "  current_branch is required, it should be the newer branch/commit point"
    echo
    echo "  List all commit messages between the two commit points"

}

function repo_squash_summary()
{
    local PARENT=${1:?"parent branch for compare is required"}
    local CURRENT_BRANCH=${2:?"working branch for compare is required"}

    git log --format='%B%n' "${PARENT}".."${CURRENT_BRANCH}"
}

function _repo_squash_summary_changelog_help()
{
    echo "repo squash_summary older_commit newer_commit"
    echo "  older_commit is required, it should be the older branch/commit point"
    echo "  newer_commit is required, it should be the newer branch/commit point"
    echo
    echo "  List all commit messages between the two commit points"
    echo "  Kinda sorta format them as markdown bullets to be added to a change log document"

}

function repo_squash_summary_changelog()
{
    local OLDER_COMMIT=${1:?"starting commit required"}
    local NEWER_COMMIT=${2:?"ending commit reqired"}

    git log --format='* %B%n' "${OLDER_COMMIT}".."${NEWER_COMMIT}"
}

function _repo_squash_branch_help()
{
    echo "repo squash_branch <message> [parent_branch]"
    echo "  message is required (should be quoted if it is more than one word)"
    echo "  parent_branch defaults to main"
    echo
    echo "Squash all commits since diverging from the parent branch"
    echo "  Add all commit messages to the commit message for the squashed commit"
    echo "  Add all Co-authors to the commit message"
    echo "  Add a list of all files changed to the commit message"
    echo "There commit message will be opened in your editor before completing the commit."
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
$(repo_squash_summary "${PARENT}" "${CURRENT_BRANCH}")
------------
$(repo_committers "${PARENT}" "${CURRENT_BRANCH}")

Files Modified
--------------
$(git diff --name-status "${PARENT}".."${CURRENT_BRANCH}")

EOM

    git reset "$(git merge-base "${PARENT}" "${CURRENT_BRANCH}")" || return 2
    git add -A
    git commit --edit -m "${COMMIT_MSG}"
}


function _repo_clone_many_help()
{
    echo "repo clone_many [host_prefix]"
    echo
    echo "  host_prefix - the github host address. defaults to 'github.com'"
    echo "                to include an organization, add it to the host address: "
    echo "                  github.com:my_org"
    echo "                  github.mycompany.com:my_org"
    echo
    echo "The list of repository names to clone is read from STDIN (one repository name per line)"
    echo "Assumes git protocol clone (git clone git@<HOST_NAME>:<ORG_NAME>/<REPO_NAME>.git)"
    echo
    echo "Example:"
    echo "  repo clone_many github.mycompany.com:my_org < repo_list.txt"
    echo
    echo "Build a list gh and clone them all:"
    echo '  repo clone_many github.com:butchhoward < <(gh repo list --json name | jq -r '\''.[] | .name'\'')'
}

function repo_clone_many()
{
    local HOST="${1:-github.com}"

    while read -r REPO_NAME; do
        git clone "git@${HOST}/${REPO_NAME}.git"
    done

}


function _repo_delete_tag_help()
{
    echo "repo delete_tag <tag>"
    echo
    echo "  tag     - the tag to delete"
    echo
    echo "Delete a tag locally and remote on the origin remote"
    echo

}

function repo_delete_tag()
{

    declare TAG="$1"

    git tag -d "${TAG}"
    git push origin :refs/tags/"${TAG}"

}

function _repo_update_tag_help()
{
    echo "repo update_tag <tag> [message]"
    echo
    echo "  tag     - the tag to update"
    echo "  message - the message for the tag"
    echo
    echo "Update a tag locally and remote on the origin remote"
    echo "Applies the tag to the current commit and pushes that tag to the origin remote."
    echo

}

function repo_update_tag()
{
    declare TAG="$1"
    declare MESSAGE="${2:-'update tag'}"

    repo_delete_tag "${TAG}"     && \
    git tag -f -a "${TAG}" -m "${MESSAGE}"  && \
    git push origin --tags
}
