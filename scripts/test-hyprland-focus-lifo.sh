#!/usr/bin/env bash
set -euo pipefail

runtime=${1:?Pass the isolated compositor runtime directory}
instance=${2:?Pass the isolated compositor instance signature}
if [[ $runtime == "/run/user/$(id -u)" ]]; then
  printf 'Refusing to test in the desktop runtime directory.\n' >&2
  exit 2
fi
export XDG_RUNTIME_DIR="$runtime" HYPRLAND_INSTANCE_SIGNATURE="$instance"

expect_focus() {
  local expected=$1 actual
  for _ in {1..30}; do
    actual=$(hyprctl activewindow -j | jq -r '.class // ""')
    if [[ $actual == "$expected" ]]; then
      printf 'PASS focus: %s\n' "$expected"
      return
    fi
    sleep 0.1
  done
  printf 'FAIL expected focus %s, got %s\n' "$expected" "$actual" >&2
  exit 1
}

open_window() {
  local class=$1
  hyprctl dispatch "hl.dsp.exec_cmd(\"kitty --class $class --override remember_window_size=no sleep 600\")" >/dev/null
  for _ in {1..30}; do
    if hyprctl clients -j | jq -e --arg class "$class" 'any(.[]; .class == $class)' >/dev/null; then
      sleep 0.2
      return
    fi
    sleep 0.1
  done
  printf 'FAIL window did not open: %s\n' "$class" >&2
  exit 1
}

close_window() {
  hyprctl dispatch "hl.dsp.window.close({window=\"class:$1\"})" >/dev/null
  sleep 0.3
}

cleanup() {
  for class in lifo-lock-a lifo-lock-b lifo-lock-c lifo-ordinary; do
    close_window "$class" || true
  done
}
trap cleanup EXIT

hyprctl eval 'hl.window_rule({match={class="^lifo-.*$"},float=true,size={300,200}})' >/dev/null
hyprctl eval 'hl.window_rule({match={class="^lifo-lock-.*$"},stay_focused=true})' >/dev/null
open_window lifo-lock-a
expect_focus lifo-lock-a
open_window lifo-lock-b
expect_focus lifo-lock-b
open_window lifo-lock-c
expect_focus lifo-lock-c
hyprctl dispatch 'hl.dsp.window.move({workspace="2",follow=false,window="class:lifo-lock-c"})' >/dev/null
if hyprctl monitors -j | jq -e 'any(.[]; .activeWorkspace.id == 2)' >/dev/null; then
  printf 'FAIL workspace 2 must be invisible for this test\n' >&2
  exit 1
fi
expect_focus lifo-lock-b
open_window lifo-ordinary
expect_focus lifo-lock-b
hyprctl dispatch 'hl.dsp.window.move({workspace="1",follow=false,window="class:lifo-lock-c"})' >/dev/null
expect_focus lifo-lock-c
hyprctl eval 'hl.window_rule({match={class="^lifo-lock-a$"},stay_focused=true})' >/dev/null
expect_focus lifo-lock-c
close_window lifo-lock-c
expect_focus lifo-lock-b
close_window lifo-lock-b
expect_focus lifo-lock-a
close_window lifo-lock-a
expect_focus lifo-ordinary
open_window lifo-lock-b
expect_focus lifo-lock-b
open_window lifo-lock-a
expect_focus lifo-lock-a
close_window lifo-lock-b
expect_focus lifo-lock-a
printf 'PASS nested locks, rule refresh, close fallback, reopen, ordinary windows\n'
