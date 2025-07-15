Per-Project-History
===================

Per-project history for Zsh, as well as global history, and the
ability to toggle between them with ^G.

This is a implementation of per-project history for Zsh based
on https://github.com/jimhester/per-directory-history

Instead of creating a separate history for each directory, it
creates separate histories only for directories that are 'tagged'
with some custom file, be it `.git`, `.envrc` or something else
(it is customizable).

For any directory you change to, it will check if that directory
or any of its parents (it will search for the closest parent)
contain the 'tag' file and use that directory as the history owner.
