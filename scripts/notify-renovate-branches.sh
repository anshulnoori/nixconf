#!/usr/bin/env bash
set -euo pipefail

state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/nixconf
seen="$state_dir/renovate-branches"
lock="$state_dir/renovate-branches.lock"
current=$(mktemp)
updated=$(mktemp)
trap 'rm -f "$current" "$updated"' EXIT

mkdir -p "$state_dir"
exec 9>"$lock"
flock 9
touch "$seen"

curl --fail --silent --show-error \
  --header 'Accept: application/vnd.github+json' \
  --header 'X-GitHub-Api-Version: 2022-11-28' \
  'https://api.github.com/repos/anshulnoori/nixconf/branches?per_page=100' |
  jq -r '.[] | select(.name | startswith("renovate/")) | [.name, .commit.sha] | @tsv' |
  sort -u >"$current"

cp "$seen" "$updated"
while IFS=$'\t' read -r branch revision; do
  [[ -n $branch && -n $revision ]] || continue
  if ! grep -Fqx -- "$branch"$'\t'"$revision" "$seen"; then
    notify-send \
      --app-name nixconf \
      'nixconf dependency update' \
      "$branch at ${revision:0:12}"
    printf '%s\t%s\n' "$branch" "$revision" >>"$updated"
  fi
done <"$current"

sort -u "$updated" >"$seen"
