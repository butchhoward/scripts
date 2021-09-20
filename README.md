# Some Handy Scripts

I use these by sourcing them into the current session.

(mostly, there are a couple of Candy scripts that I use directly.)

## Non-Sourced versions

I converted most of these to libraries instead of being sourced into the current session.

The new apps are simple names (no `.sh`) that handle some command mapping and use the current libraries to do the work.

The functons in `misc.sh` are left there and are still sourced in until I figure out whether to move them to individual files or keep them as sourced functions.

For all of these using the command without a subcommand, shows a list of all the subcommand available for it.

The `help` subcommand is available for all of the commands and shows some documentation for each of the subcommands.

### Bash Profile

Add these lines to the `.bash_profile` or `.bashrc` to set the path and to enable (simple) auto complete for the commands:

```shell
#bhtools
BHTOOLS_PATH="$HOME/projects/bh/scripts"
if [ -f "${BHTOOLS_PATH}/scripts.sh" ]; then source "${BHTOOLS_PATH}/scripts.sh"; fi
export PATH="${BHTOOLS_PATH}/scripts:$PATH"

source "${BHTOOLS_PATH}/b_autocomplete.sh"
```


## repo

`repo` functions for mananging git  repositories


One added thing for repo is to duplicate it to `git-repo` so it can be used as a `git` command:

Then use it as a `git` sub-command:
```
git repo current_branch
```

This works because `git` uses any executable that begins with `git-` as a sub-command where the name following the dash is the sub-command name.

## venv

`venv` functions are for managing python virtual environments

* Most assume you are working in a folder that is a git repository
* If possible, the venv is created in a folder in `../venv/<Repo Name>`. The function `venv_location()` attempts to determine the location using the current git repository.

## bdocker

Tools for docker images

## baz

Tools for the Azure cli

## Libraries

These are the meat of the above stand-alones.

Sourcing them into the current session is still supported, but not how I am using them any more.

### venv_tools.sh
### repo_tools.sh
### bdocker_tools.sh
### baz_tools.sh

## misc.sh
General use functions

## scripts.sh

A script to source the scripts which are not stand-alone tools.

This is the one I source from my `.bash_rc` so all my terminal session have all the tools all the time.

# Candy

## gource-git-dir

Use the gource application to make a pretty graphic display of the commit history a folder full of git repositories. See the script for more information.

## fuckingping

A script to report the status of the network by pinging some well-known IP addresses. This helped while I was working from home and having some network/ISP issues.
