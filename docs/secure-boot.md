# Secure Boot

The `t1` configuration uses native NixOS Limine Secure Boot support. It uses
local `sbctl` keys under encrypted root to sign Limine, Memtest86+, and the fwupd
EFI app. Limine verifies the configuration, kernel, and initrd hashes before
boot. Configuration editing is disabled, and checksum failures stop boot.
It does not use Lanzaboote or shim.

Installation verifies the Limine signature against the local certificate and
compares its embedded configuration hash with the installed configuration.
These checks do not prove that firmware trusts the certificate or enforces
Secure Boot. A successful boot with Secure Boot enabled is still required.

Initial key creation and firmware enrollment are manual. Later rebuilds reuse
the existing keys. Firmware enrollment must remain an explicit action.

## 1. Install and verify signatures

Keep Secure Boot disabled during installation and initial tests. Automatic key
generation is disabled, so missing keys cause installation to fail.

On a new machine without existing keys or a backup, create keys once with
`sudo sbctl create-keys`. On an existing installation, preserve the keys in
`/var/lib/sbctl`. Do not regenerate them. If keys are lost, restore the backup
before a rebuild.

After `t1` passes its first-boot checks, install the latest boot generation and
verify both EFI applications:

```sh
nh os switch /etc/nixos
sudo verify-signed-efi /boot/efi/limine/BOOTX64.EFI /boot/limine/limine.conf
sudo verify-signed-efi /boot/efi/memtest86/memtest.efi
```

Stop if either verification fails.

## 2. Back up and verify the firmware keys

Back up the entire `/var/lib/sbctl` directory to an encrypted external drive.
An encrypted off-machine backup is also suitable. A second copy on the same
disk does not protect against disk failure.

The backup must preserve private keys, certificates, the owner GUID, databases,
ownership, and permissions. Never put private keys in Git or an unencrypted
cloud folder. Anyone with the private signing key can sign trusted boot files.

After mounting an encrypted drive, replace the example destination with its
actual mount path:

```sh
sudo tar --acls --xattrs -C /var/lib -cpf /path/to/encrypted-drive/t1-sbctl.tar sbctl
sudo tar --acls --xattrs -C /var/lib -df /path/to/encrypted-drive/t1-sbctl.tar
```

Stop if the comparison reports differences. Test extraction into a separate
directory on the encrypted drive before relying on the backup. Keep the drive
unlock credentials somewhere accessible without this computer.

The firmware export below contains public certificates, not the private keys
needed for future signing. Keep this export with the private-key backup.

Before firmware changes, prepare a recovery USB and verify the LUKS unlock
passphrase. Recovery must not depend on a working installed bootloader.

Before deleting any firmware variables, verify that `sbctl` can identify the
firmware-default certificates and export the currently enrolled keys:

```sh
sudo sbctl status
sudo sbctl --disable-landlock export-enrolled-keys \
  --dir /root/secure-boot-firmware-keys \
  --format der
sudo sh -c 'test -n "$(ls -A /root/secure-boot-firmware-keys/DB)"'
sudo sh -c 'test -n "$(ls -A /root/secure-boot-firmware-keys/KEK)"'
```

The destination must not already exist. In sbctl 0.18, Landlock prevents this
command from creating its destination. The flag disables Landlock for this
export only, not for signing or other commands.

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
sudo verify-signed-efi /boot/efi/limine/BOOTX64.EFI /boot/limine/limine.conf
sudo verify-signed-efi /boot/efi/memtest86/memtest.efi
```

`bootctl` must report Secure Boot enabled. `sbctl` must report Secure Boot
enabled and Setup Mode disabled.

Finally, boot the Memtest86+ entry and one previous NixOS generation once. Both
must start without a Secure Boot violation.

Microsoft and firmware-default certificates preserve compatibility with device
firmware and recovery media. They also permit boot files signed by those
authorities, not only your own key.

A firmware reset can clear the `dbx` revocation database. After enrollment,
inspect available UEFI revocation updates with `fwupdmgr get-updates`.
Review their recovery-media requirements before installation.

## Recovery

If a boot is rejected, disable Secure Boot without restoring factory keys. Boot
NixOS, run `sudo nixos-rebuild boot --flake /etc/nixos#t1`, and repeat both
signature checks before enabling Secure Boot again.

If `/var/lib/sbctl` is lost, restore its backup with ownership and permissions
preserved before a rebuild. Existing firmware enrollment then remains valid.

Without a usable backup, disable Secure Boot and explicitly create replacement
keys. Rebuild and verify signatures, then repeat enrollment in Setup Mode.
Replacement keys require new backups. Do not reset firmware keys merely because
one boot file fails verification.
