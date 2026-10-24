# Project notes for agents

Deliberate decisions in this repo - do NOT silently revert them:

- `homebrew.onActivation.cleanup = "none"` in `configuration.nix` is intentional (it was `"zap"` until 2026-08-13). The `brews`/`casks` lists are a baseline, not the full set, so a rebuild must leave alone brews installed by hand or by MDM (e.g. twingate). Do not switch it back to `zap` or `uninstall`: on a Mac that already has software, the next rebuild would remove everything not listed.
- `alex-m1` is a locked-down agent box (`machines/alex-m1.md`). Every host shares `configuration.nix`, so never add file-sync, chat, mail, 2FA, or password-manager apps to the shared `casks`/`brews` lists.
- Never commit `.no-mistakes/` validation evidence to this public repo. `.no-mistakes/` is gitignored; if a validation pipeline stages evidence into a branch, drop it before merging.
- The active `gh` account is usually `alex-jxp`, which can only read `aaalexliu/dotfiles`. Prefix `gh` writes (PR create, merge) with `GH_TOKEN=$(gh auth token --user aaalexliu)`. This repo is a fork of `kunchenguid/dotfiles`. In a fresh clone, run `gh repo set-default aaalexliu/dotfiles` first, or `gh` targets the upstream.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
