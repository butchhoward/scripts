# Some Handy Scripts

I use these by sourcing them into the current session.

(mostly, there are a couple of Candy scripts that I use directly.)

## venv_tools.sh

* `venv_*` functions are for managing python virtual environments

  * Most assume you are working in a folder that is a git repository
  * If possible, the venv is created in a folder in `../venv/<Repo Name>`. The function `venv_location()` attempts to determine the location using the current git repository.


## repo_tools.sh

* `repo_*` functions are for mananging git  repositories

  * These are mostly helpful in folders that are collections of git reposiitories that relate to each other (as in for a single client)


## docker_tools.sh

Docker functions

## misc.sh

General use functions


## scripts.sh

A script to source all the scripts (other than the Candy scripts).

This is the one I source from my `.bash_rc` so all my terminal session have all the tools all the time.

# Candy

## gource-git-dir

Use the gource application to make a pretty graphic display of the commit history a folder full of git repositories. See the script for more information.

## fuckingping

A script to report the status of the network by pinging some well-known IP addresses. This helped while I was working from home and having some network/ISP issues.

