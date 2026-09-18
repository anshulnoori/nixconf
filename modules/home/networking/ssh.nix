_: {
  flake.modules.homeManager.base = {
    home.sessionVariables.SSH_AUTH_SOCK = "$HOME/.1password/agent.sock";
    home.file.".ssh/github.pub".text = ''
      ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIFzVmQzhajkwYF/s1jWyLwAAjGnmAhBqB3VEKP2S/Xwf
    '';

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings."github.com" = {
        User = "git";
        IdentityFile = "~/.ssh/github.pub";
        IdentitiesOnly = true;
        ControlMaster = "auto";
        ControlPath = "~/.ssh/control-%C";
        ControlPersist = "10m";
      };
      settings."*" = {
        IdentityAgent = "~/.1password/agent.sock";
      };
    };
  };
}
