{lib, ...}: {
  perSystem = {
    pkgs,
    system,
    ...
  }: let
    commitizen = pkgs.commitizen.overridePythonAttrs (_: {doCheck = false;});

    branchNameCheck = pkgs.writeShellApplication {
      name = "check-branch-name";
      runtimeInputs = [pkgs.gitMinimal];
      text = builtins.readFile ../../scripts/check-branch-name.sh;
    };

    ampCliRelease = {
      version = "0.0.1788134497-gb6ce09";
      source = {
        platform = "linux-x64-baseline";
        hash = "sha256-ZwoZF9xl93hVEtC2fygcE9ccvJMPZJt0Ih+zmec9w7w=";
      };
    };

    ampCliArchive = pkgs.fetchurl {
      url = "https://static.ampcode.com/cli/${ampCliRelease.version}/amp-${ampCliRelease.source.platform}.gz";
      inherit (ampCliRelease.source) hash;
    };

    ampCli = pkgs.writeShellApplication {
      name = "amp";
      runtimeInputs = [pkgs.coreutils pkgs.gzip pkgs.ripgrep pkgs.util-linux];
      text = ''
        export AMP_HOME="''${AMP_HOME:-$HOME/.amp}"
        bin_dir="$AMP_HOME/bin"
        mkdir -p "$bin_dir"

        (
          flock 9
          if [[ ! -e "$bin_dir/amp" ]]; then
            temporary=$(mktemp "$bin_dir/.amp-bootstrap.XXXXXX")
            trap 'rm -f "$temporary"' EXIT
            gzip -dc ${ampCliArchive} > "$temporary"
            chmod 0755 "$temporary"
            mv "$temporary" "$bin_dir/amp"
          fi
        ) 9>"$AMP_HOME/.bootstrap.lock"

        export PATH="$bin_dir:$PATH"
        exec "$bin_dir/amp" "$@"
      '';
    };

    ampDesktopVersion = "0.1.29894161";

    ampDesktopDeb = pkgs.fetchurl {
      url = "https://static.ampcode.com/linux/${ampDesktopVersion}/amp-desktop-${ampDesktopVersion}-amd64.deb";
      sha256 = "99f304924807a8724652ddf7be46d236e18371e757e155bda8b37ec39201cf75";
    };

    ampDesktopLibraries = with pkgs; [
      alsa-lib
      at-spi2-atk
      at-spi2-core
      atk
      cairo
      cups
      dbus
      expat
      glib
      gtk3
      libdrm
      libgbm
      libGL
      libnotify
      libsecret
      libuuid
      libx11
      libxcb
      libxcomposite
      libxdamage
      libxext
      libxfixes
      libxkbcommon
      libxrandr
      nspr
      nss
      pango
      systemd
      wayland
    ];

    ampDesktopLauncher = pkgs.writeShellApplication {
      name = "amp-desktop";
      runtimeInputs = [pkgs.coreutils pkgs.curl pkgs.gnused pkgs.libarchive pkgs.util-linux];
      text = ''
        data_dir="''${XDG_DATA_HOME:-$HOME/.local/share}/amp-desktop"
        versions="$data_dir/versions"
        mkdir -p "$versions"

        install_deb() {
          local deb=$1 version=$2 previous staging
          previous=$(readlink "$data_dir/current" || true)
          if [[ ! -d "$versions/$version" ]]; then
            staging=$(mktemp -d "$versions/.staging.XXXXXX")
            bsdtar -xOf "$deb" 'data.tar.*' | bsdtar -xf - -C "$staging" opt/amp
            mv "$staging/opt/amp" "$versions/$version"
            rm -rf "$staging"
          fi
          ln -sfn "versions/$version" "$data_dir/.current.tmp"
          mv -T "$data_dir/.current.tmp" "$data_dir/current"
          for dir in "$versions"/*; do
            case "versions/''${dir##*/}" in
              "versions/$version" | "$previous") ;;
              *) rm -rf "$dir" ;;
            esac
          done
        }

        update() {
          local pkgbuild version hash
          pkgbuild=$(curl -fsSL --max-time 15 'https://aur.archlinux.org/cgit/aur.git/plain/PKGBUILD?h=amp-desktop-bin')
          version=$(sed -n 's/^pkgver=\([0-9.]*\)$/\1/p' <<<"$pkgbuild")
          hash=$(sed -n "s/^sha256sums_x86_64=('\([0-9a-f]\{64\}\)')$/\1/p" <<<"$pkgbuild")
          [[ -n "$version" && -n "$hash" ]]
          [[ "$(readlink "$data_dir/current")" != "versions/$version" ]] || return 0
          deb=$(mktemp "$data_dir/.download.XXXXXX")
          trap 'rm -f "$deb"' EXIT
          curl -fsSL --max-time 900 -o "$deb" "https://static.ampcode.com/linux/$version/amp-desktop-$version-amd64.deb"
          sha256sum -c --quiet <<<"$hash  $deb"
          install_deb "$deb" "$version"
        }

        (
          flock 9
          [[ -x "$data_dir/current/amp-desktop" ]] || install_deb ${ampDesktopDeb} ${ampDesktopVersion}
        ) 9>"$data_dir/.lock"

        (
          flock -n 9 || exit 0
          update
        ) 9>"$data_dir/.lock" >"$data_dir/update.log" 2>&1 &

        export XDG_DATA_DIRS="${pkgs.gsettings-desktop-schemas}/share/gsettings-schemas/${pkgs.gsettings-desktop-schemas.name}:${pkgs.gtk3}/share/gsettings-schemas/${pkgs.gtk3.name}''${XDG_DATA_DIRS:+:$XDG_DATA_DIRS}"
        export NIX_LD_LIBRARY_PATH="${lib.makeLibraryPath ampDesktopLibraries}:${pkgs.addDriverRunpath.driverLink}/lib''${NIX_LD_LIBRARY_PATH:+:$NIX_LD_LIBRARY_PATH}"
        exec "$data_dir/current/amp-desktop" "$@"
      '';
    };

    ampDesktop =
      pkgs.runCommand "amp-desktop-${ampDesktopVersion}" {
        nativeBuildInputs = [pkgs.libarchive];
        meta.mainProgram = "amp-desktop";
      } ''
        mkdir -p "$out/bin" deb
        ln -s ${lib.getExe ampDesktopLauncher} "$out/bin/amp-desktop"
        bsdtar -xOf ${ampDesktopDeb} 'data.tar.*' | bsdtar -xf - -C deb usr/share/applications usr/share/icons
        cp -r deb/usr/share "$out/share"
        substituteInPlace "$out/share/applications/amp-desktop.desktop" \
          --replace-fail "Exec=/opt/amp/amp-desktop" "Exec=$out/bin/amp-desktop"
      '';

    boatCliBinary = pkgs.fetchurl {
      url = "https://github.com/ariana-dot-dev/agent-server/releases/download/boat-cli-v1.0.36/boat-linux-x64";
      hash = "sha256-R8sr5CRCuiXVwc9YbZfcMppHe3lXSnEn8ta00inwgLw=";
    };

    boatCli = pkgs.writeShellApplication {
      name = "boat";
      runtimeInputs = [pkgs.coreutils pkgs.util-linux];
      text = ''
        bin_dir="$HOME/.ascii/bin"
        mkdir -p "$bin_dir"

        (
          flock 9
          if [[ ! -e "$bin_dir/boat" ]]; then
            temporary=$(mktemp "$bin_dir/.boat-bootstrap.XXXXXX")
            trap 'rm -f "$temporary"' EXIT
            install -m 0755 ${boatCliBinary} "$temporary"
            mv "$temporary" "$bin_dir/boat"
          fi
        ) 9>"$HOME/.ascii/.boat-bootstrap.lock"

        export PATH="$bin_dir:$PATH"
        exec "$bin_dir/boat" "$@"
      '';
    };
  in {
    packages =
      {
        check-branch-name = branchNameCheck;
        inherit commitizen;
        inherit (pkgs) nvfetcher;
        proton-ge = pkgs.callPackage ../../packages/proton-ge.nix {};
        orb-tools = pkgs.buildEnv {
          name = "nixconf-orb-tools";
          paths = [
            pkgs.direnv
            pkgs.nix-direnv
          ];
        };
      }
      // lib.optionalAttrs (system == "x86_64-linux") {
        amp-cli = ampCli;
        amp-desktop = ampDesktop;
        boat-cli = boatCli;
      };

    apps = {
      check-branch-name = {
        program = lib.getExe branchNameCheck;
        meta.description = "Validate a Git branch name";
      };
      commitizen = {
        program = lib.getExe commitizen;
        meta.description = "Validate Conventional Commits";
      };
      gitleaks = {
        program = lib.getExe pkgs.gitleaks;
        meta.description = "Scan Git history for leaked secrets";
      };
    };

    checks.proton-ge-aarch64 = pkgs.callPackage ../../packages/proton-ge.nix {arch = "aarch64";};
  };
}
