# dotfiles

Stow-managed configs for fish and alacritty. Targets macOS and Debian/Ubuntu.

## First time on this machine (the one that already has my configs)

```fish
cd ~/dotfiles
just migrate   # moves ~/.config/{fish,alacritty} into this repo
just install   # installs deps, bootstraps fisher, stows
```

## Fresh machine

```sh
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
just setup     # bootstrap + install
```

## Day to day

```fish
just stow      # re-link after adding a file
just plugins   # `fisher update` — sync fish plugins
just unstow    # remove symlinks
```

## Adding a new package

1. Make a top-level dir whose layout mirrors `$HOME`. E.g. for `~/.config/foo`:
   `dotfiles/foo/.config/foo/...`
2. Add `foo` to the `stow` / `unstow` recipes in `Justfile` and to the loop
   in `install.fish`.
3. Add an install rule for `foo` in `install.fish` (`__dot_install` switch).

## Skills (Claude Code + Codex, shared)

`skills/<name>/SKILL.md` holds one canonical copy per skill. `just link-skills`
symlinks each into both `~/.claude/skills/` and `~/.codex/skills/` (plain
`ln -sfn`, not stow — those dirs already hold real per-tool content, so
mirroring the whole target dir would conflict). Re-run it after adding a
skill.

## What's intentionally not committed

See `.gitignore`. Fisher-installed plugin files live under `fish/.config/fish/{functions,completions,conf.d}/` and *are* committed for now — they'll be overwritten the next time `fisher update` runs, which is fine.
