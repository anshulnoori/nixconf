_: {
  flake.modules.nixos.base = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.boot.loader.limine;
    memtest = "${config.boot.loader.efi.efiSysMountPoint}/efi/memtest86/memtest.efi";
    sbctl = lib.getExe cfg.secureBoot.sbctl;
  in {
    boot.loader.limine = {
      additionalFiles."efi/memtest86/memtest.efi" = pkgs.memtest86plus.efi;

      extraEntries = ''
        /Memtest86+
          protocol: efi
          path: boot():/efi/memtest86/memtest.efi
      '';

      extraInstallCommands = lib.mkIf cfg.secureBoot.enable ''
        ${sbctl} sign ${lib.escapeShellArg memtest}
        ${lib.getExe config.system.build.verifySignedEfi} ${lib.escapeShellArg memtest}
      '';
    };
  };
}
