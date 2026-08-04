#!/usr/bin/env bash
set -euo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
ln -sfn "$DIR" ~/.dotfiles
# Pick the flake host entry matching this machine's current name. Pass a name
# explicitly (./rebuild.sh alex-jxp) the first time you rename a machine, since
# its current name won't match the new entry yet. It must exist in flake.nix's
# `hosts` list.
HOST="${1:-$(scutil --get LocalHostName)}"
exec sudo darwin-rebuild switch --flake ~/.dotfiles#"$HOST"
