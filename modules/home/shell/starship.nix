_: {
  flake.modules.homeManager.base.programs.starship = {
    enable = true;
    settings = {
      add_newline = true;
      command_timeout = 200;
      format = "[$directory$git_branch$git_status]($style)$character";

      character = {
        error_symbol = "[✗](bold bright-red)";
        success_symbol = "[❯](bold bright-green)";
      };

      directory = {
        truncation_length = 2;
        truncation_symbol = "…/";
        style = "bright-cyan";
        repo_root_style = "bold bright-cyan";
        repo_root_format = "[$repo_root]($repo_root_style)[$path]($style)[$read_only]($read_only_style) ";
      };

      git_branch = {
        format = "[$branch]($style) ";
        style = "italic bright-yellow";
      };

      git_status = {
        format = "[$all_status]($style)";
        style = "orange";
        ahead = "⇡\${count} ";
        diverged = "⇕⇡\${ahead_count}⇣\${behind_count} ";
        behind = "⇣\${count} ";
        conflicted = " ";
        up_to_date = " ";
        untracked = "? ";
        modified = " ";
        stashed = "";
        staged = "";
        renamed = "";
        deleted = "";
      };
    };
  };

  flake.modules.homeManager.desktop.stylix.targets.starship.enable = true;
}
