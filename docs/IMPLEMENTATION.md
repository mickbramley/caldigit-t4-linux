# Discovery and implementation method

## Safety classification

- **READ-ONLY:** identity, status and log commands. Safe in ordinary circumstances, though even read-only block-device queries can wake a sleeping HDD depending on the bridge.
- **CONFIGURATION-CHANGING:** `boltctl enroll`, `driverctl set-override`, `/etc/mdadm/mdadm.conf`, `/etc/fstab`, Samba/NFS settings. Can disrupt existing devices and access.
- **DESTRUCTIVE:** `mdadm --create`, partition-table changes and `mkfs.ext4`. **Erases/replaces existing storage metadata and/or user data.** Only for an empty or independently backed-up set of disks explicitly released from any original RAID.

The destructive examples below are a **reconstructed equivalent** of the successful configuration as recorded during the investigation, not a literal, complete shell transcript. No destructive installer is supplied. **Do not paste the example into a production machine.**

## 0. Dependencies

Verified host: Intel 2012 Mac mini running Debian 13 and a CalDigit **Thunderbolt 3** T4 connected through the Apple TB3↔TB2 adapter, compatible cable and T4 power supply. Relevant Linux facilities:

| Purpose | Components |
|---|---|
| Hardware enumeration | `pciutils` (`lspci`), `lsblk`, `udevadm`, `journalctl` |
| Thunderbolt security | Kernel `thunderbolt` module, `bolt`, `boltctl`/`boltd` |
| SATA controller | `ahci`, `libata`, `driverctl` and udev integration |
| RAID | `mdadm`, Linux `md`/`raid456` kernel infrastructure |
| Partition/filesystem | `parted` or comparable GPT tool, `e2fsprogs` / `mkfs.ext4` |
| Health checks | `smartmontools` |
| Sharing (optional) | `samba`, `nfs-kernel-server`, NFS client |

Suggested package preparation, **only after reviewing what is already installed**:

```bash
sudo apt install pciutils bolt driverctl mdadm smartmontools parted e2fsprogs
```

Packages, kernel configuration and service units may vary on other distributions.

## 1. Baseline and inventory: READ-ONLY

Inventory the host and identify the *actual* device IDs **before** touching its drivers or disks.

```bash
uname -a
lspci -Dnnk
lspci -Dnnvv -d 1b21:0613
boltctl list
lsblk -o NAME,TYPE,SIZE,MODEL,SERIAL,FSTYPE,MOUNTPOINTS
sudo mdadm --examine --scan   # inspect only; do not use as creation input blindly
```

The bundled `scripts/t4_readonly_probe.sh` also collects PCI, Thunderbolt and kernel-log context. Inspect any output before making it public; it can include identifying hardware details.

On this machine the four controller functions were observed at:

```text
0000:09:00.0
0000:0a:00.0
0000:0b:00.0
0000:0c:00.0
```

These are **observed addresses, not a universal device list**.

## 2. Authorize the enclosure: CONFIGURATION-CHANGING

Thunderbolt authorization was handled by `bolt`/`boltd`. The device was enrolled and automatically authorized after reboot in the tested setup.

```bash
boltctl list
boltctl info <verified-T4-device-ID>
sudo boltctl enroll <verified-T4-device-ID>
```

**Only authorize a device you own and have positively identified.** Do not deploy blanket udev rules that authorize all Thunderbolt devices. On older hosts, PCIe/Thunderbolt access creates additional DMA-security considerations.

## 3. Bind four SATA controllers to Linux AHCI: CONFIGURATION-CHANGING

The practical breakthrough was persistent per-device `ahci` overrides using `driverctl`. The override forces the kernel's standard AHCI driver to consider a device even when the automatic PCI ID matching was unsuitable.

First ensure the PCI IDs and that these functions really belong to the T4, **not to host boot storage**:

```bash
lspci -Dnnk -d 1b21:0613
sudo modprobe ahci
sudo driverctl list-persisted
```

Observed function addresses in this one host topology (example **only**):

```bash
# CONFIGURATION-CHANGING EXAMPLE. DO NOT RUN UNTIL EACH PCI FUNCTION IS VERIFIED.
sudo driverctl set-override 0000:09:00.0 ahci
sudo driverctl set-override 0000:0a:00.0 ahci
sudo driverctl set-override 0000:0b:00.0 ahci
sudo driverctl set-override 0000:0c:00.0 ahci
```

Verify actual driver bindings and discovered disks:

```bash
sudo driverctl list-persisted
lspci -Dnnk -d 1b21:0613
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE
sudo journalctl -k -b --no-pager | grep -Ei 'ahci|ata[0-9]+|TOSHIBA|pciehp'
```

`driverctl` stores persistent overrides under `/etc/driverctl.d/`; udev re-applies them during discovery. A cold reboot confirmed persistence on this machine. **Uncontrolled hot-plug reliability was not proven**; the experimental `driverctl@.service` drop-in tried during investigation is intentionally not included as a general recommendation.

If a controller is bound incorrectly, stop. Use `sudo driverctl unset-override <verified-pci-address>` only after confirming the affected hardware, and consult the `driverctl` manual; don't blindly unbind an in-use controller.

## 4. Identify the four RAID members: READ-ONLY

Four Toshiba MD04ACA400 drives appeared independently. Use stable `/dev/disk/by-id/` paths and *correlate their serials physically*. **Never hardcode `/dev/sdd` through `/dev/sdg` into a generic script:** these names have changed between boots in this experiment.

```bash
ls -l /dev/disk/by-id/ata-TOSHIBA_MD04ACA400_*
lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS
sudo smartctl --scan
sudo smartctl -a -d sat -n standby /dev/disk/by-id/<VERIFIED-MEMBER>
```

Original contents should be backed up/imaged before any array reconstruction. If you need data recovery, **stop here** and do not create or zero a new array.

## 5. Build a *new* Linux RAID5: DESTRUCTIVE (historical specification)

> **DO NOT EXECUTE THIS BLOCK WITHOUT A VERIFIED, INDEPENDENT BACKUP AND POSITIVE IDENTIFICATION OF ALL FOUR DISKS.** Creating an mdadm array can irreversibly overwrite existing CalDigit RAID metadata and user data. The example is intentionally presented with placeholders rather than a copy-pasteable device list.

The verified resulting Linux array had these characteristics:

```text
RAID level                 5
Number of data members     4 total, 3 data + 1 parity equivalent
Member disks               4 x 4TB Toshiba MD04ACA400
Array device               /dev/md0
Linux metadata             1.2
Layout                     left-symmetric (algorithm 2)
Chunk size                 512 KiB
Write-intent bitmap        internal, 64 MiB bitmap granularity observed
Capacity                   ~12.00 TB / 10.92 TiB
```

Equivalent **destructive command structure**, **not a runnable script**:

```bash
# DESTRUCTIVE ILLUSTRATION: Replace placeholders ONLY after backup and review.
# sudo mdadm --create /dev/md0 \
#   --metadata=1.2 --level=5 --raid-devices=4 \
#   --layout=left-symmetric --chunk=512K --bitmap=internal \
#   /dev/disk/by-id/<MEMBER-A> /dev/disk/by-id/<MEMBER-B> \
#   /dev/disk/by-id/<MEMBER-C> /dev/disk/by-id/<MEMBER-D>
```

After creating a new array, wait until synchronization completes and verify all members:

```bash
cat /proc/mdstat
sudo mdadm --detail /dev/md0
sudo mdadm --detail --scan
```

Successful verified result: `4/4 [UUUU]`, `State : clean`, `Failed Devices : 0`. Do not confuse RAID synchronization with an ext4 lazy initialization process or with a parity consistency scrub.

## 6. Persist RAID assembly: CONFIGURATION-CHANGING

The system had an `ARRAY /dev/md0 ... UUID=...` entry in `/etc/mdadm/mdadm.conf`, matching the array's actual metadata. It was captured from mdadm's own scan, not guessed. The host's initramfs was refreshed. Sample in `examples/mdadm.conf.sample`.

```bash
sudo mdadm --detail --scan
sudoedit /etc/mdadm/mdadm.conf  # match the discovered UUID; avoid duplicate ARRAY lines
sudo update-initramfs -u
```

A controlled reboot later confirmed that the Thunderbolt device reappeared, `ahci` was rebound and `/dev/md0` automatically assembled. Boot persistence was **observed on this platform**, not guaranteed on every topology.

## 7. Partition and format a *new* empty md array: DESTRUCTIVE

The successful test used a GPT on `/dev/md0` with an ext4 partition starting at approximately **3 MiB**. The resulting ext4 creation parameters were recorded explicitly:

```bash
# DESTRUCTIVE REPRODUCTION EXAMPLE ONLY: must operate on a new empty array.
# sudo parted --script /dev/md0 mklabel gpt
# sudo parted --script /dev/md0 unit MiB mkpart primary 3 100%
# sudo mkfs.ext4 -b 4096 -L CalDigitT4 -m 0 -i 262144 \
#   -E stride=128,stripe-width=384 /dev/md0p1
```

`512 KiB / 4 KiB = 128` filesystem blocks per RAID chunk (`stride`); RAID 5 with four members supplies three data chunks per full stripe, so `128 × 3 = 384` (`stripe-width`). Reserve percentage `-m 0` is appropriate only when consciously accepting no reserved ext4 blocks on this data-only volume.

`ext4lazyinit` can run in the background on a new filesystem and perform periodic writes until inode-table initialization finishes. It can survive normal reboots and resume unfinished work. It is **not** a RAID rebuild and **not** an error.

## 8. Mount and verify: CONFIGURATION-CHANGING

Use the **actual filesystem UUID**, not `/dev/md0p1` path alone, in `/etc/fstab`:

```bash
sudo blkid /dev/md0p1
# Replace UUID with the actual value in examples/fstab.sample.
sudo systemctl daemon-reload
findmnt /mnt/CalDigitT4
cat /proc/mdstat
```

The tested server uses systemd automount, `noatime` and `nofail`. Verify with a harmless test file *only after* the new filesystem is confirmed and mounted correctly.

## 9. Network sharing (optional)

Samba and NFS were tested locally and from an additional Debian Linux client. Examples are in `examples/`. The lab's NFS setup intentionally allowed `no_root_squash`, which is **not** recommended as a general default; public examples use `root_squash`.

The server supported obsolete clients using deliberately permissive legacy SMB settings. Those settings are **omitted** from the publication because they weaken security and are unrelated to T4 Linux compatibility.

## 10. Final verification

At minimum, verify:

```bash
cat /proc/mdstat
sudo mdadm --detail /dev/md0
findmnt /mnt/CalDigitT4
lsblk -o NAME,SIZE,TYPE,FSTYPE,MOUNTPOINTS
sudo journalctl -k -b --no-pager | grep -Ei 'ahci|TOSHIBA|I/O error|EXT4-fs error|Link Down' | tail -80
```

See [EVIDENCE.md](EVIDENCE.md) for observed results and what remains untested. **Do not perform a surprise-disconnect as a 'test'.**
