#!/usr/bin/env bash
set -euo pipefail

capture=$(realpath "${1:?Pass the built capture-screenrecord executable}")
scratch=$(mktemp -d)
real_runtime=${XDG_RUNTIME_DIR:-/run/user/$(id -u)}
export DBUS_SESSION_BUS_ADDRESS=${DBUS_SESSION_BUS_ADDRESS:-unix:path=$real_runtime/bus}
export HOME="$scratch/home" XDG_RUNTIME_DIR="$scratch/runtime"
mkdir -p "$HOME" "$XDG_RUNTIME_DIR/systemd" "$scratch/bin"
ln -s "$real_runtime/bus" "$XDG_RUNTIME_DIR/bus"
ln -s "$real_runtime/systemd/private" "$XDG_RUNTIME_DIR/systemd/private"

units=()
unit_files=()
cleanup() {
  local path unit
  for unit in "${units[@]}"; do
    systemctl --user stop "$unit" 2>/dev/null || true
  done
  for path in "${unit_files[@]}"; do
    rm -f "$path"
  done
  systemctl --user daemon-reload 2>/dev/null || true
  rm -rf "$scratch"
}
trap cleanup EXIT

cat >"$scratch/bin/picker" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "${PICKER_RESULT:-monitor:test}"
EOF

cat >"$scratch/bin/notifier" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$HOME/notifications"
if [[ " $* " == *' Screen recording saved '* ]]; then
  touch "$HOME/saved-notification-started"
  sleep 3
  touch "$HOME/saved-notification-finished"
fi
EOF

cat >"$scratch/bin/recorder" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
output= audio=0
printf '%q ' "$@" > "$HOME/${CAPTURE_SCREENRECORD_UNIT%.service}.args"
while (($#)); do
  case $1 in
    -o) output=$2; shift 2 ;;
    -a) audio=1; shift 2 ;;
    *) shift ;;
  esac
done
make_media() {
  local audio_args=()
  touch "$HOME/finalization-started"
  sleep 0.6
  (( audio == 0 )) || audio_args=(-f lavfi -i 'sine=frequency=440:sample_rate=48000' -c:a aac)
  ffmpeg -loglevel error -y -f lavfi -i color=c=black:s=320x240:r=30 \
    "${audio_args[@]}" -t 1 -c:v libx264 -pix_fmt yuv420p "$output"
  touch "$HOME/finalization-finished"
}
case "${CAPTURE_SCREENRECORD_UNIT:-}" in
  *startup-failure*) exit 1 ;;
  *unexpected-exit*) make_media; exit 7 ;;
  *corrupt-output*) touch "$output"; exit 0 ;;
esac
trap 'trap - INT TERM; make_media; exit 0' INT TERM
while :; do sleep 1; done
EOF
chmod +x "$scratch/bin/picker" "$scratch/bin/notifier" "$scratch/bin/recorder"

run_capture() {
  CAPTURE_SCREENRECORD_UNIT="$1" \
    CAPTURE_SCREENRECORD_SESSION_TARGET="$2" \
    CAPTURE_SCREENRECORD_RECORDER="$scratch/bin/recorder" \
    CAPTURE_SCREENRECORD_PICKER="$scratch/bin/picker" \
    CAPTURE_SCREENRECORD_NOTIFIER="$scratch/bin/notifier" \
    "$capture" "${@:3}"
}

wait_for() {
  local path=$1
  for _ in {1..100}; do
    [[ -e $path ]] && return 0
    sleep 0.1
  done
  printf 'FAIL: timed out waiting for %s\n' "$path" >&2
  return 1
}

wait_inactive() {
  local unit=$1
  for _ in {1..100}; do
    systemctl --user --quiet is-active "$unit" || return 0
    sleep 0.1
  done
  printf 'FAIL: %s remained active\n' "$unit" >&2
  return 1
}

make_target() {
  local target=$1 path="$real_runtime/systemd/user/$1"
  mkdir -p "${path%/*}"
  printf '[Unit]\nDescription=Disposable screen recording test session\n' >"$path"
  unit_files+=("$path")
  systemctl --user daemon-reload
  systemctl --user start "$target"
}

target="nixconf-screenrecord-test-session-$$.target"
make_target "$target"
units+=("$target")

unit="nixconf-screenrecord-test-normal-$$.service"
units+=("$unit")
PICKER_RESULT='10,20 640x480' run_capture "$unit" "$target" no-audio
run_capture "$unit" "$target" active
if run_capture "$unit" "$target" no-audio; then
  printf 'FAIL: duplicate start succeeded\n' >&2
  exit 1
fi
systemctl --user show "$unit" -p PartOf -p BindsTo -p After | rg --quiet "$target"
rm -f "$HOME/finalization-started" "$HOME/finalization-finished"
run_capture "$unit" "$target" stop
run_capture "$unit" "$target" inactive
test -e "$HOME/finalization-started"
test -e "$HOME/finalization-finished"
rg --quiet -- '-w region -region 640x480\+10\+20' "$HOME/${unit%.service}.args"
output=$(fd --type f --extension mp4 . "$HOME/Videos" | head -n 1)
ffprobe -v error -select_streams v:0 -show_entries stream=codec_type -of csv=p=0 "$output" | rg --quiet video
wait_for "$HOME/saved-notification-started"
test ! -e "$HOME/saved-notification-finished"
rg --quiet -- '--action=default=Open.*--icon=.*Screen recording saved' "$HOME/notifications"
printf 'PASS: selection, duplicate start, SIGINT finalization, media, dependencies, and detached notification\n'

unit="nixconf-screenrecord-test-audio-$$.service"
units+=("$unit")
run_capture "$unit" "$target" microphone
run_capture "$unit" "$target" stop
rg --quiet -- "-a default_output\\\|default_input -ac aac" "$HOME/${unit%.service}.args"
output=$(fd --type f --extension mp4 . "$HOME/Videos" | sort | tail -n 1)
ffprobe -v error -select_streams a:0 -show_entries stream=codec_type -of csv=p=0 "$output" | rg --quiet audio
printf 'PASS: microphone/system audio arguments and audio postprocessing\n'

unit="nixconf-screenrecord-test-startup-failure-$$.service"
units+=("$unit")
if run_capture "$unit" "$target" no-audio; then
  printf 'FAIL: startup failure was reported as success\n' >&2
  exit 1
fi
run_capture "$unit" "$target" inactive
printf 'PASS: startup failure leaves no active state\n'

unit="nixconf-screenrecord-test-unexpected-exit-$$.service"
units+=("$unit")
: >"$HOME/notifications"
if run_capture "$unit" "$target" desktop-audio; then
  printf 'FAIL: unexpected early exit was reported as a successful start\n' >&2
  exit 1
fi
wait_inactive "$unit"
run_capture "$unit" "$target" inactive
rg --quiet 'Screen recording failed' "$HOME/notifications"
if rg --quiet 'Screen recording saved' "$HOME/notifications"; then
  printf 'FAIL: failed recorder reported success\n' >&2
  exit 1
fi
printf 'PASS: unexpected recorder exit leaves no active state\n'

unit="nixconf-screenrecord-test-corrupt-output-$$.service"
units+=("$unit")
: >"$HOME/notifications"
run_capture "$unit" "$target" no-audio && exit 1
wait_inactive "$unit"
rg --quiet 'Screen recording failed' "$HOME/notifications"
if rg --quiet 'Screen recording saved' "$HOME/notifications"; then
  printf 'FAIL: corrupt recording reported success\n' >&2
  exit 1
fi
printf 'PASS: corrupt output does not produce a saved notification\n'

rm -f "$HOME/finalization-started" "$HOME/finalization-finished"
unit="nixconf-screenrecord-test-session-stop-$$.service"
units+=("$unit")
run_capture "$unit" "$target" desktop-audio
systemctl --user stop "$target"
wait_inactive "$unit"
run_capture "$unit" "$target" inactive
test -e "$HOME/finalization-started"
test -e "$HOME/finalization-finished"
printf 'PASS: stopping the disposable session target gracefully finalizes its recording\n'
