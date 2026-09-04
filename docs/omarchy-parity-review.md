# Omarchy Classic Feel Review

Reviewed: 2026-09-02

## Scope

The comparison baseline is Omarchy commit
[`7a988d8`](https://github.com/omacom/omarchy/commit/7a988d89090cca80e47fc9bddcf38e7b2df17e36).
It is the last relevant classic desktop baseline: Walker, Elephant, Waybar, Mako,
SwayOSD, Hyprlock, and Hypridle. Quickshell features are excluded unless a later
fix contains a portable lesson for the classic stack.

The review also covers applicable fixes through Omarchy commit
[`f99d33a`](https://github.com/omacom/omarchy/commit/f99d33a8ddee7b36509a71a6d20d5d23355ce8b1).

This is a feel and interaction review. Package catalogs and development-stack
installers are out of scope.

## Already-decided design

- Keep Walker and Elephant. Do not move to Quickshell.
- `Super+Space` opens applications.
- `Super+Alt+Space` opens the control menu.
- The root control menu searches all descendants and runs matching leaves.
- Persistent settings open their Nix declarations instead of mutating generated
  configuration.
- Keep one Packages submenu with Install and Remove.
- Keep System Monitor as a centered `btop` window and About as centered
  `fastfetch`.
- Keep the TTE screensaver, with no logo or branding.
- Keep explicit Suspend and Hibernate actions. Do not enable
  suspend-then-hibernate by default.
- Keep GPU Screen Recorder for scripted capture. OBS Studio and its loopback
  camera remain available for interactive production workflows.

## Current repair batch

These are direct corrections, not open product decisions:

- The control menu uses Omarchy's 295-pixel Walker proportions, a `Go…` prompt,
  and icon-led rows while retaining global descendant search.
- The bar uses a Nix glyph instead of the previous menu glyph.
- The clock is centered and uses 12-hour time.
- A red recording indicator remains visible while capture is active; clicking it
  stops recording.
- Screenshot notifications include a large preview and open Satty when clicked.
- Recording completion notifications include a preview and open the video when
  clicked.
- Capture notifications remain visible in Do Not Disturb mode.
- Screenshots are copied with the explicit `image/png` MIME type.
- `btop` now receives the generated Stylix/Gruvbox theme.
- About waits for a real keypress through `/dev/tty` instead of closing after
  `fastfetch` exits.
- The screensaver waits for its fullscreen terminal to map before checking
  focus, uses 12-hour time, and excludes the plain `print` effect.
- Bare Super uses keyd's tap-vs-hold mapping to emit F13 only for a completed
  tap. A native Hyprland modifier-release bind was rejected because it would
  also fire after ordinary Super shortcuts on the pinned Hyprland release.
- The pointer uses Adwaita at 24 pixels across Hyprland, GTK, and XCursor,
  matching classic Omarchy instead of imposing a separate Hyprcursor theme.
- Plymouth uses the same declarative wallpaper and Gruvbox palette as Hyprlock,
  with a pre-blurred background, matching centered field, font, dots, and HiDPI
  assets. Plymouth cannot follow a runtime wallpaper change until the next NixOS
  rebuild because it runs before the encrypted root is unlocked.

## Feature-by-feature comparison

### 1. Launcher and control menu

Classic Omarchy uses a 644×300 Walker application launcher. Its control menu is
different: a narrow 295-pixel Walker dmenu with icon-prefixed noun labels,
layer-specific prompts, and recursive parent navigation.

The current configuration now matches those proportions and visual cues. It
intentionally improves the original menu by exposing descendant leaves when a
root query is present. Searching `caffeine` from the root therefore runs the
Caffeine action directly.

Classic Omarchy's searchable keybinding browser opens with `Super+K`; it does
not implement bare-Super which-key. Bare-Super `wlr-which-key` is a deliberate
addition in this configuration.

### 2. Waybar

Classic Omarchy's bar provides:

- left: logo/menu and workspaces;
- center: clock plus conditional weather, update, dictation, recording, idle,
  and Do Not Disturb indicators;
- right: expandable tray, Bluetooth, network, audio, CPU, and optional battery;
- click, right-click, and scroll actions on most status modules.

Current parity after the repair batch:

- menu button and workspaces on the left;
- truly centered 12-hour clock;
- recording indicator and stop action;
- revision-aware update indicator with persistent Mako notifications, full
  diffs, and an explicitly confirmed fast-forward-and-switch action;
- Omarchy's 600 ms hover-revealed tray, including the later empty scroll
  handlers that prevent Waybar crashes, plus Bluetooth, network, audio, and CPU
  controls;
- CPU opens Gruvbox-themed `btop`.

Still undecided:

- active-only Caffeine, Do Not Disturb, and idle-lock indicators;
- weather;
- battery and power-profile controls if this profile is later used on a laptop;
- Waybar edge movement and position controls.

### 3. Notifications and OSD

Classic Omarchy uses Mako for notifications and SwayOSD for volume, microphone,
brightness, and media feedback. It also provides shortcuts to dismiss one,
dismiss all, invoke an action, restore the last notification, and toggle Do Not
Disturb.

The current configuration has themed Mako and SwayOSD, actionable capture
notifications, and a menu DND toggle. The full Mako keyboard-control set is not
yet bound.

### 4. Screenshots

Classic Omarchy's default Print action is a smart capture:

- the screen freezes while selection is active;
- dragging selects an arbitrary region;
- clicking snaps to the containing window or monitor;
- transformed and negatively positioned monitors work;
- the PNG is saved and copied;
- a preview notification opens Satty when clicked.

Current behavior includes the shared smart selector, region/window/output and
fullscreen modes, freeze-through-capture, transform handling, collision-safe
filenames, explicit PNG clipboard data, and the actionable Satty notification.
The complete set of direct capture-mode keybindings remains optional.

### 5. Screen recording

Classic Omarchy provides region/monitor recording with no audio, desktop audio,
desktop plus microphone, and webcam variants. It shows a red clickable Waybar
indicator, stops gracefully, post-processes startup/audio artifacts, then shows
an actionable thumbnail notification.

Current behavior includes all four menu variants, transform-aware region and
monitor selection, the NixOS capability wrapper required for direct KMS
capture, CPU encoder fallback, serialized start/stop state, startup cleanup, a
click-to-stop bar indicator, and an actionable completion thumbnail. Remaining
possible parity work is portal capture for HDR or secondary-GPU displays,
webcam placement relative to a selected region, and explicit webcam selection.

### 6. Screensaver, lock, and sleep

Classic Omarchy uses a fullscreen terminal with random TTE effects, exits on
input or focus loss, launches before lock, locks before sleep, and powers down
displays later. Its lock screen uses a blurred wallpaper and centered password
field.

The current profile has the logo-free TTE screensaver, Hyprlock, a 5/10/20-minute
screensaver/lock/DPMS sequence, a 32 GiB disk swapfile for 32 GiB RAM, and a
Hyprlock-matched Plymouth LUKS prompt.

Remaining reliability work from later Omarchy fixes:

- synchronize one screensaver window per monitor before moving focus;
- kill effects before their terminal containers during teardown;
- lazily unmount FUSE mounts before suspend/hibernate;
- hold a logind delay inhibitor until Hyprlock is confirmed secure;
- avoid unconditional DPMS re-enable during clamshell recovery.

### 7. Wallpaper, theme, font, and cursor

Classic Omarchy supports runtime theme, font, corner, bar-position, and wallpaper
switching. This configuration deliberately keeps theme and font declarative,
but allows runtime wallpaper selection. Persistent settings open their Nix
sources.

The cursor uses Omarchy's Adwaita theme at 24 pixels. `XCURSOR_THEME` comes from
Home Manager and no `HYPRCURSOR_THEME` override is set, allowing Hyprland to use
the same pointer rather than the previous native-theme mismatch.

### 8. Clipboard, sharing, capture utilities, and reminders

Classic Omarchy includes universal copy/paste/cut mappings, Walker clipboard
history, LocalSend sharing, OCR, color picking, and systemd-timer reminders.

The current menus expose LocalSend, clipboard/file/folder/receive sharing, QR
creation, OCR, QR decoding, color picking, and Todoist-oriented reminders.
Hyprland mirrors Omarchy's universal `Super+C`, `Super+V`, and `Super+X`
translation, including explicit synthetic key release and Kitty's terminal-safe
Insert bindings. The remaining direct shortcuts stay intentionally selected
rather than copied wholesale.

### 9. Window-management feel

Both configurations share square corners, small gaps, two-pixel borders,
shadows, blur, opacity, fast pop/fade animations, mouse move/resize, workspace
navigation, and disabled workspace animations.

Classic Omarchy additionally has extensive resize increments, scratchpads,
groups, pseudo-tiling, floating/fullscreen variants, workspace history, window
pinning, and per-app rules. The current profile keeps only the smaller core set.
This is the largest remaining feature-choice area, not a bug.

### 10. Presentation terminals and system controls

Classic Omarchy uses centered 875×600 presentation terminals for operations that
need visible progress and a completion pause. The current configuration uses the
same geometry. Its completion pause now includes Omarchy's later `/dev/tty` fix.

The selected Nix-oriented Setup, Packages, About, and System menu structure is a
deliberate replacement for Omarchy's Arch package/install/update structure.

## Applicable later fixes

### Already represented

- actionable screenshot notification and Satty flow:
  [`bbb57e9`](https://github.com/omacom/omarchy/commit/bbb57e98c143057dba276f52061dada8d3b2e3e1)
- transformed screenshot geometry:
  [`95f1f31`](https://github.com/omacom/omarchy/commit/95f1f312b409902fd2a556cc42d390f4deff3696)
- keep freeze helper alive through capture:
  [`2b4d89a`](https://github.com/omacom/omarchy/commit/2b4d89a9eaf88cd0f6aa5a8d61b56ac3bd574e42)
- explicit PNG clipboard MIME:
  [`ab78fd0`](https://github.com/omacom/omarchy/commit/ab78fd07eff2eacace4ca803165f2a8317f2436d)
- recording indicator and click-to-stop:
  [`a57060e`](https://github.com/omacom/omarchy/commit/a57060ee31e4b2e48ad47fa26454ff478b122fd6)
- recording CPU fallback and safer process handling:
  [`128a612`](https://github.com/omacom/omarchy/commit/128a6125a92d7de6b117b6fd7234b804a5ff1a41)
- transformed recording geometry:
  [`54539b4`](https://github.com/omacom/omarchy/commit/54539b4a8374ed70ae61f38c91b780a57c6650d4)
- shared smart region/window/output selector with signed coordinates:
  [`362d97c`](https://github.com/omacom/omarchy/commit/362d97c151a3a0be03be69f8f53fdeb061767902)
- tray-expander scroll crash protection:
  [`f578880`](https://github.com/omacom/omarchy/commit/f578880bc83ce5b055d008493ff0e8fd4f1c25e8)
- close Walker before screensaver launch:
  [`46c85e4`](https://github.com/omacom/omarchy/commit/46c85e49a3a35e3456482fc24625898bcfb4f5d2)
- wait for a completion key through `/dev/tty`:
  [`5d3299f`](https://github.com/omacom/omarchy/commit/5d3299fb9426ae927b9fc7ef16c94bd334a90f01)

### Recommended next

- prevent software cursors from appearing in screenshots:
  [`fa2b997`](https://github.com/omacom/omarchy/commit/fa2b997513d04a1fa20a1f94e23c6ba8a4ab345a)
- multi-monitor screensaver launch synchronization:
  [`6ecb1db`](https://github.com/omacom/omarchy/commit/6ecb1dbb56f94a60eb15dac228f832ef7bd47799)
- screensaver resize and teardown ordering:
  [`354c2f0`](https://github.com/omacom/omarchy/commit/354c2f006075c5c471a5758601a0a87966469923),
  [`9691e63`](https://github.com/omacom/omarchy/commit/9691e638b20a872aa7b6181c74da9930baaf8e06),
  and [`438f7b3`](https://github.com/omacom/omarchy/commit/438f7b3340b3468cb82ff6e5d218b6c7ef50f165)
- focused-monitor and valid fractional scale handling:
  [`7a0bdaa`](https://github.com/omacom/omarchy/commit/7a0bdaafa45001756eb7da5f5404442720752d07),
  [`6ba0e9c`](https://github.com/omacom/omarchy/commit/6ba0e9c234336794c68db38b989d629720daa140),
  and [`0526ebe`](https://github.com/omacom/omarchy/commit/0526ebefccf6e58fb2cc9419070f1b5aff4b2df2)
- pre-sleep FUSE unmount:
  [`f927125`](https://github.com/omacom/omarchy/commit/f92712541d415450d8db972f09e52577dc3edbbb),
  [`a89c4f8`](https://github.com/omacom/omarchy/commit/a89c4f849dff474b9612221df69f00ec76e81775),
  and [`dd86a89`](https://github.com/omacom/omarchy/commit/dd86a893cb513f78eb93f047231c7128b6596339)
- lock-before-sleep delay inhibitor and bounded lock confirmation:
  [`d1b452c`](https://github.com/omacom/omarchy/commit/d1b452cc5f221165bfc76f96f3cb70c8abe7a963)
  and [`9ddcec2`](https://github.com/omacom/omarchy/commit/9ddcec272d638cb9adc59f4ad456ce58a9db0d3c)

### Conditional or deliberately rejected

- Portal recording is useful for HDR and secondary-GPU capture, but should not
  replace direct region/monitor capture unless that hardware requires it.
- Webcam-within-region placement from
  [`ada53b0`](https://github.com/omacom/omarchy/commit/ada53b090ed705a4353c9db19b970bddd0eb6aa3)
  matters only if the webcam overlay workflow is used.
- Waybar restart fixes are already better handled by the current systemd user
  unit; do not copy process-killing shell scripts.
- Do not hard-code `BAT0`; Omarchy reverted that attempted crash workaround.
- Do not enable suspend-then-hibernate globally. Omarchy removed it in
  [`e4b7372`](https://github.com/omacom/omarchy/commit/e4b737266687e8ea4d5e97cb7e22f107335028c1)
  after repeated hardware-specific wake loops.

## Walkthrough queue

Review the remaining choices in this order:

1. Capture polish: smart Print behavior, cursor suppression, and capture-mode
   shortcuts.
2. Bar and notification state: active-only Caffeine/DND/idle indicators and the
   Mako notification-control keybindings.
3. Sleep reliability: FUSE unmount and lock-before-sleep inhibitor.
4. Screensaver multi-monitor behavior and teardown.
5. Window-management depth: choose only the Omarchy bindings that are useful.
6. Optional status widgets: weather, updates, battery, and power profile.
