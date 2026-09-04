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
`package.json`, not `node_modules`.

`just plugins` runs `fisher update`, which reconciles the machine against that
file. Listed but missing gets installed. Installed but unlisted gets removed.
To add a plugin, add the line and run `just plugins`.

Now the part that has cost this repo twice. After every command, fisher
rewrites `fish_plugins` from `_fisher_plugins`, a universal variable holding
what it believes is installed, dropping any line it cannot account for.
`fish_plugins` is symlinked into the repo, so that rewrite arrives as a git
change. If `_fisher_plugins` is only partly populated, say it lists fisher and
nothing else, the next fisher command quietly truncates `fish_plugins` to match
and the other plugins vanish from git.

Two things prevent that, and neither is safe to tidy away.

`install.fish` never runs `fisher install jorgebucaran/fisher`. That command
merges in the file's contents only when `_fisher_plugins` is completely empty.
With fisher alone recorded, it truncates instead. Sourcing `fisher.fish` and
letting `fisher update` read the manifest avoids it.

`just unstick` never deletes `~/.config/fish/fish_variables`. `_fisher_plugins`
lives in that file, and erasing it while fisher stays installed produces
exactly the partial state above.

If `fish_plugins` ever shrinks on its own, restore it before reinstalling:

```fish
git checkout HEAD -- fish/.config/fish/fish_plugins
just plugins
```

The order matters. Run `just plugins` first and nothing happens, because the
truncated file already agrees with the machine.

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
