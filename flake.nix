{
  description = "dotfiles";

  inputs = {
    # Use `github:NixOS/nixpkgs/nixpkgs-26.05-darwin` to use Nixpkgs 26.05.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-26.05-darwin";
    # Use `github:nix-darwin/nix-darwin/nix-darwin-26.05` to use Nixpkgs 26.05.
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-26.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager/release-26.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    # Pin the Homebrew CLI ourselves instead of inheriting nix-homebrew's bundled
    # revision. That bundled pin drifts: brew's cask metadata auto-updates from
    # the API, but the immutable nix-store brew binary does not, so over time an
    # old brew can't parse newer cask definitions (e.g. it links completions
    # before the app, or errors "unknown install step: run"). Bump with
    # `nix flake update homebrew-brew` when a cask install breaks that way.
    homebrew-brew = {
      url = "github:Homebrew/brew";
      flake = false;
    };
    nix-homebrew.inputs.brew-src.follows = "homebrew-brew";
  };

  outputs = inputs@{ self, nix-darwin, nix-homebrew, home-manager, nixpkgs, ... }:
    let
      # The one username line to change if this isn't your machine.
      # bootstrap.sh offers to rewrite this for you if your macOS username differs.
      user = "alexliu";

      # One entry per physical machine. The attribute name IS the hostname the
      # machine gets (networking.hostName / computerName), so each Mac needs its
      # own distinct name here or they collide on the network (.local, AirDrop).
      # rebuild.sh selects the entry matching the machine's current hostname, so
      # to add a machine you just add its name to this list.
      hosts = [
        "alex-jxp"  # this machine (M5)
        "alex-m5"   # other machine
      ];

      mkHost = hostName: nix-darwin.lib.darwinSystem {
        specialArgs = { inherit user hostName; };
        modules = [
          ./configuration.nix
          nix-homebrew.darwinModules.nix-homebrew
          home-manager.darwinModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            # Back up (don't error on) any pre-existing file home-manager needs
            # to replace, e.g. the ~/.zshrc the Nix installer wrote. The old
            # file is renamed to <name>.backup on first activation.
            home-manager.backupFileExtension = "backup";
            home-manager.extraSpecialArgs = { inherit user; };
            home-manager.users.${user} = import ./home.nix;
          }
        ];
      };
    in
    {
      darwinConfigurations = nixpkgs.lib.genAttrs hosts mkHost;
    };
}
