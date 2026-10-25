#!/bin/bash
# Install Debian trixie's live-build, debootstrap and archive keyring on an
# Ubuntu (or Debian) host. Ubuntu ships an old, patched live-build that can't
# build RibOS. The packages are architecture-independent, so Debian's .debs
# install cleanly; their current file names are looked up in the trixie
# index so this keeps working after Debian point releases.
set -euo pipefail

MIRROR=https://deb.debian.org/debian
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

curl -fsSL "$MIRROR/dists/trixie/main/binary-all/Packages.xz" | xz -d > "$WORK/Packages"

for pkg in live-build debootstrap debian-archive-keyring; do
	file=$(awk -v p="$pkg" '$0 == "Package: " p {f=1} f && /^Filename:/ {print $2; exit}' "$WORK/Packages")
	[ -n "$file" ] || { echo "Could not find $pkg in the trixie index" >&2; exit 1; }
	echo "Downloading $file"
	curl -fsSL -o "$WORK/$(basename "$file")" "$MIRROR/$file"
done

sudo apt-get install -y "$WORK"/*.deb
lb --version
