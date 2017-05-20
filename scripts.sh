export CGO_TESTCLIENT_ID='afabbecf-7ac1-4964-84a7-cff3a2acea04'
export CGO_TESTCLIENT_SECRET='2NO8bAoM8GgFqMcpgnTz3w3W9hfZWqbAlncihflWW4U='

function venv_location()
{
    local location=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -z "${location}" ]; then
        location="venv"
    else
        location="../venv/${location##*/}"
    fi
    echo ${location}
}

function venv_pip_upgrade()
{
    pip install --upgrade pip
}

function venv_deactivate()
{
    ! type -t deactivate &> /dev/null || deactivate
}

function venv_is_a_venv()
{
    local location=${1:?"venv folder was not specified"}
    if [[ -d "${location}" && -e "${location}/bin/activate" ]]; then
        return 0
    fi
    return 1
}

function venv_create()
{
    venv_deactivate

    local location=${1:-$(venv_location)}

    if venv_is_a_venv "${location}"  ;then
        rm -rf "${location}"
    fi
    if [ ! -a "${location}" ]; then
        ~/.pyenv/versions/3.5.1/bin/pyvenv "${location}"
    fi
}

function venv_activate()
{
    local activate_script=${1:-$(venv_location)}/bin/activate
    [ -r "${activate_script}" ] && source "${activate_script}"
}

function venv_start_rabbit()
{
    brew services start rabbitmq
}

function venv_pip_reqiurements()
{
    pip install --upgrade -r requirements.txt
}

function venv_rvm_use_ruby_hisc()
{
    rvm use ruby-2.2.3@hisc    
}

function venv_rebuild()
{
    venv_deactivate
    venv_rvm_use_ruby_hisc
    venv_create
    venv_activate
    venv_pip_upgrade
    venv_pip_reqiurements

    venv_start_rabbit
#    brew services start postgresql
}

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
