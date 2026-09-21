{inputs, ...}: {
  perSystem = {
    lib,
    pkgs,
    ...
  }: let
    host = inputs.self.nixosConfigurations.t1.config;
    testSbctl = pkgs.writeShellScriptBin "sbctl" ''
      exec ${lib.getExe pkgs.sbctl} --config "$SBCTL_TEST_CONFIG" "$@"
    '';
    verifier =
      ((import ../../nixos/boot/secure-boot.nix {}).flake.modules.nixos.base {
        inherit lib pkgs;
        config.boot.loader = {
          efi.efiSysMountPoint = "/boot";
          limine.secureBoot.sbctl = testSbctl;
        };
      }).system.build.verifySignedEfi;
  in {
    checks = lib.optionalAttrs (pkgs.stdenv.hostPlatform.system == "x86_64-linux") {
      secure-boot = assert !host.boot.loader.limine.secureBoot.autoGenerateKeys;
      assert !host.boot.loader.limine.secureBoot.autoEnrollKeys.enable;
      assert host.boot.loader.limine.enrollConfig && host.boot.loader.limine.validateChecksums && host.boot.loader.limine.panicOnChecksumMismatch;
      assert !host.boot.loader.limine.enableEditor;
        pkgs.runCommand "secure-boot-checks" {
          nativeBuildInputs = [pkgs.sbctl pkgs.limine pkgs.jq pkgs.coreutils verifier];
        } ''
          export HOME="$TMPDIR"
          export SYSTEMD_ESP_PATH="$PWD"
          make_keys() {
            local dir="$PWD/$1"
            mkdir -p "$dir"
            jq -n --arg d "$dir" '{landlock:false, keydir:($d+"/keys"), guid:($d+"/GUID"), files_db:($d+"/files.json"), bundles_db:($d+"/bundles.json"), keys:(["PK","KEK","db"]|map({key:(ascii_downcase), value:{type:"file", privkey:($d+"/keys/"+.+"/"+.+".key"), pubkey:($d+"/keys/"+.+"/"+.+".pem")}})|from_entries)}' > "$dir/config.json"
            sbctl --config "$dir/config.json" create-keys
          }
          reject() {
            if verify-signed-efi "$@"; then
              echo "Unexpected verification success: $*" >&2
              exit 1
            fi
          }
          make_keys local
          make_keys other
          export SBCTL_TEST_CONFIG="$PWD/local/config.json"
          printf 'timeout: 5\n' > limine.conf
          cp ${pkgs.limine}/share/limine/BOOTX64.EFI unsigned.efi
          chmod u+w unsigned.efi
          hash=$(b2sum limine.conf | cut -d ' ' -f1)
          limine enroll-config unsigned.efi "$hash"
          reject "$PWD/unsigned.efi"
          cp unsigned.efi valid.efi
          sbctl --config "$SBCTL_TEST_CONFIG" sign "$PWD/valid.efi"
          verify-signed-efi "$PWD/valid.efi" "$PWD/limine.conf"
          printf '\n' >> limine.conf
          reject "$PWD/valid.efi" "$PWD/limine.conf"
          printf 'timeout: 5\n' > limine.conf
          cp unsigned.efi foreign.efi
          sbctl --config "$PWD/other/config.json" sign "$PWD/foreign.efi"
          reject "$PWD/foreign.efi"
          cp valid.efi tampered.efi
          limine enroll-config tampered.efi "$(printf 'f%.0s' {1..128})"
          reject "$PWD/tampered.efi"
          cp ${pkgs.limine}/share/limine/BOOTX64.EFI unenrolled.efi
          chmod u+w unenrolled.efi
          sbctl --config "$SBCTL_TEST_CONFIG" sign "$PWD/unenrolled.efi"
          reject "$PWD/unenrolled.efi" "$PWD/limine.conf"
          reject "$PWD/missing.efi"
          touch "$out"
        '';
    };
  };
}
