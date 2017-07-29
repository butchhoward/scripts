# Some Handy Scripts

I use these by sourcing them into the current session.

## venv_tools.sh

* `venv_*` scripts are for managing python virtual environments

  * Most assume you are working in a folder that is a github repository
  * If possible, the venv is created in a folder in `../venv/<Repo Name>`. The function `venv_location()` attempts to determine the location using the current git repository.


## repo_tools.sh

* `repo_*` scripts are for mananging git hub repositories

  * These are mostly helpful in folders that are collections of github reposiitories that relate to each other (as in for a single client)


## General

I tend to combine these in the form that makes sense for the particular client.

Example (`rvm_use_ruby_hisc`, `start_rabbit` are separate functions specific to this client):

```bash
function venv_rebuild()
{
    venv_deactivate
    rvm_use_ruby_hisc
    venv_create
    venv_activate
    venv_pip_upgrade
    venv_pip_reqiurements

    start_rabbit
}
```

# Candy

## gource-git-dir

Use the gource application to make a pretty graphic display of the commit history a folder full of git repositories. See the script for more information.
