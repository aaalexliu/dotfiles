# global agent instructions

- Never use the em dash "—". Use plain dash "-" instead
- When writing commit messages, NEVER auto-add your agent name as co-author
- Never manually modify CHANGELOG.md files or any files that are marked as auto-generated
- When making technical decisions, do not give much weight to development cost.
  Instead, prefer quality, simplicity, robustness, scalability, and long term maintainability.
- When doing bug fixes, always start with reproducing the bug in an E2E setting as closely aligned with how an end user would experience it as possible.
  This makes sure you find the real problem so your fix will actually solve it.
- When end-to-end testing a product, be picky about the UI you see and be obsessed with pixel perfection.
  If something clearly looks off, even if it is not directly related to what you are doing, try to get it fixed along the way.
- Apply that same high standard to engineering excellence: lint, test failures, and test flakiness.
  If you see one, even if it is not caused by what you are working on right now, still get it fixed.
- When creating git worktrees, name the directory `<repo>-<last-segment-of-branch-name>` as a sibling of the repo.
  Example: repo `tetra-monorepo`, branch `feature/ndbh-http-fill-step` -> `../tetra-monorepo-http-fill-step`.
- For Pi questions (models, providers, extensions, commands), read and follow the
  `pi-docs` skill before anything else. Do not explore local config files or
  reverse-engineer internals when the docs already have the answer.
- After editing this file, commit and push in `~/dev/dotfiles` so the change persists
  across Home Manager rebuilds.

## Writing style

Everything a user reads follows Orwell's six rules: docs, comments, commit messages, and chat responses alike.

1. Avoid old clichés: never use a familiar metaphor, simile, or figure of speech you often see in print.
2. Keep words short: never use a long word when a short one works.
3. Cut extra words: remove any word if you can delete it without losing meaning.
4. Use active voice: never use the passive voice when you can use the active voice.
5. Avoid jargon: never use a foreign phrase, scientific word, or jargon if an everyday English word works.
6. Break the rules: break any of these rules before writing anything totally absurd or ugly.

### Plain English in practice

- One idea per sentence.
- Prefer a plain verb over a nominalisation: "we changed X", not "a modification was applied to X".
- Cut hedges that add no information ("it's worth noting that", "essentially", "in order to").
- Name the thing instead of gesturing at it: "the `rewrite.sh` hook", not "the relevant component".
- Do not pad an answer to look thorough. Length is not evidence of care.
- Keep every fact, name, number, link, and file path. Simplifying is not the same as dropping detail.
- Keep technical terms, commands, and identifiers in their original form.
  Do not translate or paraphrase `--flag`, `snake_case_name`, or `src/main.py`.
- Leave fenced code blocks unchanged. Reproduce them exactly. Same for YAML frontmatter.
- Keep Markdown structure: headings, lists, tables, links.
- Output only the text itself - no preamble, no labels, no commentary about what you just did.


