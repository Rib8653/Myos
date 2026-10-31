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

## Stage 5: Calamares installer
- `installer.list.chroot`: Calamares with Debian's `calamares-settings-debian`
  (its module sequence and helpers), plus `efibootmgr`.
- RibOS overrides: `branding: ribos` in `settings.conf`, branding
  (`branding.desc`, logo, welcome image, 4-slide slideshow), "Install
  RibOS" launcher (auto-copied to the live desktop), `packages.conf` also
  removes Calamares from the installed system, and `calamares-sources-final`
  writes deb822 sources with contrib/non-free/non-free-firmware over HTTPS.
- `installer-efi.list.binary` / `installer-bios.list.binary`: GRUB (UEFI,
  signed shim, and BIOS) plus cryptsetup go into a package pool on the ISO,
  so installing works offline. Two lists, because grub-pc and grub-efi
  conflict.
- `build.sh` now also checks for `apt-ftparchive` (apt-utils), which
  live-build needs to index that pool.
- Verified in QEMU (UEFI): the live desktop shows the RibOS installer, and
  an "Erase disk" install to a blank 32 GB disk ran all 41 jobs (partition,
  unpack, GRUB from the ISO pool, package cleanup, initramfs).
- Slideshow images now scale to fit above their captions (the first layout
  pushed the captions off-screen).

## GitHub Actions build
- `.github/workflows/build-iso.yml`: builds the ISO on an Ubuntu runner
  (manual "Run workflow" or a `v*` tag) and publishes it as a GitHub Release,
  split into parts under 2 GB plus a SHA-256 file, with joining instructions
  for macOS, Linux and Windows. Uploads `build.log` if the build fails.
- `ci/install-live-build.sh`: installs Debian trixie's current live-build,
  debootstrap and archive keyring on Ubuntu hosts (Ubuntu's live-build is
  too old).
- Fixed `build.sh` writing an empty `config/environment.chroot` on hosts
  without a proxy; live-build's grep of that file aborted the first
  GitHub build. The second run built and published the ISO in ~33 minutes.

## arm64 build
- `build.sh --arch arm64` (or `RIBOS_ARCH=arm64`) builds an arm64 ISO.
  `auto/config` picks GRUB EFI only for arm64 (Arm machines have no BIOS)
  and adds live-build's QEMU options automatically when cross-building.
- Package lists use live-build `#if ARCHITECTURE` blocks for the x86-only
  packages (Intel/AMD microcode, grub-pc, grub-efi-amd64*) and the arm64
  GRUB packages. Every other package exists on both architectures (checked
  against the trixie arm64 index).
- GRUB `config.cfg` only loads the PC-only video modules on x86.
- `build.sh` clears the package cache when the architecture changes.
- `test.sh --arm64` boots the arm64 ISO on QEMU's Arm `virt` machine with
  UEFI firmware; virtual disks are kept per architecture under `test/`.
- GitHub workflow: architecture choice (both/amd64/arm64), arm64 builds
  natively on `ubuntu-24.04-arm`, and both ISOs go into one release.
- README: arm64 build notes and a UTM-on-Mac guide; corrected the live
  password (it's `live`).

## Windows 11 style start menu and icons
- New start menu widget `org.ribos.startmenu` (QML, built on the same KDE
  models as Kickoff) replacing Kickoff on the taskbar: search box on top
  ("Search for apps, settings and documents"), a 6-column **Pinned** grid,
  **All apps** A–Z list, **Recommended** recent files, and a footer with the
  user's avatar/name (opens account settings) and a power flyout (Lock, Sign
  out, Sleep, Restart, Shut down). Type anywhere to search, Enter opens the
  best match, Esc goes back/closes, right-click to pin/unpin. The Super key
  still opens it.
- Default pins now live in the widget's own config (`main.xml`), so the
  Kickoff workaround (build hook + apt hook editing Kickoff's defaults) is
  gone.
- Icons: the Fluent icon theme (GPL-3.0, Windows 11 "Fluent" style), fetched
  by `build.sh` at a pinned commit and built by
  `branding/install-fluent-icons.sh` into `Fluent-light` (default) and
  `Fluent-dark`, with yellow folders. The dark-mode toggle switches between
  them. Fluent's Windows logo (`start-here`) and Microsoft product logos are
  removed at build time.
- LibreOffice defaults to its Colibre icon style.
- Tested the start menu (pinned grid, All apps, search, power flyout, light
  and dark icons) by running it on a virtual X display inside the build chroot.

## Windows-style mouse cursor and smoother pointer
- Cursor: Fluent's white cursor set (white arrow with a dark outline, blue
  spinning busy ring, like Windows 11), installed as `Fluent-white-cursors` by
  `branding/install-fluent-icons.sh`, size 30 (Windows uses 32). Set for
  Plasma (`/etc/xdg/kcminputrc`, both global themes), the login screen
  (`/etc/sddm.conf.d/10-ribos.conf`, which also pins the Breeze SDDM theme)
  and X11/GTK apps (Debian's `x-cursor-theme` alternative, set by a hook).
- Smoothness: Firefox uses momentum ("msd physics") smooth scrolling like on
  Windows; `spice-vdagent` and `qemu-guest-agent` added so the pointer,
  clipboard and screen size work smoothly in UTM/QEMU/Proxmox; README tells
  UTM users to pick the accelerated `virtio-gpu-gl-pci` display. Pointer
  acceleration stays at libinput's "adaptive" default, which behaves like
  Windows' "Enhance pointer precision".
- Start button icon is now drawn at the same size as the taskbar's app icons.

## Windows programs with Wine
- amd64: Wine 10 preinstalled (64-bit `wine64` plus 32-bit `wine32:i386`, which
  most installers need; a hook enables Debian's i386 architecture), with
  `fonts-wine` and `winetricks`.
- Double-clicking a `.exe`, `.msi` or `.lnk` runs it: `/usr/bin/ribos-run-windows-app`
  is the default app for all Windows executable MIME types (`wine start`, or
  `msiexec /i` for installers) and shows a "first start takes a minute" notice
  while Wine sets up `~/.wine`. Installed Windows apps appear in the start menu.
- arm64: Debian's Wine there can only run Windows-on-Arm programs, so it isn't
  installed; opening a `.exe` explains that Intel/AMD Windows programs can't
  run on the Arm edition.
- Tested in QEMU: double-clicking a 64-bit (Notepad) and a 32-bit
  (Minesweeper) Windows program opens them. Fixes from that test: KDE asked
  "Execute or Cancel?" for every .exe, so `/etc/xdg/kiorc` sets
  `behaviourOnLaunch=execute` (runs them via their associated app straight
  away); and the launcher now finishes Wine's one-time setup
  (`wineboot --init`) before starting the program, because on a slow machine
  starting both at once made the first program time out.

## Gaming and handheld support (ROG Xbox Ally)
- Debian **trixie-backports** enabled (`config/archives/backports.list`) with
  pins (`backports.pref`) for the kernel (7.2), firmware (2026-09) and the
  Mesa 26.1 graphics/Vulkan stack + gamescope, for 64-bit and 32-bit (`:i386`
  pins are needed, apt otherwise only pins native packages). Everything else
  stays on Debian stable. Installed systems keep backports in their sources so
  these keep updating.
- amd64: Steam (`steam-installer`, 32-bit parts in the renamed
  `0500-ribos-i386` hook together with Wine), Vulkan drivers, gamescope,
  GameMode, MangoHud + GOverlay, Lutris, `steam-devices` controller rules.
- **Gaming Mode** launcher (Steam Big Picture, `steam -gamepadui`) pinned in the
  start menu; Steam added to the taskbar when installed (`applicationExists`).
- Touch: Maliit on-screen keyboard enabled in KWin; `power-profiles-daemon` for
  the Power saver / Balanced / Performance switch.
- README: "Gaming and handhelds" section (Ally boot keys, Proton, MangoHud,
  what isn't covered: extra buttons and TDP need Handheld Daemon, not in Debian).
- Verified the backports + i386 package set resolves (apt simulation); not
  tested on real Ally hardware.
