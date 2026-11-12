# Persistent operation, sharing and monitoring

This document describes the **observed implementation** and safe system-administration patterns, not a mandatory configuration for all users.

## RAID persistence

`/etc/mdadm/mdadm.conf` contained a single `ARRAY /dev/md0 ... UUID=<actual uuid>` entry matching `sudo mdadm --detail --scan`. `sudo update-initramfs -u` was performed. Persistent per-controller AHCI overrides were stored by `driverctl`. Reboots showed the four disks returning and array assembled automatically at `[4/4] [UUUU]`.

Never fabricate an mdadm UUID. Use the actual `mdadm --detail --scan` value.

## ext4 and mounting

An ext4 partition `/dev/md0p1` was formatted with 4 KiB blocks and RAID-aware stride=128, stripe-width=384. Mount point was `/mnt/CalDigitT4`, owned by the server account, with directory setgid where desired. `fstab` used the real ext4 UUID and systemd automount, for example:

```fstab
UUID=<REAL-EXT4-UUID> /mnt/CalDigitT4 ext4 noatime,nofail,noauto,x-systemd.automount,x-systemd.device-timeout=60s 0 0
```

On a new filesystem, `ext4lazyinit` performs one-time inode-table initialization that can write for hours and resume after reboots. It can prevent HDD spin-down during that period; this is not itself an error.

## Samba

The implementation made `/mnt/CalDigitT4` available as a writable authenticated Samba share. A sanitized example is under `examples/smb.conf.sample`. A localhost `smbclient` write/list/delete check passed. Note that the original lab carried extra legacy SMB compatibility settings unrelated to this project; those settings should **not** be copied by default.

## NFS

An NFS export was set up for the LAN; a Debian client mounted via NFSv4.1 using a systemd automount. Create/write/remove and reconnection after server reboot succeeded. Public sample uses `root_squash`. The actual lab configuration used `no_root_squash` at the operator's explicit request, which gives clients excessive privilege for a normal deployment.

## Shutdown and disconnect

Normal server `systemctl poweroff` is the preferred procedure. Stop traffic first. An mdadm consistency check may cause service inhibitors; observe state before stopping any checks. **Do not yank the Thunderbolt cable on a mounted filesystem.** Boot/reassembly was tested. Safe unplug/replug and enclosure fan-control were not conclusively characterized.

## Health checks

```bash
cat /proc/mdstat
sudo mdadm --detail /dev/md0
findmnt /mnt/CalDigitT4
sudo journalctl -k -b --no-pager | grep -Ei 'I/O error|EXT4-fs error|AHCI controller unavailable|pciehp.*Link Down' | tail -40
```

At a later stage, `mdmonitor` email alerts and `smartd` monitoring were configured; Cockpit displayed storage topology. Those are operational enhancements, not necessary for the initial hardware/RAID proof-of-concept.

## RAID scrubs and SMART checks

On Linux md, a parity consistency check differs from an array rebuild. The original project configured a daytime Sunday scrub timer and retry policy to defer when disks were sleeping. A complete scheduled scrub and standalone retry sequence had **not yet been observed end-to-end** at Phase 1 publication. The project deliberately does not ship that custom scheduling machinery as a proven, portable configuration.

A `smartd` installation eventually monitored seven host drives: the T4's four Toshiba members, the host SSD and two unrelated USB/SATA HGST disks. The latter two require explicit `-d sat` passthrough on this host. More details belong in Phase 2's monitoring documentation.

## Notes on a software-monitoring alias bug

In this Debian mdadm 4.4 setup, a monitor start initially produced apparent duplicate event messages for `/dev/md/md0` and `/dev/md0`. A **udev-only compatibility symlink**, uniquely matched to the md array UUID and targeting `md/md0`, was used; after installing it, a monitor restart produced no repeated startup phantom events. The RAID itself remained clean throughout. This is a host-specific monitoring issue, not a requirement for all distributions or a fix for hardware disconnects.
