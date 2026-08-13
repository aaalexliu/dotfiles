{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";

  # Persists AI assistant session IDs across tmux restarts and resumes them
  # with --resume <id>. Upstream ships as a TPM plugin; packaging it with
  # mkTmuxPlugin means run-shell executes the same .tmux entry point TPM would,
  # so upstream keeps owning the @resurrect-hook-* wiring.
  tmux-assistant-resurrect = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-assistant-resurrect";
    # Default would be tmux_assistant_resurrect.tmux (dashes -> underscores).
    rtpFilePath = "tmux-assistant-resurrect.tmux";
    version = "0-unstable-2026-08-10";
    src = pkgs.fetchFromGitHub {
      owner = "timvw";
      repo = "tmux-assistant-resurrect";
      rev = "86fe250f3a992a7763b896714e942fd39dc6f202";
      hash = "sha256-vzJsgDo4D9mhc8x9PvxAPuYsjnWl48gTjxxDYOTGmHY=";
    };
    # Disable only the Claude hook installer: it jq-rewrites
    # ~/.claude/settings.json via `mv`, which would replace home-manager's
    # symlink with a regular file. Those hooks are declared in Nix instead
    # (see home/.claude/settings.json). Anchored to the bare call on its own
    # line so the function definition above it is untouched.
    postInstall = ''
      sed -i 's|^install_claude_hooks$|: # disabled: hooks declared in home.nix|' \
        $target/tmux-assistant-resurrect.tmux
    '';
  };

  # Stable path indirection: ~/.claude/settings.json must reference the hook
  # scripts by a path that does not change on every rebuild.
  assistantResurrectDir = "${config.home.homeDirectory}/.config/tmux/assistant-resurrect";
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    tmux
    gh        # github cli
    # portable cli i want reproducible across machines
    awscli2   # aws cli
    uv        # python package/proj manager
    yq-go     # yaml/json processor (mikefarah yq)
    tldr      # concise command examples
    ffmpeg    # media transcoding
    mkcert    # local trusted TLS certs
    yt-dlp    # media downloader
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
      eval "$(/opt/homebrew/bin/mise activate zsh)"
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      # Route coding agents through lapdog for tracing/instrumentation.
      claude = "lapdog claude";
      pi = "lapdog pi";
      cc = "lapdog claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # modern cli upgrades (opt-in; plain ls/cat/cd still work)
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;  # faster, cached direnv for nix shells
  };
  programs.eza.enable = true;    # nicer ls
  programs.bat.enable = true;    # nicer cat
  programs.zoxide.enable = true; # smarter cd (z)
  programs.atuin.enable = true;  # searchable shell history

  programs.delta = {
    enable = true;                # syntax-highlighted diffs
    enableGitIntegration = true;
  };

  programs.git = {
    enable = true;
    settings = {
      user.name = "aaalexliu";
      user.email = "4alexliu@gmail.com";
      init.defaultBranch = "main";
      push.autoSetupRemote = true;  # first `git push` on a new branch sets upstream
      pull.rebase = true;           # rebase instead of merge on pull
    };
  };

  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;  # opt out of the deprecated implicit defaults
    settings = {
      # Re-declare the defaults home-manager used to inject implicitly.
      "*" = {
        ForwardAgent = false;
        AddKeysToAgent = "no";
        Compression = false;
        ServerAliveInterval = 0;
        ServerAliveCountMax = 3;
        HashKnownHosts = false;
        UserKnownHostsFile = "~/.ssh/known_hosts";
        ControlMaster = "no";
        ControlPath = "~/.ssh/master-%r@%n:%p";
        ControlPersist = "no";
      };
      "github.com" = {
        IdentityFile = "~/.ssh/id_ed25519";
        # Use ONLY id_ed25519 for personal github.com, never other agent keys.
        # Without this, the work key (id_jxp, loaded in the agent for ~/dev/jxp
        # repos) gets offered first and GitHub authenticates as the work account.
        IdentitiesOnly = "yes";
        AddKeysToAgent = "yes";  # load key into ssh-agent on first use
        UseKeychain = "yes";     # store passphrase in the macOS keychain
      };
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".config/ghostty".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/ghostty";
  home.file.".tmux.conf".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.tmux.conf";

  # Nix-owned tmux plugin bootstrap (replaces TPM). Sourced by ~/.tmux.conf so
  # the main config stays editable without a rebuild.
  home.file.".config/tmux/plugins.conf".text = ''
    set -g @resurrect-dir '~/.tmux/resurrect'
    set -g @continuum-restore 'on'
    set -g @continuum-save-interval '10'

    # Restore scrollback in ordinary panes. The assistant save hook strips
    # captured contents for assistant panes so restore does not flash stale TUI.
    set -g @resurrect-capture-pane-contents 'on'

    # Deliberately NOT listing claude/pi/codex here: that would launch bare
    # binaries with no session ID, and the post-restore hook would then type
    # resume commands into an already-running TUI. The hooks below do the
    # resuming, with the real session IDs.
    set -g @resurrect-processes 'nvim "~ssh" lazygit'

    # Load order matters. continuum must be last: it performs its auto-restore
    # the moment it loads, so the assistant plugin has to have set
    # @resurrect-hook-post-restore-all before that happens.
    run-shell ${pkgs.tmuxPlugins.resurrect.rtp}
    run-shell ${tmux-assistant-resurrect.rtp}
    run-shell ${pkgs.tmuxPlugins.continuum.rtp}
  '';
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";

  # Stable symlink -> pinned plugin dir, referenced by the Claude
  # SessionStart/SessionEnd hooks in home/.claude/settings.json.
  home.file.".config/tmux/assistant-resurrect".source =
    "${tmux-assistant-resurrect}/share/tmux-plugins/tmux-assistant-resurrect";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
