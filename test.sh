#!/bin/bash
# Boot the RibOS ISO in QEMU.
#
#   ./test.sh              UEFI boot (default), with a blank 32 GB disk for installing
#   ./test.sh --bios       legacy BIOS boot instead of UEFI
#   ./test.sh --disk       boot the installed system from the virtual disk (no ISO)
#   ./test.sh --reset      delete the virtual disk and UEFI vars, then boot the ISO
#
# Env: ISO=path/to.iso  RAM=4096  CPUS=2
# Needs: qemu-system-x86 ovmf   (sudo apt install qemu-system-x86 ovmf)
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

ISO="${ISO:-ribos-amd64.hybrid.iso}"
RAM="${RAM:-4096}"
CPUS="${CPUS:-2}"
WORK=test
DISK="$WORK/disk.qcow2"
MODE=uefi
BOOT_ISO=1

for arg in "$@"; do
	case "$arg" in
		--bios)  MODE=bios ;;
		--disk)  BOOT_ISO=0 ;;
		--reset) rm -rf "$WORK" ;;
		*) sed -n '2,12p' "$0"; exit 1 ;;
	esac
done

mkdir -p "$WORK"
[ -f "$DISK" ] || qemu-img create -q -f qcow2 "$DISK" 32G

ARGS=(-m "$RAM" -smp "$CPUS" -machine q35
	-device qemu-xhci -device usb-tablet
	-nic user,model=virtio-net-pci
	-drive file="$DISK",if=virtio,format=qcow2)

# Display: a GTK window when available, otherwise QEMU's default (SDL/VNC).
if qemu-system-x86_64 -display help 2>/dev/null | grep -qx gtk; then
	ARGS+=(-vga virtio -display gtk)
else
	ARGS+=(-vga virtio)
fi

# Sound through PulseAudio/PipeWire if the host has it.
if command -v pactl >/dev/null && pactl info >/dev/null 2>&1; then
	ARGS+=(-audiodev pa,id=snd0 -device ich9-intel-hda -device hda-output,audiodev=snd0)
fi

# KVM makes this ~10x faster; without it QEMU emulates the CPU.
if [ -w /dev/kvm ]; then
	ARGS+=(-enable-kvm -cpu host)
else
	echo "warning: /dev/kvm not available, booting without acceleration (slow)" >&2
	ARGS+=(-cpu max)
fi

if [ "$MODE" = uefi ]; then
	CODE=""
	for f in /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/qemu/OVMF.fd; do
		[ -f "$f" ] && { CODE=$f; break; }
	done
	[ -n "$CODE" ] || { echo "OVMF firmware not found: sudo apt install ovmf" >&2; exit 1; }
	VARS_SRC="${CODE/CODE/VARS}"
	[ -f "$WORK/OVMF_VARS.fd" ] || cp "$VARS_SRC" "$WORK/OVMF_VARS.fd"
	ARGS+=(-drive if=pflash,format=raw,readonly=on,file="$CODE"
		-drive if=pflash,format=raw,file="$WORK/OVMF_VARS.fd")
fi

if [ "$BOOT_ISO" = 1 ]; then
	[ -f "$ISO" ] || { echo "ISO not found: $ISO (run ./build.sh first)" >&2; exit 1; }
	ARGS+=(-drive file="$ISO",media=cdrom,readonly=on -boot order=d)
fi

echo "Booting $( [ "$BOOT_ISO" = 1 ] && echo "$ISO" || echo "$DISK" ) in $MODE mode..."
exec qemu-system-x86_64 "${ARGS[@]}"
