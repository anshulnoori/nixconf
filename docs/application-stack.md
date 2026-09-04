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
| Theme                  | Gruvbox Dark Hard from one shared palette                                         |
| Font                   | JetBrains Mono Nerd Font with Nerd Font glyphs                                    |
| Configuration          | Declarative NixOS and Home Manager modules                                        |
| Development toolchains | Per-project Nix development shells; no global language toolchains                 |
| Package channel        | NixOS unstable, with pinned flake inputs                                          |
| Kernel                 | CachyOS BORE ThinLTO Zen 4; previous Limine generations provide rollback          |

## Desktop

| Role                 | Selection                                            | Integration notes                                               |
| -------------------- | ---------------------------------------------------- | --------------------------------------------------------------- |
| Compositor           | Hyprland                                             | Owns windows, workspaces, displays, keybindings, and animations |
| Bar                  | Waybar                                               | Square CSS; launches system interfaces in Kitty                 |
| Command launcher     | Walker + Elephant                                    | One launcher UI with one provider backend                       |
| Desktop menu         | Walker + Elephant menus                              | Nested actions with full-tree search from the root              |
| Shortcut overlay     | wlr-which-key + keyd                                 | Tap Super to discover and dispatch existing shortcuts           |
| Notifications        | Mako                                                 | Only notification daemon; Gruvbox styling and DND mode          |
| Wallpaper            | swaybg                                               | Omarchy Flexoki Orb composition recolored to Gruvbox Dark Hard  |
| Lock screen          | hyprlock                                             | Visible password field over the matching wallpaper              |
| Idle management      | hypridle                                             | Lock and display power; no automatic suspend                    |
| Authentication agent | hyprpolkitagent                                      | Graphical Polkit prompts                                        |
| Screenshots          | grim + slurp + Satty                                 | Region capture, clipboard copy, annotation, and export          |
| Screen recording     | gpu-screen-recorder                                  | Region, monitor, audio, microphone, and webcam-overlay capture  |
| Screensaver          | terminaltexteffects in Kitty                         | Fullscreen animated pattern before the lock deadline            |
| OSD                  | SwayOSD                                              | Volume and brightness feedback                                  |
| Clipboard            | Elephant + wl-clipboard                              | Searchable history through Walker and direct clipboard commands |
| Media control        | playerctl                                            | Hardware keybindings                                            |
| Portals              | xdg-desktop-portal-hyprland + xdg-desktop-portal-gtk | Screen sharing, file dialogs, URI opening, and screenshots      |
| Removable media      | udisks2 + udiskie                                    | Device access and automounting                                  |
| Cooling GUI          | CoolerControl                                        | Manual GUI; daemon starts at boot without GUI or tray autostart |

The flake pins Omarchy commit
`a7f8f2495f4990044b7791d8f11a32cf14d34b39` as a frozen visual-asset source.
The Walker menu interaction follows the last pre-Quickshell Walker/Elephant
commit, `7fe472bf8ab3efe8c2a7470a285aad87dea9052f`. This configuration does not
follow later Omarchy desktop changes. It deliberately substitutes Kitty for
Alacritty and hyprpolkitagent for polkit-gnome. Omarchy is not the source for
bindings or feature policy.

Elephant's clipboard provider owns clipboard history. Do not also run cliphist;
that would duplicate the clipboard watcher and history database.

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

## System interfaces

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
| Remote client          | Mosh + OpenSSH       |
| Terminal recording     | asciinema            |
| Downloads              | aria2                |
| Network diagnostics    | nmap                 |
| Hardware sensors       | lm_sensors           |
| System information     | Fastfetch            |

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
| Activation comparison    | dix                            | Built into nh and shown during system activation                           |
| Generation comparison    | nvd                            | Summarize package changes between generations                              |
| Closure inspection       | nix-tree                       | Explain store dependencies                                                 |
| Package index            | nix-index                      | Find packages that provide files and commands                              |
| Missing-command lookup   | comma                          | Run commands through nix-index results                                     |
| Documentation search     | Native Nix/NixOS documentation | Do not add manix initially                                                 |

The NixOS `nh` module sets `/etc/nixos` as the default flake, allowing `nh os`
to select `t1` from the hostname and rebuild the integrated Home Manager
configuration with the system. Its nix-output-monitor build tree and dix
activation diff remain enabled. A persistent weekly `nh clean all` timer
replaces native automatic garbage collection, retains six generations in every
profile, and retains active direnv roots. Native Nix commands remain available
underneath it.

## Theme and typography

| Layer               | Decision                                                                               |
| ------------------- | -------------------------------------------------------------------------------------- |
| Palette source      | Stylix with a selected Gruvbox dark scheme                                             |
| Shared colors       | Custom modules consume `config.lib.stylix.colors`                                      |
| GTK and Qt          | Stylix targets                                                                         |
| Terminal            | Stylix Kitty target                                                                    |
| Editor              | Stylix nvf target                                                                      |
| Desktop components  | Generate Waybar, Walker, Mako, SwayOSD, hyprlock, and Hyprland colors from the palette |
| Custom applications | Consume the same generated palette rather than embedding hex values                    |
| Primary font        | JetBrains Mono Nerd Font                                                               |
| Icon glyphs         | Symbols Nerd Font                                                                      |
| Shape language      | Zero corner radius and minimal or no shadows where applications allow it               |

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

| Role                | Selection                            | Notes                                     |
| ------------------- | ------------------------------------ | ----------------------------------------- |
| Password manager    | 1Password                            | Human-managed secrets                     |
| CLI                 | `op`                                 | Runtime secret access                     |
| SSH agent           | 1Password SSH agent                  | Git and outbound SSH authentication       |
| Browser integration | 1Password extension for Brave Origin | Primary web credential flow               |
| Secret Service      | GNOME Keyring                        | Home Manager owns the sole session daemon |

Secrets must not be written into the Nix store. Resolve them at runtime through
1Password, protected files, or an appropriate secrets module.

## Browsers, search, and launcher

| Role                | Selection                          | Notes                                                                                        |
| ------------------- | ---------------------------------- | -------------------------------------------------------------------------------------------- |
| Primary browser     | Brave Origin, standalone Linux app | Minimal Brave build; free Linux activation, authenticated browsing, web apps, and Brave Sync |
| Terminal browser    | Browsh                             | Low-bandwidth and remote terminal browsing                                                   |
| Launcher UI         | Walker                             | Applications and Elephant-backed providers                                                   |
| Launcher backend    | Elephant                           | Files, calculator, web search, clipboard, and symbols                                        |
| Graphing calculator | Desmos in Brave Origin             | Do not add a terminal substitute                                                             |

Elephant web-search results should open in Brave Origin rather than render a
second browser surface.

Browsh runs a separate Firefox profile and cannot share Brave Origin Sync,
cookies, history, or authenticated sessions. Treat it as an independent
browser. If shared bookmarks become necessary, add a browser-independent
bookmark service rather than copying browser profile files.

## Communication and productivity

| Role             | Selection                                    | Packaging notes                                                   |
| ---------------- | -------------------------------------------- | ----------------------------------------------------------------- |
| Secure messaging | Signal Desktop                               | Native Linux client                                               |
| Community chat   | Discord Canary + Vencord                     | Package declaratively; accept client-mod compatibility risk       |
| WhatsApp         | WhatsApp Web installed as a Brave Origin app | No unofficial credential-holding wrapper                          |
| iMessage         | BlueBubbles client                           | Connect only to the Mac over Tailscale                            |
| Mail             | Private custom client                        | Existing application                                              |
| Calendar         | Private Notion Calendar Electron package     | Personal distribution only; Waybar integration over a Unix socket |
| Tasks            | Todoist                                      | Native client or Brave Origin app selected during packaging       |
| Notes            | Obsidian                                     | Unfree package allowed explicitly                                 |

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
| Video, audio, and still images | mpv                     | Default media handler; MPRIS integrates with playerctl           |
| Media retrieval                | yt-dlp                  | Integrate with mpv where useful                                  |
| Transcoding and inspection     | FFmpeg                  | Full codec build for CLI work and DaVinci-compatible transcodes  |
| Recording and streaming        | OBS Studio              | Includes the `v4l2loopback`-backed OBS virtual camera            |
| Video editing                  | DaVinci Resolve         | Unfree package; codec limitations may require FFmpeg transcoding |
| Local file transfer            | LocalSend               | Cross-platform transfer over Tailscale only                      |

## Gaming

| Role                  | Selection      | Notes                                                 |
| --------------------- | -------------- | ----------------------------------------------------- |
| Platform              | Steam          | Enable 32-bit graphics and audio support              |
| Compatibility runtime | Proton-GE      | Exposed declaratively; select as Steam's default once |
| Minecraft             | Prism Launcher | Per-instance Java and mod management                  |
| Performance overlay   | MangoHud       | FPS, frame time, and hardware metrics                 |
| Overlay editor        | GOverlay       | Interactive MangoHud configuration                    |
| Performance policy    | GameMode       | Game process and I/O tuning; fixed CPU policy stays   |
| Nested compositor     | Gamescope      | Resolution, scaling, and fullscreen control           |
| Prefix management     | Protontricks   | Per-game Wine and Proton changes                      |

GeForce Now, Moonlight, Heroic, Lutris, and UMU are intentionally excluded.
Steam libraries, Prism Launcher instances, and Minecraft worlds use
`/home/mvs/games`. This Btrfs subvolume has no local snapshot policy. A
separate backup method protects Minecraft worlds. After first launch, select
Proton-GE as Steam's default compatibility tool and add
`/home/mvs/games/Steam` as its library. Nix does not rewrite Steam's mutable VDF
state.

## Networking and remote access

| Role                  | Selection        | Notes                                                                 |
| --------------------- | ---------------- | --------------------------------------------------------------------- |
| Wi-Fi backend         | iwd              | Fallback backend required by Impala                                   |
| Wi-Fi UI              | Impala           | Fallback UI; do not run NetworkManager or wpa_supplicant concurrently |
| Network configuration | systemd-networkd | Ethernet is primary and uses wired DHCP                               |
| DNS                   | systemd-resolved | Cloudflare DNS over TLS                                               |
| Bluetooth backend     | BlueZ            | Required by Bluetui                                                   |
| Bluetooth UI          | Bluetui          | Primary pairing and device UI                                         |
| Tailnet               | Tailscale        | Only selected VPN                                                     |
| Incoming remote shell | Disabled         | Do not enable OpenSSH or Mosh services                                |
| Outbound remote shell | Mosh             | Primary interactive client; OpenSSH provides bootstrap and fallback   |
| Outbound SSH          | OpenSSH client   | Required by Mosh, Git, and noninteractive remote administration       |
| Local transfer        | LocalSend        | Direct transfer by Tailscale IP or MagicDNS name                      |

The Amp runner uses an outbound connection. It does not require an incoming SSH
service. Wi-Fi credentials are entered interactively and stored as mutable state
below LUKS.

LocalSend accepts inbound TCP traffic on port 53317 only through `tailscale0`.
The firewall blocks this port on LAN interfaces. Tailscale does not forward
LocalSend multicast discovery, so each peer must use a Tailscale address. The
packaged launcher refuses to start without an active Tailscale address and
updates LocalSend's mutable interface whitelist with the machine's current
Tailscale IPv4 and IPv6 addresses before every launch. This prevents LocalSend
from advertising or scanning on physical LAN interfaces without replacing its
other mutable preferences.

## Wallpaper, idle, and locking

The desktop uses one wallpaper service, one terminal screensaver, and one lock
implementation. It does not run a shell framework or live wallpaper.

| Behavior             | Decision                                                          |
| -------------------- | ----------------------------------------------------------------- |
| Wallpaper engine     | swaybg                                                            |
| Default wallpaper    | Pinned Omarchy `1-orb.png`, deterministically recolored           |
| Wallpaper selection  | Walker picker over generated and user-provided wallpaper files    |
| Screensaver          | Random terminaltexteffects animation in fullscreen Kitty windows  |
| Idle scheduler       | hypridle                                                          |
| Screensaver deadline | 5 minutes from the beginning of inactivity                        |
| Lock deadline        | 10 minutes from the beginning of inactivity                       |
| Display-off deadline | 20 minutes from the beginning of inactivity                       |
| Automatic suspend    | Disabled; suspend and hibernate remain explicit actions           |
| Lock styling         | Matching selected wallpaper and a centered visible password field |
| Idle inhibitors      | Respect media and application inhibitors                          |

hyprlock is the security boundary. swaybg owns the wallpaper surface and no
other wallpaper daemon runs concurrently.

## Kernel

| Role                 | Selection                                 | Notes                                            |
| -------------------- | ----------------------------------------- | ------------------------------------------------ |
| Kernel family        | CachyOS                                   | Desktop responsiveness and scheduler tuning      |
| Normal package       | `linuxPackages-cachyos-bore-lto-zen4`     | Clang ThinLTO, BORE, 1000 Hz, dynamic preemption |
| CPU target           | `zen4`                                    | Fixed target until the input supports Zen 5      |
| Profile optimization | Disabled                                  | No AutoFDO or Propeller profile                  |
| Real-time mode       | Disabled                                  | Normal BORE kernel                               |
| TCP congestion       | BBR3 with FQ                              | Default TCP policy                               |
| Binder               | Compiled but dormant                      | No BinderFS mount or Android service             |
| v4l2loopback         | OBS virtual camera                        | Loaded for OBS Studio virtual-camera output      |
| ZFS                  | Excluded                                  | Btrfs is the only root filesystem                |
| Flake source         | `xddxdd/nix-cachyos-kernel`               | Use its pinned overlay                           |
| Recovery             | Previous Limine generations and TTY login | Separate recovery specialization is deferred     |

GPU and other out-of-tree kernel modules must come from the selected kernel
package set. Add proprietary NVIDIA modules only after the GPU is installed.

## Private packages

| Package         | Constraint                                                                                   |
| --------------- | -------------------------------------------------------------------------------------------- |
| Notion Calendar | Package the tested Electron application privately and do not redistribute copyrighted assets |
| Mail client     | Keep private implementation and credentials out of the public flake                          |
| TTFX            | Add a local package only if the pinned nixpkgs does not provide it                           |

Private source, credentials, license material, and application data must never
enter the public repository or Nix store unintentionally.

Notion Calendar is consumed from the private application monorepo. Its helper
streams calendar state to Waybar over a Unix socket; Waybar opens the app on
left-click and its menu on right-click. The private mail client remains deferred
until its source and runtime contracts are ready.

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
| tldraw                                 | No native package is available                           |
| Terminal Desmos replacement            | Use Desmos itself in Brave Origin                        |
| NetworkManager for Wi-Fi               | Conflicts with the selected standalone iwd/Impala design |
| BlueBubbles Private API initially      | Requires disabling macOS SIP                             |

## References

| Project                        | Reference                                                                                                           |
| ------------------------------ | ------------------------------------------------------------------------------------------------------------------- |
| Frozen classic Omarchy desktop | [basecamp/omarchy at `a7f8f249`](https://github.com/basecamp/omarchy/tree/a7f8f2495f4990044b7791d8f11a32cf14d34b39) |
| BlueBubbles                    | [Installation](https://bluebubbles.app/install)                                                                     |
| BlueBubbles over Tailscale     | [Tailscale guide](https://tailscale.com/blog/bluebubbles-tailscale-imessage-android-pc-no-port-forwarding)          |
| Brave Origin                   | [Official product page](https://brave.com/origin/)                                                                  |
| Walker                         | [Documentation](https://github.com/abenz1267/walker)                                                                |
| Elephant                       | [Documentation](https://github.com/abenz1267/elephant)                                                              |
| Browsh profiles                | [Configuration](https://www.brow.sh/docs/config/)                                                                   |
| CachyOS kernel packages        | [xddxdd/nix-cachyos-kernel](https://github.com/xddxdd/nix-cachyos-kernel)                                           |
| Recursive Nix module imports   | [vic/import-tree](https://github.com/vic/import-tree)                                                               |
| Neovim configuration           | [NotAShelf/nvf](https://github.com/NotAShelf/nvf)                                                                   |
| Selective package wrappers     | [Lassulus/wrappers](https://github.com/Lassulus/wrappers)                                                           |
| Discoverable shortcut overlay  | [wlr-which-key](https://github.com/eepp/wlr-which-key)                                                              |
| Super tap/hold mapping         | [keyd](https://github.com/rvaiya/keyd)                                                                              |
