#!/usr/bin/env bash
#source this script to get the useful functions


function _bzoom_help()
{
    echo "Tools to handle Zoom tasks"
}

function _bzoom_save_recordings_help()
{
    echo "Save recordings captured from a Zoom recording."
    echo
    echo "  bzoom save_recordings archive_folder [pattern] [downloads_folder]"
    echo
    echo "  Copies a set of Zoom recording files from a downloads folder to an archive folder"
    echo "      archive_folder   - where the recordings will be stored. Required. Will be created if needed."
    echo "      pattern          - regex to match the recordins file name. [Optional] Defaults to '.*GMT.*Recording.*'"
    echo "      downloads_folder - folder where the recordings were saved from Zoom. [Optional] Defaults to '~/Downloads'"
}


function bzoom_save_recordings()
{
    declare ARCHIVE="${1:?"Must give an archive folder!"}"
    declare MATCHES="${2:-.*GMT.*Recording.*}"
    declare DOWNLOADS="${3:-"$HOME/Downloads"}"

    mkdir -p "${ARCHIVE}"
    find "${DOWNLOADS}/" -regex "${MATCHES}" -print -exec mv {} "${ARCHIVE}" \;
}
