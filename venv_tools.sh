#source this script to get the useful functions

function venv_location()
{
    local location=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -z "${location}" ]; then
        location=".venv"
    else
        location="${location}/../.venv/${location##*/}"
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
        ~/.pyenv/versions/3.6.0/bin/python -m venv "${location}"
    fi
}

function venv_activate()
{
    venv_deactivate
    local activate_script=${1:-$(venv_location)}/bin/activate
    [ -r "${activate_script}" ] && source "${activate_script}"
}

function venv_pip_reqiurements()
{
    local requirements_file=${1:-"requirements.txt"}
    if [ -a "${requirements_file}" ]; then
        pip install --upgrade -r "${requirements_file}"
    else
        echo "Could not pip the requirments file: '${requirements_file}'"
    fi
}

function venv_rebuild()
{
    local requirements_folder=${1:-'.'}
    local requirements_file="${requirements_folder/requirements.txt}"
    
    venv_deactivate
    venv_create
    venv_activate
    venv_pip_upgrade
    venv_pip_reqiurements "${requirements_file}"
}
