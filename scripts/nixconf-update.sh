#!/usr/bin/env bash
set -euo pipefail

repository=anshulnoori/nixconf
repository_api="https://api.github.com/repos/$repository"
default_branch=master
checkout=/etc/nixos
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/nixconf
status_file="$state_dir/update-status.json"
notified_file="$state_dir/update-notified"
runtime_dir=${XDG_RUNTIME_DIR:-/tmp}
lock_file="$runtime_dir/nixconf-update.lock"
temporary_directory=

cleanup() {
  if [[ -n $temporary_directory ]]; then
    rm -rf "$temporary_directory"
  fi
}
trap cleanup EXIT

make_temporary_directory() {
  if [[ -z $temporary_directory ]]; then
    temporary_directory=$(mktemp -d)
  fi
}

github_get() {
  curl \
    --fail \
    --silent \
    --show-error \
    --header 'Accept: application/vnd.github+json' \
    --header 'X-GitHub-Api-Version: 2022-11-28' \
    "$repository_api/$1"
}

running_revision() {
  local revision

  revision=$(
    /run/current-system/sw/bin/nixos-version \
      --configuration-revision 2>/dev/null || true
  )
  printf '%s\n' "${revision:-unknown}"
}

signal_waybar() {
  pkill -RTMIN+10 -x waybar 2>/dev/null || true
}

notify_once() {
  local notification_id=$1
  local summary=$2
  local body=$3

  if grep -Fqx -- "$notification_id" "$notified_file"; then
    return
  fi

  if notify-send \
    --app-name=nixconf-update \
    --urgency=normal \
    "$summary" \
    "$body"; then
    printf '%s\n' "$notification_id" >>"$notified_file"
  fi
}

fetch_branches() {
  local destination=$1
  local page=1
  local page_file
  local page_length

  printf '[]\n' >"$destination"
  while true; do
    page_file="$temporary_directory/branches-$page.json"
    github_get "branches?per_page=100&page=$page" >"$page_file"
    jq -e 'type == "array"' "$page_file" >/dev/null
    jq -s 'add' "$destination" "$page_file" >"$destination.next"
    mv "$destination.next" "$destination"

    page_length=$(jq 'length' "$page_file")
    if ((page_length < 100)); then
      break
    fi
    page=$((page + 1))
  done
}

check_updates() {
  local branches_file
  local master_file
  local master_revision
  local renovate_file
  local current_revision
  local relation=unknown
  local compare_file
  local main_update=false
  local checked_at
  local next_status

  mkdir -p "$state_dir"
  exec 9>"$lock_file"
  flock 9
  touch "$notified_file"
  make_temporary_directory

  branches_file="$temporary_directory/branches.json"
  master_file="$temporary_directory/master.json"
  renovate_file="$temporary_directory/renovate.json"
  compare_file="$temporary_directory/master-compare.json"

  fetch_branches "$branches_file"
  github_get "branches/$default_branch" >"$master_file"
  master_revision=$(jq -er '.commit.sha' "$master_file")
  jq '[
    .[]
    | select(.name | startswith("renovate/"))
    | {name, revision: .commit.sha}
  ] | sort_by(.name)' "$branches_file" >"$renovate_file"

  current_revision=$(running_revision)
  if [[ $current_revision == "$master_revision" ]]; then
    relation=identical
  elif [[ $current_revision =~ ^[0-9a-f]{40}$ ]] &&
    github_get "compare/$current_revision...$master_revision" >"$compare_file"; then
    relation=$(jq -r '.status // "unknown"' "$compare_file")
  fi

  if [[ $relation == ahead ]]; then
    main_update=true
  fi

  checked_at=$(date --utc --iso-8601=seconds)
  next_status=$(mktemp --tmpdir="$state_dir" update-status.XXXXXX)
  jq -n \
    --arg checkedAt "$checked_at" \
    --arg branch "$default_branch" \
    --arg masterRevision "$master_revision" \
    --arg runningRevision "$current_revision" \
    --arg relation "$relation" \
    --argjson mainUpdate "$main_update" \
    --slurpfile renovate "$renovate_file" \
    '{
      checkedAt: $checkedAt,
      main: {
        branch: $branch,
        revision: $masterRevision,
        runningRevision: $runningRevision,
        relation: $relation,
        updateAvailable: $mainUpdate
      },
      renovate: $renovate[0],
      count: (($renovate[0] | length) + (if $mainUpdate then 1 else 0 end))
    }' >"$next_status"
  mv "$next_status" "$status_file"

  if [[ $main_update == true ]]; then
    notify_once \
      "$default_branch"$'\t'"$master_revision" \
      "NixOS update available" \
      "$default_branch is newer than the running system (${master_revision:0:12})"
  fi

  while IFS=$'\t' read -r branch revision; do
    [[ -n $branch && -n $revision ]] || continue
    notify_once \
      "$branch"$'\t'"$revision" \
      "nixconf dependency update" \
      "$branch at ${revision:0:12}"
  done < <(jq -r '.[] | [.name, .revision] | @tsv' "$renovate_file")

  sort -u -o "$notified_file" "$notified_file"
  signal_waybar
}

waybar_status() {
  if [[ ! -r $status_file ]] || ! jq -e . "$status_file" >/dev/null 2>&1; then
    printf '{"text":""}\n'
    return
  fi

  jq -c '
    if .count == 0 then
      {text: ""}
    else
      ([
        if .main.updateAvailable then
          "Running system → " + .main.branch + " " + (.main.revision[0:12])
        else empty end,
        (.renovate[] | .name + " " + (.revision[0:12]))
      ]) as $updates
      | {
          text: ("󰏗 " + (.count | tostring)),
          class: "updates",
          tooltip: (($updates + ["", "Click to inspect diffs and update safely"]) | join("\n"))
        }
    end
  ' "$status_file"
}

append_comparison() {
  local base=$1
  local head=$2
  local title=$3
  local report=$4
  local comparison="$temporary_directory/compare-$head.json"

  {
    printf '\n%s\n' "$title"
    printf '%*s\n' "${#title}" '' | tr ' ' '='
  } >>"$report"

  if ! github_get "compare/$base...$head" >"$comparison"; then
    printf 'GitHub comparison unavailable.\n' >>"$report"
    return
  fi

  jq -r '
    "Status: \(.status) | commits: \(.total_commits) | files: \(.files | length)",
    "",
    "Commits:",
    (.commits[]? | "  \(.sha[0:12])  \(.commit.message | split("\n")[0])"),
    "",
    "Diff:",
    (.files[]? |
      "\n--- \(.filename) [\(.status), +\(.additions)/-\(.deletions)]\n"
      + (.patch // "[binary file or diff unavailable from GitHub]"))
  ' "$comparison" >>"$report"
}

show_details() {
  local report
  local main_update
  local master_revision
  local current_revision
  local checked_at
  local branch
  local revision
  local answer=

  if [[ ! -r $status_file ]]; then
    check_updates
  fi

  make_temporary_directory
  report="$temporary_directory/update-report.txt"
  main_update=$(jq -r '.main.updateAvailable' "$status_file")
  master_revision=$(jq -r '.main.revision' "$status_file")
  current_revision=$(jq -r '.main.runningRevision' "$status_file")
  checked_at=$(jq -r '.checkedAt' "$status_file")

  {
    printf 'nixconf update status\n'
    printf '=====================\n\n'
    printf 'Checked: %s\n' "$checked_at"
    printf 'Running revision: %s\n' "$current_revision"
    printf '%s revision: %s\n' "$default_branch" "$master_revision"
    printf 'Relationship: %s\n' "$(jq -r '.main.relation' "$status_file")"
  } >"$report"

  if [[ $main_update == true ]]; then
    append_comparison \
      "$current_revision" \
      "$master_revision" \
      "Merged $default_branch update" \
      "$report"
  elif [[ $current_revision != "$master_revision" ]]; then
    printf '\nA clean running Git revision is required to compare merged updates.\n' \
      >>"$report"
  fi

  while IFS=$'\t' read -r branch revision; do
    [[ -n $branch && -n $revision ]] || continue
    append_comparison \
      "$master_revision" \
      "$revision" \
      "$branch" \
      "$report"
  done < <(jq -r '.renovate[] | [.name, .revision] | @tsv' "$status_file")

  if jq -e '.renovate | length > 0' "$status_file" >/dev/null; then
    {
      printf '\nRenovate branches require Amp review and an explicit owner merge.\n'
      printf 'This tool never merges a Renovate branch.\n'
    } >>"$report"
  fi

  less "$report"

  if [[ $main_update == true ]]; then
    read -r -p \
      "Fast-forward $checkout to origin/$default_branch and switch now? [y/N] " \
      answer || true
    if [[ $answer == [yY] || $answer == [yY][eE][sS] ]]; then
      apply_update "$master_revision"
    fi
  fi
}

apply_update() {
  local expected_revision=${1:-}
  local origin
  local branch
  local remote_line
  local remote_revision
  local fetched_revision

  if [[ ! $expected_revision =~ ^[0-9a-f]{40}$ ]]; then
    printf 'A full expected revision is required.\n' >&2
    exit 2
  fi
  if [[ ! -d $checkout/.git ]]; then
    printf '%s is not a Git checkout.\n' "$checkout" >&2
    exit 1
  fi

  origin=$(git -C "$checkout" config --local --get remote.origin.url || true)
  case "$origin" in
  https://github.com/anshulnoori/nixconf | https://github.com/anshulnoori/nixconf.git | ssh://git@github.com/anshulnoori/nixconf | ssh://git@github.com/anshulnoori/nixconf.git | git@github.com:anshulnoori/nixconf | git@github.com:anshulnoori/nixconf.git)
    ;;
  *)
    printf 'Refusing to update unexpected origin: %s\n' "${origin:-unset}" >&2
    exit 1
    ;;
  esac

  branch=$(git -C "$checkout" branch --show-current)
  if [[ $branch != "$default_branch" ]]; then
    printf 'Refusing to update %s while branch %s is checked out.\n' \
      "$checkout" "${branch:-detached HEAD}" >&2
    exit 1
  fi
  if [[ -n $(git -C "$checkout" status --porcelain=v1) ]]; then
    printf 'Refusing to update a dirty %s checkout.\n' "$checkout" >&2
    exit 1
  fi

  remote_line=$(
    git -C "$checkout" ls-remote --exit-code origin \
      "refs/heads/$default_branch" || true
  )
  remote_revision=${remote_line%%[[:space:]]*}
  if [[ $remote_revision != "$expected_revision" ]]; then
    printf 'origin/%s changed since the last check; inspect updates again.\n' \
      "$default_branch" >&2
    exit 1
  fi

  git -C "$checkout" fetch --no-tags origin "$default_branch"
  fetched_revision=$(git -C "$checkout" rev-parse FETCH_HEAD)
  if [[ $fetched_revision != "$expected_revision" ]]; then
    printf 'Fetched revision does not match the reviewed revision.\n' >&2
    exit 1
  fi

  git -C "$checkout" merge --ff-only FETCH_HEAD
  nh os switch "$checkout"
  check_updates
}

case "${1:-check}" in
check)
  check_updates
  ;;
waybar)
  waybar_status
  ;;
open)
  exec present-terminal "Nixconf Updates" "$0" details
  ;;
details)
  show_details
  ;;
apply)
  apply_update "${2:-}"
  ;;
*)
  printf 'Usage: nixconf-update [check|waybar|open|details|apply REVISION]\n' >&2
  exit 2
  ;;
esac
