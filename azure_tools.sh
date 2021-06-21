#!/usr/bin/env bash
#source this script to get the useful functions

# You have to be already logged in for these to work:
#   az login
#   az acr login --name leadingagilestudios

DEFAULT_REGISTRY="leadingagilestudios"

function baz_repositories()
{
    local REGISTRY="${1:-"${DEFAULT_REGISTRY}"}"

    az acr repository list --name "${REGISTRY}" | jq -r '.[]'
}

baz_repository_tags()
{
    local REGISTRY="${1:-"${DEFAULT_REGISTRY}"}"
    local REPOSITORY="${2:?"requires repository name"}"

    az acr repository show-manifests --name "${REGISTRY}" --repository "${REPOSITORY}" | jq -r '.[].tags[]'
}

baz_repository_images()
{
    local REPOSITORY="${1:?"requires repository name"}"
    local REGISTRY="${2:-"${DEFAULT_REGISTRY}"}"

    while read -r TAG; do
        echo "${REGISTRY}.azurecr.io/${REPOSITORY}:${TAG}"
    done < <(baz_repository_tags "${REGISTRY}" "${REPOSITORY}")
}

function baz_images()
{
    local REGISTRY="${1:-"${DEFAULT_REGISTRY}"}"

    while read -r REPOSITORY; do
        baz_repository_images "${REPOSITORY}" "${REGISTRY}"
    done < <(baz_repositories "${REGISTRY}")
}

function baz_delete_image()
{
    # note: 'image' does not include the repository prefix
    # for baz_images output 'leadingagilestudios.azurecr.io/analysis/gather-example:0.4'
    # use
    #   baz_delete_image analysis/gather-example:0.4

    local IMAGE="${1:?"requires image name:tag"}"
    local REGISTRY="${2:-"${DEFAULT_REGISTRY}"}"

    az acr repository delete --name "${REGISTRY}" --image "${IMAGE}"
}
