_: {
  flake.modules.nixos.desktop.services.keyd = {
    enable = true;
    keyboards.default = {
      ids = ["*"];
      settings = {
        global.overload_tap_timeout = 250;
        main = {
          leftmeta = "overload(meta, f13)";
          rightmeta = "overload(meta, f13)";
        };
      };
    };
  };
}
