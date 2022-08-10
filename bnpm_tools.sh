#!/usr/bin/env bash

BNPM_RC_FILE="$HOME/.npmrc"

_bnpm_save_rc_help()
{
    echo 'save current .npmrc to named file'
}

bnpm_save_rc()
{
    declare NEW_SUFFIX="$1"

    mv "${BNPM_RC_FILE}" "${BNPM_RC_FILE}_${NEW_SUFFIX}"

}

bnpm_switch_rc()
{
    declare NEW_SUFFIX="$1"

    cp  "${BNPM_RC_FILE}_${NEW_SUFFIX}" "${BNPM_RC_FILE}"
}