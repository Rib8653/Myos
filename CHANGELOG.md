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

## Stage 2: KDE Plasma desktop and default apps
- `desktop.list.chroot`: Plasma 6 (Wayland default, X11 session available),
  SDDM, NetworkManager/PipeWire/Bluetooth/power applets, Inter and Noto
  fonts, CUPS printing (Gutenprint, HPLIP, IPP-over-USB, print-manager),
  scanning, Plymouth.
- `apps.list.chroot`: Firefox ESR, LibreOffice (KDE integration), VLC,
  Dolphin, Konsole, Kate, Ark, Gwenview, Okular, KCalc, Spectacle,
  Discover with the Flatpak backend.
- Checked every package name against the trixie archive before building.
- Verified: ISO (2.6 GB) boots under UEFI in QEMU straight into a Plasma
  session for the live user.
