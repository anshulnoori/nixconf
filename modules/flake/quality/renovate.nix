_: {
  perSystem = {pkgs, ...}: {
    checks.renovate-config =
      pkgs.runCommand "nixconf-renovate-config" {
        nativeBuildInputs = [pkgs.renovate];
      } ''
        renovate-config-validator --strict ${../../../renovate.json}
        touch "$out"
      '';
  };
}
