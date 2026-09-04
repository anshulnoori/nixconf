_: {
  flake.modules.homeManager.base = {
    home.sessionVariables.SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."*".IdentityAgent = "~/.1password/agent.sock";
    };
  };
}
