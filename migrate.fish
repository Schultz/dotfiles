#!/usr/bin/env fish
# migrate.fish — one-time: move existing ~/.config/{fish,zellij,nvim} into the
# dotfiles repo so stow can manage them. Idempotent: skips packages already
# migrated.

set -l here (status dirname)
set -l packages fish zellij nvim mise

function __log; set_color cyan; echo "==> $argv"; set_color normal; end
function __warn; set_color yellow; echo "!! $argv"; set_color normal; end

for pkg in $packages
    set -l src $HOME/.config/$pkg
    set -l dst $here/$pkg/.config/$pkg

    if test -d $dst
        echo "    $pkg: already migrated, skipping"
        continue
    end

    if not test -d $src
        __warn "$pkg: nothing at $src — nothing to migrate"
        continue
    end

    if test -L $src
        __warn "$pkg: $src is already a symlink — skipping"
        continue
    end

    __log "Migrating $pkg: $src → $dst"
    mkdir -p (dirname $dst)
    mv $src $dst
end

# Initialize git repo if needed
if not test -d $here/.git
    __log "git init"
    git -C $here init -q -b main
    git -C $here add -A
    git -C $here commit -q -m "import existing dotfiles"
end

# Re-stow immediately so the live ~/.config/* symlinks are
# in place before any new fish process can recreate fresh files.
__log "Stowing migrated packages"
set -l targets
for d in $packages
    if test -d $here/$d
        set -a targets $d
    end
end
if test (count $targets) -gt 0
    # --no-folding for the same reason as install.fish: folded dir symlinks
    # let fisher write plugin files back into the repo.
    stow --no-folding --dir=$here --target=$HOME --restow $targets
    __log "Linked: $targets"
end

__log "Migration complete. Now run: just install"
