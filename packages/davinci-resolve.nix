{callPackage}: let
  # Resolve 21.1's live upstream archive no longer matches its nixpkgs hash.
  # Keep only Resolve on the previous package definition, not the whole system.
  source = builtins.fetchTree {
    type = "github";
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "9fbb54b33e91ee4ca368e35a78e0613c720600b3";
    narHash = "sha256-cV5xEJJK3BvhU8rEd4mC9UsmDi5qscv/kzGPhBRC5WA=";
  };
in
  callPackage "${source}/pkgs/by-name/da/davinci-resolve/package.nix" {}
