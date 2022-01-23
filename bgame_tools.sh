#!/usr/bin/env bash

# To use a different word, list EXPORT _BGAME_WORD_FILE="<path to word file"
: "${_BGAME_WORD_FILE:="${BHTOOLS_PROJECTS_PATH:-$HOME/projects}/english-words/words_alpha.txt"}"

function limit_length()
{
    local LENGTH=${1-:5}

    if ! [ -r "${_BGAME_WORD_FILE}" ]; then
        echo 
        echo "cannot read word file '${_BGAME_WORD_FILE}'" >&2
        return 1
    fi

    while IFS=$'\r\n' read -r WORD; do
        if (( ${#WORD} == LENGTH )); then
            echo "${WORD}"
        fi
    done < "${_BGAME_WORD_FILE}"
}

function exclude_letters()
{
    if [ -z "$1" ]; then 
        cat -
        return $?
    fi

    local letters="$1"
    local pattern="${letters:0:1}"

    for (( i=1; i<${#letters}; i++ )); do
        pattern="${pattern}|${letters:$i:1}"
    done

    cat - | grep -v -E -e "${pattern}"
}

function require_letters()
{
    if [ -z "$1" ]; then 
        cat -
        return $?
    fi

    local letters="$1"
    local cmd="grep '${letters:0:1}'"

    for (( i=1; i<${#letters}; i++ )); do
        cmd="${cmd} | grep '${letters:$i:1}'"
    done

    cat - | eval "${cmd}"
}

function require_pattern()
{
    cat - | grep -E "$1"
}

function exclude_pattern()
{
    cat - | grep -E "$1"
}


function _bgame_wordle_help()
{
    echo "A tool to help solving 5-letter word puzzled like Wordle and Absurdle"
    echo "Usage:"
    echo " bgame wordle exlcude_letters require_letters exclude_pattern require_pattern"
    echo ""
    echo "      exclude_letters - a list of letters to exclude, filters any word with any of these"
    echo "      require_letters - a list of letters to require, filters any word without one of these"
    echo "      exclude_pattern - a regex pattern for excluding letters by position e.g. '..[^ae]..' to reject words with 'ae' in the 3rd letter"
    echo "      require_pattern - a regex pattern for requiring letters by position e.g. '..a.e' to reject words without 'a' in the 3rd letter and 'e' in the 5th"
}

function bgame_wordle()
{
    EXCLUDE="$1"
    MUST_HAVE="$2"
    NEGATIVE_PATTERN="$3"
    POSITIVE_PATTERN="$4"

    limit_length 5 \
    | exclude_letters "${EXCLUDE}" \
    | require_letters "${MUST_HAVE}" \
    | require_pattern "${NEGATIVE_PATTERN}" \
    | require_pattern "${POSITIVE_PATTERN}" \
    | column
}
