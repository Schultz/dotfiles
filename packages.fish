#!/usr/bin/env fish
# packages.fish — print this repo's stow packages, one per line.
#
# A stow package mirrors $HOME, so it holds at least one dotfile or dotdir
# (fish/.config, nvim/.config, and so on). skills/ holds neither, because
# `just link-skills` links it per-package instead of stowing it.
#
# Deriving the list means adding a package is just creating its directory.
# Justfile and install.fish both read this, so the rule lives in one place.
# migrate.fish keeps its own list on purpose: it imports ~/.config/X before
# the directory exists here, so there is nothing to derive from.

set -l here (status dirname)

for d in $here/*/
    # .DS_Store alone does not make a directory a package.
    if test (count (find $d -maxdepth 1 -mindepth 1 -name '.*' -not -name '.DS_Store')) -gt 0
        basename $d
    end
end
