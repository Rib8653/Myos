#!/bin/bash
# Re-render all RibOS branding PNGs from the SVG sources in branding/src.
# Run this after editing any SVG; the PNGs it writes are committed so a build
# does not need these tools.  Needs: librsvg2-bin, fonts-inter.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")/src"
R=../../config
C=$R/includes.chroot

mkdir -p "$R/bootloaders/grub-pc" "$R/bootloaders/isolinux" \
	"$C/usr/share/wallpapers/RibOS/contents/images" \
	"$C/usr/share/wallpapers/RibOS/contents/images_dark" \
	"$C/usr/share/plymouth/themes/ribos" \
	"$C/usr/share/pixmaps" \
	"$C/usr/share/icons/hicolor/scalable/apps" \
	"$C/etc/calamares/branding/ribos"

# Boot menus
rsvg-convert -w 800 -h 600 boot-splash.svg -o "$R/bootloaders/grub-pc/splash.png"
rsvg-convert -w 640 -h 480 boot-splash.svg -o "$R/bootloaders/isolinux/splash.png"

# Wallpaper (KDE wallpaper package with light and dark variants)
for size in 1920x1080 2560x1440 3840x2160; do
	w=${size%x*}; h=${size#*x}
	rsvg-convert -w "$w" -h "$h" wallpaper-light.svg -o "$C/usr/share/wallpapers/RibOS/contents/images/$size.png"
	rsvg-convert -w "$w" -h "$h" wallpaper-dark.svg  -o "$C/usr/share/wallpapers/RibOS/contents/images_dark/$size.png"
done
rsvg-convert -w 400 -h 225 wallpaper-light.svg -o "$C/usr/share/wallpapers/RibOS/contents/screenshot.png"

# Logo / start button icons
cp logo.svg "$C/usr/share/icons/hicolor/scalable/apps/ribos-logo.svg"
cp start-button.svg "$C/usr/share/icons/hicolor/scalable/apps/ribos-start.svg"
rsvg-convert -w 256 -h 256 logo.svg -o "$C/usr/share/pixmaps/ribos-logo.png"

# Plymouth
rsvg-convert -w 420 plymouth-logo.svg -o "$C/usr/share/plymouth/themes/ribos/logo.png"

# Calamares installer branding
rsvg-convert -w 128 -h 128 logo.svg -o "$C/etc/calamares/branding/ribos/logo.png"
rsvg-convert -w 800 -h 450 wallpaper-light.svg -o "$C/etc/calamares/branding/ribos/welcome.png"
for s in slide-*.svg; do
	[ -e "$s" ] || continue
	rsvg-convert -w 800 -h 440 "$s" -o "$C/etc/calamares/branding/ribos/${s%.svg}.png"
done
echo "Branding rendered."
