#!/usr/bin/env bash
set -euo pipefail

capture=$(realpath "${1:?Pass the built capture-screenrecord executable}")
scratch=$(mktemp -d)
export HOME="$scratch/home" XDG_RUNTIME_DIR="$scratch/runtime"
export recorder_test_bin="$scratch/bin"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR" "$recorder_test_bin"
cleanup() {
  if [[ -r $XDG_RUNTIME_DIR/nixconf-screenrecord.pid ]]; then
    pkill -TERM -F "$XDG_RUNTIME_DIR/nixconf-screenrecord.pid" 2>/dev/null || true
  fi
  rm -rf "$scratch"
}
trap cleanup EXIT

# Use a real executable with the expected /proc/PID/exe basename. No screen,
# microphone, notification daemon, or running Waybar is needed by this test.
cp "$(command -v sleep)" "$recorder_test_bin/gpu-screen-recorder"
capture-region-pick() { printf 'monitor:test\n'; }
setsid() { exec env --default-signal=INT --argv0=sleep "$recorder_test_bin/$1" 30; }
notify-send() {
  if [[ " $* " == *' Screen recording saved '* ]]; then
    touch "$XDG_RUNTIME_DIR/saved-notification"
    sleep 3
  fi
}
pkill() {
  if [[ ${1:-} == -RTMIN+8 ]]; then return; fi
  command pkill "$@"
}
export -f capture-region-pick setsid notify-send pkill

if ! bash "$capture" no-audio; then
  cat "$XDG_RUNTIME_DIR/nixconf-screenrecord.log" >&2
  exit 1
fi
if ! timeout 3 bash "$capture" active; then
  printf 'FAIL: running recorder is hidden by the active-state query\n' >&2
  exit 1
fi
flock -n "$XDG_RUNTIME_DIR/nixconf-screenrecord.lock" true
printf 'PASS: active recorder does not retain the control lock\n'

timeout 5 bash "$capture" stop
for _ in {1..30}; do
  [[ ! -e $XDG_RUNTIME_DIR/saved-notification ]] || break
  sleep 0.1
done
test -e "$XDG_RUNTIME_DIR/saved-notification"
flock -n "$XDG_RUNTIME_DIR/nixconf-screenrecord.lock" true
timeout 3 bash "$capture" inactive
test ! -e "$XDG_RUNTIME_DIR/nixconf-screenrecord.pid"
printf 'PASS: stop completes and saved notification does not retain the control lock\n'
# Let the disposable notification finish before removing its runtime directory.
sleep 3
