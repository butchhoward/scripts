#!/usr/bin/env bash

for s in repo bdocker baz venv bgame; do
    complete -o bashdefault -o default -W "$($s | tr '\n' ' ')" "$s"
done
