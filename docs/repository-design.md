# Repository design

## Scope

This repository owns declarative configuration for Anshul's physical NixOS
devices. It remains standalone from the private application monorepo: there is
no submodule, nested checkout, or continuous file synchronization. A shared
module should move to a dedicated flake only after both repositories have a
real consumer with the same contract.

The current configuration implements the inspected `x86_64-linux` PC named
`t1`, including its base system, Hyprland desktop, applications, and gaming
layer. The later target is an `aarch64-linux` Apple Silicon MacBook with Asahi
Linux. Darwin outputs are not part of this repository.

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
├── nixos/    NixOS module contributions
└── home/     Home Manager module contributions

hosts/        actual machine roots
users/        integrated Home Manager user roots
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

The host implementation uses the following target tree. This tree is an
ownership map. A directory exists only when it has an implemented feature.
Each application and command-line tool has its own Nix file.

```text
modules/
├── flake/                  repository outputs, development, and checks
├── nixos/
│   ├── boot/               kernel, Limine, and Plymouth
│   ├── system/             audio, Bluetooth, Lix, logs, cooling, and health
│   ├── desktop/            session, login, policy, portals, and appearance
│   ├── networking/         service-specific firewall policy
│   ├── gaming/             Steam, GameMode, and Gamescope
│   ├── containers/         rootless Podman
│   ├── hardware.nix
│   ├── home-manager.nix
│   ├── networking.nix
│   ├── security.nix
│   ├── storage.nix
│   └── graphics.nix
└── home/
    ├── shell/              Zsh, Kitty, Neovim, Yazi, and general CLI tools
    ├── system/             local hardware and system interfaces
    ├── networking/         remote and network clients
    ├── nix/                Nix inspection and command-discovery tools
    ├── desktop/            Hyprland session components and desktop actions
    ├── browsers/           Brave Origin, Browsh, and browser applications
    ├── messaging/          Signal, Discord, WhatsApp, and BlueBubbles
    ├── productivity/       Todoist and Obsidian
    ├── media/              Spotify, mpv, yt-dlp, and DaVinci Resolve
    ├── gaming/             MangoHud, GOverlay, and Prism Launcher
    ├── containers/         Lazydocker
    ├── services/           user timers and notification services
    └── ai/                 Amp

hosts/
└── t1/
    ├── default.nix
    ├── hardware.nix
    ├── disko.nix
    └── networking.nix

users/
└── mvs/
    └── default.nix
```

`networking.nix` owns reusable network policy. Device names and links stay in
the host's `networking.nix`. `storage.nix` owns Disko integration, swap, and
storage maintenance. The host's `disko.nix` owns the destructive disk layout.
`system/storage-health/` owns health checks and persistent status. Boot stays
in a directory because its components have independent responsibilities.

The Walker desktop menu calls executable interfaces and does not own their
implementations. Elephant's generated Lua menu provider returns top-level
categories for an empty root query and all descendants for a non-empty query,
so root search can execute a matched leaf directly. The wlr-which-key leader
menu is a separate shortcut tree. `present-terminal` owns UWSM launch, Kitty
presentation, and the matching Hyprland window rule. `nixpkgs-package-search`
owns package indexing, selection, preview, installation, and removal from the
user profile. The generated wallpaper is exposed through the internal read-only
`nixconf.desktop.wallpaper` option; a state symlink records the selected
wallpaper so swaybg and hyprlock share the same current image.

Home Manager keeps visible domain directories from the agreed tree. Amp stays
under `ai/`. Zsh, Kitty, Neovim, Yazi, and general CLI tools stay under
`shell/`. System interfaces stay under `system/`. Network clients stay under
`networking/`. User services stay under `services/`.

There is no root theme directory for one standard scheme. Stylix owns the
shared Gruvbox palette; application-specific adapters remain with their
consumers. There is no local overlay directory until a package genuinely needs
to participate in the global package set. `modules/flake/packages.nix` owns the
pinned Amp derivation and repository tools. Brave Origin, zmx, Proton-GE,
MangoHud, and the other available applications come from pinned inputs or
nixpkgs.

## Ownership boundaries

NixOS owns hardware, boot, storage, accounts, networking, security, and system
services. Home Manager is integrated into each NixOS system and owns the user
session, Hyprland configuration, user services, packages, and dotfiles. There
is no standalone Home Manager activation path.

The flake exports reusable deferred modules for each active layer:

- `modules.nixos.base`, `modules.nixos.desktop`, and
  `modules.nixos.gaming` contain the system layers.
- `modules.homeManager.base`, `modules.homeManager.desktop`, and
  `modules.homeManager.gaming` contain the matching user layers.

The `t1` host imports all three layers. A future host can select only the layers
it needs. A separate recovery specialization remains deferred; previous Limine
generations are the current rollback path.

`Lassulus/wrappers` is not a Home Manager replacement. Use it selectively when
a package genuinely needs fixed flags, environment, or store-backed
configuration. Home Manager still owns installation and activation. The Git
package wrapper is similarly narrow: it selects authorship only from the
current repository's `remote.origin.url`, then executes upstream Git.

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

CI currently performs repository checks and cross-system evaluation only. The
planned host-build workflow uses one AMD64 GitHub runner: AMD64 builds locally,
while ARM64 builds use nixbuild.net. Remote-builder credentials remain CI-only.

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
