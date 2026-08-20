# Dotfiles tasks. Run `just` to see this list.

# Use fish for recipes that aren't already a shell script.
set shell := ["fish", "-c"]

# Show available recipes.
default:
    @just --list --unsorted

# Full first-time setup on a fresh machine.
setup: bootstrap install

# Install fish, git, stow, curl via the system package manager.
# Uses Homebrew on macOS and apt-get on Debian/Ubuntu.
bootstrap:
    sh ./bootstrap.sh

# Install dependencies (starship, fzf, tmux, etc), bootstrap fisher, and stow.
install:
    fish ./install.fish

# One-time: move existing ~/.config/{fish,alacritty} into this repo.
migrate:
    fish ./migrate.fish

# (Re-)create the symlinks from this repo into $HOME.
stow:
    stow --dir={{justfile_directory()}} --target=$HOME --restow alacritty fish zellij nvim

# Remove all symlinks for this repo from $HOME.
unstow:
    stow --dir={{justfile_directory()}} --target=$HOME --delete alacritty fish zellij nvim

# Show what stow *would* do without changing anything.
stow-dry:
    stow --dir={{justfile_directory()}} --target=$HOME --restow --no --verbose=2 alacritty fish zellij nvim

# Sync fish plugins listed in fish/.config/fish/fish_plugins.
plugins:
    fisher update

# Report which expected tools are present and which are missing.
doctor:
    fish ./doctor.fish

# Set fish as the default login shell for the current user.
chsh:
    sh ./bootstrap.sh chsh-only

# Remove regenerable files at ~/.config/fish that block stow, then re-stow.
unstick:
    rm -f ~/.config/fish/fish_variables \
          ~/.config/fish/fish_plugins \
          ~/.config/fish/completions/fisher.fish \
          ~/.config/fish/functions/fisher.fish
    just stow

# Symlink dotfiles/skills/* into ~/.claude/skills and ~/.codex/skills, so
# one SKILL.md is shared by both tools (not stow — their skills dirs
# already hold real per-tool content, so this links per-package instead
# of mirroring the whole target dir).
link-skills:
    #!/usr/bin/env fish
    set -l here {{justfile_directory()}}
    mkdir -p ~/.claude/skills ~/.codex/skills
    for pkg in $here/skills/*/
        set -l name (basename $pkg)
        ln -sfn $pkg ~/.claude/skills/$name
        ln -sfn $pkg ~/.codex/skills/$name
        echo "linked $name"
    end
