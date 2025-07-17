# Zsh-Per-Project-History

Per-project history for Zsh. With the option to switch between
the project and global histories with ^G.

The implementation is based on https://github.com/jimhester/per-directory-history

Instead of creating a separate history for each directory you
change to, it creates separate histories only for directories
that are 'tagged' with some custom file, be it `.git`, `.envrc`
or something else (it is customizable).

For any directory you change to, it will check if that directory
or any of its parents (it will search for the closest parent)
contain the 'tag' file and it will use that directory as the project root
thus creating a separate history for it.

## Installation and configuration

You just create an array named `PER_PROJECT_HISTORY_TAGS` that
contains all the file names you want to be used for detecting
the project roots:

```
declare -a PER_PROJECT_HISTORY_TAGS
PER_PROJECT_HISTORY_TAGS=(.envrc .should_have_per_project_history)
declare -r PER_PROJECT_HISTORY_TAGS
```

In the example above, any directory that I defined custom environment
variables for using direnv's `.envrc` will be treated as project roots,
along with any directory explicitly tagged with `.should_have_per_project_history`.

This is useful when you have several source repositories inside
of a single project that should all have a common history,
so you can't use `.git` as a tag to detect the project root.

If you don't define your own tags, the default ones will be used
(`.git .hg .jj .stack-work .cabal .cargo .envrc .per_project_history`).

Then you just source the `per-project-history.zsh` file
from this repo.

Or, if you use a plugin manager, add `ivan-cukic/per-project-history`
to the list of plugins. For Zinit, it would look like this:

```
zinit light ivan-cukic/per-project-history
```
