#!/usr/bin/env bash

LOCATION="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for s in repo bdocker baz venv bimage bnpm bzoom; do
    complete -o bashdefault -o default -W "$("${LOCATION}/${s}" | tr '\n' ' ')" "${s}"
done
