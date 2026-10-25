{ user, ... }:

# Settings for alex-m1 alone (flake.nix loads machines/<host>.nix when it
# exists). They let my other Macs reach this agent box over SSH. See
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
}
