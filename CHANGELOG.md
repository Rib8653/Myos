# RibOS changelog

## Stage 1: minimal bootable ISO
- live-build config tree (`auto/config`, `auto/build`, `auto/clean`) for
  Debian 13 "trixie", amd64, with main/contrib/non-free/non-free-firmware.
- Hybrid ISO that boots on UEFI (GRUB) and legacy BIOS (isolinux).
- HTTPS mirrors throughout, plus `build.sh` passes the host's proxy settings
  into the build chroot (`config/environment.chroot`, never shipped).
- Base packages (live-boot/config, NetworkManager, sudo, locales) and a
  firmware list for common Wi-Fi, GPU, sound and Bluetooth chips.
- `build.sh` (clean build) and `test.sh` (QEMU UEFI/BIOS launcher).
- Verified: ISO (780 MB) boots in QEMU under UEFI to an auto-logged-in console
  and shows the isolinux menu under legacy BIOS.
