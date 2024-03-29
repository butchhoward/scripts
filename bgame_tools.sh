#!/usr/bin/env bash

# To use a different word list, export BGAME_WORD_FILE="<path to word file"
: "${BGAME_WORD_FILE:="${BHTOOLS_PROJECTS_PATH:-$HOME/projects}/scripts/dict_wordle_winners.txt"}"

function _bgame_wordle_usage
{
    echo "Usage:"
    echo " bgame $1 [-l num | --word-length num]"
    echo "          [-x 'letters' | --exlcude-letters 'letters' ]"
    echo "          [-r 'letters' | --require-letters 'letters']"
    echo "          [[-n 'pattern' | --negative-pattern 'pattern'] ...]"
    echo "          [-p 'pattern' | --positive-pattern 'pattern']"
    echo "          [-d <filename> | --dictionary <filename>]"
    echo "          [--dw ]"
    echo "          [--dv ]"
    echo ""
    echo "      -l, --word_length     - the length of the words to be used in the solving (defaults to 5)"
    echo "      -x, --exclude-letters - a list of letters to exclude, filters any word with any of these"
    echo "      -r, --require-letters - a list of letters to require, filters any word without one of these"
    echo "      -n, --negaative-pattern - regex pattern(s) for excluding letters by position (can used multiple times) e.g. -n '..a..' -n '..e..' to reject words with 'a' or 'e' in the 3rd letter"
    echo "      -p, --positive-pattern - a regex pattern for requiring letters by position e.g. '..a.e' to reject words without 'a' in the 3rd letter and 'e' in the 5th"
    echo "      -d, --dictionary - a file name to use as the word dictionary. The dictionary can also be provided though STDIN, or the default dictionary setting (see below)"
    echo "      --dw - use the wordles winning-words dictionary"
    echo "      --dv - use the wordles valid-words dictionary. This is the default dictionary."
    echo
    echo "The default word list is currently set to '${BGAME_WORD_FILE}'."
    echo "Change the default word list file by setting 'BGAME_WORD_FILE'."
    echo "Use the -d or --dictionary option to set the file for a run."
    echo "To set it permmanently for the session:"
    echo '      export BGAME_WORD_FILE=/path/to/my_word_list.txt'
    echo "The dictionary can also be read from STDIN."
    echo "The dictionary data source will be the first of STDIN (if present), -d <file> (if given), default file."
    echo
    echo "The dictionary data must have a single word on each line."
    echo
    echo "Examples:"
    echo "  While solving a Wordle game:"
    echo "      bgame wordle -x 'iteol' -r 'ars' -n '.[^r][^a]..' -p 's..ar'"
    echo "  Choosing a random word from the words made with frequent letters (results from first piped as dictionary to try)"
    echo "      bgame wordle -p '[eariotnslcud]{5}' | bgame wordle_try"
    echo "  Use a list of primes as the dictionary (for playing primel)"
    echo "      bgame wordle_try -d ~/primes-to-100k.txt"
}

function _bgame_wordle_help()
{
    echo "A tool to help solving 5-letter word puzzled like Wordle and Absurdle"
    echo "The output is a list of words limited by the options given"
    _bgame_wordle_usage "wordle"
}

function bgame_wordle()
{
    _bgame_wordle "$@"
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
        declare WORDLE_FD WORDLE_PID
        exec {WORDLE_FD}< <(_bgame_wordle "$@")
        WORDLE_PID=$!
        mapfile -t WORDS <& "${WORDLE_FD}"
        exec {WORDLE_FD}<&-
        wait "${WORDLE_PID}" || return 1
    else
        while read -r WORD; do
            WORDS+=("${WORD}")
        done < <(_bgame_wordle "$@")
    fi

    declare RESULT_WORD
    declare RESULT_SIZE=${#WORDS[@]}
    declare RESULT_RC=0

    if (( RESULT_SIZE == 0 )); then
        RESULT_RC=1
    else
        declare INDEX
        if (( RESULT_SIZE == 1 )); then
            INDEX=0
        else
            # use /dev/urandom because the word list is larger than 32k
            declare r
            r=$(head -c 4 /dev/urandom | od -An -tu4 | tr -d ' ')
            INDEX=$((r % RESULT_SIZE))
        fi
        RESULT_WORD="${WORDS[${INDEX}]}"
    fi


    printf "%s (out of %d possible)\n" "${RESULT_WORD}" "${RESULT_SIZE}"
    return ${RESULT_RC}
}


function _limit_length()
{
    declare LENGTH=${1-:5}
    declare DICTIONARY="${2}"

    if [[ -p /dev/stdin ]]; then
        # echo "dictionary is stdin" >&2

        while IFS=$'\r\n' read -r WORD; do
            if (( ${#WORD} == LENGTH )); then
                echo "${WORD}"
            fi
        done < <(cat -)
    else
        : "${DICTIONARY:="${BGAME_WORD_FILE}"}"

        if ! [ -r "${DICTIONARY}" ]; then
            echo "cannot read word file '${DICTIONARY}'" >&2
            return 1
        fi

        # echo "dictionary file is '${DICTIONARY}'" >&2

        while IFS=$'\r\n' read -r WORD; do
            if (( ${#WORD} == LENGTH )); then
                echo "${WORD}"
            fi
        done < "${DICTIONARY}"
    fi
}

function _exclude_letters()
{
    if [ -z "$1" ]; then
        cat -
        return $?
    fi

    declare letters="$1"

    cat - | grep -E -e "[^${letters}]{5}"
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

    declare WORD_LENGTH="$1"
    shift

    if (( "$#" == 0 )) ; then
        cat -
        return $?
    fi

    # build regex pattern from multiple simple patterns passed in
    # '..a..' '.a.o.' '.d...' -> '.[^ad][^a][^o].'


    declare letter_sets=()
    while (( "$#" != 0 )); do
        declare letters="$1"
        for (( i=0; i<WORD_LENGTH; i++ )); do
            if [[ "${letters:$i:1}" != "." ]]; then
                letter_sets[$i]="${letter_sets[$i]}${letters:$i:1}"
            fi
        done
        shift
    done

    declare pattern
    for (( i=0; i<WORD_LENGTH; i++)); do
        if [[ -z "${letter_sets[$i]}" ]]; then
            pattern+="."
        else
            pattern+="[^${letter_sets[$i]}]"
        fi
    done
    declare cmd="grep -E '${pattern}'"

    cat - | eval "${cmd}"
}

function _bgame_wordle()
{
    declare WORD_LENGTH=5
    declare EXCLUDE
    declare MUST_HAVE
    declare NEGATIVE_PATTERNS=()
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
            NEGATIVE_PATTERNS+=("$2")
            shift
            shift
            ;;
        -n=*|--negative-pattern=*)
            NEGATIVE_PATTERNS=("${1##*=}")
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
        --dw)
            DICTIONARY="${BHTOOLS_PROJECTS_PATH:-$HOME/projects}/scripts/dict_wordle_winners.txt"
            shift
            ;;
        --dv)
            DICTIONARY="${BHTOOLS_PROJECTS_PATH:-$HOME/projects}/scripts/dict_wordle_valid.txt"
            shift
            ;;


        *)
            echo "unknown option: '$1'" >&2
            _bgame_wordle_usage 'wordle|wordle_try' >&2
            return 1
            ;;
        esac

    done

    _limit_length "${WORD_LENGTH}" "${DICTIONARY}" \
    | _exclude_letters "${EXCLUDE}" \
    | _require_letters "${MUST_HAVE}" \
    | _exclude_pattern "${WORD_LENGTH}" "${NEGATIVE_PATTERNS[@]}" \
    | _require_pattern "${POSITIVE_PATTERN}"
}
