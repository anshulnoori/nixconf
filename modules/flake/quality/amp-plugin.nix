_: {
  perSystem = {pkgs, ...}: {
    checks.amp-plugin =
      pkgs.runCommand "nixconf-amp-plugin" {
        nativeBuildInputs = [pkgs.bun];
      } ''
        cp -R ${../../../.amp/plugins/renovate-review} renovate-review
        chmod -R u+w renovate-review
        cd renovate-review
        bun test index.test.ts
        touch "$out"
      '';
  };
}
