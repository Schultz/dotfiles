# dotfiles

Stow-managed configs for fish, zellij, nvim and mise. Targets macOS and
Debian/Ubuntu.

## First time on this machine (the one that already has my configs)

```fish
cd ~/dotfiles
just migrate   # moves existing ~/.config/{fish,zellij,nvim} into this repo
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
just doctor    # report which expected tools are missing
just unstow    # remove symlinks
```

## How it works

Three parts. stow places the files, fisher manages fish plugins, just drives
both.

### stow

Each top-level directory is a stow package, laid out the way it should appear
under `$HOME`. So `fish/.config/fish/config.fish` here becomes
`~/.config/fish/config.fish` on disk, as a symlink pointing back into the repo.
Edit either path. Same file.

The `packages` variable at the top of `Justfile` holds the list. Names with no
matching directory get skipped, so a package can be listed before it has been
migrated.

Every stow call passes `--no-folding`. Without it stow folds: once every file
in `~/.config/fish/functions/` comes from this repo, stow throws away the
directory and leaves a single symlink to the repo directory in its place.
Fisher installs plugins by writing into that directory. The writes follow the
symlink and the plugin files land in the repo. That is how roughly 90 plugin
files ended up committed here. `--no-folding` keeps real directories holding
per-file symlinks, so fisher's writes stay in `$HOME`.

`install.fish` deletes leftover directory symlinks from an older folded stow
before re-stowing, so an existing machine repairs itself on the next
`just install`.

### fisher

`fish/.config/fish/fish_plugins` lists which plugins to install. The plugins'
own files are not committed. Fisher downloads them at install time. Think
`package.json`, not `node_modules`. To add one, add the line and run
`just plugins`, which reconciles the machine against the file: listed but
missing gets installed, installed but unlisted gets removed.

Watch one thing, which has cost this repo twice. Fisher rewrites
`fish_plugins` after every command, keeping only what the universal variable
`_fisher_plugins` says is installed. The file is symlinked into the repo, so
when `_fisher_plugins` is partly populated the rewrite truncates the manifest
in git. Two pieces of code prevent this and both look like dead weight.
`install.fish` omits `fisher install jorgebucaran/fisher`, which merges the
file in only when `_fisher_plugins` is empty and truncates when it is partly
populated. `just unstick` leaves `fish_variables` alone, which is where
`_fisher_plugins` lives. Leave both as they are.

Recovering a truncated manifest, in this order:

```fish
git checkout HEAD -- fish/.config/fish/fish_plugins
just plugins
```

Reversing the order does nothing, since the truncated file already agrees with
the machine.

### What gets committed

Config you wrote: `config.fish`, everything in `conf.d/`, your own functions
and completions, `fish_plugins`, the nvim lockfile, mise's `config.toml`.

Nothing a tool generates, and nothing that only applies to one machine.
Fisher's plugin files, `fish_variables`, `fish_history` and `.claude/` are
either gitignored or never written here any more. `.gitignore` has the list.

Two files look generated but are not. `conf.d/.gitnow` holds custom gitnow
keybindings, and `conf.d/artisan.fish` holds the `art*` abbreviations. Both
should stay tracked.

## Adding a new package

1. Make a top-level dir whose layout mirrors `$HOME`. E.g. for `~/.config/foo`:
   `dotfiles/foo/.config/foo/...`
2. Add `foo` to the `packages` variable at the top of `Justfile`, and to the
   loop in `install.fish`.
3. Add an install rule for `foo` in `install.fish` (`__dot_install` switch) and
   to the checks in `doctor.fish`.

## Skills (Claude Code + Codex, shared)

`skills/<name>/SKILL.md` holds one canonical copy per skill. `just link-skills`
symlinks each into both `~/.claude/skills/` and `~/.codex/skills/` (plain
`ln -sfn`, not stow — those dirs already hold real per-tool content, so
mirroring the whole target dir would conflict). Re-run it after adding a
skill.

## When stow refuses to link

"existing target is not a symlink" means a real file is sitting where a symlink
belongs. If the file is regenerable, `just unstick` clears the usual suspects
and re-stows. Otherwise move the real file into the repo and run `just stow`.
