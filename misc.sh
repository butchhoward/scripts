#!/usr/bin/env bash
#source this script to get the useful functions
# shellcheck disable=SC1090
# SC1090 -> don't try to follow sourced files


# from this stackoverflow answer https://stackoverflow.com/a/16178979/4787468
# stderrred program [args]
function stderrred()
{
    (set -o pipefail;"$@" 2>&1>&3|sed $'s,.*,\e[31m&\e[m,'>&2)3>&1
}


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

# top display for process names matching grep pattern '$1'
function toppgrep()
{
    top -pid $(pgrep "$1" | tr "\\n" "," | sed 's/,$//')
}


# Wifi Checker tools

function current_wifi_adapter()
{
    networksetup -listallhardwareports | awk '/Wi-Fi/{getline; print $2}' | xargs networksetup -getairportnetwork
}
