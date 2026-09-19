#!/usr/bin/env bash
set -euo pipefail

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
export HOME="$scratch/home" XDG_CONFIG_HOME="$scratch/config" GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME" "$XDG_CONFIG_HOME"
unset GIT_CONFIG_COUNT GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE || true
# shellcheck source=scripts/nixconf-update.sh
source "$(dirname "${BASH_SOURCE[0]}")/nixconf-update.sh"
ssh-keygen -q -t ed25519 -N '' -f "$scratch/test-key"
printf 'anshulnoori@gmail.com %s\n' "$(cat "$scratch/test-key.pub")" >"$scratch/allowed"
real_git=$(command -v git)

git() {
  if [[ " $* " == *' fetch '* ]]; then
    [[ " $* " == *' fetch --no-tags upstream-read '* ]] || die 'Fetch did not use the read remote'
  fi
  if [[ " $* " == *' push '* ]]; then
    [[ " $* " == *' push origin '* ]] || die 'Push did not use origin'
    printf 'push\n' >>"$events"
    [[ $failure != push ]] || return 1
  fi
  "$real_git" "$@"
}
running_revision() { cat "$installed"; }
signal_waybar() { :; }
notify-send() { printf '%s\n' "$@" >"$scratch/notification"; }
sudo() { die 'Build-only updates must not request sudo'; }
nix() {
  case "$*" in
  'flake update')
    if [[ $failure != unchanged ]]; then printf 'new lock\n' >flake.lock; fi
    ;;
  'run .#nvfetcher')
    printf 'generate\n' >>"$events"
    [[ $failure != generation ]] || return 1
    ;;
  'run .#refresh-local-sources')
    [[ $failure != local-sources ]] || return 1
    if [[ $failure != unchanged ]]; then
      printf '{"version":"new"}\n' >packages/sf-pro-source.json
      printf 'new action pins\n' >.github/workflows/cache.yml
    fi
    ;;
  *)
    printf 'validate\n' >>"$events"
    [[ $failure != validation ]] || return 1
    ;;
  esac
}
nh() {
  [[ $1 == os && $2 == build && $3 == "$worktree" ]]
  [[ " $* " != *' --update '* ]]
  [[ " $* " == *' -- --no-update-lock-file '* ]]
  [[ -z $(git -C "$worktree" status --porcelain) ]]
  git -C "$worktree" verify-commit HEAD
  printf 'build\n' >>"$events"
  [[ $failure != build ]] || return 1
  if [[ $failure == remote-race ]]; then
    # Another writer advances the remote while the local candidate builds.
    git -C "$checkout" -c commit.gpgSign=false commit --allow-empty -m 'test: concurrent writer'
    "$real_git" -C "$checkout" push origin HEAD:master
  fi
}

fixture() {
  local name=$1
  checkout="$scratch/$name/repo"
  state_dir="$scratch/$name/state"
  status_file="$state_dir/update-status.json"
  worktree="$state_dir/update-worktree"
  lock_file="$scratch/$name/update.lock"
  installed="$scratch/$name/installed"
  events="$scratch/$name/events"
  failure=none
  phase=starting
  mkdir -p "$checkout" "$state_dir"
  : >"$events"
  "$real_git" init -q --bare "$scratch/$name/remote"
  git -C "$checkout" init -q -b master
  git -C "$checkout" config user.name 'Anshul Noori'
  git -C "$checkout" config user.email anshulnoori@gmail.com
  git -C "$checkout" config gpg.format ssh
  git -C "$checkout" config gpg.ssh.program ssh-keygen
  git -C "$checkout" config gpg.ssh.allowedSignersFile "$scratch/allowed"
  git -C "$checkout" config user.signingKey "$scratch/test-key"
  git -C "$checkout" config commit.gpgSign true
  git -C "$checkout" remote add origin "$scratch/$name/remote"
  git -C "$checkout" remote add upstream-read "$scratch/$name/remote"
  mkdir -p "$checkout/_sources" "$checkout/packages" "$checkout/.github/workflows"
  printf '{}\n' >"$checkout/packages/sf-pro-source.json"
  printf 'old action pins\n' >"$checkout/.github/workflows/cache.yml"
  printf 'old lock\n' >"$checkout/flake.lock"
  printf '{}\n' >"$checkout/_sources/generated.json"
  printf '{}\n' >"$checkout/_sources/generated.nix"
  printf 'original\n' >"$checkout/user-work"
  printf '.pre-commit-config.yaml\n' >"$checkout/.gitignore"
  git -C "$checkout" add .
  git -C "$checkout" commit -q -m 'test: initial state'
  "$real_git" -C "$checkout" push -q origin HEAD:master
  git -C "$checkout" rev-parse HEAD >"$installed"
  printf 'generated hook config\n' >"$checkout/.pre-commit-config.yaml"
  printf '#!%s\ntest -r .pre-commit-config.yaml\n' "$(command -v bash)" >"$checkout/.git/hooks/pre-commit"
  cp "$checkout/.git/hooks/pre-commit" "$checkout/.git/hooks/pre-push"
  chmod +x "$checkout/.git/hooks/pre-commit" "$checkout/.git/hooks/pre-push"
}

run_case() {
  local expected=$1 action=${2:-update} result
  # Do not use an if-condition: it disables Bash errexit inside the function.
  set +e
  (
    set -e
    run_update "$action"
  ) >"$state_dir/test.log" 2>&1
  result=$?
  set -e
  if [[ $expected == success && $result != 0 ]] || [[ $expected == failure && $result == 0 ]]; then
    cat "$state_dir/test.log" >&2
    die "Expected $expected, got exit $result"
  fi
}

fixture origin-guard
if (validate_origin) 2>/dev/null; then die 'Accepted unexpected push destination'; fi
# All transport below is real Git against a disposable bare repository only.
validate_origin() { [[ $("$real_git" -C "$checkout" remote get-url origin) == "$scratch/"* ]]; }

fixture success
printf 'staged work\n' >"$checkout/user-work"
git -C "$checkout" add user-work
printf 'dirty work\n' >"$checkout/user-work"
printf 'untracked work\n' >"$checkout/untracked"
before=$(git -C "$checkout" status --porcelain)
original=$(cat "$installed")
run_case success
[[ $(cat "$installed") == "$original" ]]
[[ $(git --git-dir="$scratch/success/remote" rev-parse master) != "$original" ]]
[[ $(git -C "$checkout" rev-parse HEAD) == "$original" ]]
jq -e '.state == "available"' "$status_file" >/dev/null
grep -Fx -- '--expire-time=10000' "$scratch/notification"
grep -Fx 'Update Available' "$scratch/notification"
grep -E '^Committed [0-9a-f]{12}: chore\(nix\): update flake.lock\. Built and pushed\. Reconcile or pull /etc/nixos before switching\.$' "$scratch/notification"
[[ $(git -C "$checkout" status --porcelain) == "$before" ]]
[[ $(git -C "$checkout" show :user-work) == 'staged work' ]]
[[ $(cat "$checkout/user-work") == 'dirty work' && $(cat "$checkout/untracked") == 'untracked work' ]]
[[ $(tail -2 "$events") == $'build\npush' ]]
[[ ! -e $worktree ]]
jq -e '.message | contains("Reconcile or pull")' "$status_file" >/dev/null
echo 'PASS: signed candidate builds before push without activation; dirty checkout survives'

fixture clean-checkout
original=$(cat "$installed")
run_case success
[[ $(git -C "$checkout" rev-parse HEAD) == $(git --git-dir="$scratch/clean-checkout/remote" rev-parse master) ]]
[[ $(git -C "$checkout" log -1 --format=%s) == 'chore(nix): update flake.lock' ]]
[[ $(cat "$installed") == "$original" ]]
git -C "$checkout" verify-commit HEAD
grep -E '^Committed [0-9a-f]{12}: chore\(nix\): update flake.lock\. Built and pushed\. Click to review and switch\.$' "$scratch/notification"
git -C "$checkout" rev-parse HEAD >"$installed"
waybar_status | jq -e '.class == "ready" and .text == ""' >/dev/null
echo 'PASS: clean master fast-forwards to the built signed commit without switching'

for failure_case in signing validation build attribution remote-race local-sources; do
  fixture "$failure_case"
  failure=$failure_case
  if [[ $failure == signing ]]; then git -C "$checkout" config user.signingKey "$scratch/missing-key"; fi
  if [[ $failure == attribution ]]; then
    # shellcheck disable=SC2016 # The hook expands its own argument.
    printf '#!%s\nprintf "\\nCo-authored-by: unwanted\\n" >> "$1"\n' "$(command -v bash)" >"$checkout/.git/hooks/commit-msg"
    chmod +x "$checkout/.git/hooks/commit-msg"
  fi
  run_case failure
  [[ -e $worktree/.git ]]
  if grep -qx push "$events"; then die "Pushed after $failure"; fi
  jq -e '.state == "failed"' "$status_file" >/dev/null
  if [[ $failure == signing || $failure == validation || $failure == attribution || $failure == build ]]; then
    if grep -qx switch "$events"; then die "Switched after $failure"; fi
  fi
  echo "PASS: $failure blocks publication and preserves candidate"
done

fixture push-retry
failure=push
run_case failure
candidate=$(git -C "$worktree" rev-parse HEAD)
failure=none
run_case success
[[ $(git --git-dir="$scratch/push-retry/remote" rev-parse master) == "$candidate" ]]
echo 'PASS: failed push retries the same built signed revision'

fixture unchanged
failure=unchanged
run_case success
[[ $(cat "$events") == generate && ! -e $worktree ]]
echo 'PASS: unchanged installed pins do not switch or push'

fixture generation-retry
failure=generation
run_case failure
failure=none
run_case success resume
[[ $(grep -c '^generate$' "$events") == 2 ]]
[[ $(tail -2 "$events") == $'build\npush' ]]
echo 'PASS: incomplete source generation resumes before signing or switching'

fixture ancestry
base=$(cat "$installed")
git -C "$checkout" commit -q --allow-empty -m 'test: newer local commit'
newer=$(git -C "$checkout" rev-parse HEAD)
[[ $(revision_relation "$checkout" "$base" "$newer") == ahead ]]
[[ $(revision_relation "$checkout" "$newer" "$base") == behind ]]
[[ $(revision_relation "$checkout" "$base-dirty" "$newer") == ahead ]]
[[ $(revision_relation "$checkout" "$base-dirty" "$base") == identical ]]
[[ $(revision_relation "$checkout" "$newer-dirty" "$base") == behind ]]
[[ $(revision_relation "$checkout" "$base-dirty-dirty" "$newer") == unknown ]]
[[ $(revision_relation "$checkout" aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa-dirty "$newer") == unknown ]]
git -C "$checkout" switch -q -c sibling "$base"
git -C "$checkout" commit -q --allow-empty -m 'test: sibling commit'
sibling=$(git -C "$checkout" rev-parse HEAD)
[[ $(revision_relation "$checkout" "$newer" "$sibling") == diverged ]]
[[ $(revision_relation "$checkout" "$newer-dirty" "$sibling") == diverged ]]
[[ $(revision_relation "$checkout" aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa "$newer") == unknown ]]
printf '%s\n' "$sibling" >"$installed"
run_case failure
[[ ! -e $worktree ]]
printf '%s\n' aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa >"$installed"
run_case failure
[[ ! -e $worktree ]]
echo 'PASS: local ancestry handles ahead, behind, diverged, and absent installed commits without substituting HEAD'

fixture dirty-installed
printf '%s-dirty\n' "$(cat "$installed")" >"$installed"
printf 'user lock changes\n' >"$checkout/flake.lock"
run_case success
[[ $(cat "$checkout/flake.lock") == 'user lock changes' ]]
[[ $(cat "$installed") == *-dirty ]]
echo 'PASS: dirty installed base permits build-only updates and preserves user lock changes'

fixture downgrade
base=$(cat "$installed")
git -C "$checkout" commit -q --allow-empty -m 'test: installed unpublished revision'
git -C "$checkout" rev-parse HEAD >"$installed"
git -C "$checkout" update-ref refs/heads/master "$base"
run_case failure
[[ ! -e $worktree && ! -s $events ]]
echo 'PASS: a newer installed revision is never automatically downgraded'

fixture unexpected-staged
failure=signing
git -C "$checkout" config user.signingKey "$scratch/missing-key"
run_case failure
git -C "$checkout" config user.signingKey "$scratch/test-key"
printf 'unexpected edit\n' >"$worktree/user-work"
git -C "$worktree" add user-work
failure=none
run_case failure resume
if grep -qx switch "$events"; then die 'Switched with unexpected staged files'; fi
echo 'PASS: resume does not automatically commit unrelated staged edits'

fixture indicator-ancestry
base=$(cat "$installed")
git -C "$checkout" commit -q --allow-empty -m 'test: available candidate'
candidate=$(git -C "$checkout" rev-parse HEAD)
write_status available 'Ready to activate' "$candidate"
waybar_status | jq -e '.class == "updates"' >/dev/null
printf '%s-dirty\n' "$candidate" >"$installed"
waybar_status | jq -e '.class == "ready" and .text == ""' >/dev/null
git -C "$checkout" commit -q --allow-empty -m 'test: later installed revision'
git -C "$checkout" rev-parse HEAD >"$installed"
waybar_status | jq -e '.class == "ready" and .text == ""' >/dev/null
git -C "$checkout" switch -q -c unrelated "$base"
git -C "$checkout" commit -q --allow-empty -m 'test: unrelated installed revision'
git -C "$checkout" rev-parse HEAD >"$installed"
waybar_status | jq -e '.class == "updates"' >/dev/null
write_status available 'Old status without candidate'
waybar_status | jq -e '.class == "updates"' >/dev/null
echo 'PASS: indicator clears for installed candidate or descendant, not unrelated or missing metadata'

write_status failed 'Approval needed'
waybar_status | jq -e '.class == "failed" and .text != "" and .tooltip == "Approval needed"' >/dev/null
for stage in generating:0 signing:20 validating:40 building:60 publishing:80; do
  phase=${stage%:*}
  write_status running 'Preparing update'
  waybar_status | jq -e --arg progress "progress-${stage#*:}" \
    '.class == ["updates", "running", $progress] and .text == "󰏗"' >/dev/null
done
write_status success 'Published'
waybar_status | jq -e '.class == "ready" and .text == ""' >/dev/null
write_status available 'Built; switch when ready'
waybar_status | jq -e '.class == "updates" and .text != "" and .tooltip == "Built; switch when ready"' >/dev/null
printf '{"main":{"relation":"identical"},"count":0}\n' >"$status_file"
waybar_status | jq -e '.class == "unavailable"' >/dev/null
echo 'PASS: Waybar JSON exposes local failures, progress, and success'
echo 'PASS: local updater tests'
