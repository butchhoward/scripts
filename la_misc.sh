#!/usr/bin/env bash
#source this script to get the useful functions
# shellcheck disable=SC1090
# SC1090 -> don't try to follow sourced files

# Add meta: {} and data: {} elements to OLD json
function la_fix_old_stats_one()
{
    local f=${1:?"provide a statistics.json file"}

    jq '. | {meta:{}, data: .}' "$f" > "mod_$f"
    mv "mod_$f" "$f"
}


# process all stats file in current folder
function la_fix_old_stats()
{
    for f in *_statistics.json; do
        la_fix_old_stats_one "$f"
    done
}

# REMOVE meta: {} and data: {} eelements from mistakenly fixed json
function la_un_fix_stats_one()
{
    local f=${1:?"provide a statistics.json file"}

    jq '.data ' "$f" > "mod_$f"
    mv "mod_$f" "$f"
}

# process all stats file in current folder
function la_un_fix_stats()
{
    for f in *_statistics.json; do
        la_un_fix_stats_one "$f"
    done
}

function sample_code_reset()
{
    pushd ~/projects/la/sample_code || return 1

    for d in ./*; do
        pushd "$d" || return 1
        git checkout main || git checkout master || git checkout develop
        popd || return 1
    done

    popd || return 1
}
