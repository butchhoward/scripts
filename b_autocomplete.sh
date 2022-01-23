#!/usr/bin/env bash

for s in repo bdocker baz venv bgame; do
    complete -W "$($s | tr '\n' ' ')" "$s"
done
