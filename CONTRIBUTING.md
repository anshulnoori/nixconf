# Contributing

## Development environment

```sh
direnv allow    # or: nix develop
```

This loads a devShell with `nil`, `alejandra`, `statix`, `deadnix`, `commitizen`,
and `cachix`, and installs the git hooks (via git-hooks.nix).

- `nix fmt` — format (alejandra, prettier, shfmt)
- `nix flake check` — formatting + statix + deadnix + commit hooks (same as CI)

## Commit messages — Conventional Commits

Format: `type(scope)!: subject`

Allowed types: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`,
`build`, `ci`, `chore`, `revert`, `flake` (input bumps), `host`, `module`.

Examples:

```
feat(host): add laptop configuration
flake: bump nixpkgs
fix(module): correct nvidia driver option
```

Validated on commit by `commitizen` (`cz check`).

## Branches

Trunk-based. `master` is the protected default. Work on short-lived branches:

```
type/short-kebab-description
```

e.g. `feat/add-desktop-host`, `flake/bump-nixpkgs`. The `type` must be one of the
commit types above. Enforced on push by a git hook. `master` is exempt.

## CI & cache

GitHub Actions runs `nix flake check` on push to `master` and on PRs, using the
`anshulnoori` Cachix cache (`CACHIX_AUTH_TOKEN` secret required for pushing).

## First-time setup (maintainer)

- `cachix use anshulnoori`, then paste the printed public key into `flake.nix`'s
  `extra-trusted-public-keys` (replace `REPLACE_ME`).
- Add the `CACHIX_AUTH_TOKEN` repository secret on GitHub.
