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
git clone git@github.com:Schultz/dotfiles.git ~/dotfiles
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

Three moving parts: **stow** puts the files in place, **fisher** manages fish
plugins, and **just** drives both.

### stow — symlinks, one package per top-level dir

Each top-level directory is a stow *package* whose internal layout mirrors
`$HOME`. So `fish/.config/fish/config.fish` in this repo becomes
`~/.config/fish/config.fish` on disk, as a symlink pointing back here. Edit
either path — they're the same file.

The package list lives in one place, the `packages` variable at the top of
`Justfile`. Names whose directory doesn't exist in the repo are skipped at
runtime, so a package can be listed before it's been migrated.

**Everything is stowed with `--no-folding`, and that matters.** By default
stow "folds": if every file in `~/.config/fish/functions/` comes from this
repo, it replaces the whole directory with a single symlink to the repo dir.
That is fine for static config and actively harmful here — fisher installs
plugins by writing into `~/.config/fish/functions/`, and through a folded
directory symlink those writes land *inside this repo*. That's how ~90 plugin
files ended up committed. `--no-folding` forces real directories containing
per-file symlinks, so fisher's writes stay in `$HOME` where they belong.

`install.fish` also deletes any dir-level symlink left over from an older
folded stow before re-stowing, so upgrading an existing machine is a no-op.

### fisher — `fish_plugins` is the manifest

`fish/.config/fish/fish_plugins` is the source of truth for which plugins get
installed. It's the `package.json` here, not the `node_modules`: the plugins'
actual files are **not** committed, they're fetched at install time.

`just plugins` (i.e. `fisher update`) reconciles the machine to that file —
anything listed but missing gets installed, anything installed but unlisted
gets removed. To add a plugin, add the line and run `just plugins`.

One sharp edge worth knowing, because it has bitten this repo twice. After
*every* command, fisher rewrites `fish_plugins` from the universal variable
`_fisher_plugins` — its record of what's actually installed — keeping only
entries it believes are present. Since `fish_plugins` is symlinked into this
repo, that rewrite is a commit-able change. If `_fisher_plugins` is ever
*partially* populated (say it lists only fisher itself), the next fisher
command silently truncates `fish_plugins` down to match, and the other plugins
are gone from git.

Two things guard against that now, and both are load-bearing:

- `install.fish` does **not** run `fisher install jorgebucaran/fisher`. That
  command only merges in the file's contents when `_fisher_plugins` is
  entirely empty; with fisher alone recorded, it truncates instead. Sourcing
  `fisher.fish` and letting `fisher update` read the manifest is the safe path.
- `just unstick` does **not** delete `~/.config/fish/fish_variables`. That file
  is where `_fisher_plugins` lives, and erasing it while fisher stays installed
  produces exactly the partial state above.

If `fish_plugins` ever shrinks on its own, restore it from git first
(`git checkout HEAD -- fish/.config/fish/fish_plugins`), then run
`just plugins` — reconciling in that order reinstalls the missing plugins.
Running `just plugins` before restoring is a no-op, since the manifest and the
machine already agree.

### What's committed

Committed: your own config — `config.fish`, everything in `conf.d/`, your own
functions and completions, `fish_plugins`, `nvim/`'s lockfile, `mise`'s
`config.toml`.

Not committed: anything a tool generates or that is specific to one machine.
Fisher-installed plugin files, `fish_variables`, `fish_history`, and `.claude/`
are all either gitignored or simply never written into the repo now. See
`.gitignore`.

Some files that *look* generated are genuinely yours and should stay tracked —
`conf.d/.gitnow` holds custom gitnow keybindings, and `conf.d/artisan.fish` is
a set of `art*` abbreviations. Neither is plugin output.

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

## Troubleshooting

**stow refuses to link, "existing target is not a symlink".** A real file is
sitting where a symlink should go. If it's regenerable, `just unstick` clears
the usual suspects and re-stows. Otherwise move the real file into the repo
and re-run `just stow`.

**A plugin's commands vanished.** Check `fish_plugins` still lists it, then
`just plugins`. See the fisher notes above if the file itself looks truncated.

**`git fetch` seems to do nothing.** `origin` should be the SSH URL
(`git@github.com:Schultz/dotfiles.git`). Over HTTPS it can fail silently when
the keychain has no credential, which leaves `origin/master` stale and makes
pushes fail later for no visible reason.
