# dotfiles

Stow-managed configs for fish, zellij, nvim and mise. Targets macOS and
Debian/Ubuntu.

## Machine that already has my configs

```fish
cd ~/dotfiles
just migrate   # moves existing ~/.config/{fish,zellij,nvim,mise} into this repo
just install   # installs deps, bootstraps fisher, stows
```

## Fresh machine

```sh
git clone <repo-url> ~/dotfiles
cd ~/dotfiles
just setup     # bootstrap + install
```

On a Mac out of the box there is no git to clone with. Running `git` at all
pops the Xcode Command Line Tools dialog, so accept that, wait for it, then
clone. `bootstrap.sh` installs git too, but that does not help you get
`bootstrap.sh` in the first place. If you would rather not wait on the dialog:

```sh
xcode-select --install
```

## Day to day

```fish
just stow      # re-link after adding a file
just plugins   # sync fish plugins with fisher update
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

`packages.fish` works out which directories those are, so no list needs
maintaining. A directory counts as a package when it holds at least one
dotfile or dotdir, which is what mirroring `$HOME` means in practice.

`skills/` is the one top-level directory stow does not handle. It is still
part of the dotfiles and still tracked, it just does not belong under
`~/.config`. Skills go to `~/.claude/skills/` and `~/.codex/skills/`, which
`link-skills.fish` takes care of. `just install` runs it, so a fresh machine
gets the skills without a separate step.

Every stow call passes `--no-folding`. Without it stow folds. Once every file
in `~/.config/fish/functions/` comes from this repo, stow throws away that
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

Alacritty has no directory here because it has no config. It reads
`alacritty.toml` only if you create one, and ships with defaults otherwise.
Write one at `alacritty/.config/alacritty/alacritty.toml` and `just stow`
picks it up with no list to edit.

Nothing a tool generates, and nothing that only applies to one machine.
Fisher's plugin files, `fish_variables`, `fish_history` and `.claude/` are
either gitignored or never written here any more. `.gitignore` has the list.

Two files look generated but are not. `conf.d/.gitnow` holds custom gitnow
keybindings, and `conf.d/artisan.fish` holds the `art*` abbreviations. Both
should stay tracked.

## Adding a new package

1. Make a top-level directory whose layout mirrors `$HOME`. For `~/.config/foo`:
   `dotfiles/foo/.config/foo/...`
2. Run `just stow`. `packages.fish` picks the directory up on its own.
3. If `foo` is also a program to install, add it to the `tools` list in
   `install.fish`, give it an install rule in the `__dot_install` switch, and
   add it to the checks in `doctor.fish`.

`migrate.fish` keeps a hand-written list, and it is the one place that has to.
It imports `~/.config/foo` before that directory exists here, so there is
nothing to derive from. Add the name there only if you want `just migrate` to
pull an existing config in on another machine.

## Skills (Claude Code + Codex, shared)

`skills/<name>/SKILL.md` holds one canonical copy per skill.
`link-skills.fish` symlinks each into `~/.claude/skills/` and
`~/.codex/skills/`. It uses plain `ln -sfn` rather than stow, because both
directories already hold real per-tool content and mirroring the whole target
directory would conflict.

`just install` runs it, so this happens on setup. Run `just link-skills`
directly after adding a skill.

## When stow refuses to link

"existing target is not a symlink" means a real file is sitting where a symlink
belongs. If the file is regenerable, `just unstick` deletes `fish_plugins` and
fisher's two `fisher.fish` copies, then re-stows. Otherwise move the real file
into the repo and run `just stow`.
