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
