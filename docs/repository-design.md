# Repository design

## Scope

This repository owns declarative configuration for Anshul's physical NixOS
devices. It consumes the application monorepo as one pinned root flake input;
there is no submodule, nested checkout, separate lock, or continuous file
synchronization.

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
├── nixos/    system-owned NixOS module contributions
└── home/     user-facing features and their complete integrations

hosts/        actual machine roots
users/        integrated Home Manager user roots
overlays/     local package overlays, added only for real consumers
```

Every `.nix` file in `modules/` is imported automatically. A feature keeps its
implementation with its module rather than routing it through a repository-wide
helper directory. Static menu entries use the `.data` extension so they can
remain beside the menu renderer without becoming auto-imported modules.

The flake enables the upstream `flake.modules` option from flake-parts. Each
base NixOS file contributes to `flake.modules.nixos.base`. Each base Home
Manager file contributes to `flake.modules.homeManager.base`. Deferred-module
merging composes files that use the same class and name.

This pattern is the repository standard. A module does not read sibling outputs
through `inputs.self` while those outputs are under construction. A host imports
one completed base module for each module class. A profile exists only for a
real optional layer, such as `desktop` or `gaming`.

### Target topology

The host implementation uses the following target tree. This tree is an
ownership map. A directory exists only when it has an implemented feature.
Configured applications keep focused Nix files. Shallow command-line tools are
grouped in the owning domain's `tools.nix`.

```text
modules/
├── flake/                  repository outputs, development, and checks
├── nixos/
│   ├── boot/               kernel, Limine, and Plymouth
│   ├── system/             audio, Bluetooth, Lix, logs, cooling, and health
│   ├── desktop/            session, login, policy, portals, and appearance
│   ├── gaming/             Steam, GameMode, and Gamescope
│   ├── containers/         container runtimes
│   ├── hardware.nix
│   ├── home-manager.nix
│   ├── networking.nix      shared network configuration and policy
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
    ├── media/              Spotify, mpv, yt-dlp, Blender, and DaVinci Resolve
    ├── gaming/             MangoHud, GOverlay, and Prism Launcher
    ├── containers/         container clients and integrations
    ├── update.nix          update timer, notifications, and command
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
`system/storage-health.nix` owns health checks and persistent status. Boot
stays in a directory because its components have independent responsibilities;
Plymouth itself is one module rather than a one-file subdirectory.

The Walker desktop menu calls executable interfaces and does not own their
implementations. Its renderer and static entry data remain together under
`desktop/menu/navigation/`. Elephant's generated Lua menu provider returns
top-level categories for an empty root query and all descendants for a
non-empty query, so root search can execute a matched leaf directly. The
wlr-which-key leader menu is a separate shortcut tree. `present-terminal` owns
UWSM launch, Kitty presentation, and the matching Hyprland window rule.
`nixpkgs-package-search` owns package indexing, selection, preview,
installation, and removal from the user profile. The generated wallpaper is
exposed through the internal read-only `nixconf.desktop.wallpaper` option; a
state symlink records the selected wallpaper so swaybg and hyprlock share the
same current image.

Home Manager keeps visible domain directories from the agreed tree. Amp stays
under `ai/`. Zsh, Kitty, Neovim, Yazi, and general CLI tools stay under
`shell/`. System interfaces stay under `system/`. Network clients stay under
`networking/`.

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

The `t1` host imports all three layers as one system. A future host can select
only the layers it needs. A separate recovery specialization remains deferred;
previous Limine generations are the current rollback path.

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

The application monorepo is a normal SSH root input pinned in `flake.lock`.
Interactive evaluation authenticates through the user's 1Password SSH agent;
no GitHub token enters Nix configuration. This personal configuration does not
maintain separate public and authenticated output graphs.

nvf replaces Nixvim. Migration of the existing editor behavior is a semantic
rewrite performed with the user module, not parallel ownership by two Neovim
frameworks.

## Checks and caches

Local flake checks validate both Linux systems without building the full host
closure. On each push to `master`, GitHub Actions repeats evaluation and builds
the full `t1` closure.

Trusted public Cachix keys are part of flake trust, so machines can use those
caches read-only. The GitHub Actions build uploads newly built paths to the
personal cache. It reads the private monorepo through a deploy-key secret. The
machine configuration does not install a persistent uploader.

## Explicit exclusions

The repository does not contain Buck2, deploy-rs, nixos-anywhere, Kubernetes,
cloud deployment, OCI publication, application release workflows, or broad
language toolchains.

## References

- [flake-parts](https://flake.parts/)
- [vic/import-tree](https://github.com/vic/import-tree)
- [Home Manager](https://github.com/nix-community/home-manager)
- [nvf](https://github.com/NotAShelf/nvf)
- [Lassulus/wrappers](https://github.com/Lassulus/wrappers)
- [Lix NixOS module](https://git.lix.systems/lix-project/nixos-module)
- [wlr-which-key](https://github.com/eepp/wlr-which-key)
- [Hyprland Home Manager options](https://wiki.hypr.land/Nix/Hyprland-on-Home-Manager/)
