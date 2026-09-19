_: {
  perSystem = {pkgs, ...}: {
    packages.refresh-local-sources = pkgs.writeShellApplication {
      name = "refresh-local-sources";
      runtimeInputs = with pkgs; [coreutils curl diffutils gnugrep jq libarchive libxml2 openssl _7zz];
      text = builtins.readFile ../../scripts/refresh-local-sources.sh;
    };
  };
}
