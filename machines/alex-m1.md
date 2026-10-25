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
