#!/bin/bash
# Build the RibOS ISO from scratch.
#
#   sudo ./build.sh            clean build (keeps the downloaded package cache)
#   sudo ./build.sh --purge    also wipe the package cache (fully from scratch)
#
# The finished image is written to ./ribos-amd64.hybrid.iso
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

if [ "$(id -u)" -ne 0 ]; then
	exec sudo -E "$0" "$@"
fi

for tool in lb debootstrap mksquashfs xorriso apt-ftparchive; do
	command -v "$tool" >/dev/null || {
		echo "Missing '$tool'. Install with:" >&2
		echo "  sudo apt install live-build debootstrap squashfs-tools xorriso isolinux syslinux-common grub-pc-bin grub-efi-amd64-bin mtools dosfstools apt-utils" >&2
		exit 1
	}
done

# Start from a clean tree.
if [ "${1:-}" = "--purge" ]; then
	lb clean --purge
else
	lb clean
fi
rm -f ribos-amd64.hybrid.iso

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
lb build

if [ -f live-image-amd64.hybrid.iso ]; then
	mv live-image-amd64.hybrid.iso ribos-amd64.hybrid.iso
fi
if [ -f ribos-amd64.hybrid.iso ]; then
	ls -lh ribos-amd64.hybrid.iso
	echo "Done. Test it with: ./test.sh"
else
	echo "Build failed: no ISO produced. See build.log" >&2
	exit 1
fi
