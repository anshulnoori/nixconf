#!/usr/bin/env bash
set -euo pipefail

branch=${1:-}
if [[ $# -gt 1 ]]; then
  printf 'Usage: check-branch-name [branch]\n' >&2
  exit 2
fi
if [[ -z $branch ]]; then
  branch=$(git symbolic-ref --quiet --short HEAD) || {
    printf 'Cannot determine the branch name from a detached HEAD.\n' >&2
    exit 1
  }
fi

conventional='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert|flake|host|module)/[a-z0-9]+(-[a-z0-9]+)*$'
renovate='^renovate/[a-z0-9]([a-z0-9._/-]*[a-z0-9])?$'
if [[ $branch == master || $branch =~ $conventional || $branch =~ $renovate ]]; then
  exit 0
fi

printf '%s\n' \
  "Invalid branch name: $branch" \
  'Use <type>/<lowercase-kebab-description>, for example feat/add-desktop-host.' \
  'Allowed types: feat, fix, docs, style, refactor, perf, test, build, ci,' \
  'chore, revert, flake, host, and module. The master and renovate/* branches' \
  'are also allowed.' >&2
exit 1
