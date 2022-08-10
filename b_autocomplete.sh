#!/usr/bin/env bash

for s in repo bdocker baz venv bimage bnpm; do
    complete -o bashdefault -o default -W "$($s | tr '\n' ' ')" "$s"
done
