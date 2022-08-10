#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091

# These need to be in the current terminal session because they modify the
# active environment

function venv_deactivate()
{
    # this works for both venv and virtualenv
    ! type -t deactivate &> /dev/null || deactivate
}

function venv_activate()
{
    venv_deactivate
    local location="${1:-$(venv location)}"
    local activate_script="${location}"/bin/activate
    if [ -r "${activate_script}" ]; then
        source "${activate_script}"
    else
        workon "${location##*/}"
    fi
}
