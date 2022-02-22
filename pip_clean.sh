#!/usr/bin/env bash

# pip uninstall everything

# while read -r package; do
#     pip uninstall -y "${package}"
# done < <(pip freeze)

pip list --format freeze --exclude pip --exclude wheel --exclude setuptools --exclude distribute  | xargs -t -n 1 -I {} pip uninstall -y '{}'
