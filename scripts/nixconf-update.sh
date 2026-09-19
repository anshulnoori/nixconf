#!/usr/bin/env bash
set -euo pipefail

checkout=/etc/nixos
state_dir=${XDG_STATE_HOME:-$HOME/.local/state}/nixconf
status_file="$state_dir/update-status.json"
worktree="$state_dir/update-worktree"
lock_file="${XDG_RUNTIME_DIR:-/tmp}/nixconf-update-$(id -u).lock"
default_branch=master
candidate_branch=build/local-update
phase=starting

running_revision() {
  local revision
  revision=$(/run/current-system/sw/bin/nixos-version --configuration-revision 2>/dev/null || true)
  printf '%s\n' "${revision:-unknown}"
}

signal_waybar() { pkill -RTMIN+10 -x waybar 2>/dev/null || true; }

write_status() {
  local next_status
  mkdir -p "$state_dir"
  next_status=$(mktemp "$state_dir/status.XXXXXX")
  jq -n --arg state "$1" --arg message "$2" --arg phase "$phase" \
    --arg running "$(running_revision)" --argjson time "$(date +%s)" \
    '{state:$state,message:$message,phase:$phase,runningRevision:$running,checkedAtEpoch:$time}' >"$next_status"
  mv "$next_status" "$status_file"
  signal_waybar
}

failed() {
  local code=$?
  trap - ERR
  write_status failed "Update stopped during $phase. Signing or sudo may need approval in a terminal. Inspect journalctl --user -u nixconf-update; run nixconf-update resume if a candidate exists."
  notify-send --app-name=nixconf-update 'Nixconf update stopped' "Phase: $phase. Signing or sudo may need approval. Run nixconf-update resume in a terminal." || true
  exit "$code"
}

die() {
  printf '%s\n' "$*" >&2
  return 1
}

# Compare actual commit objects, including installed commits not yet on GitHub.
# 'ahead' means the target advances the running revision, never the reverse.
revision_relation() {
  local repository=$1 base=$2 target=$3
  if [[ ! $base =~ ^[0-9a-f]{40}$ || ! $target =~ ^[0-9a-f]{40}$ ]] ||
    ! git -C "$repository" cat-file -e "$base^{commit}" 2>/dev/null ||
    ! git -C "$repository" cat-file -e "$target^{commit}" 2>/dev/null; then
    echo unknown
  elif [[ $base == "$target" ]]; then
    echo identical
  elif git -C "$repository" merge-base --is-ancestor "$base" "$target"; then
    echo ahead
  elif git -C "$repository" merge-base --is-ancestor "$target" "$base"; then
    echo behind
  else
    echo diverged
  fi
}

validate_origin() {
  local origin
  origin=$(git -C "$checkout" remote get-url --push --all origin)
  case "$origin" in
  https://github.com/anshulnoori/nixconf | https://github.com/anshulnoori/nixconf.git | ssh://git@github.com/anshulnoori/nixconf | ssh://git@github.com/anshulnoori/nixconf.git | git@github.com:anshulnoori/nixconf | git@github.com:anshulnoori/nixconf.git) ;;
  *) die 'Refusing unexpected push destination; inspect the origin configuration.' ;;
  esac
}

fetch_master() {
  git -C "$checkout" fetch --no-tags origin "refs/heads/$default_branch"
  remote_revision=$(git -C "$checkout" rev-parse FETCH_HEAD)
}

prepare_update() {
  local base relation current
  [[ ! -e $worktree ]] || die "Candidate exists at $worktree. Inspect it and run nixconf-update resume."
  fetch_master
  base=$(git -C "$checkout" rev-parse "refs/heads/$default_branch")
  relation=$(revision_relation "$checkout" "$base" "$remote_revision")
  case "$relation" in
  ahead) base=$remote_revision ;;
  identical | behind) ;;
  *) die 'Local master and origin/master diverged; reconcile them manually.' ;;
  esac
  current=$(running_revision)
  relation=$(revision_relation "$checkout" "$current" "$base")
  case "$relation" in
  identical | ahead) ;;
  *) die "Refusing $relation transition from installed revision $current." ;;
  esac
  git -C "$checkout" worktree add -b "$candidate_branch" "$worktree" "$base"
  # Git hooks are shared by worktrees, but their generated config is ignored.
  if [[ -r $checkout/.pre-commit-config.yaml ]]; then
    cp --dereference "$checkout/.pre-commit-config.yaml" "$worktree/.pre-commit-config.yaml"
  fi
  generate_pins
}

generate_pins() {
  phase=generating
  write_status running 'Updating flake pins and Proton GE sources in the isolated worktree.'
  (
    cd "$worktree"
    nix flake update
    nix run .#nvfetcher
  )
  touch "$(git -C "$worktree" rev-parse --git-path nixconf-generated)"
}

verify_publication() {
  local revision=$1 commit message
  # Inspect final messages, including anything appended by hooks or signing tools.
  while read -r commit; do
    message=$(git -C "$worktree" log -1 --format=%B "$commit")
    if grep -Eiq 'Co-authored-by:|Amp-Thread-ID:|ampcode\.com/threads/|(^|[[:space:]])(generated|authored|written|committed|signed)[[:space:]]+(by|with)[[:space:]]+(AI|Amp|an? agent)' <<<"$message"; then
      die "Prohibited attribution in $commit; correct and re-sign it before retrying."
      return 1
    fi
    git -C "$worktree" verify-commit "$commit" || return
  done < <(git -C "$worktree" rev-list "$remote_revision..$revision")
  git -C "$worktree" verify-commit "$revision"
}

finish_update() {
  local candidate current relation path
  [[ -e $worktree/.git ]] || die 'No retained candidate. Run nixconf-update update.'
  [[ $(git -C "$worktree" symbolic-ref --short HEAD) == "$candidate_branch" ]] || die 'Unexpected candidate branch.'
  if [[ ! -e $(git -C "$worktree" rev-parse --git-path nixconf-generated) ]]; then generate_pins; fi
  phase=signing
  write_status running 'Signing the local update candidate; 1Password approval may be required.'
  # Only generated dependency pins may enter an automatic commit.
  while IFS= read -r -d '' path; do
    case "$path" in
    flake.lock | _sources/generated.nix | _sources/generated.json) ;;
    *)
      die "Unexpected candidate change: $path"
      return 1
      ;;
    esac
  done < <(
    git -C "$worktree" ls-files --modified --others --exclude-standard -z
    git -C "$worktree" diff --cached --name-only -z
  )
  git -C "$worktree" add -- flake.lock _sources/generated.nix _sources/generated.json
  if ! git -C "$worktree" diff --cached --quiet; then
    phase=signing
    git -C "$worktree" -c user.name='Anshul Noori' -c user.email=anshulnoori@gmail.com \
      commit -S -m 'build: update local dependency pins'
  fi
  [[ -z $(git -C "$worktree" status --porcelain) ]] || die 'Candidate is dirty after commit; refusing activation.'
  candidate=$(git -C "$worktree" rev-parse HEAD)
  fetch_master
  relation=$(revision_relation "$worktree" "$remote_revision" "$candidate")
  case "$relation" in
  identical | ahead) ;;
  *) die 'Remote master advanced or diverged; inspect the retained candidate. No force-push is allowed.' ;;
  esac
  current=$(running_revision)
  relation=$(revision_relation "$worktree" "$current" "$candidate")
  case "$relation" in
  identical | ahead) ;;
  *) die "Refusing $relation transition from installed revision $current." ;;
  esac
  if [[ $candidate == "$current" && $candidate == "$remote_revision" ]]; then
    git -C "$checkout" worktree remove "$worktree"
    git -C "$checkout" update-ref -d "refs/heads/$candidate_branch" "$candidate"
    write_status success 'No dependency changes; installed revision is current.'
    return
  fi
  verify_publication "$candidate"
  phase=validating
  write_status running 'Checking the signed local update candidate.'
  (
    cd "$worktree"
    nix flake check --all-systems --no-build --no-update-lock-file -L
    nix build --no-link --no-update-lock-file -L \
      .#checks.x86_64-linux.treefmt .#proton-ge \
      .#checks.x86_64-linux.proton-ge-aarch64 .#checks.x86_64-linux.nixconf-update
  )
  [[ $(git -C "$worktree" rev-parse HEAD) == "$candidate" && -z $(git -C "$worktree" status --porcelain) ]] ||
    die 'Candidate changed during validation; refusing activation.'
  phase=building
  write_status running "Building signed candidate $candidate without activation."
  nh os build "$worktree" --hostname t1 --no-nom --diff never --out-link "$state_dir/result-system" -- --no-update-lock-file
  [[ $(git -C "$worktree" rev-parse HEAD) == "$candidate" && -z $(git -C "$worktree" status --porcelain) ]] ||
    die 'Candidate changed during build; refusing activation.'
  if [[ $1 != switch ]]; then
    write_status available "Built ${candidate:0:12}. Run nixconf-update switch when ready to activate and publish it."
    notify-send --app-name=nixconf-update 'Nixconf update available' "Built ${candidate:0:12}. Run nixconf-update switch when ready." || true
    return
  fi
  phase=switching
  write_status running "Switching to signed candidate $candidate."
  # No --update here: build and activate the clean, already signed revision.
  nh os switch "$worktree" --hostname t1 --no-nom --diff never --out-link "$state_dir/result-system" \
    -- --no-update-lock-file
  [[ $(running_revision) == "$candidate" ]] || die 'Installed revision does not match the signed candidate; refusing publication.'
  [[ $(git -C "$worktree" rev-parse HEAD) == "$candidate" && -z $(git -C "$worktree" status --porcelain) ]] ||
    die 'Candidate changed during activation; refusing publication.'
  phase=publishing
  write_status running "Signed revision $candidate is installed; publishing it."
  validate_origin
  fetch_master
  case "$(revision_relation "$worktree" "$remote_revision" "$candidate")" in
  identical | ahead) ;;
  *) die 'Remote changed during activation. Installed candidate retained; reconcile manually, then resume.' ;;
  esac
  verify_publication "$candidate"
  # Normal fast-forward push only; races fail safely and retain the installed commit.
  git -C "$worktree" push origin "$candidate:refs/heads/$default_branch"
  git -C "$checkout" worktree remove "$worktree"
  git -C "$checkout" update-ref -d "refs/heads/$candidate_branch" "$candidate"
  write_status success "Installed and published signed revision $candidate."
  notify-send --app-name=nixconf-update 'Nixconf updated' "Installed and published ${candidate:0:12}." || true
}

run_update() {
  mkdir -p "$state_dir"
  exec 9>"$lock_file"
  flock -n 9 || die 'Another update is running.'
  set -E
  trap failed ERR
  trap 'die "Update interrupted"' TERM INT
  validate_origin
  if [[ $1 == update && ! -e $worktree ]]; then prepare_update; fi
  finish_update "$1"
  trap - ERR TERM INT
}

waybar_status() {
  if [[ ! -r $status_file ]] || ! jq -e '.state == "running" or .state == "failed" or .state == "success" or .state == "available"' "$status_file" >/dev/null 2>&1; then
    printf '{"text":"","class":"unavailable","tooltip":"No local update run yet. Click to update."}\n'
    return
  fi
  jq -c '
    if .state == "failed" then {text:"󰏗 !",class:"failed",tooltip:.message}
    elif .state == "available" then {text:"󰏗",class:"updates",tooltip:.message}
    elif .state == "running" and now - .checkedAtEpoch > 21600 then {text:"󰏗 ?",class:"unavailable",tooltip:"Local update did not finish. Inspect the journal and retained candidate."}
    elif .state == "running" then {text:"󰏗 …",class:"updates",tooltip:.message}
    elif now - .checkedAtEpoch > 345600 then {text:"󰏗 ?",class:"unavailable",tooltip:"No successful local update in four days. Click to inspect."}
    else {text:"",class:"ready",tooltip:.message} end
  ' "$status_file"
}

show_details() {
  local answer
  if [[ -r $status_file ]]; then jq -r '.message, ("Phase: " + .phase)' "$status_file"; fi
  if [[ -e $worktree/.git ]]; then
    git -C "$worktree" --no-pager log -1 --show-signature
    git -C "$worktree" --no-pager diff HEAD
    printf '\nRetained candidate: %s\n' "$worktree"
    read -r -p 'Validate, switch, and publish this candidate? [y/N] ' answer
    if [[ $answer == [yY] ]]; then run_update switch; fi
  else
    read -r -p 'Generate, sign, and build updates without switching? [y/N] ' answer
    if [[ $answer == [yY] ]]; then run_update update; fi
  fi
}

if [[ ${BASH_SOURCE[0]} == "$0" ]]; then
  case "${1:-update}" in
  update | resume | switch) run_update "${1:-update}" ;;
  scheduled)
    run_update update
    ;;
  check | waybar) waybar_status ;;
  open) exec present-terminal 'Nixconf Updates' "$0" details ;;
  details) show_details ;;
  *)
    printf 'Usage: nixconf-update [update|resume|switch|scheduled|check|waybar|open|details]\n' >&2
    exit 2
    ;;
  esac
fi
