#!/usr/bin/env bash
#source this script to get the useful functions
# shellcheck disable=SC1090
# SC1090 -> don't try to follow sourced files


# Assumes you have installed the various Python versions to be used by way of pyenv
#       brew install pyenv
# List the Python version pyenv can manage
#       pyenv install --list
# Install one
#       pyenv install 3.6.0
# Show the ones installed
#       pyenv versions

# This is what I had to use to install Python 2.7.13 on MacOS 10.13.6
# CFLAGS="-I$(xcrun --show-sdk-path)/usr/include -I$(brew --prefix openssl)/include" LDFLAGS="-L$(brew --prefix openssl)/lib" pyenv install 2.7.13

# If you are going to use any Python 2.x versions, you must have installed virtualenv tools at the global level
#   pip install virtualenv virtualenvwrapper

function venv_help()
{
    echo ""
    echo "venv_rebuild requirements_folder version location"
    echo "      folder defaults to current"
    echo "      version defaults to 3.6.0"
    echo "      venv location defaults to computed (../.venv/<git repo name>)"
    echo ""
    echo ""
    echo "venv_activate"
    echo ""
    echo "venv_deactivate"
    echo ""
    echo "venv_pip_requirements requirements_file"
    echo "      file defaults to ./requirements.txt"
    echo ""
    echo "venv_pip_upgrade"
}
    

function venv_location()
{
    local location
    location="$(git rev-parse --show-toplevel 2>/dev/null)"
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
    # this works for both venv and virtualenv
    ! type -t deactivate &> /dev/null || deactivate
}

function venv_is_a_venv()
{
    local location
    location="${1:?"venv folder was not specified"}"
    if [[ -d "${location}" && -e "${location}/bin/activate" ]]; then
        return 0
    fi
    local locationp2="$HOME/.virtualenvs/${location##*/}"
    if [[ -d "${locationp2}" ]]; then
        return 0
    fi
    return 1
}

# shellcheck disable=SC2120
function venv_remove()
{
    local location
    local location=${1:-$(venv_location)}
    if [[ -d "${location}" && -e "${location}/bin/activate" ]]; then
            rm -rf "${location}"
    fi
    local locationp2="$HOME/.virtualenvs/${location##*/}"
    if [[ -d "${locationp2}" ]]; then
        rmvirtualenv "${location##*/}"
    fi
    }

# shellcheck disable=SC2120
function venv_create()
{
    local version="${1:-3.6.0}"
    local location=${2:-$(venv_location)}

    venv_deactivate
    venv_remove "${location}"

    if [ ! -a "${location}" ]; then
        # shellcheck disable=SC2071
        if [[ "${version}" < "3" ]]; then
            # use virtualenvwrapper tools for the prehistoric pythons
            echo "using virtualenvwrapper for python 2.x to create environment '${location##*/}'"
            # shellcheck disable=SC1094
            source /usr/local/bin/virtualenvwrapper.sh
            mkvirtualenv -p ~/.pyenv/versions/${version}/bin/python "${location##*/}"
        else
            ~/.pyenv/versions/${version}/bin/python -m venv "${location}"
        fi
    fi
}

# shellcheck disable=SC2120
function venv_activate()
{
    venv_deactivate
    local location="${1:-$(venv_location)}"
    local activate_script="${location}"/bin/activate
    if [ -r "${activate_script}" ]; then 
        source "${activate_script}"
    else
        workon "${location##*/}"
    fi
}

function venv_pip_requirements()
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
    local version="${2:-3.6.0}"
    local location="${3:-$(venv_location)}"

    local requirements_file="${requirements_folder}/requirements.txt"
    
    venv_create "${version}" "${location}"
    venv_activate "${location}"
    venv_pip_upgrade
    venv_pip_requirements "${requirements_file}"
}

