# Application and Desktop Stack

This document is the source of truth for the intended NixOS desktop and
application stack. It records product decisions and integration constraints;
individual Nix modules should implement these choices without duplicating the
policy. It is secondary only to the user's confirmed requirements.
`system-design.md` supplements it with confirmed system policy; any conflict
must return to the user rather than being resolved silently.

## Experience goals

| Area                   | Decision                                                                          |
| ---------------------- | --------------------------------------------------------------------------------- |
| Desktop                | Square, minimal Hyprland environment assembled from focused components            |
| Primary interaction    | Terminal and TUIs wherever they remain practical                                  |
| Graphical applications | Keep applications that benefit from graphics, rich media, or proprietary services |
| Theme                  | Gruvbox from one shared palette                                                   |
| Font                   | JetBrains Mono Nerd Font, with Symbols Nerd Font as icon fallback                 |
| Configuration          | Declarative NixOS and Home Manager modules                                        |
| Development toolchains | Per-project Nix development shells; no global language toolchains                 |
| Package channel        | NixOS unstable, with pinned flake inputs                                          |
| Kernel                 | CachyOS BORE ThinLTO Zen 4 kernel with a standard NixOS recovery kernel           |

## Desktop

| Role                 | Selection                                            | Integration notes                                               |
| -------------------- | ---------------------------------------------------- | --------------------------------------------------------------- |
| Compositor           | Hyprland                                             | Owns windows, workspaces, displays, keybindings, and animations |
| Bar                  | Waybar                                               | Square CSS; launches system TUIs in Kitty                       |
| Command launcher     | Vicinae                                              | Primary launcher and Raycast replacement                        |
| Minimal launcher     | Fuzzel                                               | Fallback and dmenu-style workflows                              |
| Notifications        | Mako                                                 | Minimal notification daemon with Gruvbox styling                |
| Wallpaper            | TTFX in Kitty background panels                      | Live, unbranded random terminal effects per output              |
| Lock screen          | hyprlock                                             | Secure lock boundary                                            |
| Idle management      | hypridle                                             | Screensaver, lock, and display power; no automatic suspend      |
| Authentication agent | hyprpolkitagent                                      | Graphical Polkit prompts                                        |
| Screenshots          | grim + slurp                                         | Capture outputs, windows, and regions                           |
| Screenshot editor    | Satty                                                | Annotation and export                                           |
| OSD                  | SwayOSD                                              | Volume and brightness feedback                                  |
| Clipboard            | wl-clipboard + cliphist                              | Clipboard commands and searchable history                       |
| Media control        | playerctl                                            | Keybindings and Waybar controls                                 |
| Night light          | hyprsunset                                           | Color-temperature control                                       |
| Portals              | xdg-desktop-portal-hyprland + xdg-desktop-portal-gtk | Screen sharing, file dialogs, URI opening, and screenshots      |
| Removable media      | udisks2 + udiskie                                    | Device access and automounting                                  |
| Cooling GUI          | CoolerControl                                        | Manual GUI; daemon starts at boot without GUI or tray autostart |

## Terminal environment

| Role                 | Selection | Integration notes                                            |
| -------------------- | --------- | ------------------------------------------------------------ |
| Terminal             | Kitty     | JetBrains Mono Nerd Font, square decorations, Gruvbox colors |
| Session persistence  | zmx       | Hyprland remains responsible for visible pane tiling         |
| Interactive shell    | Zsh       | Keep Bash and POSIX `sh` for scripts                         |
| Prompt               | Starship  | Shared prompt across local and remote shells                 |
| History              | Atuin     | Searchable shell history                                     |
| Directory navigation | zoxide    | Initialized as the `cd` replacement                          |
| Fuzzy selection      | fzf       | General-purpose terminal selection                           |
| Editor               | Neovim    | Primary editor                                               |
| Coding agent         | Amp       | Primary coding agent                                         |

Zsh is the interactive shell, but portable scripts must use an explicit
`#!/bin/sh` shebang and Bash-specific scripts must use
`#!/usr/bin/env bash`. Interactive-shell selection does not make scripts
portable.

## System TUIs

| Role                  | Selection             | Preferred command                                            |
| --------------------- | --------------------- | ------------------------------------------------------------ |
| Wi-Fi                 | Impala                | `impala`                                                     |
| Bluetooth             | Bluetui               | `bluetui`                                                    |
| Audio mixer           | WireMix               | `wiremix`                                                    |
| File manager          | Yazi                  | `yazi`, wrapped as `y` to change the parent shell directory  |
| System monitor        | btop                  | `btop`                                                       |
| GPU monitor           | nvtop                 | `nvtop`                                                      |
| Journal viewer        | lazyjournal           | `lj`                                                         |
| Git UI                | lazygit               | `lg`                                                         |
| Container UI          | lazydocker            | `lazydocker`                                                 |
| Command documentation | tealdeer              | `tldr`                                                       |
| Terminal browser      | Browsh                | `browsh`                                                     |
| Mail                  | Private custom client | Package separately without publishing private source or data |

Waybar modules should open these applications in a consistently styled,
floating Kitty window. Wi-Fi, Bluetooth, audio, system load, GPU load, and logs
should therefore remain one click or one keybinding away without requiring a
desktop control center.

CoolerControl has no official TUI. NixOS owns its package and service;
CoolerControl's GUI owns mutable calibration and profiles under encrypted root.
Use the `sensors` command from `lm_sensors` for terminal sensor readings.

## CLI toolkit

| Area                   | Tools                |
| ---------------------- | -------------------- |
| Search and discovery   | ripgrep, fd, fzf     |
| File display           | bat, eza             |
| Structured data        | jq, yq, gron, Miller |
| Text and HTML          | sd, htmlq            |
| Command-output parsing | jc                   |
| Git output             | delta                |
| Benchmarking           | hyperfine            |
| GitHub                 | gh                   |
| Environment activation | direnv + nix-direnv  |
| Disk inspection        | dust, duf            |
| Process inspection     | procs                |
| Archives               | ouch                 |
| HTTP                   | xh                   |
| File watching          | watchexec            |
| Remote client          | OpenSSH              |
| Terminal recording     | asciinema            |
| Downloads              | aria2                |
| Network diagnostics    | nmap                 |
| Hardware sensors       | lm_sensors           |

## Nix tooling and structure

| Role                     | Selection                      | Notes                                                                      |
| ------------------------ | ------------------------------ | -------------------------------------------------------------------------- |
| Flake composition        | flake-parts                    | Top-level flake framework                                                  |
| Recursive module imports | import-tree                    | Discover modules without maintaining manual import lists                   |
| User configuration       | Home Manager                   | User services, packages, and dotfiles                                      |
| Neovim configuration     | nvf                            | Home Manager owns one integrated editor configuration                      |
| Selective package wraps  | Lassulus/wrappers              | Add fixed flags or environment only when a package needs them              |
| Project environments     | Per-project `devShells`        | No global Rust, Go, Zig, OCaml, Java, Android, Python, or C/C++ toolchains |
| Automatic activation     | direnv + nix-direnv            | Enter project shells on directory change                                   |
| Rebuild frontend         | nh                             | Wrap rebuild, update, and cleanup workflows                                |
| Build visualization      | nix-output-monitor             | Used directly and through nh                                               |
| Generation comparison    | nvd                            | Summarize package changes between generations                              |
| Closure inspection       | nix-tree                       | Explain store dependencies                                                 |
| Package index            | nix-index                      | Find packages that provide files and commands                              |
| Missing-command lookup   | comma                          | Run commands through nix-index results                                     |
| Documentation search     | Native Nix/NixOS documentation | Do not add manix initially                                                 |

`nh` is not part of `nix gc`; it is a separate frontend around rebuild and
cleanup operations. Native Nix commands remain available underneath it.

## Theme and typography

| Layer               | Decision                                                                             |
| ------------------- | ------------------------------------------------------------------------------------ |
| Palette source      | Stylix with a selected Gruvbox dark scheme                                           |
| Shared colors       | Custom modules consume `config.lib.stylix.colors`                                    |
| GTK and Qt          | Stylix targets                                                                       |
| Terminal            | Stylix Kitty target                                                                  |
| Editor              | Stylix Neovim target or a generated Gruvbox configuration                            |
| Desktop components  | Generate Waybar, Fuzzel, Mako, hyprlock, and Hyprland colors from the shared palette |
| Custom applications | Consume the same generated palette rather than embedding hex values                  |
| Primary font        | JetBrains Mono Nerd Font                                                             |
| Icon fallback       | Symbols Nerd Font                                                                    |
| Shape language      | Zero corner radius and minimal or no shadows where applications allow it             |

Stylix owns palette values. Application-specific adapters may exist, but they
must consume the shared palette rather than define a second theme source.

## Audio

| Layer                    | Selection      | Notes                                   |
| ------------------------ | -------------- | --------------------------------------- |
| Audio server             | PipeWire       | Do not run a separate PulseAudio daemon |
| Session manager          | WirePlumber    | PipeWire policy and routing             |
| PulseAudio compatibility | pipewire-pulse | Required by many desktop applications   |
| ALSA compatibility       | PipeWire ALSA  | Include 32-bit support for Steam        |
| JACK compatibility       | PipeWire JACK  | Low-latency and production applications |
| Realtime scheduling      | rtkit          | Allow realtime audio scheduling         |
| Mixer                    | WireMix        | Primary interactive mixer               |
| Media control            | playerctl      | Media keys and Waybar                   |
| OSD                      | SwayOSD        | Volume and mute feedback                |
| Sample rate              | 48 kHz         | Desktop, games, and video default       |
| Starting quantum         | 128 samples    | Lower to 64 only after underrun testing |

The initial 128-sample quantum is 2.67 ms at 48 kHz. Actual round-trip latency
is higher because hardware and additional buffers contribute. Wired or USB
audio is required when Bluetooth latency is unacceptable.

## Credentials

| Role                | Selection                     | Notes                                             |
| ------------------- | ----------------------------- | ------------------------------------------------- |
| Password manager    | 1Password                     | Human-managed secrets                             |
| CLI                 | `op`                          | Runtime secret access                             |
| SSH agent           | 1Password SSH agent           | Git and outbound SSH authentication               |
| Browser integration | 1Password extension for Brave | Primary web credential flow                       |
| Secret Service      | GNOME Keyring                 | Battle-tested Freedesktop Secret Service provider |

Secrets must not be written into the Nix store. Resolve them at runtime through
1Password, protected files, or an appropriate secrets module.

## Browsers, search, and launcher

| Role                | Selection                   | Notes                                                                                        |
| ------------------- | --------------------------- | -------------------------------------------------------------------------------------------- |
| Primary browser     | Brave, official Linux build | Authenticated browsing, web apps, and Brave Sync                                             |
| Terminal browser    | Browsh                      | Low-bandwidth and remote terminal browsing                                                   |
| Launcher            | Vicinae                     | Applications, files, calculator, conversion, web search, clipboard, snippets, and extensions |
| Launcher fallback   | Fuzzel                      | Minimal application and dmenu launcher                                                       |
| Graphing calculator | Desmos in Brave             | Do not add a terminal substitute                                                             |

Vicinae should send web searches to Brave rather than render its own search UI.
Its browser extension may provide Brave tab switching.

Browsh runs a separate Firefox profile and cannot share Brave Sync, Brave
cookies, history, or authenticated sessions. Treat it as an independent browser.
If shared bookmarks become necessary, add a browser-independent bookmark
service rather than copying browser profile files.

## Communication and productivity

| Role             | Selection                                | Packaging notes                                                   |
| ---------------- | ---------------------------------------- | ----------------------------------------------------------------- |
| Secure messaging | Signal Desktop                           | Native Linux client                                               |
| Community chat   | Discord Canary + Vencord                 | Package declaratively; accept client-mod compatibility risk       |
| WhatsApp         | WhatsApp Web installed as a Brave app    | No unofficial credential-holding wrapper                          |
| iMessage         | BlueBubbles client                       | Connect only to the Mac over Tailscale                            |
| Mail             | Private custom client                    | Existing application                                              |
| Calendar         | Private Notion Calendar Electron package | Personal distribution only; Waybar integration over a Unix socket |
| Tasks            | Todoist                                  | Native client or Brave app selected during packaging              |
| Notes            | Obsidian                                 | Unfree package allowed explicitly                                 |
| Canvas           | tldraw                                   | Offline package or Brave app selected during packaging            |

### iMessage bridge

| Component         | Decision                                                            |
| ----------------- | ------------------------------------------------------------------- |
| Server            | BlueBubbles Server on the existing Mac                              |
| Apple service     | Messages.app remains signed into the Apple ID on the Mac            |
| Network           | Direct tailnet access using the Mac's Tailscale IP or MagicDNS name |
| Public ingress    | None; do not use Funnel or router port forwarding                   |
| Linux client      | BlueBubbles desktop client                                          |
| SMS               | Enable iPhone Text Message Forwarding to the Mac if needed          |
| macOS permissions | Grant Full Disk Access; grant Accessibility only when needed        |
| Private API       | Disabled initially because it requires disabling macOS SIP          |
| Availability      | Mac must remain awake, logged in, and running BlueBubbles           |

Basic messages and media do not require BlueBubbles Private API. Reactions,
typing indicators, read receipts, and some chat-management features may be
limited without it; those limitations are preferable to weakening SIP initially.

## Media and creative applications

| Role                           | Selection               | Notes                                                            |
| ------------------------------ | ----------------------- | ---------------------------------------------------------------- |
| Music                          | Official Spotify client | Keep the graphical client                                        |
| Video, audio, and still images | mpv                     | Default media handler where practical                            |
| Media retrieval                | yt-dlp                  | Integrate with mpv where useful                                  |
| Video editing                  | DaVinci Resolve         | Unfree package; codec limitations may require FFmpeg transcoding |
| Local file transfer            | LocalSend               | Cross-platform local transfer                                    |

## Gaming

| Role                  | Selection      | Notes                                               |
| --------------------- | -------------- | --------------------------------------------------- |
| Platform              | Steam          | Enable 32-bit graphics and audio support            |
| Compatibility runtime | Proton-GE      | Default Steam compatibility runtime                 |
| Minecraft             | Prism Launcher | Per-instance Java and mod management                |
| Performance overlay   | MangoHud       | FPS, frame time, and hardware metrics               |
| Overlay editor        | GOverlay       | Interactive MangoHud configuration                  |
| Performance policy    | GameMode       | Game process and I/O tuning; fixed CPU policy stays |
| Nested compositor     | Gamescope      | Resolution, scaling, and fullscreen control         |
| Prefix management     | Protontricks   | Per-game Wine and Proton changes                    |

GeForce Now, Moonlight, Heroic, Lutris, and UMU are intentionally excluded.

## Networking and remote access

| Role                  | Selection        | Notes                                                                 |
| --------------------- | ---------------- | --------------------------------------------------------------------- |
| Wi-Fi backend         | iwd              | Fallback backend required by Impala                                   |
| Wi-Fi UI              | Impala           | Fallback UI; do not run NetworkManager or wpa_supplicant concurrently |
| Network configuration | systemd-networkd | Ethernet is primary and uses wired DHCP                               |
| DNS                   | systemd-resolved | Recommended resolver                                                  |
| Bluetooth backend     | BlueZ            | Required by Bluetui                                                   |
| Bluetooth UI          | Bluetui          | Primary pairing and device UI                                         |
| Tailnet               | Tailscale        | Only selected VPN                                                     |
| Incoming remote shell | Disabled         | Do not enable OpenSSH or Mosh services                                |
| Outbound SSH          | OpenSSH client   | Git and administration of other systems                               |
| Local transfer        | LocalSend        | GUI transfer between nearby devices                                   |

The Amp runner uses an outbound connection. It does not require an incoming SSH
service. Wi-Fi credentials are entered interactively and stored as mutable state
below LUKS.

## Live wallpaper, idle animation, and locking

The live wallpaper and screensaver reproduce Omarchy's TTFX behavior without
its Quickshell shell, branding, or lock implementation.

| Behavior              | Decision                                                       |
| --------------------- | -------------------------------------------------------------- |
| Wallpaper engine      | TTFX with random effects at 30 FPS                             |
| Wallpaper rendering   | One `kitty +kitten panel --edge=background` surface per output |
| Animation input       | Generated unbranded ASCII/Unicode character pattern            |
| Idle scheduler        | hypridle                                                       |
| Screensaver deadline  | 5 minutes                                                      |
| Lock deadline         | 10 minutes from the beginning of inactivity                    |
| Display-off deadline  | 20 minutes from the beginning of inactivity                    |
| Automatic suspend     | Disabled; suspend is an explicit desktop control action        |
| Screensaver rendering | One fullscreen 60 FPS TTFX Kitty instance per output           |
| Window classes        | Neutral `org.nixconf.ttfx-*` classes                           |
| Styling               | Gruvbox palette, JetBrains Mono Nerd Font, zero padding        |
| Dismissal             | Keyboard/mouse activity or loss of screensaver focus           |
| Lock transition       | Stop foreground TTFX, close its windows, then start hyprlock   |
| Idle inhibitors       | Respect media and application inhibitors                       |

TTFX may require a local package if it is unavailable in the pinned nixpkgs.
The background panels run as a Home Manager user service. hyprpaper does not
run concurrently. The screensaver is decorative; hyprlock remains the security
boundary. Activity before the lock deadline dismisses the screensaver without a
password; activity after hyprlock starts still requires the account password.

## Kernel

| Role                 | Selection                                        | Notes                                            |
| -------------------- | ------------------------------------------------ | ------------------------------------------------ |
| Kernel family        | CachyOS                                          | Desktop responsiveness and scheduler tuning      |
| Normal package       | `linuxPackages-cachyos-bore-lto-zen4`            | Clang ThinLTO, BORE, 1000 Hz, dynamic preemption |
| CPU target           | `zen4`                                           | Fixed target until the input supports Zen 5      |
| Profile optimization | Disabled                                         | No AutoFDO or Propeller profile                  |
| Real-time mode       | Disabled                                         | Normal BORE kernel                               |
| TCP congestion       | BBR3 with FQ                                     | Default TCP policy                               |
| Binder               | Compiled but dormant                             | No BinderFS mount or Android service             |
| v4l2loopback         | Available on demand                              | Do not load the module at boot                   |
| ZFS                  | Excluded                                         | Btrfs is the only root filesystem                |
| Flake source         | `xddxdd/nix-cachyos-kernel`                      | Use its pinned overlay                           |
| Recovery             | Keep a standard NixOS kernel generation bootable | Stable repair path                               |

GPU and other out-of-tree kernel modules must come from the selected kernel
package set. Add proprietary NVIDIA modules only after the GPU is installed.

## Private packages

| Package                    | Constraint                                                                                   |
| -------------------------- | -------------------------------------------------------------------------------------------- |
| Notion Calendar            | Package the tested Electron application privately and do not redistribute copyrighted assets |
| Mail client                | Keep private implementation and credentials out of the public flake                          |
| tldraw offline application | Reuse existing personal packaging or install as a Brave app                                  |
| TTFX                       | Add a local package only if the pinned nixpkgs does not provide it                           |

Private source, credentials, license material, and application data must never
enter the public repository or Nix store unintentionally.

## Explicit exclusions

| Exclusion                              | Reason                                                   |
| -------------------------------------- | -------------------------------------------------------- |
| Noctalia                               | Desktop is assembled from focused components             |
| Fish                                   | Zsh remains the interactive shell                        |
| oo7-server                             | Secret Service must be mature and battle-tested          |
| manix                                  | Native documentation is sufficient initially             |
| Global development language toolchains | Projects own their complete environments                 |
| Zed                                    | Neovim is the selected editor                            |
| GeForce Now                            | Not part of the migrated gaming stack                    |
| Terminal Desmos replacement            | Use Desmos itself in Brave                               |
| NetworkManager for Wi-Fi               | Conflicts with the selected standalone iwd/Impala design |
| BlueBubbles Private API initially      | Requires disabling macOS SIP                             |

## References

| Project                            | Reference                                                                                                  |
| ---------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Omarchy screensaver implementation | [basecamp/omarchy](https://github.com/basecamp/omarchy)                                                    |
| BlueBubbles                        | [Installation](https://bluebubbles.app/install)                                                            |
| BlueBubbles over Tailscale         | [Tailscale guide](https://tailscale.com/blog/bluebubbles-tailscale-imessage-android-pc-no-port-forwarding) |
| Vicinae                            | [Documentation](https://docs.vicinae.com/)                                                                 |
| Browsh profiles                    | [Configuration](https://www.brow.sh/docs/config/)                                                          |
| CachyOS kernel packages            | [xddxdd/nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel)                                  |
| Recursive Nix module imports       | [vic/import-tree](https://github.com/vic/import-tree)                                                      |
| Neovim configuration               | [NotAShelf/nvf](https://github.com/NotAShelf/nvf)                                                          |
| Selective package wrappers         | [Lassulus/wrappers](https://github.com/Lassulus/wrappers)                                                  |
| Discoverable Wayland leader menu   | [wlr-which-key](https://github.com/eepp/wlr-which-key)                                                     |
