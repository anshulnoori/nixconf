# nixconf Repository Standards Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the husky/Bun repo-hygiene layer with native Nix tooling (treefmt-nix + git-hooks.nix), and establish formatting, linting, conventional commits, branch naming, CI, and docs.

**Architecture:** A single flake exposes `formatter`, `checks`, and a `devShells.default`. `treefmt-nix` owns formatting (alejandra/prettier/shfmt) as the single source of truth. `git-hooks.nix` runs treefmt + statix + deadnix on pre-commit, commitizen on commit-msg, and a custom branch-name check on pre-push — the same hooks run in CI via `nix flake check`. direnv auto-loads the devShell so hooks self-install.

**Tech Stack:** Nix flakes, `flake-utils`, `numtide/treefmt-nix`, `cachix/git-hooks.nix`, alejandra, statix, deadnix, commitizen, Cachix, GitHub Actions.

> **As-built note:** Tasks 2–3 were implemented with **flake-parts** instead of
> `flake-utils` (maintainer's request). treefmt + git-hooks are wired via their
> `flakeModule`s, treefmt is inline in `perSystem` (no `treefmt.nix`), systems are
> `["aarch64-darwin" "x86_64-linux"]`, commitizen is overridden with `doCheck = false`
> (nixpkgs py3.14 test breakage), the branch-name hook sets `always_run = true`, and
> the devShell adds `nil`/`git`. See the design doc's "As-built deltas" for details.

## Global Constraints

- Default/protected branch is `master` (not `main`) — everywhere: CI trigger, branch-name hook exemption.
- Commit types (exact list): `feat fix docs style refactor perf test build ci chore revert flake host module`.
- Branch regex: `^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|flake|host|module)/[a-z0-9-]+$`, `master` exempt.
- No license, no license metadata. `LICENSE` / `tsconfig.json` stay deleted.
- Cachix cache name: `anshulnoori` (`https://anshulnoori.cachix.org`), push + pull.
- Nix formatter: alejandra. Nixpkgs: `nixos-unstable` (kept).
- Commit messages: subject/body only — **never** add `Co-Authored-By:` trailers.
- Config folders `hosts/ modules/ overlays/ users/` are empty placeholders only — no NixOS/home-manager content this session.

**Prerequisite check (run once before Task 1):**

```bash
command -v nix && nix --version
```

Expected: Nix present with flakes usable (`nix flake --help` works). If `nix` is missing, stop — this plan cannot be verified without it.

---

### Task 1: Remove the husky/Bun tooling layer

**Files:**

- Delete: `package.json`, `bun.lock`, `commitlint.config.js`, `.husky/` (whole dir)

**Interfaces:**

- Consumes: nothing.
- Produces: a repo with no JS tooling and no active git hooks, ready for native Nix wiring.

- [ ] **Step 1: Confirm current hooks path**

Run: `git config core.hooksPath`
Expected: `.husky/_`

- [ ] **Step 2: Remove the JS layer and unset the hooks path**

```bash
git rm -r --quiet package.json bun.lock commitlint.config.js .husky
git config --unset core.hooksPath
```

- [ ] **Step 3: Verify removal**

Run: `git config core.hooksPath; ls package.json bun.lock commitlint.config.js .husky 2>&1`
Expected: hooksPath prints nothing (unset); `ls` reports all four paths do not exist.

- [ ] **Step 4: Commit**

```bash
git add -A
git commit -m "chore: remove husky/bun tooling layer"
```

---

### Task 2: Flake formatting via treefmt-nix

**Files:**

- Create: `treefmt.nix`
- Modify: `flake.nix` (full rewrite of inputs + outputs; keep `nixConfig`, add treefmt formatter + formatting check)

**Interfaces:**

- Consumes: nothing.
- Produces: `formatter.<system>`, `checks.<system>.formatting`, and a `treefmtEval` binding reused by Task 3.

- [ ] **Step 1: Write `treefmt.nix`**

```nix
# treefmt.nix — single source of truth for formatting.
{ ... }:
{
  projectRootFile = "flake.nix";
  programs = {
    alejandra.enable = true; # *.nix
    prettier.enable = true; # *.md, *.json, *.yaml/*.yml
    shfmt.enable = true; # *.sh
  };
}
```

- [ ] **Step 2: Rewrite `flake.nix` (formatter stage only — git-hooks added in Task 3)**

```nix
{
  description = "Anshul's personal NixOS configuration";

  nixConfig = {
    extra-substituters = [ "https://anshulnoori.cachix.org" ];
    extra-trusted-public-keys = [
      # TODO: replace with the real key printed by `cachix use anshulnoori`
      "anshulnoori.cachix.org-1:REPLACE_ME"
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt-nix,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        treefmtEval = treefmt-nix.lib.evalModule pkgs ./treefmt.nix;
      in
      {
        formatter = treefmtEval.config.build.wrapper;

        checks.formatting = treefmtEval.config.build.check self;
      }
    );
}
```

- [ ] **Step 3: Verify the formatter builds and the check passes**

Run: `nix flake check -L 2>&1 | tail -20 && nix fmt -- --version`
Expected: `nix flake check` succeeds (formatting check green); `nix fmt` runs treefmt and prints a version. If files get reformatted, re-run until clean.

- [ ] **Step 4: Commit**

```bash
git add flake.nix flake.lock treefmt.nix
git commit -m "build: format via treefmt-nix, drop placeholder flake"
```

---

### Task 3: git-hooks (lint, format, commit, branch) + devShell

**Files:**

- Modify: `flake.nix` (add `git-hooks` input, `pre-commit-check`, `branchNameCheck`, `checks.pre-commit`, `devShells.default`)
- Create: `.cz.toml`

**Interfaces:**

- Consumes: `treefmtEval` from Task 2.
- Produces: `checks.<system>.pre-commit`, `devShells.<system>.default` (with hook-installing `shellHook`).

- [ ] **Step 1: Write `.cz.toml` (commitizen custom type list)**

```toml
[tool.commitizen]
name = "cz_customize"

[tool.commitizen.customize]
# `cz check` validates the commit message against this pattern.
schema_pattern = '^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|flake|host|module)(\([\w-]+\))?!?: .+$'
```

- [ ] **Step 2: Add the `git-hooks` input to `flake.nix`**

In the `inputs` block, add:

```nix
    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
```

And add `git-hooks` to the `outputs` function argument set (alongside `treefmt-nix`).

- [ ] **Step 3: Extend the `let` block with the branch check and pre-commit config**

Inside `let ... in`, after `treefmtEval`, add:

```nix
        branchNameCheck = pkgs.writeShellScript "branch-name-check" ''
          set -eu
          branch="$(git rev-parse --abbrev-ref HEAD)"
          if [ "$branch" = "master" ]; then
            exit 0
          fi
          pattern='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|flake|host|module)/[a-z0-9-]+$'
          if ! printf '%s' "$branch" | grep -qE "$pattern"; then
            echo "Branch name '$branch' does not follow the naming convention." >&2
            echo "Expected: type/short-kebab-description" >&2
            echo "Example:  feat/add-desktop-host" >&2
            exit 1
          fi
        '';

        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            treefmt = {
              enable = true;
              package = treefmtEval.config.build.wrapper;
            };
            statix.enable = true;
            deadnix.enable = true;
            commitizen.enable = true;
            branch-name = {
              enable = true;
              name = "branch naming convention";
              entry = "${branchNameCheck}";
              stages = [ "pre-push" ];
              pass_filenames = false;
            };
          };
        };
```

- [ ] **Step 4: Add the pre-commit check and devShell to the outputs attrset**

Replace the returned attrset so it reads:

```nix
      {
        formatter = treefmtEval.config.build.wrapper;

        checks = {
          formatting = treefmtEval.config.build.check self;
          pre-commit = pre-commit-check;
        };

        devShells.default = pkgs.mkShell {
          inherit (pre-commit-check) shellHook;
          buildInputs =
            pre-commit-check.enabledPackages
            ++ (with pkgs; [
              alejandra
              statix
              deadnix
              commitizen
              cachix
            ]);
        };
      }
```

- [ ] **Step 5: Verify the full check passes and hooks install**

Run: `nix flake check -L 2>&1 | tail -30`
Expected: both `formatting` and `pre-commit` checks pass. If the `treefmt` hook errors on the `package` option, consult git-hooks.nix docs via context7 (`hooks.treefmt` option name) and correct, then re-run.

Run: `nix develop -c bash -c 'ls -la .git/hooks/pre-commit'`
Expected: `.git/hooks/pre-commit` now exists (installed by the devShell shellHook).

- [ ] **Step 6: Verify commit-msg and branch-name enforcement**

Run (bad message must fail):

```bash
nix develop -c bash -c 'echo "bad message no type" > /tmp/msg && cz check --commit-msg-file /tmp/msg'
```

Expected: non-zero exit / validation failure.

Run (good message must pass):

```bash
nix develop -c bash -c 'echo "feat: add thing" > /tmp/msg && cz check --commit-msg-file /tmp/msg'
```

Expected: passes.

Run (branch check on a bad name must fail):

```bash
nix develop -c bash -c 'git checkout -b nonsense 2>/dev/null; '"$(git rev-parse --show-toplevel)"'/.git/hooks/pre-push . . </dev/null; echo "exit=$?"' ; git checkout master ; git branch -D nonsense
```

Expected: the pre-push branch-name hook reports the naming violation. (Manual alternative: run `branchNameCheck` logic — the key check is that a non-conforming branch name is rejected and `master` is exempt.)

- [ ] **Step 7: Commit**

```bash
git add flake.nix flake.lock .cz.toml
git commit -m "build: add git-hooks (format/lint/commit/branch) via git-hooks.nix"
```

---

### Task 4: direnv `.envrc`

**Files:**

- Create: `.envrc`

**Interfaces:**

- Consumes: `devShells.default` from Task 3.
- Produces: auto-loading devShell on `cd` (hooks self-install).

- [ ] **Step 1: Write `.envrc`**

```bash
use flake
```

- [ ] **Step 2: Verify direnv loads the shell**

Run: `direnv allow && direnv exec . which alejandra`
Expected: prints a `/nix/store/...alejandra...` path (devShell active). If `direnv` is not installed, note it and skip — the file is still correct.

- [ ] **Step 3: Commit**

```bash
git add .envrc
git commit -m "chore: auto-load devShell with direnv"
```

---

### Task 5: Scaffold empty config folders

**Files:**

- Create: `hosts/.gitkeep`, `modules/.gitkeep`, `overlays/.gitkeep`, `users/.gitkeep`

**Interfaces:**

- Consumes: nothing.
- Produces: empty top-level dirs for future NixOS/home-manager content.

- [ ] **Step 1: Create the placeholders**

```bash
for d in hosts modules overlays users; do mkdir -p "$d" && : > "$d/.gitkeep"; done
```

- [ ] **Step 2: Verify**

Run: `fd -H .gitkeep`
Expected: lists `hosts/.gitkeep`, `modules/.gitkeep`, `overlays/.gitkeep`, `users/.gitkeep`.

- [ ] **Step 3: Commit**

```bash
git add hosts/.gitkeep modules/.gitkeep overlays/.gitkeep users/.gitkeep
git commit -m "chore: scaffold hosts/modules/overlays/users folders"
```

---

### Task 6: CI workflow

**Files:**

- Create: `.github/workflows/ci.yml`

**Interfaces:**

- Consumes: `checks` from Task 3 (run via `nix flake check`).
- Produces: CI that formats/lints/validates on push to `master` and PRs.

- [ ] **Step 1: Write `.github/workflows/ci.yml`**

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

- [ ] **Step 2: Verify YAML is well-formed and the check command matches local**

Run: `nix develop -c bash -c 'command -v yq >/dev/null && yq . .github/workflows/ci.yml >/dev/null && echo YAML_OK || echo "no yq, skipping"'`
Expected: `YAML_OK` (or the skip note). The `nix flake check -L` line must match what passed locally in Task 3.

- [ ] **Step 3: Commit**

```bash
git add .github/workflows/ci.yml
git commit -m "ci: run nix flake check with cachix on master and prs"
```

---

### Task 7: Documentation (README, CONTRIBUTING, CLAUDE.md)

**Files:**

- Modify: `README.md`
- Create: `CONTRIBUTING.md`
- Modify: `CLAUDE.md` (full replacement)

**Interfaces:**

- Consumes: all conventions established above.
- Produces: human + agent onboarding docs.

- [ ] **Step 1: Append a Development section to `README.md`**

Add before the final `Maintained by` line:

````markdown
## Development

This repo uses native Nix tooling — no Node/Bun.

```sh
direnv allow        # first time: loads the devShell, installs git hooks
# or, without direnv:
nix develop         # enter the devShell (installs git hooks)

nix fmt             # format everything (alejandra + prettier + shfmt)
nix flake check     # run all checks: formatting, statix, deadnix, commit hooks
```
````

Commits follow **Conventional Commits** and branches follow `type/kebab-description`.
See [CONTRIBUTING.md](./CONTRIBUTING.md).

````

Also remove any lingering Bun/Node references from `README.md` if present.

- [ ] **Step 2: Write `CONTRIBUTING.md`**

```markdown
# Contributing

## Development environment

```sh
direnv allow    # or: nix develop
````

This loads a devShell with `alejandra`, `statix`, `deadnix`, `commitizen`, and
`cachix`, and installs the git hooks (via git-hooks.nix).

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

- `cachix use anshulnoori`, then paste the printed public key into
  `flake.nix`'s `extra-trusted-public-keys` (replace `REPLACE_ME`).
- Add the `CACHIX_AUTH_TOKEN` repository secret on GitHub.

````

- [ ] **Step 3: Replace `CLAUDE.md`**

```markdown
# nixconf — agent guide

Personal NixOS configuration managed with Nix flakes. **No Node/Bun** — tooling is native Nix.

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

- `flake.nix` — inputs, dev tooling, Cachix substituters.
- `treefmt.nix` — formatter config.
- `hosts/`, `modules/`, `overlays/`, `users/` — NixOS/home-manager content (grown as needed).
````

- [ ] **Step 4: Format, verify, and confirm the docs pass checks**

Run: `nix fmt && nix flake check -L 2>&1 | tail -10`
Expected: prettier may reformat the markdown; `nix flake check` passes.

- [ ] **Step 5: Commit**

```bash
git add README.md CONTRIBUTING.md CLAUDE.md
git commit -m "docs: document native nix tooling and conventions"
```

---

## Self-Review

**Spec coverage:** remove JS layer (T1) · treefmt formatter (T2) · git-hooks statix/deadnix/commitizen/branch-name + devShell (T3) · nixConfig cachix (T2) · `.cz.toml` types (T3) · branch naming master-exempt (T3) · `.envrc` (T4) · config folders (T5) · CI (T6) · README/CONTRIBUTING/CLAUDE.md (T7). All spec sections mapped.

**Manual (out of scope, documented in T7):** fill Cachix public key in `flake.nix`; add `CACHIX_AUTH_TOKEN` GitHub secret.

**Known trade-off (from spec):** header-length/subject-case not hard-enforced natively — `.cz.toml` schema enforces type + structure only.

**Placeholder scan:** the only intentional placeholder is `REPLACE_ME` for the Cachix key, called out as a manual step. No TBD/TODO logic gaps.

**Type consistency:** `treefmtEval`, `pre-commit-check`, `branchNameCheck` names are consistent between T2 and T3; branch regex and commit-type list are identical in `flake.nix`, `.cz.toml`, and the docs.
