#!/usr/bin/env fish
# install.fish — install dependencies for the dotfiles, then bootstrap fisher
# and stow the packages.
#
# Assumes bootstrap.sh has already run (so fish/git/stow/curl are available).

set -l here (status dirname)

# ── packages ────────────────────────────────────────────────────────────
# Add or remove freely. Each name maps to install logic in __dot_install.

set -l packages \
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
    eza

# ── helpers ─────────────────────────────────────────────────────────────

function __log; set_color cyan; echo "==> $argv"; set_color normal; end
function __warn; set_color yellow; echo "!! $argv"; set_color normal; end
function __is_macos; test (uname) = Darwin; end
function __have; command -q $argv[1]; end

function __apt_install
    sudo apt-get install -y $argv
end

function __cargo_install
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
            case alacritty lazygit lazydocker
                brew install --cask $pkg 2>/dev/null; or brew install $pkg
            case '*'
                brew install $pkg
        end
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
            __cargo_install eza
        case fnm
            curl -fsSL https://fnm.vercel.app/install | bash
        case kubectl
            set -l ver (curl -L -s https://dl.k8s.io/release/stable.txt)
            sudo curl -fsSLo /usr/local/bin/kubectl "https://dl.k8s.io/release/$ver/bin/linux/amd64/kubectl"
            sudo chmod +x /usr/local/bin/kubectl
        case lazygit
            set -l ver (curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep tag_name | cut -d'"' -f4 | string trim --left -c v)
            curl -Lo /tmp/lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_"$ver"_Linux_x86_64.tar.gz"
            sudo tar -xf /tmp/lazygit.tar.gz -C /usr/local/bin lazygit
            rm /tmp/lazygit.tar.gz
        case lazydocker
            curl -fsSL https://raw.githubusercontent.com/jesseduffield/lazydocker/master/scripts/install_update_linux.sh | bash
        case '*'
            __warn "No install rule for '$pkg' on Linux — skipping"
    end
end

# ── main ────────────────────────────────────────────────────────────────

__log "Installing system packages"
for pkg in $packages
    __dot_install $pkg
end

# Stow MUST run before fisher install/update — otherwise fisher writes its
# files to a real ~/.config/fish/ and stow then conflicts with them. We also
# pre-delete known regenerable files at the target so a stale state from a
# previous bad run can't block stow.
__log "Cleaning regenerable conflicts at the stow target"
for f in \
    $HOME/.config/fish/fish_variables \
    $HOME/.config/fish/fish_plugins \
    $HOME/.config/fish/completions/fisher.fish \
    $HOME/.config/fish/functions/fisher.fish
    if test -f $f; and not test -L $f
        rm -f $f
    end
end

__log "Stowing dotfiles"
set -l targets
for d in alacritty fish zellij nvim
    if test -d $here/$d
        set -a targets $d
    end
end
if test (count $targets) -gt 0
    stow --dir=$here --target=$HOME --restow $targets
    __log "Linked: $targets"
else
    __warn "Nothing to stow yet — run 'just migrate' first"
end

# Now fisher writes through the symlinks into the repo.
__log "Bootstrapping fisher (fish plugin manager)"
if not __have fisher
    curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source
    fisher install jorgebucaran/fisher
end

__log "Syncing fisher plugins from fish_plugins"
fisher update

__log "Verifying tools (doctor)"
fish $here/doctor.fish
or __warn "Some tools missing — see above"

__log "Done."
