# Secure Boot

The `t1` configuration uses NixOS's native Limine Secure Boot support. It
automatically creates local `sbctl` keys under encrypted root, signs Limine,
checks every kernel and initrd, and signs Memtest86+ and fwupd's EFI app. It does
not use Lanzaboote or shim.

Only firmware enrollment is manual. Firmware keys are a machine security
boundary, so that one-time step must stay explicit.

## 1. Install and verify signatures

Keep Secure Boot disabled while installing and testing the system. The first
bootloader installation creates `/var/lib/sbctl` automatically. Do not copy or
regenerate these keys.

After `t1` passes its first-boot checks, install the latest boot generation and
verify both EFI applications:

```sh
cd /etc/nixos
sudo nixos-rebuild boot --flake .#t1
sudo verify-signed-efi /boot/efi/limine/BOOTX64.EFI
sudo verify-signed-efi /boot/efi/memtest86/memtest.efi
```

Stop if either verification fails.

## 2. Back up and verify the firmware keys

Before deleting any firmware variables, verify that `sbctl` can identify the
firmware-default certificates and export the currently enrolled keys:

```sh
sudo sbctl status
sudo sbctl export-enrolled-keys \
  --dir /root/secure-boot-firmware-keys \
  --format der
sudo sh -c 'test -n "$(ls -A /root/secure-boot-firmware-keys/DB)"'
sudo sh -c 'test -n "$(ls -A /root/secure-boot-firmware-keys/KEK)"'
```

The `Vendor Keys` line must include both `builtin-db` and `builtin-KEK`. Keep
the exported backup until Secure Boot and every required device work. Stop here
if either marker or either exported key set is missing. On such firmware,
`--firmware-builtin` can succeed without adding the missing certificates, so do
not reset the keys until the required OEM certificates have been identified.

## 3. Put the firmware in Setup Mode

```sh
systemctl reboot --firmware-setup
```

In MSI Click BIOS X:

1. Open **Settings → Security → Secure Boot**.
2. Set **Secure Boot Mode** to **Custom**.
3. Set **Secure Boot Preset** to **Maximum Security**.
4. Disable **Provision Factory Default Keys**.
5. Select **Reset to Setup Mode**. If unavailable, select **Delete all Secure
   Boot variables**.
6. Save and boot NixOS with Secure Boot still disabled.

Confirm that `sudo sbctl status` reports Setup Mode enabled.

Recheck the firmware-default variables after the reset:

```sh
sudo sh -eu -c '
  for name in dbDefault KEKDefault; do
    found=false
    for variable in /sys/firmware/efi/efivars/"$name"-*; do
      [ -f "$variable" ] || continue
      [ "$(stat -c %s "$variable")" -gt 4 ] || continue
      found=true
      break
    done
    if [ "$found" != true ]; then
      echo "$name is unavailable after the firmware reset" >&2
      exit 1
    fi
  done
'
```

Stop if this command fails. The four-byte size threshold excludes an EFI
variable that contains attributes but no certificate data.

## 4. Enroll once and enable

Enroll the local keys with Microsoft's certificates and the firmware-default
certificates verified in the previous step:

```sh
sudo sbctl enroll-keys --microsoft --firmware-builtin
sudo sbctl list-enrolled-keys
systemctl reboot --firmware-setup
```

In firmware, keep **Custom** and **Maximum Security**, enable **Secure Boot**,
and save. Then verify the active state:

```sh
bootctl status
sudo sbctl status
sudo verify-signed-efi /boot/efi/limine/BOOTX64.EFI
sudo verify-signed-efi /boot/efi/memtest86/memtest.efi
```

`bootctl` must report Secure Boot enabled. `sbctl` must report Secure Boot
enabled and Setup Mode disabled.

Finally, boot the Memtest86+ entry and one previous NixOS generation once. Both
must start without a Secure Boot violation.

## Recovery

If a boot is rejected, disable Secure Boot without restoring factory keys. Boot
NixOS, run `sudo nixos-rebuild boot --flake /etc/nixos#t1`, and repeat both
signature checks before enabling Secure Boot again.

If `/var/lib/sbctl` is lost, disable Secure Boot, return to Setup Mode, rebuild
once to create new keys, enroll them, and then enable Secure Boot.
