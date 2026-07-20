# nixconf Repository Standards — Design

**Date:** 2026-07-19
**Status:** Approved (pending spec review)

## Goal

Replace the JavaScript/husky repository-hygiene layer with native Nix tooling, and
establish repository standards: formatting, linting, conventional commits, branch
naming, CI, and documentation. The actual NixOS + home-manager configuration is
**out of scope** — this session only creates the empty top-level folders for it.

## Decisions (locked)

| Area | Choice |
|---|---|
| Tooling stack | Native Nix: `treefmt-nix` + `git-hooks.nix` (cachix). Remove husky/Bun/commitlint. |
| Nix formatter | `alejandra` |
| Commit checker | `commitizen` (`cz check`) |
| Commit types | Nix-flavored: standard conventional + `flake`, `host`, `module` |
| License | None. Remove license metadata. `LICENSE`/`tsconfig.json` stay deleted. |
| Branch model | Trunk-based, single protected `master`. Drop `dev`. |
| CI | GitHub Actions, `nix flake check`, DeterminateSystems installer + Cachix. |
| Cachix | Cache `anshulnoori`, push + pull. |
| direnv | Commit `.envrc` (`use flake`). |
| Config folders | `hosts/`, `modules/`, `overlays/`, `users/` — empty placeholders only. |
| CLAUDE.md | Rewrite for this repo (Nix tooling + conventions). |

## Remove

- `package.json`
- `bun.lock`
- `commitlint.config.js`
- `.husky/` (`commit-msg`, `pre-commit`, `pre-push`)
- `LICENSE`, `tsconfig.json` — already deleted in working tree; keep deleted.

## Resulting structure

```
.
├── flake.nix              # inputs: nixpkgs, flake-utils, treefmt-nix, git-hooks; nixConfig cachix; devShell/checks/formatter
├── flake.lock             # regenerated
├── treefmt.nix            # alejandra (nix), prettier (md/json/yaml), shfmt (sh)
├── .cz.toml               # commitizen cz_customize — enforces the Nix-flavored type list
├── .envrc                 # use flake
├── .github/
│   └── workflows/
│       └── ci.yml
├── hosts/.gitkeep
├── modules/.gitkeep
├── overlays/.gitkeep
├── users/.gitkeep
├── CLAUDE.md              # rewritten
├── CONTRIBUTING.md        # commit + branch conventions, dev setup
├── README.md              # updated (remove Bun, add dev/setup)
└── .gitignore             # unchanged
```

## flake.nix

- **inputs:**
  - `nixpkgs` → `github:nixos/nixpkgs?ref=nixos-unstable` (kept)
  - `flake-utils`
  - `treefmt-nix`
  - `git-hooks` → `github:cachix/git-hooks.nix`
- **nixConfig:**
  ```nix
  nixConfig = {
    extra-substituters = [ "https://anshulnoori.cachix.org" ];
    extra-trusted-public-keys = [ "anshulnoori.cachix.org-1:<TODO: fill from `cachix use anshulnoori`>" ];
  };
  ```
- **outputs** — per-system via `flake-utils.lib.eachDefaultSystem`:
  - `formatter.<system>` = treefmt wrapper
  - `checks.<system>.formatting` = treefmt check
  - `checks.<system>.pre-commit` = git-hooks check
  - `devShells.<system>.default` = `mkShell` with `alejandra`, `statix`, `deadnix`,
    `commitizen`, `cachix` in `buildInputs`, and the git-hooks `shellHook` so hooks
    self-install on shell entry.
- The placeholder `hello` package is **removed**.

## treefmt.nix

Single source of truth for formatting, consumed by both `formatter` and the
`treefmt` git-hook:

- `alejandra` → `*.nix`
- `prettier` → `*.md`, `*.json`, `*.yaml`/`*.yml`
- `shfmt` → `*.sh`

## git-hooks configuration

Runs locally (commit/push) and inside `nix flake check`.

| Hook | Stage | Purpose |
|---|---|---|
| `treefmt` | pre-commit | formatting via the treefmt-nix wrapper |
| `statix` | pre-commit | Nix anti-pattern lint |
| `deadnix` | pre-commit | dead Nix code detection |
| `commitizen` | commit-msg | conventional-commit validation (reads `.cz.toml`) |
| `branch-name` (custom) | pre-push | enforce branch naming; exempt `main` |

Custom `branch-name` hook: a `writeShellScript` that reads the current branch,
exits 0 for `master`, otherwise matches the branch regex and fails with a helpful
message on mismatch. `pass_filenames = false`, `stages = [ "pre-push" ]`.

## Commit standard — `.cz.toml`

commitizen `cz_customize` with a `schema_pattern` enforcing the type list:

```
feat fix docs style refactor perf test build ci chore revert flake host module
```

Format: `type(scope)!: subject` (scope and `!` optional).

**Known limitation vs commitlint:** header max-length (72) and subject-case are not
hard-enforced by the native commitizen schema. The regex enforces type + structure.
Accepted as a minor trade-off for a personal repo.

## Branch naming

Trunk-based. Single protected `master`. Feature branches:

```
^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|flake|host|module)/[a-z0-9-]+$
```

`dev` is dropped (no longer exempt; no longer used).

## CI — `.github/workflows/ci.yml`

```yaml
name: CI
on:
  push:
    branches: [master]
  pull_request:
jobs:
  check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - uses: cachix/cachix-action@v15
        with:
          name: anshulnoori
          authToken: ${{ secrets.CACHIX_AUTH_TOKEN }}
      - run: nix flake check -L
```

`cachix-action` adds the substituter (pull) and pushes new store paths (push) when
the auth token is present. A single `nix flake check` runs formatting, statix,
deadnix, and the commit hooks.

## Manual steps (outside this session)

- Add the `CACHIX_AUTH_TOKEN` repository secret on GitHub.
- Fill the Cachix public key in `flake.nix` (`cachix use anshulnoori` prints it).
- Run `direnv allow` on first `cd` into the repo.

## Documentation

- **README.md** — remove Bun/Node references; add a "Development" section covering
  `direnv allow` / `nix develop`, formatting, and the commit/branch conventions.
- **CONTRIBUTING.md** — commit types + format with examples, branch naming, the
  local hook workflow, and the Cachix note.
- **CLAUDE.md** — rewritten to describe this repo: native Nix tooling
  (alejandra/statix/deadnix/treefmt), conventional commits, branch naming. No Bun.

## Out of scope

- Any actual NixOS / home-manager configuration content (folders are empty).
- Filling the Cachix public key and adding the GitHub secret (manual).
