#!/usr/bin/env bash

_repo_subcommands=$(repo | tr '\n' ' ')
_bdocker_subcommands=$(bdocker | tr '\n' ' ')
_baz_subcommands=$(baz | tr '\n' ' ')
_venv_subcommands=$(venv | tr '\n' ' ')

complete -W "${_repo_subcommands}" repo
complete -W "${_venv_subcommands}" venv
complete -W "${_bdocker_subcommands}" bdocker
complete -W "${_baz_subcommands}" baz
