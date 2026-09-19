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
and updater tests. It does not evaluate systems or build `t1`, Proton, or desktop
packages. Updates, system validation, and activation run locally before clients
push. CI never updates pins, commits, pushes, or publishes a binary cache.

## Git conventions

The repository is trunk-based. `master` is the default branch. Short-lived
experimental branches use `type/lowercase-kebab-description`.
The local updater reserves `build/local-update` for its isolated worktree.

Allowed conventional commit types are:

```text
feat fix docs style refactor perf test build ci chore revert flake host module
```

Use `revert: ...` for a conventional revert. Generated `Merge ...`,
`Revert ...`, `fixup! ...`, and `squash! ...` commits are rejected. Keep history
linear.

## Dependency updates

Updates originate on `t1`, not in CI. The user timer runs ten minutes after
boot, then every three days while the user manager runs. Manual updates use:

```sh
nixconf-update update
```

The updater creates an isolated worktree under
`~/.local/state/nixconf/update-worktree`. It uses the newer compatible commit
from local `master` and remote `master`. It preserves staged, unstaged, and
untracked files in `/etc/nixos`. Uncommitted configuration changes do not enter
the update. Diverged histories and unknown installed revisions stop the update.

The update sequence is:

1. Fetch `master` and create the clean `build/local-update` worktree.
2. Run `nix flake update` and `nix run .#nvfetcher` there.
3. Commit changed pins with `git commit -S` as `Anshul Noori <anshulnoori@gmail.com>`.
4. Verify signatures and final commit messages, then validate the signed candidate.
5. Run `nh os build` against that clean candidate, retain it, and notify you.
6. Wait for you to run `nixconf-update switch` or approve the switch in the details prompt.
7. Revalidate the candidate and run `nh os switch` without updating its pins.
8. Verify the installed revision, inspect signatures and messages again, then push it to `master`.

Neither the timer nor `update` or `resume` activates or pushes a candidate.
Repeated runs retain the pending candidate rather than replacing it.

The updater never force-pushes. Signing, validation, or activation failures
prevent publication. A failed push retains the installed commit locally.
Successful publication removes the temporary worktree and its reserved branch.
The original checkout stays unchanged, even after success.

CI checks repository maintenance after activation. CI success is not an
activation prerequisite in this local-first model. Public upstream caches remain
available, but there is no personal binary cache. Niks3 and R2 are deferred.

### Authentication and recovery

The updater uses the configured Git signing key and 1Password agent. The SSH
authentication key and signing key can be different. Signature verification
requires the matching public key in Git's allowed-signers file. Private monorepo
fetches and repository pushes also require authentication.

The timer builds without requesting sudo. A locked agent or denied signing
request can still stop preparation. Only an explicit switch requires sudo;
the existing password-required policy remains unchanged. No private key export
or passwordless sudo rule is part of this workflow.

If an update stops, inspect the log and retained candidate:

```sh
journalctl --user -u nixconf-update
git -C ~/.local/state/nixconf/update-worktree status
git -C ~/.local/state/nixconf/update-worktree log -1 --show-signature
nixconf-update resume
```

Run `resume` in a terminal as the login user and approve 1Password requests.
Resume validates and builds the retained candidate without switching. When ready,
run `nixconf-update switch` to activate and publish it.
If the remote advanced, reconcile the histories manually before resumption.
Do not delete a retained worktree that contains an unpublished installed commit.
If the installed revision is unknown, establish a clean committed system revision
manually before enabling automatic updates.

Waybar shows available updates, local progress, failures, and stale results.
Mako notifies you when a build is ready, or when an operation succeeds or fails.
Clicking the indicator opens candidate details and asks for explicit switch
approval, or offers to build an update if none exists. The UI does not depend
on GitHub comparison or discovery APIs.

### Update sources and CI

Explicit compatibility pins in `flake.nix` remain unchanged. Proton GE uses
`nvfetcher.toml` and generated files under `_sources/`. The ARM check packages
ARM binaries without executing them. Amp keeps its separate self-updater:
Nix pins its bootstrap, not the mutable executable under `~/.amp/bin`.

Renovate is disabled entirely. Its minimal `renovate.json` prevents an installed
Renovate App from onboarding this repository again; no Renovate tooling remains.

The maintenance workflow runs on pushes and manual dispatch, without a schedule.
New pushes cancel older maintenance runs on the same ref. It uses GitHub-hosted
runners, not Namespace. Fork pull requests do not run this job or receive private
credentials. The workflow still needs the read-only `MONOREPO_SSH_KEY` because
the flake imports the private monorepo, but it needs no Cachix secret or status
write permission. Native GitHub job results replace the old `nixconf/build`
status; CI no longer claims to validate a system build.

Run `bash scripts/test-nixconf-update.sh` for isolated Git and SSH-signature tests.
These tests stub builds, activation, and notifications. Their pushes target only
disposable local repositories, never GitHub.

## Development policy

nvf owns Neovim. Per-project flakes supply language servers, formatters,
linters, build tools, and language toolchains. Do not add those tools globally
to this flake.
