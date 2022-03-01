#!/usr/bin/env bash
#source this script to get the useful functions

# You have to be already logged in for these to work:
#   az login
#   az acr login --name leadingagilestudios

DEFAULT_REGISTRY="leadingagilestudios"

function _baz_repositories_help()
{
    echo
    echo "baz repositories [registry-name]"
    echo "List container repositories in the registry. Registry defaults to '${DEFAULT_REGISTRY}'"
    echo
    echo "baz repositories"
}

function baz_repositories()
{
    local REGISTRY="${1:-"${DEFAULT_REGISTRY}"}"

    az acr repository list --name "${REGISTRY}" | jq -r '.[]'
}

function _baz_repository_tags_help()
{
    echo
    echo "baz repository_tags repository-name [registry-name] "
    echo "List image tags (verison id) for a repository in a registry."
    echo "Registry defaults to '${DEFAULT_REGISTRY}'"
    echo
    echo "baz repository_tags analysis/gather"

}

baz_repository_tags()
{
    local REPOSITORY="${1:?"requires repository name"}"
    local REGISTRY="${2:-"${DEFAULT_REGISTRY}"}"

    az acr repository show-manifests --name "${REGISTRY}" --repository "${REPOSITORY}" | jq -r '.[].tags[]'
}


function _baz_repository_images_help()
{
    echo
    echo "baz repository_images repository-name [registry-name] "
    echo "List images for a repository in a registry."
    echo "Registry defaults to '${DEFAULT_REGISTRY}'"
    echo
    echo "baz repository_images analysis/gather"

}

baz_repository_images()
{
    local REPOSITORY="${1:?"requires repository name"}"
    local REGISTRY="${2:-"${DEFAULT_REGISTRY}"}"

    while read -r TAG; do
        echo "${REGISTRY}.azurecr.io/${REPOSITORY}:${TAG}"
    done < <(baz_repository_tags "${REPOSITORY}" "${REGISTRY}")
}


function _baz_images_all_help()
{
    echo
    echo "baz images_all [registry-name] "
    echo "List all images for all repositories in a registry."
    echo "Registry defaults to '${DEFAULT_REGISTRY}'"
    echo
    echo "baz images_all"

}

function baz_images_all()
{
    local REGISTRY="${1:-"${DEFAULT_REGISTRY}"}"

    while read -r REPOSITORY; do
        baz_repository_images "${REPOSITORY}" "${REGISTRY}"
    done < <(baz_repositories "${REGISTRY}")
}


function _baz_images_help()
{
    echo
    echo "baz images [pattern] [registry-name] "
    echo "List images in a registry."
    echo "Pattern defaults to '.*'  (i.e. all images)"
    echo "Registry defaults to '${DEFAULT_REGISTRY}'"
    echo
    echo "baz images"
    echo "baz images 'analysis.*0\.1\.'"

}

function baz_images()
{
    local PATTERN="${1:-".*"}"
    local REGISTRY="${2:-"${DEFAULT_REGISTRY}"}"

    while read -r REPOSITORY; do
        grep -E "${PATTERN}" <(baz_repository_images "${REPOSITORY}" "${REGISTRY}")
    done < <(baz_repositories "${REGISTRY}")
}

function _baz_delete_image_help()
{
    echo
    echo "baz delete_image [image] [registry-name] "
    echo "Delete an image from the registry."
    echo "Image must be the image name with any tags, but not including the registry name."
    echo "Registry defaults to '${DEFAULT_REGISTRY}'"
    echo
    echo "WARNING!  Use with caution! The image named will be immediately DELETED."
    echo
    echo "baz delete_image analysis/gather-example:0.4"

}

function baz_delete_image()
{
    # note: 'image' does not include the repository prefix
    # for baz_images output 'leadingagilestudios.azurecr.io/analysis/gather-example:0.4'
    # use
    #   baz_delete_image analysis/gather-example:0.4

    local IMAGE="${1:?"requires image name:tag"}"
    local REGISTRY="${2:-"${DEFAULT_REGISTRY}"}"

    az acr repository delete --yes --name "${REGISTRY}" --image "${IMAGE}"
}


function _baz_delete_image_match_help()
{
    echo
    echo "baz delete_image_match pattern [registry-name] "
    echo "Pattern is requried. Use a regex pattern."
    echo "Delete all matching images in a registry."
    echo "Registry defaults to '${DEFAULT_REGISTRY}'"
    echo
    echo "WARNING!  Use with caution! The images matched will be immediately DELETED."
    echo "Check the pattern using 'baz images pattern' "
    echo
    echo "baz delete_image_match 'analysis.*0\.1\.'"

}

function baz_delete_image_match()
{
    local PATTERN="${1:?"requires regex pattern for image matching e.g. 'analysis.*0\.1\.'"}"
    local REGISTRY="${2:-"${DEFAULT_REGISTRY}"}"

    for REPOSITORY in $(baz_images "${PATTERN}" "${REGISTRY}"); do
        #                trim to just image tag
        baz_delete_image "${REPOSITORY#"${REGISTRY}.azurecr.io/"}" "${REGISTRY}"
    done
}
