---
name: pi-docs
description: Answer questions about the Pi coding agent using the documentation bundled with the installed Pi package. Use for Pi models, providers, commands, extensions, skills, themes, packages, SDK, TUI, keybindings, configuration, sessions, and custom tools.
---

# Pi docs

Read Pi's local documentation before answering or changing anything related to Pi.

## Locate the installed docs

Resolve the active Pi package instead of assuming a versioned Node path:

```bash
PI_CLI="$(realpath "$(command -v pi)")"
PI_ROOT="$(dirname "$(dirname "$PI_CLI")")"
```

The main files are:

- `$PI_ROOT/README.md`
- `$PI_ROOT/docs/`
- `$PI_ROOT/examples/`

Use the `read` tool to read Markdown files completely. Follow links to related local docs and examples before implementing changes. Resolve `docs/...` under `$PI_ROOT/docs` and `examples/...` under `$PI_ROOT/examples`, not under the current project.

## Topic map

- Models and custom model catalogs: `docs/models.md`
- Providers and authentication: `docs/providers.md`
- Extensions and custom tools: `docs/extensions.md`, then relevant files under `examples/extensions/`
- Skills: `docs/skills.md`
- Prompt templates: `docs/prompt-templates.md`
- Themes: `docs/themes.md`
- TUI components: `docs/tui.md`
- Keybindings: `docs/keybindings.md`
- SDK integrations: `docs/sdk.md`, then relevant files under `examples/sdk/`
- Custom providers: `docs/custom-provider.md`
- Pi packages and sharing skills: `docs/packages.md`
- Sessions: `docs/sessions.md`, `docs/session-format.md`
- Settings: `docs/settings.md`
- Environment variables: `docs/environment-variables.md`

Start with `README.md` when the question spans several topics or the right topic file is unclear.

Do not inspect project files, local Pi state, or private auth files when the bundled docs answer the question. Never print or read `~/.pi/agent/auth.json` while researching Pi usage.
