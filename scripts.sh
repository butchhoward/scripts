#!/usr/bin/env bash
# shellcheck disable=SC1090,SC1091,SC2034

#source this script to get the useful functions
LOCATION="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "${LOCATION}/misc.sh"
source "${LOCATION}/venv_special.sh"
source "${LOCATION}/b_autocomplete.sh"

"${LOCATION}/bmacos" capslock_tab
