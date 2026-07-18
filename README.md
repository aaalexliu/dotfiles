# dotfiles

My personal Mac setup, managed with [nix-darwin](https://github.com/nix-darwin/nix-darwin) and [home-manager](https://github.com/nix-community/home-manager).
One repo, one command, and a fresh Mac ends up configured the same way every time.

> Forked from [kunchenguid/dotfiles](https://github.com/kunchenguid/dotfiles).
> The original has a [walkthrough video](https://youtu.be/5N-okeDdIuI) and the rationale behind this structure — start there if you're learning how it fits together.

## What you get

`./rebuild.sh` builds:

- **System** — dark mode, fast key repeat, auto-hide dock + menu bar, Finder list view, tap-to-click, Caps Lock → Escape, hostname `alex-m5`
- **Homebrew apps** — WezTerm, Ghostty, VS Code, Obsidian, OrbStack, Alfred, CleanShot X, Rectangle, Claude Code, herdr
- **Nix CLI packages** — ripgrep, fd, fzf, jq, lazygit, Neovim, tmux, gh, Hack Nerd Font
- **Shell** — zsh (autosuggestions, syntax highlighting), aliases, starship prompt
- **Git + SSH** — commit identity, sensible defaults, and a `github.com` key with macOS keychain integration
- **Editor / terminal** — Neovim + WezTerm configs (rose-pine moon theme)
- **Agent configs** — Claude, Codex, and opencode all share one `AGENTS.md`

## Prerequisites

- Apple Silicon Mac (default).
- Intel Mac: set `nixpkgs.hostPlatform = "x86_64-darwin";` in `configuration.nix` (the comment there says the same).

## Fresh-machine setup

From a bare clone on a new Mac:

```sh
git clone https://github.com/aaalexliu/dotfiles.git
cd dotfiles
./bootstrap.sh
```

`bootstrap.sh` does four things, in order:

1. Installs Determinate Nix, if it isn't already.
2. Symlinks this repo to `~/.dotfiles` — has to happen before the first build, because `home.nix` points at config files through `~/.dotfiles`.
3. Checks the `user` in `flake.nix` against your macOS username, and offers to fix it if they differ.
4. Runs the first `darwin-rebuild switch` (pinned to nix-darwin 26.05).

After that you're on the daily workflow below.

## Daily use

Edit the config in place, then apply:

```sh
./rebuild.sh
```

Not every change needs a rebuild — see [How the symlinks work](#how-the-symlinks-work).

### Validate without applying

```sh
nix flake check --no-build
nix build .#darwinConfigurations.mac.system --dry-run
```

## SSH key (one-time, per machine)

Git/SSH config is managed here, but the key itself is generated per machine and never committed:

```sh
ssh-keygen -t ed25519 -C "alex@<machine>"        # creates ~/.ssh/id_ed25519
gh ssh-key add ~/.ssh/id_ed25519.pub --title "<machine>"   # or paste it into GitHub → Settings → SSH keys
ssh -T git@github.com                             # verify
```

`home.nix` already points `github.com` at `~/.ssh/id_ed25519` and enables keychain integration, so the passphrase is stored once.

## Repo tour

- `flake.nix` — entry point. Wires up nixpkgs, nix-darwin, home-manager, and nix-homebrew, and declares the `mac` machine.
- `configuration.nix` — system config: macOS defaults, keyboard, hostname, Homebrew apps.
- `home.nix` — user config: packages, shell, prompt, git/ssh, and the symlinks below.
- `rebuild.sh` — re-applies the config; run after any change that isn't a symlinked file.
- `home/` — the real config files symlinked into place (Neovim, WezTerm, herdr, Claude settings, the shared `AGENTS.md`).

## How the symlinks work

Files under `home/` are the real files — editing them here edits your live config, no rebuild needed. `home.nix` uses `mkOutOfStoreSymlink` to point paths like `~/.config/nvim` straight at `home/.config/nvim`, so the two never drift.

- **Instant (symlinked, no rebuild):** `home/.config/{wezterm,nvim,herdr}`, `home/.claude/settings.json`, `home/AGENTS.md`
- **Needs `./rebuild.sh`:** everything in `configuration.nix`, and the non-symlink parts of `home.nix` (packages, zsh, starship, git, ssh)

## Notes

- **`homebrew.onActivation.cleanup = "zap"`** — every switch removes any brew or cask not listed in `configuration.nix`. Add anything you want to keep to `brews`/`casks` first.
- First `nvim` launch bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim) by cloning plugins (needs network once, then offline). Neovim + WezTerm both use the rose-pine moon theme.
- The `cc`/`co` shell aliases are high-agency: `claude --dangerously-skip-permissions` and `codex --full-auto`. Know what they do before using them.

## Forking this

These are my personal dotfiles, public so people can read and fork them. If you clone for yourself, change:

- **Username** — `./bootstrap.sh` detects and offers to set it, or edit the single `user = "alexliu"` line in `flake.nix`. Everything else threads from that one variable.
- **Machine name** — `networking.computerName` / `networking.hostName = "alex-m5"` in `configuration.nix`.
- **Host label `"mac"`** — the `darwinConfigurations."mac"` name in `flake.nix`, plus the `#mac` in `rebuild.sh` and `bootstrap.sh`. All three must match.
- **Git identity** — `programs.git.settings.user` in `home.nix` is mine; set your own.
- **`home/AGENTS.md`** — my personal agent policy, installed for Claude, Codex, and opencode. Edit or delete it, or you'll silently inherit my instructions.
- **CPU architecture** — `hostPlatform` in `configuration.nix` (see Prerequisites).

## License

MIT No Attribution. See `LICENSE`.
