# alex-m1

M1 Pro MacBook Pro, set up as an agent box: coding agents run on it with high autonomy, so it was trimmed until a misbehaving agent can't do anything catastrophic.
First build on this Mac: `./bootstrap.sh alex-m1`, since its old hostname doesn't match the flake entry yet.

## Decisions (2026-10-24)

- **iCloud** — only Passwords syncs, so signing into things stays easy. iCloud Drive is off and removed from the Mac, iMessage and FaceTime are signed out, and local message history is deleted.
- **No file-sync clients** — Dropbox, Google Drive, and OneDrive are uninstalled along with their local copies, since a local delete there is a cloud delete.
- **No chat, mail, 2FA, or password-manager apps** — Slack, Mattermost, Discord, WhatsApp, WeChat, Messenger, Outlook, Teams, Authy, and Bitwarden are gone.
- **No work access** — no work repos, secrets-manager logins, cloud production keys, or saved MCP tokens.
- **GitHub** — the `gh` token keeps the broad `repo` scope, because agents need to read and write personal repos, but not `admin:public_key`, so an agent can't add its own SSH key. Protect `main` on any repo that deploys.
- **Full Disk Access** — off for terminals. Grant it for a single task that needs Mail, Messages, or another protected folder, then turn it back off.
- **Kept on purpose** — Chrome profiles (limit Claude in Chrome with its site permissions), Claude connectors, and local-only data like the Obsidian vault.

Casks in `configuration.nix` install on every host, including this one, so don't add sync, chat, or password-manager apps to the shared list.
