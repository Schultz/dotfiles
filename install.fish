#!/usr/bin/env fish
# install.fish — install dependencies for the dotfiles, then bootstrap fisher
# and stow the packages.
#
# Assumes bootstrap.sh has already run (so fish/git/stow/curl are available).

set -l here (path resolve (status dirname))

# ── tools ───────────────────────────────────────────────────────────────
# Add or remove freely. Each name maps to install logic in __dot_install.
# These are programs to install, not stow packages; packages.fish derives
# those from the repo layout.

set -l tools \
    starship \
    fzf \
    tmux \
    zellij \
    zoxide \
    fnm \
    kubectl \
    lazygit \
    lazydocker \
    alacritty \
    eza \
    lsd \
    mise

# ── helpers ─────────────────────────────────────────────────────────────

function __log; set_color cyan; echo "==> $argv"; set_color normal; end
function __warn; set_color yellow; echo "!! $argv"; set_color normal; end
function __is_macos; test (uname) = Darwin; end
function __have; command -q $argv[1]; end

function __apt_install
    sudo apt-get install -y $argv
end

# Steps that failed, reported together at the end so one bad tool doesn't
# look like a clean run. install.fish exits non-zero when this is non-empty.
set -g __dot_failures

function __fail
    set -g __dot_failures $__dot_failures $argv[1]
    __warn $argv[1]
end

# Record a non-zero install and pass the status through.
function __dot_check
    if test $argv[2] -ne 0
        __fail "$argv[1]: install exited $argv[2]"
    end
    return $argv[2]
end

function __install_alacritty_dmg
    # Homebrew disabled the alacritty cask on 2026-09-01 because the release
    # build fails the macOS Gatekeeper check, and there is no formula to fall
    # back to. Install the official GitHub release DMG instead.
    set -l ver (curl -fsSL https://api.github.com/repos/alacritty/alacritty/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4 | string trim --left --chars=v)
    if test -z "$ver"
        __warn "alacritty: could not read the latest release version"
        return 1
    end

    set -l work (mktemp -d)
    set -l dmg $work/Alacritty-v$ver.dmg
    if not curl -fsSLo $dmg "https://github.com/alacritty/alacritty/releases/download/v$ver/Alacritty-v$ver.dmg"
        __warn "alacritty: download failed"
        rm -rf $work
        return 1
    end

    # Mount at an explicit path. Letting hdiutil pick means /Volumes/Alacritty,
    # which macOS silently turns into "/Volumes/Alacritty 1" when a copy of the
    # DMG is already mounted (easy to do by installing it by hand once). We
    # would then copy from the stale volume and detach the wrong one.
    set -l mnt $work/mnt
    mkdir -p $mnt
    if not hdiutil attach -quiet -nobrowse -readonly -mountpoint $mnt $dmg
        __warn "alacritty: could not mount the disk image"
        rm -rf $work
        return 1
    end
    sudo cp -R $mnt/Alacritty.app /Applications/
    hdiutil detach -quiet $mnt
    rm -rf $work

    # The DMG is quarantined as a download and fails the Gatekeeper check that
    # got the cask disabled, so macOS refuses to open it. Clearing the
    # quarantine attribute is the same thing right-click > Open does, and it is
    # why this is not just `brew install --cask`.
    __warn "alacritty: clearing the download quarantine so macOS will open it"
    xattr -dr com.apple.quarantine /Applications/Alacritty.app
end

# Release assets disagree on how to spell the architecture: kubectl uses
# amd64/arm64, lazygit uses x86_64/arm64, eza uses rust triples. Pick the
# value for this machine rather than hardcoding one.
#   __arch_pick <value-for-x86_64> <value-for-arm64>
function __arch_pick
    switch (uname -m)
        case x86_64 amd64
            echo $argv[1]
        case aarch64 arm64
            echo $argv[2]
        case '*'
            return 1
    end
end

function __install_eza_binary
    # eza no longer builds from source against its current palette dependency
    # (error[E0433]: cannot find `lms` in `crate`), so take the release binary.
    # It also skips needing a Rust toolchain at all.
    set -l target (__arch_pick x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu)
    if test -z "$target"
        __warn "eza: no release binary for architecture "(uname -m)
        return 1
    end
    set -l tmp (mktemp -d)
    if not curl -fsSLo $tmp/eza.tar.gz \
        "https://github.com/eza-community/eza/releases/latest/download/eza_$target.tar.gz"
        __warn "eza: download failed"
        rm -rf $tmp
        return 1
    end
    tar -xzf $tmp/eza.tar.gz -C $tmp
    sudo install -m 0755 $tmp/eza /usr/local/bin/eza
    rm -rf $tmp
end

function __cargo_install
    # cargo shells out to `cc` to link. A minimal Debian has no compiler, so
    # every cargo build dies with "linker `cc` not found" without this.
    if not __is_macos; and not __have cc
        __log "Installing build-essential (cargo needs a C linker)"
        __apt_install build-essential
    end
    if not __have cargo
        __log "Installing rustup (for cargo)"
        curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
        # Make cargo visible in this session
        fish_add_path $HOME/.cargo/bin
    end
    cargo install $argv
end

# Per-package install rules. macOS always uses brew. Linux prefers apt,
# falls back to per-tool installers.
function __dot_install
    set -l pkg $argv[1]
    if __have $pkg
        echo "    $pkg already installed"
        return 0
    end
    __log "Installing $pkg"
    if __is_macos
        switch $pkg
            case alacritty
                __install_alacritty_dmg
            case lazygit lazydocker
                brew install --cask $pkg 2>/dev/null; or brew install $pkg
            case '*'
                brew install $pkg
        end
        __dot_check $pkg $status
        return
    end

    # Linux (Debian/Ubuntu)
    switch $pkg
        case fzf tmux zoxide alacritty
            __apt_install $pkg
        case starship
            curl -sS https://starship.rs/install.sh | sh -s -- -y
        case zellij
            __cargo_install zellij
        case eza
            __install_eza_binary
        case lsd
            __cargo_install lsd
        case fnm
            # The fnm installer bails out if unzip is absent, and a minimal
            # Debian does not ship it.
            __have unzip; or __apt_install unzip
            curl -fsSL https://fnm.vercel.app/install | bash
        case mise
            curl -fsSL https://mise.run | sh
        case kubectl
            set -l ver (curl -L -s https://dl.k8s.io/release/stable.txt)
            set -l arch (__arch_pick amd64 arm64)
            if test -z "$arch"
                __warn "kubectl: no build for architecture "(uname -m)
                return 1
            end
            sudo curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/$ver/bin/linux/$arch/kubectl"
            sudo chmod +x /usr/local/bin/kubectl
        case lazygit
            set -l ver (curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep tag_name | cut -d'"' -f4 | string trim --left -c v)
            set -l arch (__arch_pick x86_64 arm64)
            if test -z "$arch"
                __warn "lazygit: no build for architecture "(uname -m)
                return 1
            end
            if not curl -fsSLo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_"$ver"_linux_$arch.tar.gz"
                __warn "lazygit: download failed"
                return 1
            end
            sudo tar -xf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
            rm /tmp/lazygit.tar.gz
        case lazydocker
            curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
        case '*'
            __warn "No install rule for '$pkg' on Linux — skipping"
    end
    __dot_check $pkg $status
end

# ── main ────────────────────────────────────────────────────────────────

__log "Installing system packages"
for pkg in $tools
    __dot_install $pkg
end

# Stow MUST run before fisher install/update — otherwise fisher writes its
# files to a real ~/.config/fish/ and stow then conflicts with them.
#
# There is deliberately no pre-delete step here. __backup_stow_conflicts
# below covers anything that collides, and it preserves the file rather than
# removing it. The old step also deleted functions/fisher.fish and
# completions/fisher.fish, which this repo stopped tracking in 3f8cc0b, so
# they cannot collide with stow at all: deleting them only threw away a
# working fisher on every run.
#
# Never put fish_variables in such a step. It holds the universal variable
# _fisher_plugins, and since install.fish is itself a fish process, deleting
# it pulls the universal-variable store out from under the running shell.
# fisher then commits a truncated fish_plugins into the repo through the stow
# symlink. `just unstick` avoids it for the same reason.

# Anything the packages would place that already exists as a real file gets
# moved aside. Two of these are created by this very script: fish writes a
# default config.fish the moment install.fish runs, and rustup drops its own
# unguarded conf.d/rustup.fish during __cargo_install. Either one makes stow
# abort the whole operation. Back them up rather than delete: this runs
# unattended against a real $HOME.
# Takes the repo dir as $argv[1]: fish functions cannot see the script's
# top-level `set -l here`.
function __backup_stow_conflicts
    set -l root $argv[1]
    set -l stamp (date +%Y%m%d-%H%M%S)
    set -l moved 0
    for pkg in $argv[2..-1]
        for src in (find $root/$pkg -type f)
            set -l rel (string replace -- "$root/$pkg/" '' $src)
            set -l dst $HOME/$rel
            if test -e $dst; and not test -L $dst
                mv $dst "$dst.pre-stow-$stamp.bak"
                echo "    backed up $rel -> $rel.pre-stow-$stamp.bak"
                set moved (math $moved + 1)
            end
        end
    end
    if test $moved -gt 0
        __warn "Moved $moved conflicting file(s) aside; originals kept as .pre-stow-$stamp.bak"
    end
end

# Break dir-level symlinks left behind by a previous tree-folded stow so the
# plugin-managed dirs become real directories under ~/.config/fish/. Without
# this, fisher writes through the symlink back into the repo and conflicts on
# the next install.
for d in $HOME/.config/fish/functions $HOME/.config/fish/completions $HOME/.config/fish/conf.d
    if test -L $d
        rm $d
    end
end

__log "Stowing dotfiles"
set -l targets (fish $here/packages.fish)
if test (count $targets) -gt 0
    __backup_stow_conflicts $here $targets
    # --no-folding forces per-file symlinks so fisher can write into the
    # plugin-managed dirs (functions, completions, conf.d) without those
    # writes leaking back into the repo through a folded dir-symlink.
    if stow --no-folding --dir=$here --target=$HOME --restow $targets
        __log "Linked: $targets"
    else
        # stow aborts every package when any one conflicts, so this is not a
        # partial link. Nothing downstream works without it.
        __fail "stow failed — $targets not linked, see the conflicts above"
    end
else
    __warn "Nothing to stow yet — run 'just migrate' first"
end

__log "Linking shared skills"
fish $here/link-skills.fish

__log "Bootstrapping fisher (fish plugin manager)"
# Note: do NOT run `fisher install jorgebucaran/fisher` here — that rewrites
# fish_plugins to reflect only what's currently installed (just fisher),
# wiping the other plugins listed in the repo's fish_plugins. Sourcing
# fisher.fish gives us the function in this session, and `fisher update`
# below reads fish_plugins and installs everything listed (including fisher).
if not __have fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
end

__log "Syncing fisher plugins from fish_plugins"
fisher update; or __fail "fisher update failed — plugins not installed"

__log "Verifying tools (doctor)"
fish $here/doctor.fish
or __warn "Some tools missing — see above"

if set -q __dot_failures[1]
    __warn "Completed with "(count $__dot_failures)" failure(s):"
    for f in $__dot_failures
        echo "    - $f"
    end
    exit 1
end

__log "Done."
