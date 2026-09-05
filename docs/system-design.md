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
  plan and fresh approval; encrypted `t1` installation; first-boot validation
  with Secure Boot disabled; and Secure Boot enrollment and verification. A
  separate recovery specialization is deferred; previous Limine generations
  are the current rollback path.
- The user reports that the new target SSD is empty. This workflow has not
  performed a destructive action or consumed approval for one. The live
  successor must identify the target disk, show the existing data, exact
  partition plan, encryption boundary, and recovery path, and obtain fresh
  approval before any write.
- Live inspection confirmed MSI BIOS `1.A42` dated 2026-06-26. It did not
  establish whether a newer vendor release exists. The Samsung 990 Pro and
  other device firmware and driver states were also inspected read-only.
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
| Storage      | Empty Samsung 990 Pro 4 TB; only internal disk             |
| Memory       | 32 GiB, 2 × 16 GiB DDR5-6000                               |
| Locale       | `en_US.UTF-8`                                              |
| Keyboard     | Standard US PC keyboard                                    |
| Timezone     | Automatically selected from the current region             |

One memorized secret serves as both the passphrase typed at every cold-boot
LUKS prompt and the `mvs` Linux account password. LUKS has no TPM-backed or
automatic unlock. The plaintext is never stored in the repository, Nix store,
1Password, or shell history. The salted account-password hash exists only in
`/etc/shadow` below encrypted root.

Direct root login is disabled. `mvs` belongs to `wheel` and uses the account
password for `sudo`; passwordless sudo is disabled. Keep PAM modular so a
FIDO2 key or biometric factor can be explicitly enrolled as supplemental
authentication later, but configure neither initially and never use either for
LUKS unlock.

Set `users.mutableUsers = true`. NixOS declares the `mvs` account, groups, and
shell. During installation, set its password interactively inside the mounted
system after activation and before reboot. Later system activations preserve
the password in `/etc/shadow`.

## Release and update policy

- `nixos-unstable` is the package-set foundation.
- Moving main/nightly inputs are pinned to exact revisions in `flake.lock`.
- Lix nightly tracks `main`, with its NixOS module pinned to a compatible
  revision.
- Home Manager tracks `master` and follows the system nixpkgs input.
- Hyprland and deliberately selected nightly-capable applications track pinned
  upstream revisions rather than unpinned branches.
- `wlr-which-key`, Walker, and Elephant come from the pinned nixpkgs revision;
  all three are available on both `x86_64-linux` and `aarch64-linux`.
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
  installed boot also keeps firmware enforcement disabled while the user
  validates the complete system. Limine generates local keys and signs the boot
  chain during installation; firmware enrollment follows only after first-boot
  checks pass.
- Secure Boot uses NixOS's native Limine support with automatically generated
  and manually enrolled `sbctl` keys. The MSI board stays in custom mode with its
  maximum-security preset. Before resetting firmware keys, the runbook verifies
  and exports the current firmware certificate sets, then verifies that the
  firmware-default variables remain available in Setup Mode. Enrollment then
  includes Microsoft certificates and those verified firmware-default
  certificates for Option ROM and update compatibility. The exact procedure is in
  [the Secure Boot runbook](./secure-boot.md).
- The Secure Boot private keys remain below encrypted root. The firmware
  administrator password is recorded on paper.
- Memtest86+ is copied to the EFI system partition, signed with the same local
  key as Limine, and exposed as a Limine boot entry.
- The normal kernel package is
  `pkgs.cachyosKernels.linuxPackages-cachyos-bore-lto-zen4` from
  `xddxdd/nix-cachyos-kernel`.
- The graphics and desktop stage adds quiet boot and a custom unbranded,
  Gruvbox-themed Plymouth LUKS prompt and progress bar.
- Set `boot.loader.limine.maxGenerations = 6`; Limine exposes the current
  generation and five previous generations.
- Do not add a separate recovery specialization yet. Previous Limine
  generations and authenticated TTY login are the current recovery paths.

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
        ├── @games → /home/mvs/games
        ├── @nix → /nix
        └── @swap → /swap
```

`@games` contains Steam libraries, Prism Launcher instances, Minecraft worlds,
and other game data. This data has a separate backup method and no local
snapshot policy. The NixOS configuration checkout lives at `/etc/nixos`; other
projects remain under `~/projects` and use remote Git repositories for recovery.
No `cache`, `log`, `projects`, or snapshot subvolumes are created. The dedicated
swap subvolume isolates the Btrfs swapfile from normal compressed data.

LUKS2 uses the interactively entered passphrase, Argon2id key derivation,
AES-XTS-512, and discard propagation. Btrfs uses `noatime`; asynchronous discard
and the weekly `fstrim` timer maintain the SSD without a continuous synchronous
discard penalty. The printed high-entropy recovery key is the independent
recovery path.

Storage policy:

- Btrfs mounts use `compress=zstd:3` for normal data;
- no Snapper service or local filesystem snapshots;
- six NixOS system generations for system rollback;
- automatic Nix store optimization;
- weekly `nh clean all` that retains six generations in every profile and
  active direnv roots;
- explicit hibernation only when systemd-logind reports it as available.

Maintenance is automatic: run `fstrim` weekly, Btrfs scrub monthly, and Btrfs
device-stat plus NVMe health checks daily. Keep journald's default rotation.
Install `smartmontools` and `nvme-cli`, and monitor NVMe critical warnings,
available spare, percentage used, unsafe shutdowns, media and data-integrity
errors, temperature, error logs, self-tests, and firmware version. A newly
detected issue or low-free-space condition sends one Mako notification and
leaves a persistent Waybar warning until it is acknowledged or resolved.
Firmware checks never install an update automatically.

Keep Btrfs `autodefrag` disabled: it is not general maintenance and can reduce
reflink efficiency while increasing writes. Do not schedule defragmentation or
balance operations. Use either only as a targeted response to measured
trouble. The system should perform its routine maintenance without manual
intervention.

Memory pressure uses two swap tiers:

1. zstd zram with logical capacity equal to 100% of physical RAM and priority
   100;
2. a 32 GiB Btrfs swapfile inside LUKS with priority 10, matching physical RAM
   and comfortably exceeding Linux's default hibernation image limit of roughly
   two-fifths of available RAM.

systemd 261 discovers the active swapfile before hibernation, calculates its
Btrfs physical offset, and writes the device and offset to the
`HibernateLocation` EFI variable. The systemd-based initrd reads that variable
when booting, so this configuration does not pin a swapfile offset in kernel
parameters.

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
system uses Btrfs. OBS Studio's virtual-camera support loads v4l2loopback. The
NVIDIA modules are added only after the GPU is installed. Open NVIDIA modules
remain excluded. Binder and ADIOS stay compiled but inactive.

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

Live inspection confirmed MSI BIOS `1.A42` dated 2026-06-26 and Samsung 990 Pro
firmware `4B2QJXD7`. It did not establish whether newer vendor releases exist
because the live fwupd daemon was unavailable. Drivers are managed
declaratively by the pinned kernel, `linux-firmware`, and selected kernel
package set; do not install them imperatively.

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

The live CPU exposes 8 cores and 8 threads, so SMT is disabled or not exposed.
Do not change that policy until the user explicitly decides between the current
state and enabling SMT.

The CPU cooler is a Thermalright AXP90-X47. Stability testing is observational:
any failure stops the test, reports the evidence, and waits for user direction;
software never changes BIOS tuning in response. Optimize for maximum stable
performance per watt and temperature, with a bias toward performance rather
than minimum heat or noise.

Use the latest released CoolerControl package from `nixos-unstable`, not an
upstream-main build. Enable it with `programs.coolercontrol.enable = true` and
provide `lm_sensors` for direct terminal readings. The daemon starts at boot,
but the GUI opens only manually; do not autostart its GUI or tray. CoolerControl
has no official TUI. Bind its API and Web UI to loopback only at
`localhost:11987`, with no LAN or tailnet exposure.

NixOS owns the CoolerControl package and service. CoolerControl owns its mutable
calibration and profiles under encrypted root. Initially leave every fan
channel unmanaged so the BIOS remains in control until live calibration and an
explicit profile assignment. Use motherboard hwmon; add `liquidctl` only if a
supported USB cooling device is installed later. BIOS keeps independent safe
curves for pre-Linux boot, recovery, and service failure. Do not invent fan
percentages before calibration. Build performance-first curves from live
measurements; the user may later copy a proven runtime curve into BIOS manually.

## Gaming

- Steam enables the 32-bit graphics and audio stack.
- Nix exposes Proton-GE to Steam. Select it once as Steam's default
  compatibility runtime; declarative activation does not rewrite Steam's VDF
  state.
- MangoHud provides runtime metrics. GOverlay provides its interactive
  configuration editor; Home Manager does not own the complete MangoHud
  configuration. Home activation updates only the shared Stylix palette and
  typography keys in GOverlay's mutable MangoHud configuration.
- GameMode, Gamescope, and Protontricks are installed.
- Prism Launcher remains the Minecraft launcher.
- Steam libraries and all Prism Launcher data use `/home/mvs/games`.
- Add `/home/mvs/games/Steam` as a Steam library once through Steam's UI.
- The game subvolume has no local snapshots. Minecraft worlds use a separate
  backup method.
- Moonlight, Heroic, Lutris, UMU, Proton-CachyOS, and Wine-CachyOS are not
  installed initially.
- GPU-specific DLSS and shader-cache settings wait until the NVIDIA GPU is
  installed.

## Secrets

The base system has no machine-secrets framework or encrypted secret files.
The `mvs` password is entered interactively, and Wi-Fi, Tailscale, and
1Password authenticate interactively after installation. Their mutable state
stays below LUKS and never enters the repository or Nix store.

Add a runtime secrets mechanism only with the first real noninteractive
consumer. The private application monorepo uses SSH through the interactive
1Password agent; no GitHub token is stored in Nix configuration. Secure Boot
signing keys remain below encrypted root at `/var/lib/sbctl`. The normal
installation does not create an offline administrator-key USB. A high-entropy
LUKS recovery key is printed on paper.

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
- All language servers, formatters, linters, build tools, and language
  toolchains come from each project's Nix development shell. nvf only declares
  their command names and starts commands that exist on the project `PATH`.
- Preserve the current Mac's Gradle task UI, `uv.nvim` integration,
  project-scoped Biome, project-scoped OCaml language server and formatter,
  dotfile filetype support, `mini.hipatterns` hex previews, and the on-demand
  `StartupTime` diagnostic. The project Tailwind LSP and Neovim's native
  document-color support own Tailwind color previews.
- Snacks owns the dashboard, explorer, picker, and notifications. Alpha and
  Neo-tree are not installed.
- `mini.icons` owns icons and supplies its `nvim-web-devicons` compatibility
  shim.
- Conform owns format-on-save. LSP formatting is the fallback when a project
  formatter is unavailable.
- Each project supplies one diagnostic source for each language. Do not run the
  Biome LSP and Biome through nvim-lint at the same time. In projects with a
  Biome configuration, Biome also owns JSON diagnostics; the standalone JSON
  language server attaches only outside those projects.
- Smart-splits owns Neovim/tmux pane navigation and resizing. It loads eagerly
  so tmux can identify Neovim panes before the first navigation key.
- Do not transfer the obsolete `/tmp/nvim.sock` cleanup, Mason, or hardcoded
  macOS, Homebrew, Kotlin, and JDK paths.
- `amp.nvim` owns Amp agent interaction. Minuet provides Blink and virtual-text
  AI completion through
  `https://ai.mongoose-silverside.ts.net/v1/chat/completions`. The initial model
  is Minuet's OpenAI-compatible default, `deepseek/deepseek-v4-flash`, subject
  to validation against the authenticated LiteLLM model list. Streaming and the
  other Minuet completion defaults remain unchanged. The endpoint requires an
  API token. Minuet retrieves the item by UUID from 1Password's `credential`
  field on first use and caches it only in the Neovim process. The token does
  not enter the Nix store, process arguments, shell environment, or filesystem.
  Virtual-text suggestions trigger automatically after a short idle period.
  Blink exposes Minuet through a manual keybinding so that both interfaces do
  not request automatic completions concurrently. GitHub Copilot is excluded.
- Atuin history is local only; no Atuin account or sync credentials.
- Rootless Podman is the container engine.
- Lazydocker uses the Podman Docker-compatible socket where compatible.
- No global language toolchains; projects provide their own Nix development
  shells.
- CUPS, Syncthing, libvirt/QEMU, and unrequested network-sharing services are
  disabled initially.
- No incoming SSH or Mosh service is enabled. Mosh is the primary outbound
  interactive shell. OpenSSH remains available for Mosh bootstrap, Git, and
  noninteractive remote administration.
- No general local-data backup is configured initially. Projects use remote Git
  repositories, documents use cloud services, and Minecraft worlds use a
  separate backup method.

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
systemd-resolved owns DNS, uses Cloudflare DNS over TLS, and ignores DNS servers
offered through DHCP and IPv6 router advertisements. Tailscale is the only VPN.

Tailscale is installed declaratively but authenticated interactively after
first boot. Its mutable state remains below LUKS; no reusable Tailscale auth key
is stored in the repository.

The firewall defaults to denying inbound traffic. It trusts no physical or VPN
interface. It permits the Tailscale transport and LocalSend TCP port 53317 on
`tailscale0` only. LAN interfaces do not accept the LocalSend port. Tailscale
does not carry multicast discovery, so LocalSend peers use a Tailscale IP or
MagicDNS name. The LocalSend launcher requires an active Tailscale address and
rewrites only LocalSend's network whitelist before launch so discovery stays on
the tailnet while all other mutable preferences remain intact. No SSH or Mosh
port is open. CoolerControl remains loopback-only. Amp, Mosh, and OpenSSH make
outbound connections and need no inbound exception.

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
  not suspend automatically; suspend and hibernate are explicit desktop
  actions.
- hyprlock locks the existing session and authenticates wake.
- Explicit logout presents ReGreet under the small Cage compositor and requires
  the `mvs` password before starting another session.
- TTY login remains an independent recovery path and requires the `mvs`
  password.
- The account password authenticates hyprlock, ReGreet, and privileged actions.
- Passwordless sudo is not enabled on the physical PC.

After 5 minutes of inactivity, start the terminal screensaver. Stop it when
activity resumes. After 10 minutes of continuous inactivity, stop it and start
hyprlock. At 20 minutes, turn displays off while keeping the session locked. No
idle deadline suspends or hibernates the machine.

1Password system authentication allows Linux PAM authentication to unlock
1Password. It does not make 1Password an operating-system login or PAM
provider. Enable the 1Password GUI, CLI, browser integration, SSH agent, Git
signing integration, and required polkit policy. Initial sign-in remains
interactive. NixOS installs GNOME Keyring's package, D-Bus service, portal, and
required capability wrapper. Its standard graphical-session autostart owns the
sole daemon; Home Manager does not start a duplicate service.

Use official Hyprland ecosystem components where they directly fit, including
Hyprland, hypridle, hyprlock, hyprpolkitagent, and the Hyprland portal. Waybar,
Mako, Walker, Elephant, SwayOSD, swaybg, terminaltexteffects, and Kitty complete
the modular desktop. Do not install parallel launchers, provider backends,
notification daemons, bars, or wallpaper daemons.

## Interaction and keybindings

- Tapping `Super` opens wlr-which-key. Holding or using `Super` as a modifier
  preserves the direct Hyprland shortcuts.
- `Super+Space` opens Walker.
- `Super+Alt+Space` opens the searchable Walker desktop menu.
- `Super+W` closes the active window.
- `Super+Return` opens Kitty.
- `Super+L` starts hyprlock.
- `Print` starts region capture and offers Satty editing.
- Hardware media keys use SwayOSD.
- An empty Walker desktop-menu query shows only `Apps`, `Trigger`, `Appearance`,
  `Setup`, `Packages`, `About`, and `System`. A non-empty root query searches the
  complete tree and directly executes a selected leaf.
- The Walker desktop menu opens Nixpkgs package search in an Omarchy-sized
  875×600 modal Kitty window. Explicit selections install into or remove from
  the user's Nix profile; the core system remains declarative.
- Configuration actions start Neovim through direnv at `/etc/nixos`, so the
  repository dev shell supplies editor tooling without global toolchains.
- wlr-which-key mirrors the direct Super shortcuts after a completed Super tap;
  it does not own desktop actions or settings.
- Hardware media keys and recovery-critical bindings remain direct.

## Theme and bar

- Stylix is the shared palette source.
- Use Gruvbox Dark Hard throughout the desktop.
- Use no logo, name, or custom branding.
- Recolor Omarchy's pinned Flexoki Light `1-orb.png` composition into the
  Gruvbox Dark Hard background and foreground colors at build time. swaybg owns
  the result; no other wallpaper service runs concurrently.
- Preserve square geometry and the classic Omarchy shadow and animation
  treatment.

The desktop pins Omarchy commit
`a7f8f2495f4990044b7791d8f11a32cf14d34b39` as a frozen visual-asset source,
not an update source. Walker menu behavior follows the last pre-Quickshell
Walker/Elephant commit, `7fe472bf8ab3efe8c2a7470a285aad87dea9052f`.
Only selected visual language and explicitly chosen menu behavior are carried
over. Bindings and feature policy remain local. Local substitutions are Kitty
for Alacritty and hyprpolkitagent for polkit-gnome.

Confirmed placement:

```text
left:   desktop menu, workspaces
center: empty
right:  tray drawer, Bluetooth, network, audio, CPU, clock and date
```

The tray remains collapsed until requested. Network, Bluetooth, audio, and CPU
widgets open Impala, Bluetui, WireMix, and btop in one consistently floating,
centered 875×600 Kitty class. The Bluetooth entry remains visible when no
controller is detected so Bluetui is still reachable. There are no weather,
keyboard-layout, agent, or duplicate power widgets.

Elephant's clipboard provider owns clipboard history and Walker presents it.
Cliphist is not enabled because a second watcher and history store would be
duplicate infrastructure. Hyprland translates `Super+C`, `Super+V`, and
`Super+X` into application clipboard shortcuts. Copy and paste use the
terminal-safe `Ctrl+Insert` and `Shift+Insert` alternatives, which Kitty handles
without interrupting the foreground process.

Update state is checked by a lightweight user timer two minutes after boot and
every six hours thereafter. It detects active `renovate/*` branch revisions and
compares `master` with the Git revision embedded in the running system. Waybar
shows the state and Mako sends at most one notification per branch SHA.
Clicking the module opens a floating Kitty window with GitHub-provided diffs.
After explicit confirmation, the tool can fast-forward a clean `/etc/nixos`
`master` checkout to the inspected revision and run `nh os switch`. It never
merges a Renovate branch, and nothing auto-merges or switches.

## Git identity

There is no global author identity or signing key. Set
`user.useConfigOnly=true`. The configured Git executable selects identity from
the owner in `remote.origin.url` on every invocation. A repository without an
origin is local and defaults to the main profile. Other remotes do not
participate; an unrecognized nonempty origin remains unset and fails safely.

GitHub CLI clones over SSH so Git and GitHub CLI share the 1Password SSH agent.
The private flake input uses the same path. `SSH_AUTH_SOCK` and OpenSSH's
`IdentityAgent` both point to that agent. Run `nh` as the login user so the
fetch inherits this authentication context; `nh` elevates activation itself.

| Profile   | Author                                                           |
| --------- | ---------------------------------------------------------------- |
| Main      | `Anshul Noori <anshulnoori+github@gmail.com>`                    |
| Alternate | `Mervs <246713988+maroonverticalshape@users.noreply.github.com>` |

Both profiles sign commits and tags with profile-specific 1Password SSH keys.
Their public keys also form Git's local allowed-signers file so signatures can
be verified locally. Repositories with unknown remotes fail until assigned a
local profile. `gh auth switch` changes GitHub API credentials only and does not
select commit authorship.

Shared behavior:

- default branch `main`;
- rebase pulls;
- automatic upstream setup on first push;
- histogram diff and moved-line highlighting;
- `zdiff3` conflict presentation;
- rerere with autoupdate;
- Delta side-by-side Gruvbox output;
- Neovim editor;
- aliases `co`, `br`, `ci`, and `st`.

## First-boot gate

With Secure Boot still disabled, collect concrete evidence for every item
before enrolling firmware keys:

- the typed LUKS unlock and encrypted-root boundary;
- current and previous-generation Limine entries;
- Lix nightly as the normal package manager;
- the selected CachyOS BORE ThinLTO `zen4` kernel;
- AMD P-state in active EPP mode with the confirmed performance policy;
- the expected Btrfs subvolume mounts, zram, and encrypted swapfile;
- primary Ethernet, DNS resolution, and the optional Wi-Fi fallback;
- integrated graphics and audio hardware detection;
- default-deny firewall state; and
- absence of incoming SSH and Mosh listeners.

Also validate Plymouth, graphical automatic login, explicit logout
authentication, hyprlock, and audio services. Secure Boot enrollment remains
the final stage and follows [its dedicated runbook](./secure-boot.md), including
post-enrollment verification of normal boots, rollback, and Memtest86+.

## Remaining physical facts

- official latest-version status for the BIOS, SSD, and other fwupd devices;
- the motherboard Super-I/O driver, if one is exposed after installation;
- authenticated validation that the LiteLLM endpoint exposes Minuet's selected
  model alias; and
- concrete evidence from the first-boot checks.

Remote game-server deployment is outside this system's scope.
