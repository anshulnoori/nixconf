_: {
  perSystem = {
    config,
    pkgs,
    ...
  }: {
    checks.workflow-policy =
      pkgs.runCommand "nixconf-workflow-policy" {
        nativeBuildInputs = [config.packages.workflow-policy];
      } ''
        check-workflows
        touch "$out"
      '';
  };
}
