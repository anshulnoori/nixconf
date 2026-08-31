# NixOS system design

This document records the confirmed system requirements that are not already
covered by [the application stack](./application-stack.md). The user is the
primary source of truth and the application stack is secondary. This document
supplements both with confirmed system policy. If the documents conflict, ask
the user rather than silently choosing one.

## Status

- The immediate target is the physical `t1` PC. There is no Tart or other VM
  target.
- The installation starts from the official NixOS 26.05 minimal ISO, verified
  and flashed to USB with Balena Etcher.
- Work proceeds in this order: read-only inspection; an exact destructive disk
  plan and fresh approval; encrypted base installation; first-boot and recovery
  validation with Secure Boot disabled; full desktop activation; and Secure
  Boot enrollment and verification.
- The user reports that the new target SSD is empty. This workflow has not
  performed a destructive action or consumed approval for one. The live
  successor must identify the target disk, show the existing data, exact
  partition plan, encryption boundary, and recovery path, and obtain fresh
  approval before any write.
- The user has already flashed the latest BIOS. The live inspection verifies
  its version read-only and also checks the Samsung 990 Pro and other device
  firmware and driver state before installation.
- The Apple Silicon MacBook remains a later Asahi Linux target and is not part
  of the first installation.
- Only the live facts still awaiting confirmation are listed at the end of this
  file.

## Host and account

| Item         | Decision                                                   |
| ------------ | ---------------------------------------------------------- |
| Hostname     | `t1`                                                       |
| Primary user | `mvs`                                                      |
| Case         | FormD T1 v2.1                                              |
| Motherboard  | MSI MPG B850I Edge Ti WiFi                                 |
| CPU          | AMD Ryzen 7 9850X3D (Zen 5)                                |
| GPU          | None initially; use the CPU's integrated graphics          |
| Future GPU   | RTX 5080 or 5090 FE with proprietary NVIDIA kernel modules |
| Storage      | New Samsung 990 Pro 4 TB; exact device identity required   |
| Memory       | Exact installed capacity must be detected                  |
| Locale       | `en_US.UTF-8`                                              |
| Keyboard     | Standard US PC keyboard                                    |
| Timezone     | Automatically selected from the current region             |

One memorized secret serves as both the passphrase typed at every cold-boot
LUKS prompt and the `mvs` Linux account password. LUKS has no TPM-backed or
automatic unlock. The plaintext is never stored in the repository, Nix store,
1Password, or shell history. Only the salted yescrypt account-password hash is
provided through sops-nix.

Direct root login is disabled. `mvs` belongs to `wheel` and uses the account
password for `sudo`; passwordless sudo is disabled. Keep PAM modular so a
FIDO2 key or biometric factor can be explicitly enrolled as supplemental
authentication later, but configure neither initially and never use either for
LUKS unlock.

Set `users.mutableUsers = false`. The declarative yescrypt hash remains the only
account-password material available to the installed configuration.

## Release and update policy

- `nixos-unstable` is the package-set foundation.
- Moving main/nightly inputs are pinned to exact revisions in `flake.lock`.
- Lix nightly tracks `main`, with its NixOS module pinned to a compatible
  revision.
- Home Manager tracks `master` and follows the system nixpkgs input.
- Hyprland and deliberately selected nightly-capable applications track pinned
  upstream revisions rather than unpinned branches.
- Upstream `wlr-which-key` is pinned directly rather than using its older
  nixpkgs release.
- Amp CLI is pinned as a local flake package to an exact upstream release and
  source hash rather than taken from the slower nixpkgs package update cycle.
- Update automation may propose changes daily, but never activates or merges
  them automatically.
- Full checks, generation diffs, and an explicit promotion happen before an
  update reaches the running system.
- Garbage collection and generation limits must prevent nightly builds from
  growing the store without bound.
- The desktop provides the revision-aware Waybar and Mako update notification
  described below.

Both `system.stateVersion` and `home.stateVersion` are `"26.05"`. These values
preserve stateful compatibility defaults; they do not pin packages or prevent
the flake from using pinned unstable and nightly inputs.

Lix nightly is the normal package manager. If a regression blocks operation,
pin Lix and its NixOS module to the last known-good compatible revisions.
Previous NixOS generations remain available from the boot menu; there is no
separately maintained stable-Lix configuration.

## Boot and recovery

- Limine is the bootloader.
- The official installer boots with Secure Boot temporarily disabled. The first
  installed boot also keeps Secure Boot disabled while the user validates the
  base system, recovery path, and then the full desktop. Enrollment follows
  only after those checks pass.
- Secure Boot setup follows the current CachyOS process where it fits NixOS and
  Limine. The current [CachyOS Secure Boot guide](https://wiki.cachyos.org/configuration/secure_boot_setup/)
  is a process reference, not a source of Arch-specific commands. On the MSI
  board, firmware uses custom mode and its maximum-security compatibility
  setting. The process enrolls local keys with Microsoft and OEM certificates,
  signs Limine, enrolls its configuration checksum, enables Secure Boot, and
  then verifies the active state.
- The Secure Boot private keys remain below encrypted root. The firmware
  administrator password is recorded on paper.
- The normal kernel package is
  `pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4` from
  `xddxdd/nix-cachyos-kernel`.
- A standard NixOS kernel remains bootable as a recovery path.
- Boot is quiet and uses a Gruvbox-themed Plymouth spinner where supported.
- Set `boot.loader.limine.maxGenerations = 6`; Limine exposes the current
  generation and five previous generations.
- Snapper snapshots are for file recovery and manual rollback; they are not
  synthesized into Limine boot entries.
- One Limine `recovery` specialization combines the standard NixOS kernel,
  `tuigreet`, no graphical automatic login, and an authenticated `mvs`
  text-shell repair path. It never bypasses the account password.

## Storage and memory

The PC installation is managed by disko after explicit destructive approval.
The intended stack is:

```text
GPT
├── 4 GiB EFI system partition → Limine
└── LUKS2
    └── Btrfs
        ├── @root → /
        ├── @home → /home
        ├── @nix  → /nix
        └── @swap → /swap
```

No speculative `games`, `cache`, `log`, or `projects` subvolumes are created.
`~/Projects` remains in the snapshotted home subvolume. The dedicated swap
subvolume exists because an active Btrfs swapfile prevents snapshots of its
containing subvolume.

LUKS2 uses the interactively entered passphrase, Argon2id key derivation,
AES-XTS-512, and discard propagation. Btrfs uses `noatime`; asynchronous discard
and the weekly `fstrim` timer maintain the SSD without a continuous synchronous
discard penalty. The printed high-entropy recovery key is the independent
recovery path.

Storage policy:

- Btrfs mounts use `compress=zstd:3` for normal data;
- Snapper root retention is 7 daily, 4 weekly, and 3 monthly snapshots, with no
  hourly snapshots and at most 10 pre/post pairs;
- Snapper home retention is 6 hourly, 7 daily, and 4 weekly snapshots, with no
  monthly snapshots;
- `/nix` and `/swap` excluded from snapshots;
- pre/post system snapshots where they provide useful mutable-file recovery;
- automatic snapshot cleanup;
- automatic Nix store optimization;
- weekly Nix cleanup that retains the current system profile and five previous
  profiles;
- no hibernation initially.

Maintenance is automatic: run `fstrim` weekly, Btrfs scrub monthly, and Btrfs
device-stat plus NVMe health checks daily. Keep journald's default rotation.
Install `smartmontools` and `nvme-cli`, and monitor NVMe critical warnings,
available spare, percentage used, unsafe shutdowns, media and data-integrity
errors, temperature, error logs, self-tests, and firmware version. A newly
detected issue or low-free-space condition sends one Mako notification and
leaves a persistent Waybar warning until it is acknowledged or resolved.
Firmware checks never install an update automatically.

Keep Btrfs `autodefrag` disabled: it is not general maintenance and can reduce
snapshot and reflink efficiency while increasing writes. Do not schedule
defragmentation or balance operations. Use either only as a targeted response
to measured trouble. The system should perform its routine maintenance without
manual intervention. Same-disk snapshots remain recovery points, not backups.

Memory pressure uses two swap tiers:

1. zstd zram with logical capacity equal to 100% of physical RAM and priority
   100;
2. a 16 GiB Btrfs swapfile inside LUKS with priority 10.

The zram capacity is an uncompressed logical limit, not RAM reserved at boot.
Compressed storage is allocated dynamically. The normal running state uses
`vm.swappiness=150`, `vm.page-cluster=0`, and disabled zswap. Do not add the old
CachyOS watermark settings, which upstream removed because they increased RAM
use. Keep `vm.vfs_cache_pressure=50`. Use fixed dirty limits of 256 MiB total
and 64 MiB background, with a 15-second writeback interval. Benchmark this
writeback interval if Btrfs writes become bursty. Set transparent huge-page
defragmentation to `defer+madvise`. Set `max_ptes_none` to 409 only if the
selected kernel exports that control. Keep the kernel's normal huge-page enable
policy. Do not invent MGLRU, compaction, or watermark values that current
`cachyos-settings` does not define.

## CachyOS compatibility target

The goal is to reproduce relevant CachyOS performance, hardware, and gaming
behavior declaratively on NixOS. CachyOS package management, branding, desktop
environment, and styling are not part of the target.

Research against the current official [kernel](https://wiki.cachyos.org/features/kernel/),
[settings](https://wiki.cachyos.org/features/cachyos_settings/),
[optimized repository](https://wiki.cachyos.org/features/optimized_repos/),
[gaming](https://wiki.cachyos.org/configuration/gaming/), and
[sched-ext](https://wiki.cachyos.org/configuration/sched-ext/) documentation
found several independent layers:

1. The CachyOS kernel supplies its patchset, 1000 Hz tick rate, dynamic
   preemption, scheduler variants, ThinLTO, MGLRU and AMD P-state changes,
   sched-ext support, NTSync, optional ADIOS and BBR3, and hardware fixes.
2. CachyOS rebuilds much of the Arch package repository for x86-64-v3,
   x86-64-v4, and a shared Zen 4/5 target, with selective PGO, LTO, and BOLT.
   This is separate from its kernel.
3. `cachyos-settings` applies memory, writeback, I/O scheduler, audio,
   journald, service-limit, THP, module, and device-permission policy.
4. Optional sched-ext programs dynamically replace the built-in CPU scheduler.
5. Gaming packages add Steam runtimes, Proton and Wine variants, launchers,
   overlays, Gamescope, GameMode-like wrappers, and diagnostics.

`xddxdd/nix-cachyos-kernel` supplies the first layer only. Its current processor
targets stop at `zen4`; it does not provide a reproducible `zen5` target. AMD
confirms the Ryzen 7 9850X3D is Zen 5 with AVX-512, while CachyOS itself groups
Zen 4 and Zen 5 under its current `znver4` repository. A fixed `zen4` kernel
target is therefore compatible but does not use every Zen 5-specific compiler
optimization. A custom `native` target would sacrifice reproducibility and
binary-cache portability.

The Nix kernel package supports experimental AutoFDO input but does not support
Propeller, and CachyOS does not publish the production profile artifacts used
by its default kernel. ThinLTO is reproducible; exact reproduction of the
official AutoFDO and Propeller build is not currently available from public,
pinned inputs.

The selected package fixes Clang ThinLTO, BORE, and `zen4` at build time. BORE,
EEVDF, and BMQ are separate kernel builds, not runtime modes in one kernel. The
package also includes the CachyOS configuration, 1000 Hz timer, dynamic full
preemption, the POC idle selector, ADIOS support, MGLRU, NTSync, v4l2loopback,
Binder support, and inherited graphics and hardware patches. Keep upstream
Binder support compiled but dormant: do not mount BinderFS, run an Android
service, or create a custom kernel derivation to remove it. AutoFDO, Propeller,
and kCFI are not used. Distributed ThinLTO and a dedicated debug variant are
not exposed by the Nix kernel input.

Optional features must not be described as active only because CachyOS lists
them. The normal BORE kernel is not a real-time kernel. BBR3 with FQ is the
default TCP congestion policy. ZFS and proprietary NVIDIA drivers are external
modules from the selected kernel package set. ZFS is not installed because the
system uses Btrfs. v4l2loopback remains available as an inactive module until a
virtual-camera workflow needs it. The NVIDIA modules are added only after the
GPU is installed. Open NVIDIA modules remain excluded. Binder and ADIOS stay
compiled but inactive.

Nixpkgs supports `znver5` compiler targeting, but setting it globally changes
the standard environment and causes a near-complete source rebuild with little
reuse from `cache.nixos.org`. A second optimized package set or leaf-package
overrides could target measured workloads without rebuilding the entire
desktop. Keep the standard package set rather than adding either preemptively.

Current `cachyos-settings` source assigns Kyber to NVMe, mq-deadline to SATA
SSDs, and BFQ to rotational disks. Its documented optional ADIOS scheduler is
still under active development and is not its default. The target has one NVMe
SSD and no SATA or rotational storage. Use Kyber for the Samsung 990 Pro. A
later benchmark can compare Kyber with `none` under concurrent game, build, and
download workloads.

AMD P-state runs in active EPP mode. The governor and EPP preference remain on
`performance` at all times. Power-profiles-daemon is disabled. GameMode does
not change the governor or EPP policy; it remains available for process, I/O,
and game-specific optimizations.

Journald keeps the NixOS defaults: persistent storage, dynamic space limits, and
default rate limiting. No custom size or retention policy is applied. The
system does not generate coredumps. Disabling `systemd-coredump` alone is not
sufficient because NixOS then writes `core` files in each crashing process's
working directory. Set the core limits to zero for system services, user
services, and PAM sessions. LazyJournal is the normal interactive journal
viewer.

## Firmware, BIOS, and cooling

The user has already updated the MSI motherboard to the latest BIOS. Live
inspection verifies its reported version without writing firmware. Before
installation, also inspect the Samsung 990 Pro firmware and all detected device
firmware and active drivers. Drivers are managed declaratively by the pinned
kernel, `linux-firmware`, and selected kernel package set; do not install them
imperatively.

No firmware check authorizes a firmware write. Before any BIOS, SSD, or other
device update, present the exact official artifact, current and target versions,
checksum, procedure, and risks, then obtain fresh approval. Never apply firmware
automatically.

Preserve these existing BIOS settings exactly:

- Curve Optimizer: -20 on every core;
- positive boost-clock override: +25 MHz;
- PBO scalar: 10x;
- PBO limits: automatic;
- EXPO: enabled.

The CPU cooler is a Thermalright AXP90-X47. Stability testing is observational:
any failure stops the test, reports the evidence, and waits for user direction;
software never changes BIOS tuning in response. Optimize for maximum stable
performance per watt and temperature, with a bias toward performance rather
than minimum heat or noise.

Use the latest released CoolerControl package from `nixos-unstable`, not an
upstream-main build. Enable it with `programs.coolercontrol.enable = true` and
include its GUI plus `lm_sensors`. The daemon starts at boot, but the GUI opens
only manually; do not autostart its GUI or tray. CoolerControl has no official
TUI. Bind its API and Web UI to loopback only at `localhost:11987`, with no LAN
or tailnet exposure.

NixOS owns the CoolerControl package and service. CoolerControl owns its mutable
calibration and profiles under encrypted root. Initially leave every fan
channel unmanaged so the BIOS remains in control until live calibration and an
explicit profile assignment. Use motherboard hwmon; keep `liquidctl` available
but unused unless compatible hardware is detected. BIOS keeps independent safe
curves for pre-Linux boot, recovery, and service failure. Do not invent fan
percentages before calibration. Build performance-first curves from live
measurements; the user may later copy a proven runtime curve into BIOS manually.

## Gaming

- Steam enables the 32-bit graphics and audio stack.
- Proton-GE is the default Steam compatibility runtime.
- MangoHud provides runtime metrics. GOverlay provides its interactive
  configuration editor; Home Manager does not own the complete MangoHud
  configuration.
- GameMode, Gamescope, and Protontricks are installed.
- Prism Launcher remains the Minecraft launcher.
- Moonlight, Heroic, Lutris, UMU, Proton-CachyOS, and Wine-CachyOS are not
  installed initially.
- GPU-specific DLSS and shader-cache settings wait until the NVIDIA GPU is
  installed.

## Secrets

Use the smallest sops-nix design that preserves host isolation:

- encrypted files remain in this public repository;
- no private submodule or separate secret flake;
- each host receives one hybrid ML-KEM-768 and X25519 identity;
- the host identity and Secure Boot signing keys remain below LUKS encryption;
- host files are encrypted only to their intended host identities;
- plaintext and private identities are never committed;
- conventional age, SSH, RSA, and Ed25519 recipients are not added to protected
  files;
- SOPS contains only noninteractive machine secrets and the salted yescrypt
  `mvs` account-password hash, never the human-readable password or LUKS
  passphrase;
- secret files are added only when a real consumer exists.

sops-nix decrypts runtime files beneath `/run/secrets`. Adding another host
requires another recipient and host file; it does not change repository
topology. 1Password remains a user-facing credential, SSH-agent, and Git-signing
tool. It is not the store for machine keys. The normal installation does not
create an offline administrator-key USB. A high-entropy LUKS recovery key is
printed on paper. After total disk loss, replace the host and Secure Boot
identities and reissue affected machine secrets.

## User environment

Home Manager `master` is embedded in the NixOS configuration:

```nix
home-manager = {
  useGlobalPkgs = true;
  useUserPackages = true;
};
```

There is no standalone Home Manager profile. NixOS and the user environment
switch and roll back together. NixOS owns hardware, boot, users, networking,
security, and system services. Home Manager owns user packages, user services,
and dotfiles.

Additional decisions:

- nvf owns the Neovim configuration through the integrated Home Manager user
  module.
- Neovim uses a pinned nightly build. nvf includes pinned `amp.nvim`, despite
  that plugin's upstream deprecation.
- `amp.nvim` starts automatically.
- Snacks, Blink completion, Treesitter, Gitsigns, Lazygit integration,
  render-markdown, Markdown preview, VimTeX, Neovim which-key, linting, and
  format-on-save are retained as nvf-managed behavior.
- Flash, mini.ai, mini.pairs, Yanky, Dial, inc-rename, TODO Comments, Neotest,
  and DAP are retained.
- Reproduce the current Mac's visible editor layout: Gruvbox, Bufferline,
  Lualine, Noice, Persistence, grug-far, Which-Key, mini.icons, and the enabled
  Snacks dashboard, explorer, indentation, input, picker, notifier, quick-file,
  scope, scrolling, status-column, and word-reference features. Do not import
  LazyVim itself.
- Language servers and their toolchains normally come from each project's Nix
  development shell. The global set contains nixd, Marksman, Taplo, YAML, JSON,
  and Lua language servers.
- Preserve the current Mac's Gradle task UI, `uv.nvim` integration,
  project-scoped Biome, project-scoped OCaml language server and formatter,
  dotfile filetype support, mini.hipatterns hex and Tailwind previews, and the
  on-demand `StartupTime` diagnostic.
- Do not transfer the tmux navigator because zmx replaces tmux navigation, the
  obsolete `/tmp/nvim.sock` cleanup, Mason, or hardcoded macOS, Homebrew,
  Kotlin, and JDK paths.
- `amp.nvim` owns Amp agent interaction. Minuet provides Blink and virtual-text
  AI completion through
  `https://ai.mongoose-silverside.ts.net/v1/chat/completions`. The initial model
  is Minuet's OpenAI-compatible default, `deepseek/deepseek-v4-flash`, subject
  to validation against the authenticated LiteLLM model list. Streaming and the
  other Minuet completion defaults remain unchanged. The endpoint requires an
  API token. sops-nix decrypts that token to
  `/run/secrets/litellm-api-key`; Minuet reads the file through its synchronous
  key callback. Virtual-text suggestions trigger automatically after a short
  idle period. Blink exposes Minuet through a manual keybinding so that both
  interfaces do not request automatic completions concurrently. GitHub Copilot
  is excluded.
- Atuin history is local only; no Atuin account or sync credentials.
- Rootless Podman is the container engine.
- Lazydocker uses the Podman Docker-compatible socket where compatible.
- No global language toolchains; projects provide their own Nix development
  shells.
- CUPS, Syncthing, libvirt/QEMU, and unrequested network-sharing services are
  disabled initially.
- No incoming SSH or Mosh service is enabled. The outbound OpenSSH client
  remains available for Git and administering other tailnet hosts.
- No data backup is configured initially. Local Snapper snapshots are recovery
  points on the same disk, not backups.

The interactive shell is Zsh in vi editing mode. Yazi is the only file manager
and its `y` wrapper changes the parent shell's working directory. Preserve
`AUTO_CD`, zoxide as the `cd` replacement, local-only Atuin history, and aliases
for eza, Lazygit, ripgrep, bat, fd, and hyperfine. Do not carry over macOS paths
or globally installed language-toolchain paths.

## Networking and firewall

Ethernet through systemd-networkd DHCP is primary. Standalone iwd and Impala
remain the Wi-Fi fallback; do not enable NetworkManager or wpa_supplicant
against the same interfaces. Enter Wi-Fi credentials interactively and keep
them as mutable state below LUKS rather than in the repository or Nix store.
systemd-resolved owns DNS, and Tailscale is the only VPN.

Tailscale is installed declaratively but authenticated interactively after
first boot. Its mutable state remains below LUKS; no reusable Tailscale auth key
is stored in SOPS.

The firewall defaults to denying inbound traffic. Configure no trusted
interfaces and open no SSH, Mosh, or application ports. Allow only the Tailscale
transport required by its NixOS module; each future service must open its own
ports deliberately. CoolerControl remains loopback-only. Amp and the OpenSSH
client make outbound connections and need no inbound exception.

## Graphical session and login

Normal cold boot:

```text
typed LUKS unlock
  → greetd automatic initial mvs session
  → UWSM
  → Hyprland
```

- greetd is the login/session broker.
- Automatic login applies only to the first graphical session after each cold
  boot. It does not remove the LUKS prompt or account password.
- UWSM owns the systemd user session and starts Hyprland.
- hypridle handles screensaver, lock, and display-power transitions. It does
  not suspend automatically; suspend is available only as an explicit desktop
  control action.
- hyprlock locks the existing session and authenticates wake.
- Explicit logout presents ReGreet under the small Cage compositor and requires
  the `mvs` password before starting another session.
- `tuigreet` or an equivalent text greeter remains an independent fallback.
- TTY login and the recovery specialization always require the `mvs` password.
- The account password authenticates hyprlock, ReGreet, and privileged actions.
- Passwordless sudo is not enabled on the physical PC.

After 5 minutes of inactivity, replace the wallpaper with the unlocked
fullscreen TTFX screensaver. Activity before the lock deadline dismisses it
without authentication. At 10 minutes, stop the screensaver and start
hyprlock; subsequent activity still requires the account password. At 20
minutes, turn displays off while keeping the session locked. No idle deadline
suspends the machine.

1Password system authentication allows Linux PAM authentication to unlock
1Password. It does not make 1Password an operating-system login or PAM
provider. Enable the 1Password GUI, CLI, browser integration, SSH agent, Git
signing integration, and required polkit policy. Initial sign-in remains
interactive.

Use official Hyprland ecosystem components where they directly fit, including
Hyprland, hypridle, hyprlock, hyprsunset, hyprpolkitagent, and the Hyprland
portal. Previously confirmed focused components such as Waybar, Mako, Vicinae,
Fuzzel, and SwayOSD remain selected.

## Interaction and keybindings

`wlr-which-key` is the discoverable leader menu. Home Manager's
`programs.wlr-which-key` module generates its configuration, while a pinned
upstream package supplies the executable.

- Keep only essential direct Hyprland bindings.
- Reserve `Super+Space` as the leader.
- Do not invent menu categories or actions during scaffolding.
- Add menu actions organically as real use establishes muscle memory.
- Hardware media keys and recovery-critical bindings remain direct.

## Theme and bar

- Stylix is the shared palette source.
- Use a Gruvbox dark palette throughout the desktop.
- Use no logo, name, or custom branding.
- TTFX renders a continuous live wallpaper in one Kitty layer-shell panel per
  output. Kitty uses its background layer, so the panels are not normal
  Hyprland windows. The wallpaper runs at 30 FPS. No hyprpaper service runs
  concurrently.
- At the idle deadline, hypridle replaces the background instances with
  foreground fullscreen TTFX instances. User activity restores the background
  instances. The screensaver runs at 60 FPS. Both modes use random effects and
  an unbranded generated character pattern.
- Preserve square geometry and minimal or absent shadows.

Waybar reproduces the behavior of Omarchy's current top bar without adopting
its Quickshell shell. Current Omarchy no longer uses Waybar, so this is a
behavioral translation rather than a copied configuration.

Confirmed placement:

```text
left:   menu, workspaces
center: empty
right:  updates, indicators, Tailscale, Bluetooth, network, clock
```

The right-hand list is written from left to right; the clock is the rightmost
module. `indicators` is a collapsed Waybar drawer containing the tray, audio and
microphone, media, display and power, privacy, and recording state. There are no
weather, keyboard-layout, agent, or separate power and audio modules. Widgets
hide when irrelevant. Network, Bluetooth, Tailscale, and update modules should
expose their useful actions without carrying over Omarchy-specific shell
architecture.

Update state is checked by a lightweight user timer every six hours. It detects
new `renovate/*` branch revisions and a merged configuration newer than the
running revision. Waybar shows the state and Mako sends at most one notification
per branch SHA. Clicking the module opens a floating Kitty window with the
branch, diff, and deliberate update action. Nothing auto-merges or switches.

## Git identity

There is no global author identity or signing key. Set
`user.useConfigOnly=true` and select identity through native conditional Git
includes and SSH host aliases.

| Profile   | Author                                                           |
| --------- | ---------------------------------------------------------------- |
| Main      | `Anshul Noori <anshulnoori+github@gmail.com>`                    |
| Alternate | `Mervs <246713988+maroonverticalshape@users.noreply.github.com>` |

Both profiles sign commits and tags with profile-specific 1Password SSH keys.
Unknown repositories fail until assigned a local profile. `gh auth switch`
changes GitHub API credentials only and does not select commit authorship.

Shared behavior:

- default branch `master`;
- rebase pulls;
- automatic upstream setup on first push;
- histogram diff and moved-line highlighting;
- `zdiff3` conflict presentation;
- rerere with autoupdate;
- Delta side-by-side Gruvbox output;
- Neovim editor;
- aliases `co`, `br`, `ci`, and `st`.

## First-boot validation

With Secure Boot still disabled, collect concrete evidence for every item before
desktop expansion and again where full desktop activation changes the result:

- the typed LUKS unlock and encrypted-root boundary;
- current and recovery Limine entries;
- Lix nightly as the normal package manager;
- the selected CachyOS BORE ThinLTO `zen4` kernel;
- AMD P-state in active EPP mode with the confirmed performance policy;
- the expected Btrfs subvolume mounts, zram, and encrypted swapfile;
- primary Ethernet, DNS resolution, and the optional Wi-Fi fallback;
- integrated graphics and audio;
- one-time cold-boot automatic login, explicit logout authentication, and
  hyprlock authentication;
- default-deny firewall state; and
- absence of incoming SSH and Mosh listeners.

Secure Boot enrollment remains a later stage and requires its own post-enrollment
verification.

## Remaining live facts

Only these facts remain to be collected on the physical system:

- exact memory and disk identities, detected firmware versions, devices, active
  drivers, and network-interface names;
- exact NixOS and Limine Secure Boot commands for the discovered system;
- authenticated validation that the LiteLLM endpoint exposes Minuet's selected
  model alias; and
- concrete evidence from the confirmed live verification checks.

Remote game-server deployment is outside this system's scope.
