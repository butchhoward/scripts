#!/usr/bin/env bash
#source this script to get the useful functions

function docker_rm_all()
{
    docker rm "$(docker ps -aq)"
}

function docker_rmi_dangling()
{
    docker rmi "$(docker images -f "dangling=true" -q)"
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
function docker_rmi_matching()
{
    local MATCH_TARGET=${1:?"Give me something to match!"}
    docker rmi "$(docker images -qa --filter=reference="${MATCH_TARGET}")"
}
