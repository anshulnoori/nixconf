{moduleWithSystem, ...}: {
  flake.modules.homeManager.base = moduleWithSystem (
    {config, ...}: {
      home.packages = [config.packages.amp-cli];
    }
  );

  # `amp --no-tui --desktop` runners share a private virtual desktop. It needs a nested
  # labwc compositor and wlr-randr on PATH (ffmpeg is already installed); the runner
  # downloads waymote-gateway and waymote-streamd itself.
  flake.modules.homeManager.desktop = {pkgs, ...}: {
    home.packages = [pkgs.labwc pkgs.wlr-randr];
  };
}
