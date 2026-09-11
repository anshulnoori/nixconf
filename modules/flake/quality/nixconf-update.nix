_: {
  perSystem = {pkgs, ...}: {
    checks.nixconf-update =
      pkgs.runCommand "nixconf-update-tests" {
        nativeBuildInputs = with pkgs; [bash coreutils gnugrep jq util-linux];
      } ''
        mkdir scripts
        cp ${../../../scripts/nixconf-update.sh} scripts/nixconf-update.sh
        cp ${../../../scripts/test-nixconf-update.sh} scripts/test-nixconf-update.sh
        bash scripts/test-nixconf-update.sh
        touch "$out"
      '';
  };
}
