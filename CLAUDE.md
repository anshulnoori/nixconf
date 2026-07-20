# nixconf — agent guide

Personal NixOS configuration managed with Nix flakes (flake-parts). **No Node/Bun** — tooling is native Nix.

## Tooling

- Formatting: `nix fmt` (treefmt-nix → alejandra, prettier, shfmt). alejandra is the Nix formatter.
- Linting: `statix` (anti-patterns), `deadnix` (dead code).
- Hooks: git-hooks.nix installs pre-commit (treefmt/statix/deadnix), commit-msg
  (commitizen), and pre-push (branch-name) hooks via the devShell.
- Verify everything: `nix flake check`.

## Conventions

- Commits: Conventional Commits. Types: feat, fix, docs, style, refactor, perf,
  test, build, ci, chore, revert, flake, host, module.
- Branches: `type/kebab-description`; `master` is the protected default.
- Never add `Co-Authored-By:` trailers to commits.

## Layout

- `flake.nix` — flake-parts: inputs, dev tooling, Cachix substituters.
- `hosts/`, `modules/`, `overlays/`, `users/` — NixOS/home-manager content (grown as needed).
