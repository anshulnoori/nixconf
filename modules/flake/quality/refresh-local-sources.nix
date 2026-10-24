_: {
  perSystem = {pkgs, ...}: {
    checks.refresh-local-sources =
      pkgs.runCommand "refresh-local-sources-tests" {
        nativeBuildInputs = with pkgs; [bash coreutils diffutils git gnugrep jq openssh openssl ripgrep util-linux];
      } ''
        mkdir scripts
        cp ${../../../scripts/refresh-local-sources.sh} scripts/refresh-local-sources.sh
        cp ${../../../scripts/test-refresh-local-sources.sh} scripts/test-refresh-local-sources.sh
        bash scripts/test-refresh-local-sources.sh
        touch "$out"
      '';
  };
}
