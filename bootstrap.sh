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

set_fish_as_default_shell() {
    fish_path=$(command -v fish 2>/dev/null || true)
    if [ -z "$fish_path" ]; then
        warn "fish not on PATH yet — skipping default-shell change"
        return 0
    fi
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
        if ! command -v brew >/dev/null 2>&1; then
            log "Installing Homebrew"
            /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        fi
        log "Installing fish, git, stow, just via Homebrew"
        brew install fish git stow just
        ;;
    Linux)
        if ! command -v apt-get >/dev/null 2>&1; then
            err "This bootstrap supports Debian/Ubuntu (apt). Detected non-apt Linux."
        fi
        log "Updating apt and installing fish, git, stow, curl"
        sudo apt-get update
        sudo apt-get install -y fish git stow curl ca-certificates
        if ! command -v just >/dev/null 2>&1; then
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
