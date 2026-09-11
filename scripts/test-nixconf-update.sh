#!/usr/bin/env bash
set -euo pipefail

scratch=$(mktemp -d)
export XDG_STATE_HOME="$scratch/state" XDG_RUNTIME_DIR="$scratch"
# shellcheck source=scripts/nixconf-update.sh
source "$(dirname "${BASH_SOURCE[0]}")/nixconf-update.sh"
trap 'cleanup; rm -rf "$scratch"' EXIT

master=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
candidate=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
running=cccccccccccccccccccccccccccccccccccccccc
build_state=success
discovery_state=success
network_failure=false
branch_relation=ahead
timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)

running_revision() { echo "$running"; }
signal_waybar() { :; }
notify_once() { :; }
github_get() {
  if [[ $network_failure == true ]]; then return 22; fi
  case "$1" in
  branches\?*)
    jq -n --arg revision "$candidate" '[{name:"updates/flake-lock",commit:{sha:$revision}}]'
    ;;
  branches/master) jq -n --arg sha "$master" '{commit:{sha:$sha}}' ;;
  compare/*)
    if [[ $1 == "compare/$master...$candidate" ]]; then
      jq -n --arg status "$branch_relation" '{status:$status}'
    else
      echo '{"status":"ahead"}'
    fi
    ;;
  commits/*/statuses*)
    if [[ $build_state == unknown ]]; then
      echo '[]'
      return
    fi
    # GitHub returns newest first. An old success must not override a failed rerun.
    jq -n --arg state "$build_state" --arg timestamp "$timestamp" \
      '[{context:"unrelated",state:"success"},
          {context:"nixconf/build",state:$state,updated_at:$timestamp},
          {context:"nixconf/build",state:"success",updated_at:"2020-01-01T00:00:00Z"}]'
    ;;
  actions/workflows/*)
    jq -n --arg conclusion "$discovery_state" --arg timestamp "$timestamp" \
      '{workflow_runs:[{status:"completed",conclusion:$conclusion,updated_at:$timestamp}]}'
    ;;
  *)
    echo "Unexpected API request: $1" >&2
    return 1
    ;;
  esac
}

expect_class() {
  waybar_status | jq -e --arg expected "$1" '.class == $expected' >/dev/null
  if [[ $1 == unavailable ]]; then
    waybar_status | jq -e '.text == ""' >/dev/null
  else
    waybar_status | jq -e '.text != ""' >/dev/null
  fi
  printf 'PASS: %s\n' "$2"
}

expect_class unavailable 'missing state is not up to date'
(check_updates)
expect_class ready 'validated master is ready to install'
jq -e --arg sha "$candidate" '.renovate[0].revision == $sha and .renovate[0].build.state == "success"' "$status_file" >/dev/null

build_state=failure
(check_updates)
expect_class failed 'latest failed build supersedes older success'
if (apply_update "$master") 2>"$scratch/error"; then
  echo 'FAIL: accepted failed build' >&2
  exit 1
fi
grep -q 'without a successful' "$scratch/error"

build_state=pending
(check_updates)
expect_class updates 'pending build is available but not ready'

build_state=unknown
(check_updates)
expect_class unavailable 'no exact-SHA build result is not ready'

build_state=success
discovery_state=failure
(check_updates)
expect_class unavailable 'failed discovery is not up to date'

discovery_state=success
timestamp=2020-01-01T00:00:00Z
(check_updates)
expect_class unavailable 'stale remote discovery is visible'

timestamp=$(date -u +%Y-%m-%dT%H:%M:%SZ)
(check_updates)
jq '.checkedAtEpoch = 0' "$status_file" >"$scratch/old"
mv "$scratch/old" "$status_file"
expect_class unavailable 'stale local cache is visible'

network_failure=true
# Do not put check_updates in an if condition: Bash would suppress errexit.
set +e
(
  set -e
  check_updates
)
result=$?
set -e
if ((result == 0)); then
  echo 'FAIL: accepted network failure' >&2
  exit 1
fi
expect_class unavailable 'API failure invalidates saved success'

network_failure=false
(check_updates)
expect_class ready 'successful check recovers from failure'

branch_relation=behind
running=$master
(check_updates)
jq -e '.count == 0 and .renovate == []' "$status_file" >/dev/null
waybar_status | jq -e '.text == ""' >/dev/null
echo 'PASS: merged candidates and current validated master produce no update'
build_state=failure
(check_updates)
waybar_status | jq -e '.text == "" and .class == "failed"' >/dev/null
echo 'PASS: failed build without an update stays hidden'
echo 'PASS: updater state and installation guards'
