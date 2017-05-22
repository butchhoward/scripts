#source this script to get the useful functions

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

function repo_fetch_all()
{
    repo_do_it_to_all "git fetch --all"
}

function repo_update_to_master()
{
    git fetch --all
    git checkout master
    git reset --hard upstream/master
    git push origin master
}

function repo_update_all_to_master()
{
    # repo_do_it_to_all "git fetch --all; git checkout master; git reset --hard upstream/master"
    repo_do_it_to_all repo_update_to_master
}

function repo_status_all()
{
    repo_do_it_to_all "git status"
}

function repo_clean_fdx_all()
{
    repo_do_it_to_all "git clean -fdx"
}

function repo_delete_all_local_branches()
{
    git checkout master
    for branch in $(git for-each-ref --format='%(refname:short)' refs/heads/); do
        if [ "$branch" != "master" ]; then
            git branch -D "$branch"
        fi
    done
}
