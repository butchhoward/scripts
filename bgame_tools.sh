#!/usr/bin/env bash

# To use a different word list, export BGAME_WORD_FILE="<path to word file"
: "${BGAME_WORD_FILE:="${BHTOOLS_PROJECTS_PATH:-$HOME/projects}/english-words/words_alpha.txt"}"

function _limit_length()
{
    declare LENGTH=${1-:5}
    declare DICTIONARY="${2:-"${BGAME_WORD_FILE}"}"

    if ! [ -r "${DICTIONARY}" ]; then
        echo "cannot read word file '${DICTIONARY}'" >&2
        return 1
    fi

    while IFS=$'\r\n' read -r WORD; do
        if (( ${#WORD} == LENGTH )); then
            echo "${WORD}"
        fi
    done < "${DICTIONARY}"
}

function _exclude_letters()
{
    if [ -z "$1" ]; then
        cat -
        return $?
    fi

    declare letters="$1"
    declare pattern="${letters:0:1}"

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

    declare letters="$1"
    declare cmd="grep '${letters:0:1}'"

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
    echo " bgame $1 [-l num | --word-length num]"
    echo "          [-x 'letters' | --exlcude-letters 'letters' ]"
    echo "          [-r 'letters' | --require-letters 'letters']"
    echo "          [-x 'pattern' | --exclude-pattern 'pattern']"
    echo "          [-r 'pattern' | --require_pattern 'pattern']"
    echo "          [-d <filename> | --dictionary <filename>]"
    echo ""
    echo "      -l, --word_length     - the length of the words to be used in the solving (defaults to 5)"
    echo "      -x, --exclude_letters - a list of letters to exclude, filters any word with any of these"
    echo "      -r, --require_letters - a list of letters to require, filters any word without one of these"
    echo "      -n, --negative_pattern - a regex pattern for excluding letters by position e.g. '..[^ae]..' to reject words with 'ae' in the 3rd letter"
    echo "      -p, --positive_pattern - a regex pattern for requiring letters by position e.g. '..a.e' to reject words without 'a' in the 3rd letter and 'e' in the 5th"
    echo "      -d, --dictionary - a file name to use as the word dictionary"
    echo
    echo "The default word list is currently set to '${BGAME_WORD_FILE}'."
    echo "Change the default word list file by setting 'BGAME_WORD_FILE'."
    echo "Use the -d or --dictionary option to set the file for a run."
    echo "To set it permmanently for the session:"
    echo '      export BGAME_WORD_FILE=/path/to/my_word_list.txt'
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
    declare WORD_LENGTH=5
    declare EXCLUDE
    declare MUST_HAVE
    declare NEGATIVE_PATTERN
    declare POSITIVE_PATTERN
    declare DICTIONARY


    while (( $# )); do

        case "$1" in
        -l|--word-length)
            WORD_LENGTH="$2"
            shift
            shift
            ;;
        -l=*|--word-length=*)
            WORD_LENGTH="${1##*=}"
            shift
            ;;

        -r|--require-letters)
            MUST_HAVE="$2"
            shift
            shift
            ;;
        -r=*|--require-letters=*)
            MUST_HAVE="${1##*=}"
            shift
            ;;


        -x|--exclude-letters)
            EXCLUDE="$2"
            shift
            shift
            ;;
        -x=*|--exclude-letters=*)
            EXCLUDE="${1##*=}"
            shift
            ;;

        -n|--negative-pattern)
            NEGATIVE_PATTERN="$2"
            shift
            shift
            ;;
        -n=*|--negative-pattern=*)
            NEGATIVE_PATTERN="${1##*=}"
            shift
            ;;

        -p|--positive-pattern)
            POSITIVE_PATTERN="$2"
            shift
            shift
            ;;
        -p=*|--positive-pattern=*)
            POSITIVE_PATTERN="${1##*=}"
            shift
            ;;

        -d|--dictionary)
            DICTIONARY="$2"
            shift
            shift
            ;;
        -d=*|--dictionary=*)
            DICTIONARY="${1##*=}"
            shift
            ;;

        *)
            echo "unknown option: '$1'"
            _bgame_wordle_usage 'wordle|wordle_try'
            return 1
            ;;
        esac

    done

    _limit_length "${WORD_LENGTH}" "${DICTIONARY}" \
    | _exclude_letters "${EXCLUDE}" \
    | _require_letters "${MUST_HAVE}" \
    | _exclude_pattern "${NEGATIVE_PATTERN}" \
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
    declare WORDS=()

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
    declare r
    r=$(head -c 4 /dev/urandom | od -An -tu4 | tr -d ' ')

    declare size=${#WORDS[@]}
    declare index=$((r % size))
    echo "${WORDS[$index]} (out of ${size} possible)"
}
