#!/usr/bin/env bash

# To use a different word, list EXPORT BGAME_WORD_FILE="<path to word file"
: "${BGAME_WORD_FILE:="${BHTOOLS_PROJECTS_PATH:-$HOME/projects}/english-words/words_alpha.txt"}"

function _limit_length()
{
    local LENGTH=${1-:5}

    if ! [ -r "${BGAME_WORD_FILE}" ]; then
        echo "cannot read word file '${BGAME_WORD_FILE}'" >&2
        return 1
    fi

    while IFS=$'\r\n' read -r WORD; do
        if (( ${#WORD} == LENGTH )); then
            echo "${WORD}"
        fi
    done < "${BGAME_WORD_FILE}"
}

function _exclude_letters()
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

function _require_letters()
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

function _require_pattern()
{
    cat - | grep -E "$1"
}

function _exclude_pattern()
{
    cat - | grep -E "$1"
}


function _bgame_wordle_usage
{
    echo "Usage:"
    echo " bgame $1 exlcude_letters require_letters exclude_pattern require_pattern"
    echo ""
    echo "      exclude_letters - a list of letters to exclude, filters any word with any of these"
    echo "      require_letters - a list of letters to require, filters any word without one of these"
    echo "      exclude_pattern - a regex pattern for excluding letters by position e.g. '..[^ae]..' to reject words with 'ae' in the 3rd letter"
    echo "      require_pattern - a regex pattern for requiring letters by position e.g. '..a.e' to reject words without 'a' in the 3rd letter and 'e' in the 5th"
    echo
    echo "Word list used is currently set to '${BGAME_WORD_FILE}'."
    echo "Change the word list file by setting 'BGAME_WORD_FILE'"
    echo "To set it permmanently for the session:"
    echo '      export BGAME_WORD_FILE=/path/to/my_word_list.txt'
    echo "To set it temporarily for a run:"
    echo '      BGAME_WORD_FILE=/path/to/my_word_list.txt bgame wordle'
    echo
    echo "The word file must have a single word on each line."
}

function _bgame_wordle_help()
{
    echo "A tool to help solving 5-letter word puzzled like Wordle and Absurdle"
    echo "The output is a list of words limited by the options given"
    _bgame_wordle_usage "wordle"
}


function _bgame_wordle()
{
    EXCLUDE="$1"
    MUST_HAVE="$2"
    NEGATIVE_PATTERN="$3"
    POSITIVE_PATTERN="$4"

    _limit_length 5 \
    | _exclude_letters "${EXCLUDE}" \
    | _require_letters "${MUST_HAVE}" \
    | _require_pattern "${NEGATIVE_PATTERN}" \
    | _require_pattern "${POSITIVE_PATTERN}"
}

function bgame_wordle()
{
    _bgame_wordle "$@" \
    | column

}

function _bgame_wordle_try_help()
{
    echo "A tool to help solving 5-letter word puzzled like Wordle and Absurdle"
    echo "The output is a single word suggestion selected randomly from the list given by 'bgame wordle'"
    _bgame_wordle_usage "wordle_try"
}

function bgame_wordle_try()
{
    local WORDS=()

    if (( BASH_VERSINFO[0] >= 4 )); then
        mapfile -t WORDS < <(_bgame_wordle "$@")
    else
        while read -r WORD; do
            WORDS+=("${WORD}")
        done < <(_bgame_wordle "$@")
    fi


    if (( ${#WORDS[@]} == 0 )); then
        echo "no words to choose" >&2
        return 0
    fi

    if (( ${#WORDS[@]} == 1 )); then
        echo "only one word to choose" >&2
        echo "${WORDS[0]}"
        return 0
    fi

    # use /dev/urandom because the word list is larger than 32k
    local r
    r=$(head -c 4 /dev/urandom | od -An -tu4 | tr -d ' ')

    local size=${#WORDS[@]}
    local index=$((r % size))
    echo "${WORDS[$index]}"
}
