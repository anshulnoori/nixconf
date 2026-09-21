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
        pkgs.coreutils
        pkgs.ripgrep
      ];
      text = ''
        if (($# < 1 || $# > 2)); then
          echo 'Usage: verify-signed-efi FILE [LIMINE_CONFIG]' >&2
          exit 2
        fi

        sbctl verify --json "$1" \
          | jq -e --arg file "$1" \
            'length == 1 and .[0].file_name == $file and .[0].is_signed == 1' \
            >/dev/null

        if (($# == 2)); then
          marker='++CONFIG_B2SUM_SIGNATURE++'
          count="$(LC_ALL=C rg --text --only-matching --fixed-strings "$marker" "$1" | wc -l)"
          if [[ "$count" != 1 ]]; then
            echo 'Expected one Limine configuration hash.' >&2
            exit 1
          fi
          enrolled="$(LC_ALL=C rg --text --only-matching '\+\+CONFIG_B2SUM_SIGNATURE\+\+[0-9a-fA-F]{128}' "$1")"
          enrolled="''${enrolled#"$marker"}"
          actual="$(b2sum -- "$2" | cut -d ' ' -f 1)"
          if [[ "''${enrolled,,}" != "$actual" ]]; then
            echo 'Limine configuration hash does not match.' >&2
            exit 1
          fi
        fi
      '';
    };
  in {
    boot.loader.limine = {
      secureBoot = {
        enable = true;
        autoGenerateKeys = false;
      };

      extraInstallCommands = ''
        ${lib.getExe verifySignedEfi} ${lib.escapeShellArg limine} ${lib.escapeShellArg "${config.boot.loader.efi.efiSysMountPoint}/limine/limine.conf"}
      '';
    };

    environment.systemPackages = [
      cfg.secureBoot.sbctl
      verifySignedEfi
    ];

    system.build.verifySignedEfi = verifySignedEfi;
  };
}
