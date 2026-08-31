# Development

## Environment

Use Lix with flakes enabled. On Linux, enter the focused development shell with
direnv or directly:

```sh
direnv allow
# or
nix develop
```

`.envrc` watches the flake and module roots. It optionally loads the ignored
`.envrc.local` file for machine-local, short-lived settings. Do not store
long-lived credentials there.

Amp Orbs run `.agents/setup` once and `.agents/resume` after resumption. These
scripts install or verify Lix, configure read-only Cachix trust, and activate
the focused direnv shell. They do not configure nixbuild.net, BuildBuddy,
Tailscale, or project secrets.

## Commands

```sh
nix fmt
nix flake check --all-systems --no-build
nix flake check -L
```

`nix fmt` runs Alejandra for Nix, Prettier for Markdown, JSON, and YAML, and
shfmt for shell scripts. Checks include Statix, deadnix, ShellCheck, actionlint,
workflow policy, Renovate validation, Git-convention fixtures, Gitleaks, and the
Amp plugin tests.

The pre-push hook runs only branch validation and
`nix flake check --all-systems --no-build`. It does not build host systems.

## Git conventions

The repository is trunk-based. `master` is the default branch. Short-lived
branches use `type/lowercase-kebab-description`; `renovate/*` is also allowed.

Allowed conventional commit types are:

```text
feat fix docs style refactor perf test build ci chore revert flake host module
```

Use `revert: ...` for a conventional revert. Generated `Merge ...`,
`Revert ...`, `fixup! ...`, and `squash! ...` commits are rejected. CI also
rejects merge commits to preserve linear history.

## CI and builds

`Nixconf CI` runs on every branch push and on manual dispatch. It has no pull
request trigger or gate job.

1. The Git job validates the branch, commit range, linear history, and secrets.
2. The quality job evaluates both Linux systems, then runs the native
   `x86_64-linux` flake checks. Branch checks have read-only cache access;
   `master` checks may publish results.

There are no host build targets yet. When hosts are added, CI will call
`nix build`: AMD64 targets will build on the GitHub runner and ARM64 device
targets will use nixbuild.net. Developer machines, pre-push hooks, and Amp Orbs
must not receive nixbuild.net credentials.

Only the `master` check receives `CACHIX_AUTH_TOKEN`, scoped to the
repository-specific `cachix watch-exec` step. CI does not persist the token or
install a whole-store watcher. Trusted physical devices may publish explicit
repository builds by retrieving the Cachix token from 1Password at runtime;
they must not persist the token as plaintext.

## Dependency updates

Renovate scans daily in `prCreation: "approval"` mode. It creates update
branches immediately and lists them in the required Dependency Dashboard, but
does not create a pull request unless someone checks a dashboard approval box.
Do not use those approval boxes: Amp review, Mako notification, and an explicit
owner merge request are the promotion path. Renovate vulnerability-alert PRs
are disabled to preserve this zero-PR contract. Nix flake input updates and
GitHub Actions updates each use one grouped branch. Lock-file maintenance runs
weekly and creates a branch only when `flake.lock` changes.

CI completion on a `renovate/*` branch can be delivered to the project-local
Amp plugin as a signed `workflow_run` webhook. The plugin verifies repository,
workflow, actor, branch, commit, and signature before starting a private,
read-only review thread. Only a later direct owner message may authorize a
fast-forward merge and push.

The optional Home Manager module `homeModules.renovate-notifier` polls GitHub
every six hours and sends one desktop notification for each new branch SHA. It
does not expose an inbound device webhook.

## External setup

These shared settings are intentionally not changed by repository code:

- Install and enable Renovate for `anshulnoori/nixconf`.
- Add the `CACHIX_AUTH_TOKEN` repository secret.
- Run the Renovate review plugin in its owning private Amp Orb thread with
  `RENOVATE_REVIEW_OWNER_THREAD` and `RENOVATE_REVIEW_WEBHOOK_SECRET`.
- Register the generated private webhook URL with GitHub for `workflow_run`
  events and use the same secret.
- Add `NIXBUILDNET_TOKEN` only when ARM64 host build targets are introduced.

No repository ruleset, webhook, secret, or external service is created
automatically.
