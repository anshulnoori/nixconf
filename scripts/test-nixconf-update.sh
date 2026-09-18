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
  if [[ " $* " == *' push '* ]]; then
    printf 'push\n' >>"$events"
    [[ $failure != push ]] || return 1
  fi
  "$real_git" "$@"
}
running_revision() { cat "$installed"; }
signal_waybar() { :; }
notify-send() { :; }
sudo() { [[ $failure != sudo ]]; }
nix() {
  case "$*" in
  'flake update')
    if [[ $failure != unchanged ]]; then printf 'new lock\n' >flake.lock; fi
    ;;
  'run .#nvfetcher')
    printf 'generate\n' >>"$events"
    [[ $failure != generation ]] || return 1
    ;;
  *)
    printf 'validate\n' >>"$events"
    [[ $failure != validation ]] || return 1
    ;;
  esac
}
nh() {
  [[ $1 == os && $2 == switch && $3 == "$worktree" ]]
  [[ " $* " != *' --update '* ]]
  [[ " $* " == *' -- --no-update-lock-file '* ]]
  [[ -z $(git -C "$worktree" status --porcelain) ]]
  git -C "$worktree" verify-commit HEAD
  printf 'switch\n' >>"$events"
  [[ $failure != switch ]] || return 1
  if [[ $failure != wrong-revision ]]; then
    git -C "$worktree" rev-parse HEAD >"$installed"
  fi
  if [[ $failure == remote-race ]]; then
    # Another writer advances the remote while the local candidate switches.
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
  scheduled=false
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
  mkdir "$checkout/_sources"
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
run_case success
[[ $(git --git-dir="$scratch/success/remote" rev-parse master) == "$(cat "$installed")" ]]
[[ $(git -C "$checkout" status --porcelain) == "$before" ]]
[[ $(git -C "$checkout" show :user-work) == 'staged work' ]]
[[ $(cat "$checkout/user-work") == 'dirty work' && $(cat "$checkout/untracked") == 'untracked work' ]]
[[ $(tail -2 "$events") == $'switch\npush' ]]
[[ ! -e $worktree ]]
jq -e '.state == "success"' "$status_file" >/dev/null
echo 'PASS: signed candidate switches before push; dirty and untracked user work survives'

for failure_case in signing validation switch wrong-revision sudo attribution remote-race; do
  fixture "$failure_case"
  failure=$failure_case
  if [[ $failure == signing ]]; then git -C "$checkout" config user.signingKey "$scratch/missing-key"; fi
  if [[ $failure == sudo ]]; then scheduled=true; fi
  if [[ $failure == attribution ]]; then
    # shellcheck disable=SC2016 # The hook expands its own argument.
    printf '#!%s\nprintf "\\nCo-authored-by: unwanted\\n" >> "$1"\n' "$(command -v bash)" >"$checkout/.git/hooks/commit-msg"
    chmod +x "$checkout/.git/hooks/commit-msg"
  fi
  run_case failure
  [[ -e $worktree/.git ]]
  if grep -qx push "$events"; then die "Pushed after $failure"; fi
  jq -e '.state == "failed"' "$status_file" >/dev/null
  if [[ $failure == signing || $failure == validation || $failure == attribution || $failure == sudo ]]; then
    if grep -qx switch "$events"; then die "Switched after $failure"; fi
  fi
  echo "PASS: $failure blocks publication and preserves candidate"
done

fixture push-retry
failure=push
run_case failure
candidate=$(cat "$installed")
[[ $(git -C "$worktree" rev-parse HEAD) == "$candidate" ]]
failure=none
run_case success resume
[[ $(git --git-dir="$scratch/push-retry/remote" rev-parse master) == "$candidate" ]]
echo 'PASS: installed but unpublished signed revision can resume without GitHub comparison'

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
echo 'PASS: incomplete source generation resumes before signing or switching'

fixture ancestry
base=$(cat "$installed")
git -C "$checkout" commit -q --allow-empty -m 'test: newer local commit'
newer=$(git -C "$checkout" rev-parse HEAD)
[[ $(revision_relation "$checkout" "$base" "$newer") == ahead ]]
[[ $(revision_relation "$checkout" "$newer" "$base") == behind ]]
git -C "$checkout" switch -q -c sibling "$base"
git -C "$checkout" commit -q --allow-empty -m 'test: sibling commit'
sibling=$(git -C "$checkout" rev-parse HEAD)
[[ $(revision_relation "$checkout" "$newer" "$sibling") == diverged ]]
[[ $(revision_relation "$checkout" aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa "$newer") == unknown ]]
printf '%s\n' "$sibling" >"$installed"
run_case failure
[[ ! -e $worktree ]]
printf '%s\n' aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa >"$installed"
run_case failure
[[ ! -e $worktree ]]
echo 'PASS: local ancestry handles ahead, behind, diverged, and absent installed commits without substituting HEAD'

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

write_status failed 'Approval needed'
waybar_status | jq -e '.class == "failed" and .text != "" and .tooltip == "Approval needed"' >/dev/null
write_status running 'Switching signed candidate'
waybar_status | jq -e '.class == "updates" and .text != ""' >/dev/null
write_status success 'Published'
waybar_status | jq -e '.class == "ready" and .text == ""' >/dev/null
printf '{"main":{"relation":"identical"},"count":0}\n' >"$status_file"
waybar_status | jq -e '.class == "unavailable"' >/dev/null
echo 'PASS: Waybar JSON exposes local failures, progress, and success'
echo 'PASS: local updater tests'
