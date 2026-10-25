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

## Stage 3: Windows-style desktop defaults
- RibOS global theme (`org.ribos.desktop`, plus a dark variant) whose layout
  script builds one full-width bottom panel: centered start button + pinned
  apps (two expanding spacers), dark-mode toggle, system tray, clock with
  date below, "show desktop" sliver at the far right. Non-floating.
- Start menu (Kickoff) with the RibOS logo, search, pinned-apps grid and
  power buttons. Pins are set in `/usr/share/ribos/set-start-menu-pins`
  (Kickoff copies its built-in defaults before a layout script can change
  them, so the default itself is edited at build time and after apt runs).
- `/etc/xdg`: Breeze light, accent colour, Inter UI font, double-click to
  open, minimize/maximize/close on the right, double-click title to
  maximize, snap to edges and corners, Alt+Tab thumbnail grid, Firefox as
  default browser.
- `/etc/skel`: Recycle Bin and Home desktop icons, Windows-style shortcuts
  (Super, Super+E/D/L/I, Super+arrows, Ctrl+Shift+Esc, Print,
  Super+Shift+S, Ctrl+Alt+T).
- Dark-mode toggle: `ribos-theme` script, panel button and menu entry;
  the RibOS wallpaper has a dark variant that switches automatically.
- Original wallpaper, start button and logo rendered from `branding/src`.
- Tested in QEMU: layout, desktop icons, start menu, Ctrl+Shift+Esc,
  Super+E and the light/dark switch work. Fixed afterwards: start-menu pins
  (were Kickoff's defaults), zero-width dark-mode button, Konqueror being
  picked as the browser.
- `test.sh`: without KVM, emulate a CPU without AVX. With QEMU's emulated
  AVX, Mesa's software renderer crashed plasmashell.

## Stage 4: RibOS branding
- Original artwork only (`branding/src/*.svg`, CC0): ribbon-"R" logo,
  light/dark ribbon wallpaper, boot menu background, Plymouth logo,
  installer slides. `branding/render.sh` turns them into PNGs.
- Boot menus: custom GRUB (UEFI) theme and grub.cfg ("Try or install
  RibOS", safe graphics, fail-safe, utilities) and matching isolinux (BIOS)
  menu, both with a 5 s timeout.
- Plymouth: `ribos` script theme with the logo, an animated progress bar
  and an encrypted-disk password prompt. Set as default; initramfs rebuilt.
- `/etc/os-release` says RibOS (`ID=ribos`, `ID_LIKE=debian`). Debian's
  copy is diverted so base-files upgrades don't undo it. Plasma's Welcome
  Center and "About this System" pick this up.
- Installed systems: GRUB distributor "RibOS", `quiet splash`.
- Flathub enabled system-wide at build time (Discover sees it immediately).
- Global theme preview images taken from real screenshots.
- Live session only (live-config component): no automatic screen lock or
  suspend, since the live password isn't obvious.
- Dark-mode button rewritten after it didn't show on the panel; it now
  follows the structure of Plasma's own "Show Desktop" button.
