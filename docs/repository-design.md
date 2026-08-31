# Repository design

## Scope

This repository owns declarative configuration for Anshul's physical NixOS
devices. It remains standalone from the private application monorepo: there is
no submodule, nested checkout, or continuous file synchronization. A shared
module should move to a dedicated flake only after both repositories have a
real consumer with the same contract.

Current work establishes repository infrastructure only. Host roots, hardware
facts, disk layouts, and device activation wait for live work on each machine.
The intended targets are an `x86_64-linux` PC named `t1` and an
`aarch64-linux` Apple Silicon MacBook running Asahi Linux. Darwin outputs are
not part of this repository.

## Dendritic layout

`flake.nix` declares inputs and delegates the complete module tree to
`vic/import-tree`:

```nix
inputs.flake-parts.lib.mkFlake {inherit inputs;}
(inputs.import-tree ./modules)
```

Every Nix file under `modules/` is a flake-parts module. This removes a central
import list while keeping ownership visible:

```text
modules/
├── flake/    repository tooling, systems, checks, shells, and packages
├── nixos/    reusable NixOS module exports
└── home/     reusable Home Manager module exports

hosts/        actual machine roots, added after live inspection
users/        integrated Home Manager user roots, added with hosts
overlays/     local package overlays, added only for real consumers
```

Underscore-prefixed files or directories can hold helpers that import-tree must
not load as modules.

### Target topology

The host implementation uses the following target tree. This is an ownership
map, not an instruction to create empty directories. A directory exists only
when multiple files share a clear responsibility. An independent feature with
no honest grouping remains a directly named module rather than being forced
into a generic `apps`, `tools`, or `utilities` directory.

```text
modules/
├── flake/
│   ├── systems.nix
│   ├── configurations.nix
│   ├── packages.nix
│   ├── development.nix
│   └── checks.nix
│
├── nixos/
│   ├── profiles/
│   │   ├── base.nix
│   │   ├── desktop.nix
│   │   ├── gaming.nix
│   │   └── vm.nix
│   ├── core/
│   │   ├── lix.nix
│   │   ├── nixpkgs.nix
│   │   ├── accounts.nix
│   │   ├── locale.nix
│   │   ├── state-version.nix
│   │   └── journald.nix
│   ├── boot/
│   │   ├── kernel.nix
│   │   ├── limine.nix
│   │   ├── plymouth.nix
│   │   ├── recovery.nix
│   │   └── secure-boot.nix
│   ├── storage/
│   │   ├── btrfs.nix
│   │   ├── snapper.nix
│   │   ├── swap.nix
│   │   ├── maintenance.nix
│   │   └── health.nix
│   ├── hardware/
│   │   ├── amd.nix
│   │   ├── graphics.nix
│   │   ├── firmware.nix
│   │   └── cooling.nix
│   ├── networking/
│   │   ├── ethernet.nix
│   │   ├── wifi.nix
│   │   ├── bluetooth.nix
│   │   ├── tailscale.nix
│   │   ├── resolved.nix
│   │   └── firewall.nix
│   ├── security/
│   │   ├── sops.nix
│   │   ├── sudo-pam.nix
│   │   ├── onepassword.nix
│   │   └── keyring.nix
│   ├── desktop/
│   │   ├── session.nix
│   │   ├── login.nix
│   │   ├── portals.nix
│   │   ├── audio.nix
│   │   ├── removable-media.nix
│   │   ├── polkit.nix
│   │   └── stylix.nix
│   ├── gaming/
│   │   ├── steam.nix
│   │   ├── gamemode.nix
│   │   └── gamescope.nix
│   └── containers/
│       └── podman.nix
│
└── home/
    ├── profiles/
    │   ├── base.nix
    │   ├── desktop.nix
    │   ├── workstation.nix
    │   └── gaming.nix
    ├── shell/
    │   ├── zsh.nix
    │   ├── kitty.nix
    │   ├── zmx.nix
    │   ├── prompt.nix
    │   ├── history.nix
    │   ├── navigation.nix
    │   ├── cli-tools.nix
    │   ├── network-tools.nix
    │   ├── git.nix
    │   ├── direnv.nix
    │   ├── nix-direnv.nix
    │   ├── nh.nix
    │   ├── nix-output-monitor.nix
    │   ├── nvd.nix
    │   ├── nix-tree.nix
    │   ├── nix-index.nix
    │   └── comma.nix
    ├── ai/
    │   └── amp.nix
    ├── desktop/
    │   ├── appearance.nix
    │   ├── hyprland.nix
    │   ├── waybar.nix
    │   ├── notifications.nix
    │   ├── launchers.nix
    │   ├── leader-menu.nix
    │   ├── idle-lock.nix
    │   ├── wallpaper.nix
    │   ├── capture.nix
    │   ├── clipboard.nix
    │   ├── controls.nix
    │   ├── removable-media.nix
    │   ├── health-warning.nix
    │   └── _assets/
    ├── browsers/
    │   ├── brave-origin.nix
    │   ├── browsh.nix
    │   └── web-apps.nix
    ├── messaging/
    │   ├── signal.nix
    │   ├── discord.nix
    │   └── bluebubbles.nix
    ├── productivity/
    │   ├── mail.nix
    │   ├── notion-calendar.nix
    │   ├── todoist.nix
    │   ├── obsidian.nix
    │   └── tldraw.nix
    ├── media/
    │   ├── spotify.nix
    │   ├── mpv.nix
    │   ├── davinci-resolve.nix
    │   └── localsend.nix
    ├── gaming/
    │   ├── mangohud.nix
    │   ├── prism-launcher.nix
    │   └── protontricks.nix
    ├── containers/
    │   └── lazydocker.nix
    ├── services/
    │   └── update-notifier.nix
    ├── neovim.nix
    ├── _neovim/
    │   ├── core.nix
    │   ├── interface.nix
    │   ├── completion.nix
    │   ├── editing.nix
    │   ├── git.nix
    │   ├── syntax.nix
    │   ├── languages.nix
    │   ├── documents.nix
    │   ├── testing.nix
    │   ├── integrations.nix
    │   └── diagnostics.nix
    ├── impala.nix
    ├── bluetui.nix
    ├── wiremix.nix
    ├── yazi.nix
    ├── btop.nix
    ├── nvtop.nix
    └── lazyjournal.nix

hosts/
└── t1/
    ├── default.nix
    ├── hardware.nix
    ├── disko.nix
    ├── networking.nix
    └── secrets.nix

users/
└── mvs/
    ├── default.nix
    └── hosts/
        └── t1.nix

packages/
├── amp-cli.nix
└── ttfx.nix

secrets/
└── t1.yaml
```

The grouping rule follows ownership rather than presentation. Kitty and zmx
belong to the shell session. Git and each Nix workflow tool have explicit shell
modules. Amp belongs to the AI domain. Neovim is the only editor, so its public
module stays directly under `home/` and its cohesive nvf implementation is
colocated in the ignored `_neovim/` helper directory. Impala, Bluetui, WireMix,
Yazi, btop, nvtop, and LazyJournal are independent user tools; the fact that
they render in a terminal does not make them shell or desktop configuration.

There is no root theme directory for one standard scheme. Stylix owns the
shared Gruvbox palette; application-specific adapters remain with their
consumers. There is no local overlay directory until a package genuinely needs
to participate in the global package set. `packages/` contains only actual
local derivations: the pinned Amp release and TTFX, which is absent from the
pinned nixpkgs package set. Brave Origin, zmx, Proton-GE, MangoHud, and the
other available applications come from pinned inputs or nixpkgs.

## Ownership boundaries

NixOS owns hardware, boot, storage, accounts, networking, security, and system
services. Home Manager is integrated into each NixOS system and owns the user
session, Hyprland configuration, user services, packages, and dotfiles. There
is no standalone Home Manager activation path.

The flake currently exports these reusable boundaries without creating a host:

- `nixosModules.lix` installs pinned Lix nightly from upstream `main`.
- `nixosModules.home-manager` integrates Home Manager with the system package
  set and passes flake inputs to user modules.
- `nixosModules.disko` exposes disko for later host storage definitions.
- `homeModules.neovim` gives nvf sole ownership of Neovim.
- `homeModules.renovate-notifier` provides the disabled-by-default update
  notification timer.

`Lassulus/wrappers` is not a Home Manager replacement. Use it selectively when
a package genuinely needs fixed flags, environment, or store-backed
configuration. Home Manager still owns installation and activation.

## Inputs and recovery

`nixos-unstable` supplies the package set. Moving inputs are exact revisions in
`flake.lock`. Lix follows upstream `main` through the official Lix NixOS module;
if a nightly regression blocks operation, pin both Lix inputs to the last known
good compatible revisions. Previous NixOS generations remain the primary
rollback path.

nvf replaces Nixvim. Migration of the existing editor behavior is a semantic
rewrite performed with the user module, not parallel ownership by two Neovim
frameworks.

## CI and caches

CI is push-based because this personal repository follows trunk-based
development without pull requests. All external GitHub Actions are pinned to
full commit SHAs with readable version comments. The workflow uses a pinned Lix
installer and explicitly rejects CppNix installer actions.

Until host roots exist, CI performs repository checks and cross-system
evaluation only. Future host builds use one AMD64 GitHub runner: AMD64 builds
locally, while ARM64 builds use nixbuild.net. Remote-builder credentials remain
CI-only.

The public Cachix key is part of flake trust. Amp Orbs and other ephemeral
environments read from the cache only. Only `master` CI and trusted physical
devices may write through a command-scoped `cachix watch-exec` process.

## Explicit exclusions

The repository does not contain Buck2, BuildBuddy, deploy-rs, nixos-anywhere,
Kubernetes, cloud deployment, OCI publication, application release workflows,
or broad language toolchains. Bun exists only in the Nix development shell to
test the tracked Amp plugin; there is no JavaScript package manifest or lock
file.

## References

- [flake-parts](https://flake.parts/)
- [vic/import-tree](https://github.com/vic/import-tree)
- [Home Manager](https://github.com/nix-community/home-manager)
- [nvf](https://github.com/NotAShelf/nvf)
- [Lassulus/wrappers](https://github.com/Lassulus/wrappers)
- [Lix NixOS module](https://git.lix.systems/lix-project/nixos-module)
- [wlr-which-key](https://github.com/eepp/wlr-which-key)
- [Hyprland Home Manager options](https://wiki.hypr.land/Nix/Hyprland-on-Home-Manager/)
