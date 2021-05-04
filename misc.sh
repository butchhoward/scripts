#!/usr/bin/env bash
#source this script to get the useful functions
# shellcheck disable=SC1090
# SC1090 -> don't try to follow sourced files


# Moved to bhtool
# from this stackoverflow answer https://stackoverflow.com/a/16178979/4787468
# stderrred program [args]
# function stderrred()
# {
#     (set -o pipefail;"$@" 2>&1>&3|sed $'s,.*,\e[31m&\e[m,'>&2)3>&1
# }


# from this stackoverflow answer https://stackoverflow.com/questions/370047/what-is-the-most-elegant-way-to-remove-a-path-from-the-path-variable-in-bash
function path_append ()
{
    path_remove "$1"
    export PATH="$PATH:$1"
}
function path_prepend ()
{
    path_remove "$1"
    export PATH="$1:$PATH"
}
function path_remove ()
{
    # shellcheck disable=SC2155
    export PATH=$(echo -n "$PATH" | awk -v RS=: -v ORS=: '$0 != "'"$1"'"' | sed 's/:$//')
}

# Wifi Checker tools

function current_wifi_adapter()
{
    networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}' | xargs networksetup -getairportnetwork
}


# mac-ish pgrep to top pipe (mac sed, mac top are a bit diff from gnu)
function topgrep()
{
    # word splitting is needed here
    # shellcheck disable=SC2046
    top $(pgrep -f "$@" | awk '{print $1}' | sed -E 's/^(.*)$/-pid \1 /g' | sed -E 's/\n//g' | paste -sd' ' -)
}

# switch between ~/.ssh/config files. Copy the one specified to be the active one.
# single param is the prefix for the config to use:
#       switch_ssh default
#       switch_ssh client
function switch_ssh()
{
    config_name="${HOME}/.ssh/config"
    src_config_name="${config_name}.${1:-default_config}"

    if test -f "${src_config_name}"; then
        ssh-add -D >& /dev/null # delete all keys in the keychain just in case
        cp "${src_config_name}" "${config_name}"
        echo "switched ssh config to: ${1}"
    else
        echo "could not find ${src_config_name}" 1>&2
        return 1
    fi
}


# Pretty-print format all json files in the current folder
function pretty_json()
{
    for f in *.json; do jq '.' "$f" > "mod_$f"; mv "mod_$f" "$f"; done
}
