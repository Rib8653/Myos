# RibOS

Note this was made with aI! ribOS is a Debian 13 ("trixie") based live and installable Linux distribution with a
KDE Plasma desktop preconfigured to feel familiar to Windows 11 users:
a centered bottom taskbar, a Windows 11 style start menu (search, pinned apps,
recommended files, all apps, user and power buttons), Fluent-style icons,
window snapping, Windows-style shortcuts and a light/dark toggle.

It is built with Debian's official [`live-build`](https://live-team.pages.debian.net/live-manual/)
and produces a hybrid ISO that boots from DVD or USB, runs as a live system and
installs to disk with the Calamares graphical installer. Two architectures:

* **amd64**: Intel/AMD PCs and Intel Macs, booting on UEFI and legacy BIOS.
* **arm64**: Arm machines with UEFI, such as Apple Silicon Macs in UTM or
  Parallels, and Arm laptops/servers.

RibOS's own artwork is original (see `branding/src`). The icons come from the
freely licensed [Fluent icon theme](https://github.com/vinceliuice/Fluent-icon-theme)
(GPL-3.0), with any Windows/Microsoft logos it contains removed at build time.
RibOS mimics a familiar layout and behaviour only: it contains no Microsoft
logos, fonts, wallpapers or icons.

---

## Building

Requirements: a Debian 12/13 or Ubuntu 22.04+ machine (or VM) on x86-64,
root/sudo, ~25 GB free disk space and an internet connection.

```bash
sudo apt install live-build debootstrap squashfs-tools xorriso isolinux \
    syslinux-common grub-pc-bin grub-efi-amd64-bin mtools dosfstools apt-utils \
    qemu-system-x86 ovmf          # the last two only for test.sh

sudo ./build.sh                   # clean amd64 build (reuses the package cache)
sudo ./build.sh --arch arm64      # clean arm64 build
sudo ./build.sh --purge           # clean build, re-downloading everything
```

The result is `ribos-amd64.hybrid.iso` or `ribos-arm64.hybrid.iso` (about 2.7 GB), and the full log is
in `build.log`. A first build downloads about 2.5 GB of packages and takes
30–60 minutes. Later builds reuse `cache/` and take about 25 minutes.

> **Ubuntu hosts:** Ubuntu ships an old, patched live-build. If `lb --version`
> prints something older than `20230502`, install Debian's package instead
> (it is architecture-independent):
> `wget https://deb.debian.org/debian/pool/main/l/live-build/live-build_20250505+deb13u1_all.deb && sudo apt install ./live-build_*.deb`
> and do the same for `debootstrap` and `debian-archive-keyring` if they are older than trixie.
> `ci/install-live-build.sh` does all three for you.

**arm64 builds** run fastest on an arm64 Debian/Ubuntu machine (for amd64
builds you also need `isolinux syslinux-common grub-pc-bin grub-efi-amd64-bin`;
for arm64, `grub-efi-arm64-bin` instead). An Intel/AMD machine can build arm64
too, by emulating Arm with QEMU (`sudo apt install qemu-user-static
binfmt-support`). That works but takes several times longer. Switching
architecture clears the package cache, because it only holds one architecture.

### Building on GitHub (no Linux machine needed)

`.github/workflows/build-iso.yml` builds the ISO on GitHub's Linux runners,
for example from a Mac:

1. On GitHub, open the repository's **Actions** tab, pick
   **Build RibOS ISO**, then **Run workflow** and choose `both`, `amd64` or
   `arm64`. Pushing a tag such as `v1.0` builds both.
2. Wait 30–60 minutes. amd64 builds on a normal runner and arm64 on GitHub's
   Arm runner (`ubuntu-24.04-arm`, native, no emulation). In a private
   repository both use your Actions minutes (free plan: 2,000 per month).
3. Open **Releases** (right-hand side of the repository page). Each build
   publishes the ISO in parts (GitHub's limit is 2 GB per file) plus a
   checksum file. Download them all and join them as the release notes
   show, e.g. on a Mac: `cat ribos-amd64.hybrid.iso.part* > ribos-amd64.hybrid.iso`.

If a build fails, the run page has a `build-log` download with the full log.
Old releases can be deleted from the Releases page.

Behind a proxy? Export `https_proxy` before running `build.sh`. It is passed
into the build chroot through `config/environment.chroot`, which is generated
on every build, git-ignored and never copied into the ISO. All mirrors use
HTTPS.

## Testing

### QEMU (`test.sh`)

```bash
./test.sh            # boot the ISO with UEFI firmware (OVMF), 4 GB RAM
./test.sh --bios     # boot the ISO with legacy BIOS
./test.sh --disk     # boot what you installed onto the virtual disk
./test.sh --reset    # throw away the virtual disk and UEFI settings first
./test.sh --arm64    # boot the arm64 ISO (needs qemu-system-arm qemu-efi-aarch64)
RAM=8192 CPUS=4 ./test.sh
```

A blank 32 GB virtual disk (`test/<arch>/disk.qcow2`) is attached, so you can run
**Install RibOS** from the live desktop and then boot the result with
`./test.sh --disk`. KVM is used automatically when `/dev/kvm` is available.
Without it, QEMU emulates the CPU and the desktop is very slow.

### UTM on a Mac (arm64 ISO on Apple Silicon)

1. Install [UTM](https://mac.getutm.app/), then **Create a New Virtual Machine** → **Virtualize** → **Linux**.
2. Tick nothing special; under *Boot ISO Image* pick `ribos-arm64.hybrid.iso`.
3. Give it 4 GB+ RAM, 2+ CPU cores and a 32 GB+ disk. Before starting, open
   the VM's settings → **Display** and pick **virtio-gpu-gl-pci (GPU Supported)**
   with **Retina Mode** off: graphics acceleration is what makes the desktop
   and mouse pointer move smoothly. Then start it. (RibOS includes the SPICE
   guest agent, so the window can be resized and the clipboard is shared.)
4. After installing, open the VM's settings, remove the ISO from the CD drive
   (or clear it in the toolbar's drive menu) and restart.

Use the amd64 ISO only on Intel Macs. Apple Silicon would have to emulate it
and runs it very slowly.

### VirtualBox

1. New VM → Type *Linux*, Version *Debian (64-bit)*, 4 GB RAM, 2+ CPUs,
   a 32 GB disk.
2. Settings → System → tick **Enable EFI** to test UEFI (leave it off for BIOS).
3. Settings → Display → Graphics Controller **VMSVGA**, 128 MB video memory.
4. Settings → Storage → attach `ribos-amd64.hybrid.iso` to the optical drive.
5. Start. After installing, remove the ISO from the drive and reboot.

### Real hardware

Write the ISO to a USB stick (this erases the stick):
`sudo dd if=ribos-amd64.hybrid.iso of=/dev/sdX bs=4M status=progress oflag=sync`,
or use a tool like Ventoy, balenaEtcher or GNOME Disks.
Secure Boot works through Debian's signed shim and GRUB.

The live user is `ribos` with the password `live` (live-config default). It logs
in automatically and never locks the screen; `sudo` works without a password in
the live session.

---

## Where things are

```
auto/config                    lb config options: distribution, archive areas,
                               mirrors, boot parameters, ISO name/volume
build.sh / test.sh             build from scratch / boot in QEMU
branding/src/*.svg             ORIGINAL ARTWORK (logo, wallpaper, boot, slides)
branding/render.sh             renders the SVGs into the PNGs under config/
branding/install-fluent-icons.sh
                               builds the Fluent-light/Fluent-dark icon themes
                               (build.sh fetches Fluent at a pinned commit)
config/
  package-lists/               what gets installed (one package per line)
    base.list.chroot             live system core
    firmware.list.chroot         Wi-Fi / GPU / sound / Bluetooth firmware
    desktop.list.chroot          Plasma, fonts, audio, Bluetooth, printing
    apps.list.chroot             Firefox, LibreOffice, VLC, Discover + Flatpak…
    installer.list.chroot        Calamares
    installer-*.list.binary      GRUB packages put on the ISO for offline installs
  hooks/normal/0xxx-ribos-*      scripts run inside the image at build time
                                 (os-release, Plymouth, Flathub)
  bootloaders/                   boot menu: grub-pc/ (UEFI) and isolinux/ +
                                 syslinux_common/ (BIOS), splash images
  includes.chroot/               files copied as-is into the system:
    etc/xdg/                       system-wide KDE defaults (theme, fonts,
                                   KWin snapping & title bar, lock screen)
    etc/skel/                      copied to every new user's home: desktop
                                   icons, Windows-style keyboard shortcuts
    usr/share/plasma/look-and-feel/org.ribos.desktop/
                                   the RibOS global theme, including the
                                   taskbar/start menu layout script
    usr/share/plasma/plasmoids/org.ribos.startmenu/
                                   the Windows 11 style start menu (QML)
    usr/share/plasma/plasmoids/org.ribos.darkmode/
                                   the light/dark toggle button on the taskbar
    usr/bin/ribos-theme            light/dark switch used by the toggle
    usr/lib/live/config/2000-ribos-live-session
                                   live ISO only: no auto screen lock/suspend
    usr/share/wallpapers/RibOS/    wallpaper (light + dark variants)
    usr/share/plymouth/themes/ribos/  boot splash
    etc/calamares/                 installer branding, slideshow, settings
    etc/default/grub.d/ribos.cfg   GRUB name/options of installed systems
```

### Changing branding

1. Edit the SVGs in `branding/src/` (any vector editor, e.g. Inkscape).
2. Run `branding/render.sh` (needs `librsvg2-bin` and `fonts-inter`).
3. Rebuild.

The distro name appears in: `auto/config` (`--iso-*`, `--image-name`,
`username=`/`hostname=` in `--bootappend-live`),
`config/hooks/normal/0100-ribos-os-release.hook.chroot`,
`config/bootloaders/` (menu labels),
`config/includes.chroot/etc/calamares/branding/ribos/branding.desc`,
`config/includes.chroot/etc/default/grub.d/ribos.cfg` and the
`.desktop` launcher for the installer. `grep -ri ribos config auto` finds them all.

### Changing packages

Add or remove package names in `config/package-lists/*.list.chroot`
(add a new `something.list.chroot` file if you like). Names must exist in
Debian trixie (main, contrib, non-free or non-free-firmware). Check with
`apt-cache policy <name>` on a trixie system, or at <https://packages.debian.org>.

### Changing desktop defaults

* **Start menu pinned apps (first login):** the `favorites` default in
  `config/includes.chroot/usr/share/plasma/plasmoids/org.ribos.startmenu/contents/config/main.xml`.
  Users pin and unpin apps by right-clicking them in the menu.
* **Start menu look:** `.../org.ribos.startmenu/contents/ui/FullRepresentation.qml`
  (sizes and the number of columns are at the top).
* **Icons:** `build.sh` fetches the Fluent icon theme and
  `branding/install-fluent-icons.sh` builds `Fluent-light` (default) and
  `Fluent-dark` (used in dark mode), with yellow folders. To use another icon
  theme, change `[Icons] Theme=` in `kdeglobals` and the global themes'
  `contents/defaults`. LibreOffice uses its Colibre icons
  (`config/includes.chroot/usr/lib/libreoffice/share/registry/ribos.xcd`).
* **Taskbar and start menu layout, taskbar apps, clock, wallpaper:**
  `config/includes.chroot/usr/share/plasma/look-and-feel/org.ribos.desktop/contents/layouts/org.kde.plasma.desktop-layout.js`
  (Plasma's [desktop scripting API](https://develop.kde.org/docs/plasma/scripting/)).
  It runs once, on a user's first login.
* **Colours, fonts, icon theme, double-click:** `config/includes.chroot/etc/xdg/kdeglobals`
* **Mouse cursor and its size:** `config/includes.chroot/etc/xdg/kcminputrc`
  (plus `etc/sddm.conf.d/10-ribos.conf` for the login screen). The default is
  Fluent's white cursor set, built by `branding/install-fluent-icons.sh`.
* **Firefox defaults (smooth scrolling):** `config/includes.chroot/etc/firefox-esr/ribos.js`
* **Window snapping, title-bar buttons, Alt+Tab style:** `config/includes.chroot/etc/xdg/kwinrc`
* **Keyboard shortcuts:** `config/includes.chroot/etc/skel/.config/kglobalshortcutsrc`
* **Desktop icons:** `config/includes.chroot/etc/skel/Desktop/`

Files in `/etc/xdg` are system-wide defaults that each user's own settings
override. Files in `/etc/skel` are copied into a home directory only when the
user is created. Both apply to the live user and to users created by the
installer. To try a change without rebuilding, edit the file in a running
system and log in as a new user.

### Keyboard shortcuts

| Keys | Action |
|---|---|
| Super | Open start menu |
| Super+E | File manager (Dolphin) |
| Super+D | Show desktop |
| Super+L | Lock screen |
| Super+I | Settings |
| Super+←/→ | Snap window left/right |
| Super+↑ / Super+↓ | Maximize / minimize |
| Alt+Tab | Switch windows |
| Ctrl+Shift+Esc | Task manager (System Monitor) |
| Print Screen | Screenshot (Spectacle) |
| Ctrl+Alt+T | Terminal |

---

## Licence

Build scripts and configuration: GPL-2.0-or-later. Original artwork in
`branding/src` (logo, wallpapers, boot splash, slides): CC0. The icon themes
built from the [Fluent icon theme](https://github.com/vinceliuice/Fluent-icon-theme)
by Vince Liuice are GPL-3.0 (with recoloured folders and trademark logos
removed). Bundled software keeps its own Debian licences.
