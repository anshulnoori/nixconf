# nixconf

My personal, declarative **NixOS** configuration, managed with **Nix flakes** — an actively evolving setup for a reproducible Linux environment.

> **Status:** work in progress, updated continuously.

## Goals

- A fully **declarative, reproducible** system defined in Nix
- **Flake-based** with pinned inputs
- Clean, conventional structure (hence the rename from an earlier config repo)

## Usage

```sh
# Build & switch to the configuration
sudo nixos-rebuild switch --flake .

# Update pinned inputs
nix flake update
```

## Development

Tooling is native Nix — no Node/Bun.

```sh
direnv allow        # first time: loads the devShell, installs the git hooks
# or, without direnv:
nix develop         # enter the devShell (installs the git hooks)

nix fmt             # format everything (alejandra + prettier + shfmt)
nix flake check     # all checks: formatting, statix, deadnix, commit hooks
```

Commits follow **Conventional Commits** and branches follow `type/kebab-description`.
See [CONTRIBUTING.md](./CONTRIBUTING.md).

---

Maintained by [Anshul Noori](https://github.com/anshulnoori).
