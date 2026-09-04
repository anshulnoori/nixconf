# Development

## Environment

Use Lix with flakes enabled. Authenticate GitHub before evaluating the flake so
Git can fetch the application monorepo input. Then enter the development shell:

```sh
gh auth status --hostname github.com
direnv allow
# or
nix develop
```

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
the host. Build the full `t1` closure on `t1`, where it is substantially faster.
This personal repository has no GitHub Actions workflow or other CI.

## Git conventions

The repository is trunk-based. `master` is the default branch. Short-lived
branches use `type/lowercase-kebab-description`; `renovate/*` is also allowed.

Allowed conventional commit types are:

```text
feat fix docs style refactor perf test build ci chore revert flake host module
```

Use `revert: ...` for a conventional revert. Generated `Merge ...`,
`Revert ...`, `fixup! ...`, and `squash! ...` commits are rejected. Keep history
linear.

## Dependency updates

Renovate scans daily in `prCreation: "approval"` mode. It creates grouped Nix
flake update branches and lists them in the Dependency Dashboard. Weekly lock
file maintenance creates a branch only when `flake.lock` changes. Nothing
merges, builds, or activates an update automatically.

The `services.nixconf-update` user timer polls GitHub every six hours. It records
active `renovate/*` revisions and compares `master` with the revision embedded
in the running NixOS system. Waybar shows actionable state, and Mako sends at
most one persistent notification for each branch revision. Clicking the
indicator opens GitHub-provided diffs in a floating terminal. A confirmed
update fast-forwards a clean `/etc/nixos` checkout to the inspected `master`
revision and runs `nh os switch`; it never merges a Renovate branch.

Install and enable Renovate for `anshulnoori/nixconf` separately. The repository
does not create external services, credentials, or repository settings.

## Development policy

nvf owns Neovim. Per-project flakes supply language servers, formatters,
linters, build tools, and language toolchains. Do not add those tools globally
to this flake.
