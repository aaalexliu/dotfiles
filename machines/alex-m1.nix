{ user, ... }:

# Settings for alex-m1 alone (flake.nix loads machines/<host>.nix when it
# exists): SSH from my other Macs and the extra coding agents. See
# machines/alex-m1.md for how to connect.
{
  # Apple's built-in sshd, the same switch as Sharing > Remote Login.
  services.openssh.enable = true;
  # sshd keeps the first value it reads for a keyword, and this file loads
  # before the AuthorizedKeysFile line in /etc/ssh/sshd_config. So only the
  # root-owned keys below can log in: an agent on this box can't plant its own
  # key in ~/.ssh/authorized_keys.
  services.openssh.extraConfig = ''
    AuthorizedKeysFile none
    PasswordAuthentication no
    KbdInteractiveAuthentication no
    PermitRootLogin no
    AllowUsers ${user}
  '';

  # One public key per Mac that may log in.
  users.users.${user}.openssh.authorizedKeys.keys = [
    # alex-jxp, and possibly alex-m5 if it shares the same key
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFxse50wpqF6v8fZuK7BYyQPGXQFrQAte08+R9PiVEXq 4alexliu@gmail.com"
  ];

  # Tailscale can't wake a sleeping Mac, so never sleep on power. The
  # battery settings stay as they are.
  system.activationScripts.postActivation.text = ''
    /usr/bin/pmset -c sleep 0
  '';

  # Tailscale's own "start on login" is off here, so after a restart the box
  # would stay off the tailnet even once someone logs in.
  launchd.user.agents.tailscale.serviceConfig = {
    ProgramArguments = [ "/usr/bin/open" "-b" "io.tailscale.ipn.macsys" ];
    RunAtLoad = true;
  };

  # Self-hosted HumanLayer from ~/dev/humanlayer, served on the tailnet. The
  # script waits for OrbStack and Tailscale, so it is safe to start at login.
  # It runs from the checkout, not the store, so a script fix needs only
  # `launchctl kickstart -k gui/$(id -u)/org.nixos.humanlayer`, not a rebuild.
  launchd.user.agents.humanlayer.serviceConfig = {
    ProgramArguments = [ "/bin/bash" "/Users/${user}/.dotfiles/machines/alex-m1-humanlayer.sh" ];
    RunAtLoad = true;
    KeepAlive = true;
    ThrottleInterval = 30;
    StandardOutPath = "/Users/${user}/.humanlayer/riptide/logs/main/launchd.log";
    StandardErrorPath = "/Users/${user}/.humanlayer/riptide/logs/main/launchd.log";
  };

  # Coding agents on top of the shared Claude Code and Cursor CLI. The two apps
  # let the ChatGPT and Cursor phone apps drive agents on this box.
  homebrew.casks = [
    "codex"    # Codex CLI
    "chatgpt"  # ChatGPT desktop app, which now holds the Codex app
    "cursor"   # Cursor desktop app
  ];

  # Grok Build has no Homebrew cask, so run xAI's installer once; `grok update`
  # keeps it current after that. SHELL=/bin/sh stops the installer from editing
  # ~/.zshrc, which home-manager owns (bash fills in an unset SHELL from the
  # login shell). The bare PATH stops it from linking its `agent` alias into
  # ~/.local/bin. Only `grok` goes there.
  home-manager.users.${user} = { lib, ... }: {
    home.activation.grok = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ ! -e "$HOME/.grok/bin/grok" ]; then
        run /usr/bin/env -i HOME="$HOME" SHELL=/bin/sh PATH=/usr/bin:/bin:/usr/sbin:/sbin \
          /bin/bash -c '/usr/bin/curl -fsSL https://x.ai/cli/install.sh | /bin/bash'
      fi
      run mkdir -p "$HOME/.local/bin"
      run ln -sfn "$HOME/.grok/bin/grok" "$HOME/.local/bin/grok"
    '';
  };
}
