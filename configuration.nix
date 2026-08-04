{ user, hostName, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  # Per-machine name, supplied by the host entry in flake.nix (not hardcoded, so
  # two machines sharing this repo don't collide on the network).
  networking.computerName = hostName;  # friendly name (Sharing, AirDrop)
  networking.hostName = hostName;      # HostName + LocalHostName (.local, SSH)

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  system.keyboard = {
    enableKeyMapping = true;         # required for the remap below to take effect
    remapCapsLockToEscape = true;    # Caps Lock acts as Escape
  };
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = false;  # always show the menu bar
      AppleShowAllExtensions = true;
      "com.apple.trackpad.scaling" = 1.5;  # tracking speed
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    finder.ShowPathbar = true;             # path breadcrumb at bottom of Finder
    finder.AppleShowAllFiles = true;       # show hidden dotfiles in Finder
    trackpad.Clicking = true;              # tap to click
    screencapture.location = "~/Screenshots";  # keep the Desktop clean

    # Disable the built-in macOS shortcuts we hand off to other apps.
    # Screenshots -> CleanShot X; Cmd-Space -> Alfred (instead of Spotlight).
    # Numbers are AppleSymbolicHotKeys IDs. Takes effect after logout/login.
    CustomUserPreferences."com.apple.symbolichotkeys".AppleSymbolicHotKeys = {
      "28" = { enabled = false; };   # Save picture of screen as file   (Shift-Cmd-3)
      "29" = { enabled = false; };   # Copy picture of screen           (Ctrl-Shift-Cmd-3)
      "30" = { enabled = false; };   # Save picture of selected area    (Shift-Cmd-4)
      "31" = { enabled = false; };   # Copy picture of selected area    (Ctrl-Shift-Cmd-4)
      "184" = { enabled = false; };  # Screenshot & recording options   (Shift-Cmd-5)
      "64" = { enabled = false; };   # Show Spotlight search            (Cmd-Space)
      "65" = { enabled = false; };   # Show Finder search window        (Opt-Cmd-Space)
    };

    # Three-finger swipe down = App Exposé (show all windows of the front app).
    # Set on both the built-in trackpad and Bluetooth/Magic Trackpad domains.
    CustomUserPreferences."com.apple.AppleMultitouchTrackpad".TrackpadThreeFingerVertSwipeGesture = 2;
    CustomUserPreferences."com.apple.driver.AppleBluetoothMultitouch.trackpad".TrackpadThreeFingerVertSwipeGesture = 2;
  };
  nix-homebrew = {
    enable = true;
    inherit user;
    autoMigrate = true;  # adopt an existing /opt/homebrew install instead of failing
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    brews = [
      "herdr"
      "mise"  # runtime version manager, activated in ~/.zshrc via home.nix
    ];
    casks = [
      "wezterm"
      "claude"
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
      "slack"
    ];
  };

  # Launch these apps at login. nix-darwin has no native "login items" option,
  # so we use per-user launch agents that `open -b <bundle-id>` once at login.
  # Bundle IDs (not app names) survive version renames, e.g. Alfred 5 -> 6.
  launchd.user.agents =
    let
      loginItem = bundleId: {
        serviceConfig = {
          ProgramArguments = [ "/usr/bin/open" "-b" bundleId ];
          RunAtLoad = true;
        };
      };
    in
    {
      rectangle = loginItem "com.knollsoft.Rectangle";
      cleanshot = loginItem "pl.maketheweb.cleanshotx";
      alfred = loginItem "com.runningwithcrayons.Alfred";
    };
}
