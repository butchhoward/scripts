#!/usr/bin/env bash

# pip uninstall everything

# while read -r package; do
#     pip uninstall -y "${package}"
# done < <(pip freeze)

pip freeze | xargs pip uninstall -y
