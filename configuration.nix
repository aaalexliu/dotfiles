{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  networking.computerName = "alex-m5";  # friendly name (Sharing, AirDrop)
  networking.hostName = "alex-m5";      # HostName + LocalHostName (.local, SSH)

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = true;  # auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    finder.ShowPathbar = true;             # path breadcrumb at bottom of Finder
    finder.AppleShowAllFiles = true;       # show hidden dotfiles in Finder
    trackpad.Clicking = true;              # tap to click
    screencapture.location = "~/Screenshots";  # keep the Desktop clean
  };
  nix-homebrew = {
    enable = true;
    inherit user;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "herdr"
      "mise"  # runtime version manager (kept on brew: ~/.zshrc activates /opt/homebrew/bin/mise)
    ];
    casks = [
      "wezterm"
      "claude-code"
      "obsidian"
      "orbstack"
      "visual-studio-code"
      "ghostty"
      "alfred"
      "cleanshot"
      "rectangle"
      "keycastr"              # on-screen keystrokes
      "shortcat"              # keyboard-driven UI navigation
      "session-manager-plugin"  # aws ssm session manager
    ];
  };
}
