# PC live Amp runner bootstrap

This runbook brings the physical `t1` PC online as an Amp runner from a live
NixOS environment. It does not partition, format, encrypt, mount, or otherwise
write to an internal disk, and it does not write firmware. The user reports the
new target SSD is empty, but this workflow has neither performed nor authorized
a destructive disk action.

The installation is staged because a live runner stops when the machine
reboots:

1. inspect hardware, firmware, drivers, interfaces, and disks read-only;
2. present the exact destructive disk plan and obtain fresh approval;
3. install the encrypted base system;
4. validate the base system's first boot with Secure Boot disabled;
5. activate Plymouth and the full desktop, add its recovery specialization,
   and validate them;
6. enroll and verify Secure Boot.

This runbook provides commands only through starting the outbound live Amp
runner. Its later sections record handoff and reboot safety boundaries. It
contains no partitioning, installation, Secure Boot enrollment, or
firmware-write command.

## 1. Prepare live media

The current stable installer is NixOS 26.05:

- ISO:
  <https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso>
- SHA-256:
  <https://channels.nixos.org/nixos-26.05/latest-nixos-minimal-x86_64-linux.iso.sha256>

Download both files on the Mac. Verify the ISO before writing it:

```sh
cd "$HOME/Downloads"
expected="$(cut -d ' ' -f 1 latest-nixos-minimal-x86_64-linux.iso.sha256)"
actual="$(shasum -a 256 latest-nixos-minimal-x86_64-linux.iso | cut -d ' ' -f 1)"
test "$actual" = "$expected" && echo 'checksum OK'
```

If `checksum OK` is not printed, stop and download both files again. Flash the
verified ISO with Balena Etcher. Confirm that Etcher selected the removable USB
by matching its capacity before starting the write.

Use wired Ethernet as the primary installation network. Wi-Fi remains a
fallback and can be configured interactively from the live shell with `iwctl`
if necessary.

The official ISO is not Secure Boot signed. Temporarily disable Secure Boot to
boot it, but keep UEFI mode enabled. This exception is only for the installer;
the completed system must enforce Secure Boot. Do not clear or replace firmware
keys yet. The exact Limine enrollment sequence must be reviewed before changing
firmware key state.

Boot the USB in UEFI mode. Do not start an installer or modify partitions.
Verify the boot mode, Secure Boot state, and network:

```sh
test -d /sys/firmware/efi/efivars && echo UEFI
bootctl status
ip link
ping -c 3 ampcode.com
```

If the firmware refuses the standard NixOS image, stop and resolve the Secure
Boot decision rather than changing firmware security settings silently.

## 2. Enter the pinned installer environment

The official live ISO uses CppNix. Keep it for the temporary live environment;
a custom installer image is not required. The target flake imports pinned Lix
nightly, so only the installed system switches to Lix.

Obtain the repository with the live ISO's nixpkgs Git package. For a new
checkout, run:

```sh
mkdir -p "$HOME/.config"
nix --extra-experimental-features 'nix-command flakes' \
  shell nixpkgs#git --command \
  git clone https://github.com/anshulnoori/nixconf.git \
  "$HOME/.config/nixos"
```

If the bootstrap checkout already exists, update it instead:

```sh
nix --extra-experimental-features 'nix-command flakes' \
  shell nixpkgs#git --command \
  git -C "$HOME/.config/nixos" pull --ff-only
```

Enter the repository's temporary installer shell. It contains the pinned Amp
release, transfer tools, network diagnostics, pager, and read-only hardware and
firmware inspection tools:

```sh
cd "$HOME/.config/nixos"
NIXPKGS_ALLOW_UNFREE=1 nix \
  --extra-experimental-features 'nix-command flakes' \
  develop --impure .#installer
```

Keep this shell open through the live inspection and runner bootstrap. If it is
closed, return to the checkout and run the same `NIXPKGS_ALLOW_UNFREE=1 nix
develop --impure .#installer` command; the flake and its lock remain unchanged.

Collect read-only inventory before preparing any installation plan:

```sh
uname -a
lspci -nnk
lsusb
sudo dmidecode -s bios-vendor
sudo dmidecode -s bios-version
sudo dmidecode -s bios-release-date
sudo dmidecode --type baseboard --type memory
lsblk -e 7 -o NAME,PATH,SIZE,TYPE,FSTYPE,MODEL,SERIAL,WWN,MOUNTPOINTS
ip -brief link
sudo nvme list
sudo smartctl --scan-open
sudo fwupdmgr get-devices
sudo fwupdmgr get-updates
sensors
```

The BIOS was already updated by the user; these commands only verify its
reported version. `lspci -nnk` records active kernel drivers and candidate
modules. `sensors` may have limited output until the installed system loads the
detected motherboard modules. If `fwupdmgr` cannot connect to its daemon in the
live image, record that check for the installed system rather than changing the
live image.

After identifying the Samsung controller with `nvme list`, replace
`/dev/nvmeX` below with its controller path and read its identity, firmware, and
health data:

```sh
sudo nvme id-ctrl /dev/nvmeX
sudo nvme smart-log /dev/nvmeX
sudo smartctl -x /dev/nvmeX
```

Do not run `fwupdmgr update`, any `nvme fw-*` command, or any other firmware
write. A firmware write requires the exact official artifact, current and
target versions, checksum, procedure, and risks, followed by fresh user
approval. Target drivers come declaratively from the pinned kernel and
`linux-firmware`; do not install drivers imperatively in the live environment.

## 3. Start the outbound Amp runner

The temporary development shell provides the exact Amp release and source hash
pinned by the repository flake instead of the live ISO's older nixpkgs package.

Confirm both the version and runner option before authenticating:

```sh
amp --version
amp --help | grep -- --no-tui
```

The installed system and a verified current checkout use the same package as
`nix shell .#amp-cli`. Updating Amp requires changing the pinned version and
both platform hashes in `flake.nix`; no package updates itself imperatively.

Use the tracked two-device wizard to authenticate without typing a long token,
copying through a text-only console, or persisting an API key. Start the Mac
side first so Magic Wormhole and its dependencies are ready before Amp creates
the short-lived login URL:

```sh
nix --extra-experimental-features 'nix-command flakes' \
  shell nixpkgs#magic-wormhole --command \
  ./scripts/amp-login-wizard.sh mac
```

Leave it waiting for a Wormhole code. On `t1`, from the installer shell, run:

```sh
./scripts/amp-login-wizard.sh t1
```

The `t1` wizard starts a fresh `amp login`, sends its exact URL through a
four-word Magic Wormhole exchange, and waits for the return code. Enter the
codes shown by each wizard on the other device. The Mac asks for the Amp code
through hidden input. The `t1` wizard sends that code directly to the same Amp
process that created the URL; it does not use tmux scrollback or paste buffers.
Authentication and configuration in the live environment disappear when it
reboots.

After signing in, start a detachable terminal:

```sh
tmux new -s amp-installer
```

Inside tmux, return to the bootstrap repository and start a stable named runner:

```sh
cd "$HOME/.config/nixos"
amp --no-tui \
  --runner-id t1-installer \
  --remote-control-terminal
```

Amp's official runner documentation defines `--no-tui` as runner-only mode and
`--remote-control-terminal` as permission to access its terminal remotely. The
runner ID is deliberately stable and hostname-safe.

Detach with `Ctrl+B`, then `D`. Do not shut down, reboot, suspend, close the
shell containing Amp, or remove the live USB while work is running.

## 4. Establish the clean successor thread

Once `t1-installer` appears online:

1. verify the checkout commit, `git status`, and document hashes against the
   pushed source;
2. create a new runner thread whose prompt contains only this repository's
   sanitized current design documents;
3. inspect hardware, firmware, active drivers, interfaces, and disks read-only;
4. present the exact destructive plan and require explicit user confirmation;
5. only then partition and install.

The live installer user has broad local privileges. A remotely controllable Amp
runner therefore has the same effective installation authority. Keep the runner
connected only while actively installing and do not share access to the Amp
account or thread.

## 5. Reboot boundary

Before rebooting, the installation thread must:

- commit or otherwise preserve all intended configuration changes;
- set the `mvs` password interactively inside the installed system and verify
  that direct root login remains disabled;
- ensure `amp-cli`, Git, networking, the outbound OpenSSH client, and the
  repository checkout are available in the installed system;
- verify that no incoming SSH or Mosh service is enabled;
- record validation results and any remaining manual action;
- stop before reboot and ask the user to perform the reboot.

After the installed system reaches the initial `mvs` session, open the
repository and start a new runner process:

```sh
cd "$HOME/.config/nixos"
amp --no-tui --runner-id t1 --remote-control-terminal
```

The post-install thread follows the base-gate checklist in `system-design.md`:
LUKS, Limine generations, Lix nightly, the CachyOS kernel, AMD P-state, mounts,
zram and swap, Ethernet and DNS, integrated graphics and audio hardware,
firewall state, and the absence of SSH and Mosh listeners. Plymouth, automatic
login, lock behavior, and a standard-kernel recovery specialization belong to
the later desktop and login stage. Secure Boot stays disabled through both
stages. Enrollment and active-state verification come last.
