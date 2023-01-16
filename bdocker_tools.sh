#!/usr/bin/env bash
#source this script to get the useful functions

function _bdocker_rm_all_help()
{
    echo "bdocker rm_all [ancestor]"
    echo "  Delete all containers"
    echo "  Delete all containers which have a specific container as an ancestor"
    echo
    echo "  ancestor "
    echo "     Filters containers which share a given image as an ancestor."
    echo "     Expressed as <image-name>[:<tag>], <image id>, or <image@digest>"
    echo "     (see the ancestor filter doc in the docker cli: https://docs.docker.com/engine/reference/commandline/ps/#-filtering---filter"
    echo
    echo "  Example:"
    echo
    echo "     bdocker rm_all 'leadingagilestudios/analysis/gather-cli'"

}

function bdocker_rm_all()
{
    local MATCH_TARGET="${1}"
    local FILTER=()

    if [ -n "${MATCH_TARGET}" ]; then
        FILTER=(--filter "ancestor='${MATCH_TARGET}'")
    fi

    docker container ls -a "${FILTER[@]}" | while IFS= read -r container_id; do
        docker container rm "${container_id}"
    done
}


function _bdocker_rmi_dangling_help()
{
    echo "bdocker rmi_dangling"
    echo "  Delete all unused images"
}

function bdocker_rmi_dangling()
{
    docker image prune --force
}

function _bdocker_rm_dangling_help()
{
    echo "bdocker rm_dangling"
    echo "  Remove all stopped containers"
}

function bdocker_rm_dangling()
{
    docker container prune --force
}


function _bdocker_rmi_matching_help()
{
    echo "bdocker rmi_matchingl <reference>"
    echo "  Delete all images matching the reference"
    echo
    echo "  if your image names have slashes (/) you MUST wildcard+escape them (see examples)"
    echo
    echo "  Examples:"
    echo
    echo "  Given a list of images like this:"
    echo
    echo "      REPOSITORY                                          TAG"
    echo "      drydock.workiva.net/workiva/cds                     0.0.68"
    echo "      leadingagilestudios.azurecr.io/analysis/gather-cli  0.2.2x"
    echo "      leadingagilestudios.azurecr.io/analysis/gather-dev  0.2.2x"
    echo "      gather                                              latest"
    echo "      leadingagilestudios.azurecr.io/analysis/gather      0.2.2x"
    echo
    echo "  Example uses:"
    echo '      bdocker_rmi_matching "drydock*\/*\/*'
    echo "      bdocker rmi_matching 'gather*:*'"
    echo "      bdocker rmi_matching 'leadingagilestudios*\/analysis\/*'"
    echo
    echo
    echo "  Use the command"
    echo '      docker images --filter=reference="drydock*\/*\/*"'
    echo '  to preview the list of images that will be removed'

}

function bdocker_rmi_matching()
{
    local MATCH_TARGET=${1:?"Give me something to match!"}

    docker image ls -qa --filter=reference="${MATCH_TARGET}" | while IFS= read -r image_id; do
        docker image rm -f "${image_id}"
    done
}
