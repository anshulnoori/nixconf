# Development

## Environment

Use Lix with flakes enabled. The private application monorepo uses SSH so Git
can authenticate through the 1Password SSH agent without a GitHub token in Nix
configuration. Enable the SSH agent in 1Password, add the key to GitHub as an
authentication key, unlock 1Password, and verify the connection:

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

Run `nh os switch` as the login user, without a leading `sudo`. `nh` elevates
activation itself; starting it with `sudo` would hide the user's 1Password
agent from the flake fetch.

`.envrc` watches the flake and module roots. It optionally loads the ignored
`.envrc.local` file for machine-local, short-lived settings. Do not store
long-lived credentials there.

Amp Orbs run `.agents/setup` once and `.agents/resume` after resumption. These
scripts install or verify Lix, configure read-only Cachix trust, and activate
the focused direnv shell. They do not configure BuildBuddy, Tailscale, or
project secrets.

## Checks

```sh
nix fmt
nix flake check --all-systems --no-build
nix flake check -L
```

`nix fmt` runs Alejandra for Nix, Prettier for Markdown, JSON, and YAML, and
shfmt for shell scripts. Flake checks cover formatting, Statix, deadnix,
ShellCheck, Renovate configuration, Git conventions, Gitleaks, Minuet's secret
transport, and the Notion Calendar integration.

The pre-push hook validates the branch and evaluates the flake without building
the host. On each push to `master`, `renovate/**`, or `updates/**`, GitHub Actions
repeats evaluation, builds the full `t1` closure, and uploads newly built paths
to `anshulnoori.cachix.org`. Successful builds publish the commit status
`nixconf/build` on the exact revision that was built.
The workflow requires `CACHIX_AUTH_TOKEN` and a read-only monorepo deploy key in
`MONOREPO_SSH_KEY` as repository secrets.

## Git conventions

The repository is trunk-based. `master` is the default branch. Short-lived
branches use `type/lowercase-kebab-description`; `renovate/*` is also allowed.
The weekly workflow owns the fixed `updates/flake-lock` automation branch.

Allowed conventional commit types are:

```text
feat fix docs style refactor perf test build ci chore revert flake host module
```

Use `revert: ...` for a conventional revert. Generated `Merge ...`,
`Revert ...`, `fixup! ...`, and `squash! ...` commits are rejected. Keep history
linear.

## Dependency updates

Renovate scans supported non-Nix dependencies daily in `prCreation: "approval"`
mode. It creates `renovate/**` branches and lists proposed updates in the
Dependency Dashboard. Nix management is disabled there so that it cannot race
the repository's weekly flake updater.

The flake workflow runs Mondays at 04:41 UTC, or on manual dispatch.
It runs `nix flake update` and publishes changes to the bot-owned
`updates/flake-lock` branch. Each run replaces that branch using a lease;
do not put manual work on it. Explicit revision pins in `flake.nix` stay pinned.
The workflow builds the committed candidate and records a pending, success,
or failure status under `nixconf/build`. It does not open or merge a pull request.
Its token-authenticated push does not start another workflow, so validation
runs in the same job. Failed candidates remain visible for inspection.

Proton GE uses `nvfetcher.toml` and the generated pins in `_sources/`.
The build-and-cache workflow checks published releases every six hours.
It packages both binary architectures and builds the full `t1` system on every
scheduled run before pushing changed generated pins directly to `master`. It
then records `nixconf/build` on that new commit because token-authenticated
pushes do not start another workflow. It creates no pull requests. Failed
validation prevents publication. A concurrent change to `master` also prevents
publication because the workflow never force-pushes.

To refresh the pins locally, run `nix run .#nvfetcher`.
Do not edit `_sources/` manually. The generated files retain nvfetcher's format.
The package override inherits Steam integration from nixpkgs.
The ARM check packages ARM binaries on the native builder without executing them.

Both workflows use `nh os build` for full-system builds and upload the system
closure to Cachix before marking the commit successful. Pushes to `master`,
`renovate/**`, and `updates/**` trigger validation. Fork pull requests do not
receive private credentials or run these jobs.

Set the repository variable `NIX_BUILD_RUNNER_LABELS` to a JSON array of
your existing Namespace runner labels to run both jobs there. Without it,
jobs use `["ubuntu-24.04"]`. The runner must be an x86_64 Linux GitHub Actions
runner compatible with the Lix installer. This setting does not provision a runner.
Both jobs require `MONOREPO_SSH_KEY` and `CACHIX_AUTH_TOKEN` Actions secrets.

The `services.nixconf-update` user timer polls GitHub every six hours. It checks
`renovate/*` and `updates/*`, omits merged branches, and compares `master` with
the running system revision. Waybar distinguishes available updates, failed
builds, ready-to-install revisions, and unavailable checks. Local results expire
after 12 hours; weekly discovery results expire after eight days. Pending builds
older than six hours are unavailable. Missing results and API errors never mean
that the system is up to date.

Mako notifies once per branch, revision, and build state. Clicking the indicator
shows diffs and CI links. Installation requires a fresh successful `nixconf/build`
lookup for the exact reviewed `master` commit. It fast-forwards a clean
`/etc/nixos` checkout and runs `nh os switch`. It never merges a dependency branch
or advances local pins. Cached build results reduce compilation on the PC.

Run `bash scripts/test-nixconf-update.sh` to test states and installation guards
without network access, desktop notifications, or system activation.

Install and enable Renovate for `anshulnoori/nixconf` separately. The repository
does not create external services, credentials, or repository settings.

## Development policy

nvf owns Neovim. Per-project flakes supply language servers, formatters,
linters, build tools, and language toolchains. Do not add those tools globally
to this flake.
