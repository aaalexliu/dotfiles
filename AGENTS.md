# Project notes for agents

Deliberate decisions in this repo - do NOT silently revert them:

- `homebrew.onActivation.cleanup = "zap"` in `configuration.nix` is intentional. It forces the good habit of declaring every Homebrew package in the Nix config instead of installing things ad-hoc, which keeps the machine reproducible. Do not soften it to `uninstall` or `none`. Users are warned about its effect in README.md; this note is for anyone tempted to change the setting itself.
- Never commit `.no-mistakes/` validation evidence to this public repo. `.no-mistakes/` is gitignored; if a validation pipeline stages evidence into a branch, drop it before merging.

## Writing style

Everything a user reads follows Orwell's six rules: docs, comments, commit messages, and chat responses alike.

1. Never use a metaphor, simile, or other figure of speech you are used to seeing in print.
2. Never use a long word where a short one will do.
3. If it is possible to cut a word out, cut it out.
4. Never use the passive where you can use the active.
5. Never use a foreign phrase, a scientific word, or a jargon word if an everyday English word will do.
6. Break any of these rules sooner than say anything outright barbarous.

Rule 6 rules out caveman-style compression. Dropped articles save tokens and cost readers.

Also:

- Never shorten a security note or an irreversible-action confirmation, whatever else you are cutting.
- Never invent abbreviations. `cfg`, `impl`, `req`, and `fn` cost the same tokens as the full word and read worse.
- Before shipping a doc, hand it to a fresh agent with no context and fix what it misreads.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
