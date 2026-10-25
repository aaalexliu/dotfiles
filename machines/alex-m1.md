# alex-m1

M1 Pro MacBook Pro, set up as an agent box: coding agents run on it with high autonomy, so it was trimmed until a misbehaving agent can't do anything catastrophic.

## Decisions (2026-10-24)

- **iCloud** - only Passwords syncs, so signing into things stays easy. iCloud Drive is off and removed from the Mac, iMessage and FaceTime are signed out, and local message history is deleted.
- **No file-sync clients** - Dropbox, Google Drive, and OneDrive are uninstalled along with their local copies, since a local delete there is a cloud delete.
- **No chat, mail, 2FA, or password-manager apps** - Slack, Mattermost, Discord, WhatsApp, WeChat, Messenger, Outlook, Teams, Authy, and Bitwarden are gone.
- **Google accounts** - Mail is off in Internet Accounts. Contacts, Calendars, and Notes still sync, so an agent can read and edit them.
- **No work access** - no work repos, secrets-manager logins, cloud production keys, or saved MCP tokens.
- **GitHub** - the `gh` token keeps the broad `repo` scope, because agents need to read and write personal repos, but not `admin:public_key`, so an agent can't add its own SSH key. Protect `main` on any repo that deploys.
- **Full Disk Access** - off for terminals. Grant it for a single task that needs Mail, Messages, or another protected folder, then turn it back off.
- **Kept on purpose** - Chrome profiles (limit Claude in Chrome with its site permissions), Claude connectors, and local-only data like the Obsidian vault.

Casks in `configuration.nix` install on every host, including this one, so don't add sync, chat, or password-manager apps to the shared list.

## First build (2026-10-24)

The Mac already had apps installed outside Homebrew, and `brew` refuses to install a cask over them. Before `./bootstrap.sh alex-m1`:

```sh
brew install --cask --adopt ghostty                            # same version, just registered
brew install --cask --force claude obsidian alfred cleanshot   # replaced with the cask version
```

After the build:

- Removed the npm copy of Pi (`npm uninstall -g @earendil-works/pi-coding-agent`) so Homebrew's `pi` wins on `PATH`.
- Deleted `~/.gitconfig`, which would override home-manager's `~/.config/git/config`.
- The pre-build `~/.zshrc`, `~/.zshenv`, `~/.ssh/config`, and `~/.claude/settings.json` live on as `*.backup`.

Launch Ghostty from the Dock or Alfred, never from a shell inside a Claude session. Ghostty passes its environment to every tab, so a Ghostty started from Claude makes each new `claude` think it is a child session and turn off transcript saving.

## Remote access (2026-10-25)

My other Macs reach this box over SSH. `machines/alex-m1.nix` turns on Remote Login, allows keys only, and allows only the keys it lists. Those land in root-owned `/etc/ssh/nix_authorized_keys.d/`, and sshd ignores `~/.ssh/authorized_keys`, so an agent can't add a key of its own. To let another Mac in, add its `~/.ssh/id_ed25519.pub` to that list and run `./rebuild.sh`. The box never sleeps on power.

Tailscale (tailnet `uilxela7@gmail.com`) names the box `alex-m1`, and `machines/alex-m1.nix` opens Tailscale at login. On the home network, `alex-m1.local` works too. From the other Mac:

```sh
cmux mosh-tmux alex-m1                # default: a cmux pane on tmux session "main", over mosh
cmux ssh-tmux alex-m1                 # tmux windows as cmux tabs; needs the Remote tmux beta setting
mosh alex-m1 -- tmux new -A -s main   # the same without cmux, e.g. from Blink on iOS
```

Keep work inside tmux. tmux keeps running when the connection drops, and mosh rides through sleep and network changes. A plain `cmux ssh alex-m1` shell runs under the SSH connection and dies with it (seen with cmux 0.64.25 on the client). `mosh` comes from `home.nix`, so each Mac gets it on its own rebuild.

Never forward your SSH agent here (`ssh -A`, `cmux ssh --forward-agent`). An agent on this box could then use the other Mac's keys, work key included.

A restart cuts remote access until someone logs in at the keyboard: FileVault asks for the password at boot, and Tailscale only starts after login. Closing the lid also puts the Mac to sleep unless an external display is attached.

## Coding agents (2026-10-25)

On top of the shared `claude`, `claude-code`, and `cursor-cli`, `machines/alex-m1.nix` installs the `codex` CLI, the ChatGPT desktop app (now also the Codex app), the Cursor desktop app, and Grok Build (`grok`).

Each vendor's phone app can drive agents on this box, with no open ports:

- **Claude** - run `claude remote-control` in a repo, inside tmux. Sessions show up under Code in the Claude app.
- **Codex** - pair the ChatGPT desktop app with the phone, then use Codex in the ChatGPT phone app.
- **Cursor** - sign in to the Cursor iOS app and approve the pairing in the Cursor desktop app.
- **Grok** - no phone app. Use `cmux mosh-tmux alex-m1`.

Each of those accounts can now run commands on this box, so keep 2FA on them.

Grok has no Homebrew cask. A home-manager step runs xAI's installer into `~/.grok` once, links only `grok` into `~/.local/bin`, and leaves updates to `grok update`. The installer's `agent` alias stays off `PATH`.

How the apps got here:

- The Codex app had renamed itself to `/Applications/ChatGPT Classic.app` (bundle ID `com.openai.codex`). I moved it to the Trash and installed the `chatgpt` cask, which is the same app and version. The older `/Applications/ChatGPT (Classic).app` (`com.openai.chat`) is still there.
- `brew install --cask --adopt cursor` failed. macOS blocked brew from tagging a file inside the already-launched `Cursor.app`. Brew then deleted `/Applications/Cursor.app` as part of its rollback and left a dangling `/opt/homebrew/bin/cursor` link. Removing the link and running a plain `brew install --cask cursor` put it back. Settings in `~/.cursor` and `~/Library/Application Support/Cursor` were untouched. Before adopting any other cask that links a binary out of its app, move the app to the Trash and install fresh instead.

## HumanLayer (2026-10-25)

Self-hosted [HumanLayer](https://github.com/humanlayer/humanlayer) runs from `~/dev/humanlayer`, on local branch `alex-m1`. The launchd agent `org.nixos.humanlayer` runs `machines/alex-m1-humanlayer.sh` at login and restarts it when it exits. The script starts OrbStack, brings up the containers with `devstack sync --compose`, maps the web ports with `tailscale serve`, builds the two web apps, and runs the API, sync proxy, and daemon.

On the tailnet:

- App: `https://alex-m1.tail8cf1f1.ts.net`
- Admin (users, invites, metrics): `https://alex-m1.tail8cf1f1.ts.net:8443`
- API, sync proxy, and artifact storage: ports 8444, 8445, and 8446

Sign-in goes through a WorkOS sandbox. The org is `alex-m1`, and its WorkOS metadata `internal_org_id` must match the org row in Postgres. The WorkOS JWT template copies that value into each token. Secrets live in `~/dev/humanlayer/.env` (mode 600, gitignored).

Decisions:

- **Tailscale serve, not Caddy.** The upstream devstack serves `https://*.main.localhost` through Caddy, which needs a local CA in the System keychain and works on this box only. Tailscale gives real certificates on every device.
- **The daemon gets a short env list.** It passes its whole environment to every Claude Code session. With the full `.env`, sessions would bill the Anthropic API key instead of the Claude subscription, and would see the WorkOS key.
- **The web apps are production builds.** Dev mode overlays the composer with Vite and FPS widgets and loads slowly over the tailnet. The API, sync proxy, and daemon run from source with `--watch`.
- **Billing is off.** Every feature is on, and Stripe, Resend, GitHub, Slack, Linear, and Jira get placeholder keys so the API boots. Inviting users and creating orgs in the UI call Stripe, so they fail until a Stripe test key goes in.
- **MinIO comes from `cgr.dev/chainguard/minio`.** Docker Hub dropped `minio/minio` and `minio/mc`. That one-line change is the only commit on branch `alex-m1`.
- **Agent test user.** `uilxela7+hl-agent@gmail.com` is an admin in the org, so agents can sign in and check the UI. Its password is in `~/.humanlayer/agent-test-user`. A host belongs to one user, so it sees no host unless the daemon runs as it (`HUMANLAYER_DAEMON_USER_ID`).

Operating it:

```sh
launchctl kickstart -k gui/$(id -u)/org.nixos.humanlayer   # restart
cd ~/dev/humanlayer && git pull --rebase origin main && bun install   # update, then restart
ls ~/.humanlayer/riptide/logs/main/   # launchd.log, api, sync, daemon, ui, cloud
```

To test on this box without Tailscale, stop the agent (`launchctl bootout gui/$(id -u)/org.nixos.humanlayer`) and run the script with `--local`. It then uses `http://localhost:<port>` origins, which WorkOS also allows.

Codex sessions need their own login: `cd ~/dev/humanlayer && bun apps/cli/src/index.ts agents auth codex login`.
