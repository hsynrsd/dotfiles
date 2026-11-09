#!/bin/sh
# Only acts when the root subvolume is a snapper snapshot (set by grub-btrfs menu entries).
command -v getarg >/dev/null || . /lib/dracut-lib.sh
case "$(getarg rootflags)" in
    *.snapshots/*) ;;
    *) return 0 ;;
esac
info "snapboot: snapshot boot detected, mounting tmpfs overlay on root"
mkdir -p /run/snapboot/lower /run/snapboot/cow
if ! mount --move "$NEWROOT" /run/snapboot/lower; then
    warn "snapboot: could not move root, continuing read-only"
    return 0
fi
mount -t tmpfs -o mode=0755 snapboot-cow /run/snapboot/cow
mkdir -p /run/snapboot/cow/upper /run/snapboot/cow/work
if ! mount -t overlay -o lowerdir=/run/snapboot/lower,upperdir=/run/snapboot/cow/upper,workdir=/run/snapboot/cow/work snapboot "$NEWROOT"; then
    warn "snapboot: overlay failed, continuing read-only"
    mount --move /run/snapboot/lower "$NEWROOT"
fi
