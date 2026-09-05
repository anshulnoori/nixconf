_: {
  flake.modules.homeManager.base.programs.atuin = {
    enable = true;
    settings = {
      auto_sync = false;
      update_check = false;
    };
  };
}
