#!/usr/bin/env bash

for s in repo bdocker baz venv bimage bnpm bzoom; do
    complete -o bashdefault -o default -W "$($s | tr '\n' ' ')" "$s"
done
