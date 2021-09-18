#!/usr/bin/env bash

function subcommand_list()
{
    declare -F | grep -Eo "${1}_.*" | sed "s/^${1}_"//
}

function subcommand_list_columns()
{
    subcommand_list "$1" | sort | column
}

function subcommand_help()
{
    subcommand_list_columns "${1}"
    return 0
}

# Do all the work for sub commands that do not need any extra effort

TOOLS_FILE="${LOCATION}/${BASE_COMMAND}_tools.sh"
if [ -f  "${TOOLS_FILE}" ]; then
    source "${TOOLS_FILE}"
else
    echo "can't find: ${TOOLS_FILE}" >&2
fi

if [ $# -eq 0 ]; then
    subcommand_help "${BASE_COMMAND}"
    exit 0
fi

cmd="${1}"
shift

# echo "** ${cmd} ** ${BASE_COMMAND}_${cmd} ** $(pwd)" >&2

"${BASE_COMMAND}_${cmd}" "$@"
