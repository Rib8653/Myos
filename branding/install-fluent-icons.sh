#!/bin/bash
# Build the RibOS icon themes from the Fluent icon theme sources.
#
#   branding/install-fluent-icons.sh <fluent-source-dir> <icons-dest-dir>
#
# Fluent (https://github.com/vinceliuice/Fluent-icon-theme, GPL-3.0) is an
# original, Windows 11 "Fluent design" style icon set; it contains no
# Microsoft artwork. Debian doesn't package it, so build.sh fetches a pinned
# commit and runs this script, which only copies and recolours files
# (it replaces Fluent's own install.sh, which RibOS doesn't need to run).
#
# Produces two themes:
#   Fluent-light  light mode: dark panel/tray icons      (RibOS default)
#   Fluent-dark   dark mode: light panel/tray icons; inherits Fluent-light
# Folders are recoloured from Fluent's blue (#198ee6) to warm yellow.
set -euo pipefail

SRC="$(readlink -f "${1:?usage: $0 <fluent-source-dir> <icons-dest-dir>}")"
DEST="${2:?usage: $0 <fluent-source-dir> <icons-dest-dir>}"
FOLDER_COLOR="#ffcb52"
[ -f "$SRC/src/index.theme" ] || { echo "Not a Fluent source tree: $SRC" >&2; exit 1; }

LIGHT="$DEST/Fluent-light"
DARK="$DEST/Fluent-dark"
rm -rf "$LIGHT" "$DARK"
mkdir -p "$LIGHT" "$DARK"

# Replace a colour in every .svg under the given directories (regular files only).
recolor() {
	local from="$1" to="$2"; shift 2
	local d
	for d in "$@"; do
		[ -d "$d" ] && find "$d" -type f -name '*.svg' -exec sed -i "s/${from}/${to}/gI" {} +
	done
	return 0
}

# Write index.theme with a name and fallback themes.
write_index() {
	sed -e "s/%NAME%/$2/" -e "s/^Inherits=.*/Inherits=$3/" "$SRC/src/index.theme" > "$1/index.theme"
	# HiDPI: Fluent's scaled directories are plain aliases of the 1x ones.
	local sz m
	for sz in 16 22 24 32 256 scalable; do
		for m in 2 3; do
			[ -e "$1/$sz" ] && ln -sfn "$sz" "$1/$sz@${m}x"
		done
	done
	return 0
}

# --- Fluent-light: full set (src + symlink aliases), panel icons darkened ----
for d in 16 22 24 32 256 scalable symbolic; do
	[ -d "$SRC/src/$d" ] && cp -r "$SRC/src/$d" "$LIGHT/"
	[ -d "$SRC/links/$d" ] && cp -rT "$SRC/links/$d" "$LIGHT/$d"
done
for sz in 16 22 24; do
	recolor '#dedede' '#363636' "$LIGHT/$sz/panel"
done
recolor '#198ee6' "$FOLDER_COLOR" "$LIGHT/scalable/places"
# The file manager's app icon is a folder too; keep it the same colour.
sed -i "s/#198ee6/${FOLDER_COLOR}/gI" "$LIGHT/scalable/apps/file-manager.svg"
write_index "$LIGHT" "Fluent Light" "breeze,hicolor"

# --- Fluent-dark: only the icons that differ, light-coloured ------------------
for path in 16/actions 16/devices 16/places 22/actions 22/categories 22/devices \
            22/places 24/actions 24/devices 24/places 32/actions 32/devices \
            32/status symbolic 16/panel 22/panel 24/panel; do
	[ -d "$SRC/src/$path" ] || continue
	mkdir -p "$DARK/$(dirname "$path")"
	cp -r "$SRC/src/$path" "$DARK/$path"
	[ -d "$SRC/links/$path" ] && cp -rT "$SRC/links/$path" "$DARK/$path"
	case "$path" in
		*/panel) ;;   # Fluent's original panel icons are already light
		*) recolor '#363636' '#dedede' "$DARK/$path" ;;
	esac
done
# Everything else (full-colour app/file icons) is shared with Fluent-light.
# Linking it in, rather than only inheriting it, matters: otherwise a small
# monochrome tray icon in Fluent-dark would win over the full-colour app icon.
for path in scalable 256 16/mimetypes 16/status 22/emblems 22/mimetypes 24/animations 32/categories; do
	if [ -e "$LIGHT/$path" ] && [ ! -e "$DARK/$path" ]; then
		mkdir -p "$DARK/$(dirname "$path")"
		ln -sr "$LIGHT/$path" "$DARK/$path"
	fi
done
write_index "$DARK" "Fluent Dark" "Fluent-light,breeze-dark,breeze,hicolor"

# RibOS ships no Microsoft or Windows trademarks. Fluent draws "start-here"
# (and a few aliases) as the Windows logo and includes Microsoft product logos
# (Office, Edge, Teams, Skype, VS Code, ...). Remove them; those apps bring their
# own icons, and Plasma falls back to Breeze for the rest.
TRADEMARK_RE='start-here.*|windows|folder-windows.*|application-x-windows-themepack'
TRADEMARK_RE+='|.*microsoft.*|.*msedge.*|ms-[a-z]+|application-(x-)?ms(excel|onenote|outlook|powerpoint)'
TRADEMARK_RE+='|(gnome-mime-)?application-vnd\.ms-.*|(document-)?(excel|powerpoint|onenote)'
TRADEMARK_RE+='|(.*[-_.])?(teams|skype|outlook|onedrive|xbox|winword)([-_.].*)?'
TRADEMARK_RE+='|vscode.*|visual-?studio-?code.*|visualstudiocode|com\.visualstudio\..*|code(-oss|-insiders)?'
find "$LIGHT" "$DARK" -regextype posix-extended -iregex ".*/(${TRADEMARK_RE})\.(svg|png)" -delete

# Drop links that point outside what we copied (Fluent's links/ refer to src/)
# or at icons removed above.
find "$LIGHT" "$DARK" -xtype l -delete

echo "Installed $(find "$LIGHT" "$DARK" -name '*.svg' | wc -l) icons into $DEST (Fluent-light, Fluent-dark)."
