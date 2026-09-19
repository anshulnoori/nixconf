_: {
  perSystem = {pkgs, ...}: {
    checks.nixconf-update =
      pkgs.runCommand "nixconf-update-tests" {
        nativeBuildInputs = with pkgs; [bash coreutils diffutils git gnugrep jq openssh openssl util-linux];
      } ''
        mkdir scripts
        cp ${../../../scripts/nixconf-update.sh} scripts/nixconf-update.sh
        cp ${../../../scripts/test-nixconf-update.sh} scripts/test-nixconf-update.sh
        cp ${../../../scripts/refresh-local-sources.sh} scripts/refresh-local-sources.sh
        cp ${../../../scripts/test-refresh-local-sources.sh} scripts/test-refresh-local-sources.sh
        bash scripts/test-nixconf-update.sh
        bash scripts/test-refresh-local-sources.sh
        touch "$out"
      '';
  };
}
