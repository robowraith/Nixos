# Install dumont (Dell Wyse 3040)

Prereq: `secrets/dumont.yaml` complete (change task 4.2), repo clean, run from the flake root on a desktop.
No MACs/passwords in this file.

## 1. Wyse BIOS / USB boot
- F2 at power-on: enable USB boot, boot mode UEFI, Secure Boot off.
- F12 boot menu: pick the NixOS minimal ISO stick.
- Only EFI fallback path is expected to boot (systemd-boot installs `EFI/BOOT/BOOTX64.EFI`); verify at first boot.

## 2. Installer: enable SSH
On the Wyse console (user `nixos`, already root-capable):
```
sudo passwd root            # temporary password, installer only
ip -4 addr show             # note the installer IP (DHCP)
dmesg | grep -i firmware    # note missing firmware (only rtl_nic + i915 shipped)
lsblk                       # confirm eMMC is /dev/mmcblk0
```
The minimal ISO runs sshd already.

## 3. Stage the host key from sops
```
d=$(mktemp -d)
install -d -m 755 $d/etc/ssh
sudo SOPS_AGE_KEY_FILE=/var/lib/sops/age/keys.txt sops -d --extract '["ssh_host_ed25519_key"]' secrets/dumont.yaml > $d/etc/ssh/ssh_host_ed25519_key
cp system/hosts/dumont/ssh_host_ed25519_key.pub $d/etc/ssh/
chmod 600 $d/etc/ssh/ssh_host_ed25519_key
```

## 4. Install (kexec skipped, installer already booted)
```
nix run github:nix-community/nixos-anywhere -- \
  --flake .#dumont \
  --phases disko,install,reboot \
  --extra-files $d \
  --generate-hardware-config nixos-generate-config ./system/hosts/dumont/hardware-configuration.nix \
  --build-on local \
  root@<installer-ip>
```
- Enter the root password from step 2 when asked (or `--env-password` with `SSHPASS`).
- `--generate-hardware-config` overwrites the placeholder: review `git diff`, commit it.
- Remove USB stick when it reboots.

## 5. Cleanup
`shred -u $d/etc/ssh/ssh_host_ed25519_key; rm -rf $d`

## 6. First-boot checks
- `ssh yori@192.168.1.2` (host key pinned to the `.pub` in the repo)
- `ls /run/secrets`; no `/var/lib/sops/age/keys.txt`
- `df -h / /boot`
- `systemctl is-active pihole-ftl`
- then task 7.2 checks (dig, web UI).
