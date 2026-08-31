#!/usr/bin/env bash
set -euo pipefail

root=${1:-.}
workflows="$root/.github/workflows"
ci="$workflows/ci.yml"

actionlint -config-file "$root/.github/actionlint.yaml" "$workflows"/*.yml
shellcheck "$root/.agents/setup" "$root/.agents/resume" "$root"/scripts/*.sh

if rg -n '^[[:space:]]+pull_request:' "$workflows"; then
  printf 'Pull-request workflows are not allowed.\n' >&2
  exit 1
fi

if rg -n 'DeterminateSystems/nix-installer-action|nixbuild/nixbuild-action|\bnix build\b' "$workflows"; then
  printf 'Workflow contains a deferred or excluded build path.\n' >&2
  exit 1
fi

if rg -nP 'uses:\s+[^\s#]+@(?![a-f0-9]{40}\s+#\s+\S)' "$workflows"; then
  printf 'Every external action must use a full commit SHA and version comment.\n' >&2
  exit 1
fi

rg -F 'branches:' "$ci" >/dev/null
rg -F '      - "**"' "$ci" >/dev/null
rg -F 'workflow_dispatch:' "$ci" >/dev/null
rg -F 'nix flake check --all-systems --no-build' "$ci" >/dev/null
rg -F 'cachix watch-exec anshulnoori' "$ci" >/dev/null
rg -F "if: github.ref == 'refs/heads/master'" "$ci" >/dev/null
rg -F 'git rev-list --merges' "$ci" >/dev/null

if rg -F 'cachix authtoken' "$ci"; then
  printf 'Cachix credentials must not be persisted.\n' >&2
  exit 1
fi

test "$(rg -c 'CACHIX_AUTH_TOKEN:' "$ci")" = 1

test "$(rg -c 'samueldr/lix-gha-installer-action@[a-f0-9]{40}' "$ci")" = 2
test "$(rg -c 'actions/checkout@[a-f0-9]{40}' "$ci")" = 2

printf 'Workflow policy passed.\n'
