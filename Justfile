# Dotfiles tasks. Run `just` to see this list.

# Use fish for recipes that aren't already a shell script.
set shell := ["fish", "-c"]

# Show available recipes.
default:
    @just --list --unsorted

# Full first-time setup on a fresh machine.
setup: bootstrap install

# Uses Homebrew on macOS and apt-get on Debian/Ubuntu.
[doc("Install fish, git, stow, curl via the system package manager.")]
bootstrap:
    sh ./bootstrap.sh

# Install dependencies (starship, fzf, tmux, etc), bootstrap fisher, and stow.
install:
    fish ./install.fish

# One-time: move existing ~/.config/{fish,zellij,nvim,mise} into this repo.
migrate:
    fish ./migrate.fish

# --no-folding keeps fish's functions/conf.d/completions as real dirs so
# fisher's writes don't leak back into the repo through a folded dir symlink.
[doc("(Re-)create the symlinks from this repo into $HOME.")]
stow:
    stow --no-folding --dir={{justfile_directory()}} --target=$HOME --restow \
        (fish {{justfile_directory()}}/packages.fish)

# Remove all symlinks for this repo from $HOME.
unstow:
    stow --no-folding --dir={{justfile_directory()}} --target=$HOME --delete \
        (fish {{justfile_directory()}}/packages.fish)

# Show what stow *would* do without changing anything.
stow-dry:
    stow --no-folding --dir={{justfile_directory()}} --target=$HOME --restow --no --verbose=2 \
        (fish {{justfile_directory()}}/packages.fish)

# Sync fish plugins listed in fish/.config/fish/fish_plugins.
plugins:
    fisher update

# Report which expected tools are present and which are missing.
doctor:
    fish ./doctor.fish

# Set fish as the default login shell for the current user.
chsh:
    sh ./bootstrap.sh chsh-only

# Deliberately does NOT delete ~/.config/fish/fish_variables. That file holds
# the universal var `_fisher_plugins`, fisher's record of what's installed.
# After every command fisher rewrites fish_plugins from that var, dropping any
# entry it thinks isn't installed — and fish_plugins is a symlink into this
# repo, so the truncation lands in git. Erasing fish_variables while fisher
# itself stays installed is exactly the state that wipes the plugin list.
[doc("Remove regenerable files at ~/.config/fish that block stow, then re-stow.")]
unstick:
    rm -f ~/.config/fish/fish_plugins \
          ~/.config/fish/completions/fisher.fish \
          ~/.config/fish/functions/fisher.fish
    just stow

# Not stow — their skills dirs already hold real per-tool content, so this
# links per-package instead of mirroring the whole target dir.
[doc("Symlink dotfiles/skills/* into ~/.claude/skills and ~/.codex/skills.")]
link-skills:
    fish ./link-skills.fish
