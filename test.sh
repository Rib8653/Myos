#!/bin/bash
# Boot the RibOS ISO in QEMU.
#
#   ./test.sh              amd64 ISO, UEFI boot, with a blank 32 GB disk for installing
#   ./test.sh --bios       amd64 ISO, legacy BIOS boot instead of UEFI
#   ./test.sh --arm64      arm64 ISO on an emulated Arm UEFI machine
#   ./test.sh --disk       boot the installed system from the virtual disk (no ISO)
#   ./test.sh --reset      delete the virtual disk and UEFI vars, then boot the ISO
#
# Env: ISO=path/to.iso  RAM=4096  CPUS=2
# Needs: amd64: qemu-system-x86 ovmf   arm64: qemu-system-arm qemu-efi-aarch64
set -euo pipefail
cd "$(dirname "$(readlink -f "$0")")"

ARCH=amd64
MODE=uefi
BOOT_ISO=1
RESET=0
for arg in "$@"; do
	case "$arg" in
		--bios)  MODE=bios ;;
		--arm64) ARCH=arm64 ;;
		--disk)  BOOT_ISO=0 ;;
		--reset) RESET=1 ;;
		*) sed -n '2,12p' "$0"; exit 1 ;;
	esac
done
[ "$ARCH" = arm64 ] && [ "$MODE" = bios ] && { echo "arm64 machines have no BIOS mode" >&2; exit 1; }

ISO="${ISO:-ribos-$ARCH.hybrid.iso}"
RAM="${RAM:-4096}"
CPUS="${CPUS:-2}"
WORK="test/$ARCH"
DISK="$WORK/disk.qcow2"
[ "$RESET" = 1 ] && rm -rf "$WORK"
mkdir -p "$WORK"
[ -f "$DISK" ] || qemu-img create -q -f qcow2 "$DISK" 32G

# First firmware file that exists, from a list of candidates.
find_fw() { for f in "$@"; do [ -f "$f" ] && { echo "$f"; return; }; done; }

if [ "$ARCH" = amd64 ]; then
	QEMU=qemu-system-x86_64
	ARGS=(-machine q35 -vga virtio
		-drive file="$DISK",if=virtio,format=qcow2)
	# KVM makes this ~10x faster; without it QEMU emulates the CPU.
	if [ -w /dev/kvm ] && [ "$(uname -m)" = x86_64 ]; then
		ARGS+=(-enable-kvm -cpu host)
	else
		echo "warning: no KVM, booting without acceleration (slow)" >&2
		# No AVX: Mesa's software renderer crashed plasmashell under QEMU's
		# emulated AVX ("-cpu max") in testing; an SSE4.2-era CPU model is stable.
		ARGS+=(-cpu Nehalem -accel tcg,thread=multi)
	fi
	if [ "$MODE" = uefi ]; then
		CODE=$(find_fw /usr/share/OVMF/OVMF_CODE_4M.fd /usr/share/OVMF/OVMF_CODE.fd /usr/share/qemu/OVMF.fd)
		[ -n "$CODE" ] || { echo "OVMF firmware not found: sudo apt install ovmf" >&2; exit 1; }
		VARS_SRC="${CODE/CODE/VARS}"
	fi
	CDROM=(-drive file="$ISO",media=cdrom,readonly=on)
	SOUND_DEV=(-device ich9-intel-hda -device hda-output,audiodev=snd0)
else
	QEMU=qemu-system-aarch64
	ARGS=(-machine virt -device virtio-gpu-pci -device usb-kbd
		-drive file="$DISK",if=virtio,format=qcow2)
	if [ -w /dev/kvm ] && [ "$(uname -m)" = aarch64 ]; then
		ARGS+=(-enable-kvm -cpu host)
	else
		echo "warning: not on an Arm host with KVM, emulating the CPU (very slow)" >&2
		ARGS+=(-cpu max -accel tcg,thread=multi)
	fi
	CODE=$(find_fw /usr/share/AAVMF/AAVMF_CODE.fd /usr/share/qemu-efi-aarch64/QEMU_EFI.fd)
	[ -n "$CODE" ] || { echo "Arm UEFI firmware not found: sudo apt install qemu-efi-aarch64" >&2; exit 1; }
	VARS_SRC=$(find_fw /usr/share/AAVMF/AAVMF_VARS.fd)
	CDROM=(-device virtio-scsi-pci -drive file="$ISO",if=none,id=cd0,media=cdrom,readonly=on
		-device scsi-cd,drive=cd0,bootindex=0)
	SOUND_DEV=(-device intel-hda -device hda-output,audiodev=snd0)
fi

ARGS+=(-m "$RAM" -smp "$CPUS" -device qemu-xhci -device usb-tablet
	-nic user,model=virtio-net-pci)

# Display: a GTK window when available, otherwise QEMU's default (SDL/VNC).
if "$QEMU" -display help 2>/dev/null | grep -qx gtk; then
	ARGS+=(-display gtk)
fi

# Sound through PulseAudio/PipeWire if the host has it.
if command -v pactl >/dev/null && pactl info >/dev/null 2>&1; then
	ARGS+=(-audiodev pa,id=snd0 "${SOUND_DEV[@]}")
fi

if [ "$MODE" = uefi ]; then
	VARS="$WORK/UEFI_VARS.fd"
	if [ ! -f "$VARS" ]; then
		if [ -n "${VARS_SRC:-}" ] && [ -f "$VARS_SRC" ]; then
			cp "$VARS_SRC" "$VARS"
		else
			truncate -s "$(stat -c %s "$CODE")" "$VARS"   # empty vars store
		fi
	fi
	ARGS+=(-drive if=pflash,format=raw,readonly=on,file="$CODE"
		-drive if=pflash,format=raw,file="$VARS")
fi

if [ "$BOOT_ISO" = 1 ]; then
	[ -f "$ISO" ] || { echo "ISO not found: $ISO (run ./build.sh$( [ "$ARCH" = arm64 ] && echo ' --arch arm64') first)" >&2; exit 1; }
	ARGS+=("${CDROM[@]}")
	[ "$ARCH" = amd64 ] && ARGS+=(-boot order=d)
fi

echo "Booting $( [ "$BOOT_ISO" = 1 ] && echo "$ISO" || echo "$DISK" ) ($ARCH, $MODE)..."
exec "$QEMU" "${ARGS[@]}"
