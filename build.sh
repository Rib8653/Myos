#!/bin/bash
# Build the RibOS ISO from scratch.
#
#   sudo ./build.sh                 clean amd64 build (keeps the package cache)
#   sudo ./build.sh --arch arm64    clean arm64 build (Apple Silicon/UTM, Arm PCs)
#   sudo ./build.sh --purge         also wipe the package cache (fully from scratch)
#
# The finished image is written to ./ribos-<arch>.hybrid.iso
# Building arm64 on an Intel/AMD machine (or the other way round) works through
# QEMU emulation (needs qemu-user-static) but is several times slower.
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

if [ "$(id -u)" -ne 0 ]; then
	exec sudo -E "$0" "$@"
fi

ARCH="${RIBOS_ARCH:-amd64}"
PURGE=0
while [ $# -gt 0 ]; do
	case "$1" in
		--arch)   ARCH="${2:?--arch needs amd64 or arm64}"; shift 2 ;;
		--arch=*) ARCH="${1#--arch=}"; shift ;;
		--purge)  PURGE=1; shift ;;
		*) sed -n '2,10p' "$0"; exit 1 ;;
	esac
done
case "$ARCH" in
	amd64|arm64) ;;
	*) echo "Unsupported architecture: $ARCH (use amd64 or arm64)" >&2; exit 1 ;;
esac
export RIBOS_ARCH="$ARCH"   # read by auto/config

for tool in lb debootstrap mksquashfs xorriso apt-ftparchive git; do
	command -v "$tool" >/dev/null || {
		echo "Missing '$tool'. Install with:" >&2
		echo "  sudo apt install live-build debootstrap squashfs-tools xorriso mtools dosfstools apt-utils git" >&2
		echo "  (plus isolinux syslinux-common grub-pc-bin grub-efi-amd64-bin for amd64 builds)" >&2
		exit 1
	}
done

if [ "$ARCH" != "$(dpkg --print-architecture)" ]; then
	qemu=/usr/bin/qemu-aarch64-static
	[ "$ARCH" = amd64 ] && qemu=/usr/bin/qemu-x86_64-static
	[ -x "$qemu" ] || {
		echo "Cross-building $ARCH needs QEMU user emulation: sudo apt install qemu-user-static binfmt-support" >&2
		exit 1
	}
	echo "Note: cross-building $ARCH through QEMU emulation; this takes several times longer."
fi

# Start from a clean tree. The package/bootstrap cache only holds one
# architecture, so switching architectures also clears it.
if [ "$PURGE" = 1 ]; then
	lb clean --purge
elif [ -f cache/.ribos-arch ] && [ "$(cat cache/.ribos-arch)" != "$ARCH" ]; then
	echo "Architecture changed to $ARCH: clearing the package cache."
	lb clean --purge
else
	lb clean
fi
rm -f "ribos-$ARCH.hybrid.iso"

# Windows 11 style icons: the Fluent icon theme (GPL-3.0) isn't packaged in
# Debian, so fetch a pinned commit (kept in cache/) and build RibOS's
# Fluent-light / Fluent-dark themes from it (generated, git-ignored).
FLUENT_COMMIT=c8a244f571ef8fb47812bdc9dbce76546cedce69
FLUENT_SRC=cache/third-party/fluent-icon-theme
if [ "$(git -C "$FLUENT_SRC" rev-parse HEAD 2>/dev/null)" != "$FLUENT_COMMIT" ]; then
	echo "Fetching the Fluent icon theme..."
	rm -rf "$FLUENT_SRC"
	mkdir -p "$FLUENT_SRC"
	git -C "$FLUENT_SRC" init -q
	git -C "$FLUENT_SRC" fetch -q --depth 1 https://github.com/vinceliuice/Fluent-icon-theme "$FLUENT_COMMIT"
	git -C "$FLUENT_SRC" checkout -q FETCH_HEAD
fi
branding/install-fluent-icons.sh "$FLUENT_SRC" config/includes.chroot/usr/share/icons

# If the host reaches the internet through a proxy, pass it into the build
# chroot (apt only). This file is host-specific, git-ignored and never ends
# up in the ISO.
# Only create it when there is something to write: live-build reads it with
# grep, and an empty file makes grep (and so the build) fail.
rm -f config/environment.chroot
for var in http_proxy https_proxy no_proxy; do
	if [ -n "${!var:-}" ]; then
		echo "${var}=${!var}" >> config/environment.chroot
	fi
done

lb config
mkdir -p cache && echo "$ARCH" > cache/.ribos-arch
lb build

if [ -f "live-image-$ARCH.hybrid.iso" ]; then
	mv "live-image-$ARCH.hybrid.iso" "ribos-$ARCH.hybrid.iso"
fi
if [ -f "ribos-$ARCH.hybrid.iso" ]; then
	ls -lh "ribos-$ARCH.hybrid.iso"
	echo "Done. Test it with: ./test.sh$( [ "$ARCH" = arm64 ] && echo ' --arm64')"
else
	echo "Build failed: no ISO produced. See build.log" >&2
	exit 1
fi
