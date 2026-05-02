#!/usr/bin/env sh
# bootstrap.sh — POSIX. Installs the absolute minimum so that install.fish can run:
#   - fish, git, stow, curl
#
# After this finishes, run:  just install   (or: fish ./install.fish)

set -eu

here=$(cd "$(dirname "$0")" && pwd)
os=$(uname -s)
mode=${1:-full}

log() { printf '\033[1;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }
err() { printf '\033[1;31m!!\033[0m %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

install_fish_binary_linux() {
    arch=$(uname -m)
    case "$arch" in
        x86_64|amd64) asset_arch=x86_64 ;;
        aarch64|arm64) asset_arch=aarch64 ;;
        *) err "No prebuilt fish binary for architecture: $arch" ;;
    esac
    log "Fetching latest fish release metadata"
    url=$(curl -fsSL https://api.github.com/repos/fish-shell/fish-shell/releases/latest \
        | grep browser_download_url \
        | grep "linux-$asset_arch.tar.xz" \
        | head -n1 \
        | cut -d'"' -f4)
    [ -n "$url" ] || err "Could not find a fish linux-$asset_arch asset on the latest release"
    tmp=$(mktemp -d)
    log "Downloading $url"
    curl -fsSL "$url" -o "$tmp/fish.tar.xz"
    tar -xJf "$tmp/fish.tar.xz" -C "$tmp"
    [ -f "$tmp/fish" ] || err "Extracted archive but no 'fish' binary found"
    log "Installing fish to /usr/local/bin/fish"
    sudo install -m 0755 "$tmp/fish" /usr/local/bin/fish
    rm -rf "$tmp"
}

set_fish_as_default_shell() {
    if ! have fish; then
        warn "fish not on PATH yet — skipping default-shell change"
        return 0
    fi
    fish_path=$(command -v fish)
    case "${SHELL:-}" in
        */fish) log "fish is already the default shell ($SHELL)"; return 0 ;;
    esac
    if ! grep -qx "$fish_path" /etc/shells 2>/dev/null; then
        log "Registering $fish_path in /etc/shells"
        echo "$fish_path" | sudo tee -a /etc/shells >/dev/null
    fi
    log "Setting fish as default login shell (you may be prompted for your password)"
    chsh -s "$fish_path"
}

if [ "$mode" = "chsh-only" ]; then
    set_fish_as_default_shell
    exit 0
fi

case "$os" in
    Darwin)
        if ! have brew; then
            log "Installing Homebrew"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        for pkg in fish git stow just; do
            if have "$pkg"; then
                log "$pkg already installed — skipping"
            else
                log "Installing $pkg via Homebrew"
                brew install "$pkg"
            fi
        done
        ;;
    Linux)
        if ! have apt-get; then
            err "This bootstrap supports Debian/Ubuntu (apt). Detected non-apt Linux."
        fi
        apt_pkgs=""
        for pkg in git stow curl ca-certificates; do
            if ! have "$pkg" && ! dpkg -s "$pkg" >/dev/null 2>&1; then
                apt_pkgs="$apt_pkgs $pkg"
            fi
        done
        if [ -n "$apt_pkgs" ]; then
            log "Installing via apt:$apt_pkgs"
            sudo apt-get update
            sudo apt-get install -y $apt_pkgs
        else
            log "git, stow, curl, ca-certificates already present — skipping apt"
        fi
        if have fish; then
            log "fish already installed — skipping"
        else
            install_fish_binary_linux
        fi
        if have just; then
            log "just already installed — skipping"
        else
            log "Installing just (prebuilt binary)"
            sudo mkdir -p /usr/local/bin
            curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh \
                | sudo bash -s -- --to /usr/local/bin
        fi
        ;;
    *)
        err "Unsupported OS: $os"
        ;;
esac

set_fish_as_default_shell

log "Bootstrap complete. Next: just install   (or: fish $here/install.fish)"
