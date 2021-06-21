#!/usr/bin/env bash
#source this script to get the useful functions

function docker_rm_all()
{
    local MATCH_TARGET=${1}
    local FILTER=""

    if [ -n "${MATCH_TARGET}" ]; then
        FILTER="--filter \"ancestor=${MATCH_TARGET}\""
    fi

    docker container ls -aq "${FILTER}" | while IFS= read -r container_id; do
        docker container rm "${container_id}"
    done
}

function docker_rmi_dangling()
{

    docker image ls -f "dangling=true" -q | while IFS= read -r image_id; do
        docker image rm "${image_id}"
    done
}


# uses the docker images --filter flag
# if your image names have slashes (/) you MUST wildcard+escape them
# REPOSITORY                                       TAG
# drydock.workiva.net/workiva/cds                  0.0.68
#
# docker_rmi_matching "drydock*\/*\/*"
#
# use
# docker images --filter=reference="drydock*\/*\/*"
# to preview the list of images that will be removed
#
# example:
#    docker_rmi_matching 'gather*:*'
function docker_rmi_matching()
{
    local MATCH_TARGET=${1:?"Give me something to match!"}

    docker image ls -qa --filter=reference="${MATCH_TARGET}" | while IFS= read -r image_id; do
        docker image rm -f "${image_id}"
    done
}
