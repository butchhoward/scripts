#!/usr/bin/env bash
#source this script to get the useful functions
# shellcheck disable=SC1090
# SC1090 -> don't try to follow sourced files

function _venv_help()
{
    echo
    echo "Manage virtual environments for Python"
    echo
    echo "Assumes you are working in a git repository."
    echo
    echo "Assumes you have installed the various Python versions to be used by way of pyenv"
    echo "      brew install pyenv"
    echo "List the Python version pyenv can manage"
    echo "      pyenv install --list"
    echo "Install one"
    echo "      pyenv install 3.6.0"
    echo "Show the ones installed"
    echo "      pyenv versions"
    echo
    echo "If you are going to use any Python 2.x versions, you must have installed virtualenv tools at the global level"
    echo "  pip install virtualenv virtualenvwrapper"
    echo

    if REPO="$(git rev-parse --show-toplevel 2>/dev/null)" ; then
        echo "Current folder is a git repository: '${REPO}'"
    else
        echo "The current folder is NOT a git repository"
    fi

    if venv_is_a_venv "$(venv_location)"; then
        echo "Current venv is: $(venv_location)"
        if [ -v VIRTUAL_ENV ]; then
            echo "venv is Active"
        else
            echo "venv is not Active"
        fi
    else
        echo "Current repository does not have a venv"
    fi

}

function _venv_def_py_help()
{
    echo "Show the default version of Python to be used when a specific version is not given."
}

function venv_def_py()
{
    pyenv versions | sed -e 's/^  //g' -e 's/^* //g' -e 's/(.*$//g' -e 's/ *$//' | grep '^\d' | tail -1
}

function venv_py_available()
{
    pyenv install --list | sed 's/^  //' | grep '^\d' | grep --invert-match 'dev\|a\|b'
}

function venv_newest_py()
{
    venv_py_available | tail -1
}

function _venv_location_help()
{
    echo "Show the default location of the venv being used for the current repostory."
    echo "The location of is one folder level above the repository base directory"
    echo "    in a folder name '.venv/<repostory name>'"
}

function venv_location()
{
    local location
    location="$(git rev-parse --show-toplevel 2>/dev/null)"
    if [ -z "${location}" ]; then
        location="$(pwd)"
    fi
    location="${location}/../.venv/${location##*/}"
    echo "${location}"
}

function venv_pip_upgrade()
{
    pip install --upgrade pip
    pip install wheel
}

function _venv_deactivate_help()
{
    echo "venv_deactivate"
    echo "  Deactivate the virtual environment"
    echo "Note: you must use 'venv_deactivate' directly instead of via the venv tool."
}

function _venv_deactivate()
{
    if type -t venv_deactivate &> /dev/null; then
        venv_deactivate
        return $?
    fi

    # this works for both venv and virtualenv
    ! type -t deactivate &> /dev/null || deactivate
}

function _venv_is_a_venv_help()
{
    echo "venv is_a_venv <venv_folder>"
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

function _venv_remove_help()
{
    echo "venv remove [venv_folder]"
    echo "  if venv_folder is not given, the default location will be used."
}

function venv_remove()
{
    local location
    local location=${1:-$(venv_location)}

    _venv_deactivate

    if [[ -d "${location}" && -e "${location}/bin/activate" ]]; then
        rm -rf "${location}"
    fi

    local locationp2="$HOME/.virtualenvs/${location##*/}"
    if [[ -d "${locationp2}" ]]; then
        rmvirtualenv "${location##*/}"
    fi
}

function _venv_create_help()
{
    echo "venv create [python_version] [venv_location]"
    echo "  Creates a venv for the current repository"
    echo "  If python_version is not given, uses the default version."
    echo "  If venv_location is not given, uses the default location."
}

function venv_create()
{
    local version="${1:-$(venv_def_py)}"
    local location=${2:-$(venv_location)}

    _venv_deactivate
    venv_remove "${location}"

    if [ ! -a "${location}" ]; then
        # shellcheck disable=SC2071
        if [[ "${version}" < "3" ]]; then
            # use virtualenvwrapper tools for the prehistoric pythons
            echo "using virtualenvwrapper for python 2.x to create environment '${location##*/}' because version='${version}'"
            # shellcheck disable=SC1091
            source /usr/local/bin/virtualenvwrapper.sh
            mkvirtualenv -p "$HOME/.pyenv/versions/${version}/bin/python" "${location##*/}"
        else
            ~/.pyenv/versions/"${version}"/bin/python -m venv "${location}"
        fi
    fi
}

function _venv_activate_help()
{
    echo "venv_activate [venv_folder]"
    echo "  If venv_folder is not given, the default location will be used."
    echo "  Note that using a non-default location will require that it be used in other commands."
    echo "Note: you must use 'venv_activate' directly instead of via the venv tool."
}

function _venv_activate()
{
    if type -t venv_activate >&2 /dev/null; then
        venv_activate
        return $?
    fi

    _venv_deactivate
    local location="${1:-$(venv_location)}"
    local activate_script="${location}"/bin/activate
    if [ -r "${activate_script}" ]; then
        source "${activate_script}"
    else
        workon "${location##*/}"
    fi
}

function _venv_pip_requirements_help()
{
    echo "venv pip_requirements [requirements_file]"
    echo "  If the file name is not given, ./requirements-dev.txt will be used if present, else ./requirements.txt"
}

function venv_pip_requirements()
{
    declare requirements_file=${1:-"requirements.txt"}

    if [[ -z "$1" ]]; then
        if [[ -r "requirements-dev.txt" ]]; then
            requirements_file="requirements-dev.txt"
        fi
    fi

    echo "REQUIREMENTS: ${requirements_file}"
    if [ -a "${requirements_file}" ]; then
        pip install --upgrade -r "${requirements_file}"
    else
        echo "Could not pip the requirments file: '${requirements_file}'"
        return 1
    fi
}

function _venv_rebuild_help()
{
    echo "venv rebuild [requirements_file] [python_version] [venv_location]"
    echo "  requirements_file defaults to 'requirements_dev.txt, if it exists"
    echo "      else it defaults to requirements.txt"
    echo "  python_version defaults to the default python version"
    echo "  venv_location defaults to the default venv location"
}

function venv_rebuild()
{
    local requirements_folder="${1:-"."}"
    local version="${2:-$(venv_def_py)}"
    local location="${3:-$(venv_location)}"

    local requirements_file="${requirements_folder}/requirements.txt"
    if [ -r "${requirements_folder}/requirements-dev.txt" ]; then
        requirements_file="${requirements_folder}/requirements-dev.txt"
    fi

    venv_create "${version}" "${location}"
    _venv_activate "${location}"
    venv_pip_upgrade
    venv_pip_requirements "${requirements_file}"
}
