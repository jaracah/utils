#!/usr/bin/env bash
#
# arch-usb.sh - download, verify, and flash the arch linux iso on macos
#
# usage:
#   ./arch-usb.sh [disk]
#   MIRROR=https://mirror.example.com/archlinux OUT_DIR=~/Downloads ./arch-usb.sh /dev/disk4

set -euo pipefail

MIRROR="${MIRROR:-https://mirrors.mit.edu/archlinux}"
VERSION="${VERSION:-latest}"
OUT_DIR="${OUT_DIR:-.}"
ISO_FILE="archlinux-x86_64.iso"
ISO_PATH="$OUT_DIR/$ISO_FILE"
ISO_URL="$MIRROR/iso/$VERSION/$ISO_FILE"
# checksums come from archlinux.org, not the mirror, so a bad mirror can't fake both
SUMS_URL="https://archlinux.org/iso/$VERSION/sha256sums.txt"

err()  { printf '\033[31merror:\033[0m %s\n' "$1" >&2; exit 1; }
info() { printf '\033[36m==>\033[0m %s\n' "$1"; }

[[ "$(uname)" == "Darwin" ]] || err "this script is for macos"

mkdir -p "$OUT_DIR"

info "downloading iso to $ISO_PATH"
curl -fL -C - -o "$ISO_PATH" "$ISO_URL"

info "downloading checksums from archlinux.org"
curl -fL -o "$OUT_DIR/sha256sums.txt" "$SUMS_URL"

info "verifying checksum"
EXPECTED=$(awk -v f="$ISO_FILE" '$2 == f {print $1}' "$OUT_DIR/sha256sums.txt")
ACTUAL=$(shasum -a 256 "$ISO_PATH" | awk '{print $1}')
[[ -n "$EXPECTED" && "$EXPECTED" == "$ACTUAL" ]] || err "checksum failed, do not use this iso"
info "checksum ok"

TARGET="${1:-}"
if [[ -z "$TARGET" ]]; then
    echo
    diskutil list external physical
    echo
    read -rp "target disk (e.g. /dev/disk4): " TARGET
fi

[[ "$TARGET" =~ ^/dev/disk[0-9]+$ ]] || err "target must be a whole disk like /dev/diskN"
diskutil info "$TARGET" | grep -Eq "External|Removable Media:.*Removable" \
    || err "$TARGET does not look external or removable, refusing"

echo
diskutil info "$TARGET" | grep -E "Media Name|Disk Size" || true
printf '\033[33mthis will erase everything on %s\033[0m\n' "$TARGET"
read -rp "type the disk name again to confirm (e.g. disk4): " CONFIRM
[[ "/dev/$CONFIRM" == "$TARGET" ]] || err "confirmation did not match"

info "unmounting"
diskutil unmountDisk "$TARGET"

info "writing iso (sudo password needed)"
sudo dd if="$ISO_PATH" of="${TARGET/\/dev\/disk//dev/rdisk}" bs=4m status=progress conv=sync

sync
diskutil eject "$TARGET"
info "done, usb is bootable"

