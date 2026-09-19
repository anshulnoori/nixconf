# Development

## Environment

Use Lix with flakes enabled. Nix inputs use HTTPS for dependency downloads.
Private GitHub inputs use the existing GitHub CLI credential helper.
No token is stored in Nix configuration. Run `gh auth status` to check access.

Interactive Git and updater pushes use SSH. Enable the 1Password SSH agent,
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
The updater fetches `upstream-read` and pushes `origin`.
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
boot, then every three days while the user manager runs. To request a build now:

```sh
systemctl --user start nixconf-update.service
```

The updater creates an isolated worktree under
`~/.local/state/nixconf/update-worktree`. It uses the newer compatible commit
from local `master` and remote `master`. It preserves staged, unstaged, and
untracked files in `/etc/nixos`. Uncommitted configuration changes do not enter
the update. Diverged histories and unknown installed revisions stop the update.
An installed revision ending in `-dirty` uses its verified base commit for
ancestry checks. This does not certify the exact activated configuration.
The background service preserves local changes and never activates a system.

The background sequence is:

1. Fetch `master` and create the clean `build/local-update` worktree.
2. Run `nix flake update`, `nix run .#nvfetcher`, and the internal source refresher there.
3. Validate the candidate and run stock `nh os build` with the uncommitted pins.
4. Retain the candidate and show **Update Available** after the build succeeds.

The timer does not commit, sign, push, or request sudo. HTTPS reads use existing
credentials without terminal prompts. SSH subprocesses cannot use the agent.

Clicking the update icon or notification opens an interactive terminal. The
updater verifies that the candidate still matches the completed build. It then
signs changed pins as `Anshul Noori <anshulnoori@gmail.com>` with
`chore(nix): update flake.lock`. It validates and builds the signed revision,
verifies signatures and final messages, then pushes to `master`.
Signing changes the revision metadata, so this build reuses packages from the
background build but produces a system with the signed revision.

After publication, stock `nh os switch` shows the diff and requests confirmation
for that exact built system. The updater fast-forwards a clean `/etc/nixos`
checkout on `master`. Dirty checkouts and experimental branches stay unchanged.
There is no `nh` wrapper. A plain `nh os switch` still uses `/etc/nixos` and does
not sign or publish the retained candidate.

The updater never force-pushes. Signing, validation, or build failures prevent
publication. A failed push retains the signed candidate for retry.
Successful publication removes the worktree and its reserved branch. A failed
or cancelled switch can retry the published system without another commit or push.

CI checks repository maintenance after publication. CI success is not an
activation prerequisite in this local-first model. Public upstream caches remain
available, but there is no personal binary cache. Niks3 and R2 are deferred.

### Authentication and recovery

The updater uses the configured Git signing key and 1Password agent. The SSH
authentication key and signing key can be different. Signature verification
requires the matching public key in Git's allowed-signers file. Private monorepo
fetches use HTTPS credentials. Repository pushes use SSH authentication.

Only the interactive handoff requests signing and push approvals. A locked
agent does not block the background build. Only an explicit switch requires
sudo. No private key export or passwordless sudo rule is part of this workflow.

If an update stops, inspect the log and retained candidate:

```sh
journalctl --user -u nixconf-update
git -C ~/.local/state/nixconf/update-worktree status
git -C ~/.local/state/nixconf/update-worktree log -1 --show-signature
systemctl --user start nixconf-update.service
```

Retry the service as the login user. Then click the update icon to sign,
publish, and switch interactively. Approve 1Password requests in that terminal flow.
If the remote advanced, reconcile the histories manually before resumption.
Do not delete a retained worktree that contains an unpublished commit.
If the installed revision is unknown, establish a clean committed system revision
manually before enabling automatic updates.

Waybar shows available updates, local progress, failures, and stale results.
Mako notifies you when a build is ready, or when an operation succeeds or fails.
Clicking the indicator opens the interactive handoff. Stock `nh` receives the
built system path with `--ask --diff always`. It does not regenerate the built inputs.
The UI does not depend on GitHub comparison or discovery APIs.
An uncommitted candidate stays visible until its exact built system is installed.
After publication, the indicator also clears for an installed candidate commit
or descendant. A `-dirty` suffix does not prove the activated files match.

### Update sources and CI

Explicit compatibility pins in `flake.nix` remain unchanged. Proton GE uses
`nvfetcher.toml` and generated files under `_sources/`. The ARM check packages
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
and malformed responses stop generation. API failures also stop the update;
an optional `GH_TOKEN` can raise the public API rate limit.
Only the SF Pro JSON and the maintenance workflow join the existing generated
pin whitelist. All changes enter the same signed, checked, locally built candidate.

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

Run `bash scripts/test-nixconf-update.sh` for isolated Git and SSH-signature tests.
Run `bash scripts/test-refresh-local-sources.sh` for offline source-validation tests.
These tests stub builds, activation, and notifications. Their pushes target only
disposable local repositories, never GitHub.

## Development policy

nvf owns Neovim. Per-project flakes supply language servers, formatters,
linters, build tools, and language toolchains. Do not add those tools globally
to this flake.
