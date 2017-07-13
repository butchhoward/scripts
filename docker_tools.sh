#source this script to get the useful functions

function docker_rm_all()
{
    docker rm $(docker ps -aq)
}

function docker_rmi_dangling()
{
    docker rmi $(docker images -f "dangling=true" -q)
}

function docker_rmi_matching()
{
    local MATCH_TARGET=${1:?"Give me something to match!"}
    docker rmi $(docker images -q "${MATCH_TARGET}")
}