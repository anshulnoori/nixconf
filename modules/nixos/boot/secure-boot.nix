_: {
  flake.modules.nixos.base = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.boot.loader.limine;
    limine = "${config.boot.loader.efi.efiSysMountPoint}/efi/limine/BOOTX64.EFI";
    verifySignedEfi = pkgs.writeShellApplication {
      name = "verify-signed-efi";
      runtimeInputs = [
        cfg.secureBoot.sbctl
        pkgs.jq
      ];
      text = ''
        if (($# != 1)); then
          echo 'Usage: verify-signed-efi FILE' >&2
          exit 2
        fi

        sbctl verify --json "$1" \
          | jq -e --arg file "$1" \
            'length == 1 and .[0].file_name == $file and .[0].is_signed == 1' \
            >/dev/null
      '';
    };
  in {
    boot.loader.limine = {
      secureBoot = {
        enable = true;
        autoGenerateKeys = true;
      };

      extraInstallCommands = ''
        ${lib.getExe verifySignedEfi} ${lib.escapeShellArg limine}
      '';
    };

    environment.systemPackages = [
      cfg.secureBoot.sbctl
      verifySignedEfi
    ];

    system.build.verifySignedEfi = verifySignedEfi;
  };
}
