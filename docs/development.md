# Development

## Environment

Use Lix with flakes enabled. Nix inputs use HTTPS for dependency downloads.
Private GitHub inputs use the existing GitHub CLI credential helper.
No token is stored in Nix configuration. Run `gh auth status` to check access.

Interactive Git pushes use SSH. Enable the 1Password SSH agent,
register the authentication key with GitHub, unlock 1Password, and verify access:

```sh
test -S "$HOME/.1password/agent.sock"
ssh -T git@github.com
```

GitHub should identify the account and report that it does not provide shell
access. Then enter the development shell:

```sh
direnv allow
# or
nix develop
```

Run `nh os switch` as the login user, without a leading `sudo`.
`nh` elevates activation separately.

### Git transport

Each URL selects its transport. There is no global HTTPS-to-SSH rewrite.
GitHub CLI still clones over SSH. Direnv uses standard nix-direnv without
transport overrides. Other private Git servers need their own credential helper.

For each nixconf checkout, configure an SSH origin and an HTTPS read remote:

```sh
git remote set-url origin ssh://git@github.com/anshulnoori/nixconf.git
git remote add upstream-read https://github.com/anshulnoori/nixconf.git
```

If `upstream-read` already exists, use `git remote set-url` instead of `add`.
Normal `git fetch` and `git push` retain the SSH origin.
Dependency downloads use the HTTPS URLs declared in `flake.nix`.
Commit signing and pushes retain 1Password approval requirements.

`.envrc` watches the flake and module roots. It optionally loads the ignored
`.envrc.local` file for machine-local, short-lived settings. Do not store
long-lived credentials there.

Amp Orbs run `.agents/setup` once and `.agents/resume` after resumption. These
scripts install or verify Lix and activate the focused direnv shell. They do
not configure a personal binary cache, BuildBuddy, Tailscale, or project secrets.

## Checks

```sh
nix fmt
nix flake check --all-systems --no-build
nix flake check -L
```

`nix fmt` runs Alejandra for Nix, Prettier for Markdown, JSON, and YAML, and
shfmt for shell scripts. Flake checks cover formatting, Statix, deadnix,
ShellCheck, Git conventions, Gitleaks, Minuet's secret
transport, and the Notion Calendar integration.

The pre-push hook validates the branch and evaluates the flake without building
the host. On pushes, GitHub Actions runs repository maintenance on standard
`ubuntu-24.04` runners: formatting, lint/security checks, Git-convention tests,
and source-refresher tests. It does not evaluate systems or build `t1`, Proton, or desktop
packages. Updates, system validation, and activation run locally before clients
push. CI never updates pins, commits, pushes, or publishes a binary cache.

## Git conventions

The repository is trunk-based. `master` is the default branch. Short-lived
experimental branches use `type/lowercase-kebab-description`.

Allowed conventional commit types are:

```text
feat fix docs style refactor perf test build ci chore revert flake host module
```

Use `revert: ...` for a conventional revert. Generated `Merge ...`,
`Revert ...`, `fixup! ...`, and `squash! ...` commits are rejected. Keep history
linear.

## Dependency updates

Update and activate the system from `/etc/nixos` as the login user:

```sh
nh os switch --update
```

The System menu's **Update** entry runs the same command in a terminal.
`--update` runs `nix flake update` before the build. Commit the changed
`flake.lock` afterwards as `chore(nix): update flake.lock`.

### Update sources and CI

Proton GE uses `nvfetcher.toml` and generated files under `_sources/`. Refresh
them with `nix run .#nvfetcher`. The ARM check packages
ARM binaries without executing them. Amp keeps its separate self-updater:
Nix pins its bootstrap, not the mutable executable under `~/.amp/bin`.

The internal source refresher downloads SF Pro from Apple's official HTTPS URL.
It validates the installer layout, package identifier, version, and font formats
before recording the DMG hash in `packages/sf-pro-source.json`. Unexpected formats
or version decreases stop generation for manual review. It never executes the installer.
Its Nix package supplies modern 7-Zip, libarchive, libxml2, curl, jq, and OpenSSL.

The same refresher resolves the latest stable releases of `actions/checkout` and
`samueldr/lix-gha-installer-action` through GitHub's API. Workflow references remain
full commit SHA pins with release comments. Moved existing tags, older releases,
and malformed responses stop generation. API failures also stop the refresh;
an optional `GH_TOKEN` can raise the public API rate limit.
Run `nix run .#refresh-local-sources` to refresh these pins.

Devbox follows the root `namespace-devbox-release` checksum-manifest input.
After `nix flake update`, the refresher obtains the hash-verified manifest through
Nix and compares it with the versioned release manifest. It changes only that
input's locked URL to the immutable release URL. The original latest URL and
locked hash remain unchanged, so later updates still discover new releases.
Both Linux archive entries must declare the same version. Missing or mismatched
metadata stops generation without changing the pin files.

Renovate is disabled entirely. Its minimal `renovate.json` prevents an installed
Renovate App from onboarding this repository again; no Renovate tooling remains.

The maintenance workflow runs on pushes and manual dispatch, without a schedule.
New pushes cancel older maintenance runs on the same ref. It uses GitHub-hosted
runners, not Namespace. Fork pull requests do not run this job or receive private
credentials. The workflow still needs the read-only `MONOREPO_SSH_KEY` because
the flake imports the private monorepo, but it needs no Cachix secret or status
write permission. Native GitHub job results replace the old `nixconf/build`
status; CI no longer claims to validate a system build.

Run `bash scripts/test-refresh-local-sources.sh` for offline source-validation tests.
These tests stub builds, activation, and notifications. Their pushes target only
disposable local repositories, never GitHub.

## Development policy

nvf owns Neovim. Per-project flakes supply language servers, formatters,
linters, build tools, and language toolchains. Do not add those tools globally
to this flake.
