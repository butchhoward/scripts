#!/usr/bin/env bash

function subcommand_list()
{
    # declare -f _venv_help
    # declare -f venv_create
    # match the latter but not the former,
    #   then remove the leading space plus the base command name
    declare -F | grep -Eo -e " ${1}"'_.*' | sed "s/^ ${1}_"// | sort
}

function subcommand_list_columns()
{
    subcommand_list "$1" | column
}

function subcommand_help()
{
    local BASE_COMMAND="${1}"

    local HELP_FUNCTION="_${BASE_COMMAND}_help"
    if type -t "${HELP_FUNCTION}" &> /dev/null; then
        "${HELP_FUNCTION}"
        echo
    fi

    while read -r SUB_CMD; do
        local HELP_FUNCTION="_${BASE_COMMAND}_${SUB_CMD}_help"
        echo "* ${SUB_CMD}"
        if type -t  "${HELP_FUNCTION}" &> /dev/null; then
            echo
            "${HELP_FUNCTION}"
            echo "---------------------------------------"
        fi
        echo
    done < <(subcommand_list "${BASE_COMMAND}")

    return 0
}

# Do the work for sub commands that do not need any extra effort

TOOLS_FILE="${LOCATION}/${BASE_COMMAND}_tools.sh"
if [ -f  "${TOOLS_FILE}" ]; then
    source "${TOOLS_FILE}"
else
    echo "can't find: ${TOOLS_FILE}" >&2
    return 1
fi

if [ $# -eq 0 ]; then
    subcommand_list_columns "${BASE_COMMAND}"
    exit 0
fi

SUB_CMD="${1}"
shift

case "${SUB_CMD}" in
    help|-h|-?)
        subcommand_help "${BASE_COMMAND}"
        exit 0
        ;;
esac

"${BASE_COMMAND}_${SUB_CMD}" "$@"
