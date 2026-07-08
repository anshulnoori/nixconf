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

---

Maintained by [Anshul Noori](https://github.com/anshulnoori).
