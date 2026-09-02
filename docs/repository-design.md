# Repository design

## Scope

This repository owns declarative configuration for Anshul's physical NixOS
devices. It remains standalone from the private application monorepo: there is
no submodule, nested checkout, or continuous file synchronization. A shared
module should move to a dedicated flake only after both repositories have a
real consumer with the same contract.

Current work prepares the inspected `x86_64-linux` PC named `t1` for its base
installation. The later target is an `aarch64-linux` Apple Silicon MacBook with
Asahi Linux. Darwin outputs are not part of this repository.

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
├── nixos/    deferred NixOS module contributions
└── home/     deferred Home Manager module contributions

hosts/        actual machine roots, added after live inspection
users/        integrated Home Manager user roots, added with hosts
overlays/     local package overlays, added only for real consumers
```

Underscore-prefixed files or directories can hold helpers that import-tree must
not load as modules.

The flake enables the upstream `flake.modules` option from flake-parts. Each
base NixOS file contributes to `flake.modules.nixos.base`. Each base Home
Manager file contributes to `flake.modules.homeManager.base`. Deferred-module
merging composes files that use the same class and name.

This pattern is the repository standard. A module does not read sibling outputs
through `inputs.self` while those outputs are under construction. A host imports
one completed base module for each module class. A profile exists only for a
real optional layer, such as `desktop` or `gaming`; no aggregator-only base
profile exists.

### Target topology

The host implementation uses the following target tree. This is an ownership
map, not an instruction to create empty directories. Create the listed files
only when their feature is implemented. The reusable NixOS base keeps boot
concerns split, but merges system, hardware, storage, networking, and security
policy into one file each.

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
│   ├── boot/
│   │   ├── kernel.nix
│   │   ├── limine.nix
│   │   ├── plymouth.nix
│   │   └── secure-boot.nix
│   ├── hardware.nix
│   ├── home-manager.nix
│   ├── networking.nix
│   ├── security.nix
│   ├── storage.nix
│   ├── system.nix
│   ├── graphics.nix
│   ├── desktop/
│   │   ├── appearance/
│   │   │   └── stylix.nix
│   │   ├── session.nix
│   │   ├── login.nix
│   │   ├── portals.nix
│   │   ├── audio.nix
│   │   ├── removable-media.nix
│   │   └── polkit.nix
│   ├── gaming/
│   │   ├── steam.nix
│   │   ├── gamemode.nix
│   │   └── gamescope.nix
│   └── containers/
│       └── podman.nix
│
└── home/
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
    │   ├── appearance/
    │   │   ├── cursor.nix
    │   │   └── wallpaper.nix
    │   ├── leader-menu/
    │   │   ├── menu.nix
    │   │   └── package-search.nix
    │   ├── presentation/
    │   │   └── terminal.nix
    │   ├── hyprland.nix
    │   ├── waybar.nix
    │   ├── notifications.nix
    │   ├── launchers.nix
    │   ├── idle-lock.nix
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
    └── networking.nix

users/
└── mvs/
    └── default.nix

packages/
├── amp-cli.nix
└── ttfx.nix
```

`networking.nix` owns the complete reusable network policy; device names and
links stay in the host's `networking.nix`. `storage.nix` owns Disko integration,
runtime storage, swap, maintenance, and health; the destructive host layout
stays in the host's `disko.nix`. `hardware.nix`, `security.nix`, and
`system.nix` similarly keep their related base policy together. Boot remains a
directory because the kernel, bootloader, Plymouth, and later Secure Boot work
are independent responsibilities. Plymouth is added with the graphics and
desktop stage rather than the base installation.

The leader menu calls executable interfaces and does not own their
implementations. `present-terminal` owns UWSM launch, Kitty presentation, and
the matching Hyprland window rule. `nixpkgs-package-search` owns package
indexing, selection, preview, and installation. The generated wallpaper is
exposed through the internal read-only `nixconf.desktop.wallpaper` option so
swaybg and hyprlock share one artifact without sharing its implementation.

Home Manager keeps visible domain directories from the agreed tree. Amp stays
under `ai/`; shell programs and tools stay under `shell/`; user services stay
under `services/`. Neovim's public module remains directly under `home/`, with
an ignored `_neovim/` directory only when the real nvf implementation is large
enough to justify it.

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

The flake exports two reusable deferred modules:

- `modules.nixos.base` contains the current base-system policies.
- `modules.homeManager.base` contains the current base-user policies.

Desktop and future gaming files contribute to separately named deferred
modules. A host can add those layers after the base installation passes its
first-boot gate. A separate recovery specialization remains deferred; previous
Limine generations are the current rollback path.

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
