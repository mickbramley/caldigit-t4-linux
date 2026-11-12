# Evidence, verification, and boundaries

**Evidence classification:** The findings below are taken from operator-supplied command outputs and observations during the November 2026 investigation. This document does **not** claim independent lab access, a complete packet trace, a recovered CalDigit RAID format specification, or automated test coverage.

## Verified observations

| Test/observation | Evidence reported | Conclusion supported |
|---|---|---|
| Thunderbolt discovery | PCIe topology exposes four ASMedia controller functions under T4; AHCI rebind logs show four SATA controller functions | Linux can interact with these controllers |
| Physical disks | Four Toshiba MD04ACA400, 4 TB each, identified in kernel enumeration / SMART | Four independent SATA members accessible to Linux |
| RAID assembly | `/proc/mdstat` repeatedly reports `md0 : active raid5`, `11720658432 blocks`, `512k chunk`, `algorithm 2`, `[4/4] [UUUU]` | Native RAID5 active with all members |
| RAID detail | `State : clean`; `Active Devices : 4`; `Working Devices : 4`; `Failed Devices : 0`; `Consistency Policy : bitmap` | No failed members at sampled time |
| Bitmap | `bitmap: 2/30 pages [8KB], 65536KB chunk` (later 3/30) | Internal write-intent bitmap is active; figures are **not** progress percentages |
| Filesystem | `/dev/md0p1` ext4 mounted `/mnt/CalDigitT4` in read/write mode; ext4 label and UUID recorded locally | Operational 12 TB logical volume |
| Reboot | After reboot, four disks reappeared and md0 reassembled `4/4 [UUUU]`; persistent fstab automount worked | Verified boot persistence on tested host |
| Samba | `testparm` passed, localhost SMB share file create/list/remove passed | Samba service access tested |
| NFS | Network client mounted using NFSv4.1 and performed create/write/delete, including after server reboot | Remote Linux filesystem access tested |
| SMART | Four Toshiba SMART devices passed and key bad-sector/CRC attributes were zero at a snapshot; later seven-drive smartd monitoring was configured | Disk monitoring possible, not a guarantee against future failure |
| Failure handling | At ~17:32 Nov 11, kernel reported `pciehp: ... Link Down`, all four `AHCI controller unavailable!`, followed by failed reconnect; ext4 journal had aborted during an earlier disruption (~16:55) | Shared Thunderbolt disruption can take down the entire md RAID / filesystem |
| Recovery after cable reposition | Reboot re-enumerated controllers and md RAID healthy `[UUUU]`; ext4 later mounted RW and `tune2fs` reported `Filesystem state: clean` | Recoverability observed after *this* event; not proof of absence of latent fs damage |
| Alerting (Phase 2) | mdadm alerts and SMART runner test emails received externally | Optional monitoring path can deliver mail; separate from core compatibility claim |

## Representative anonymized output snippets

```text
Personalities : [raid0] [raid1] [raid6] [raid5] [raid4] [raid10]
md0 : active raid5 sdg[0] sdf[4] sde[2] sdd[1]
      11720658432 blocks super 1.2 level 5, 512k chunk, algorithm 2 [4/4] [UUUU]
      bitmap: 2/30 pages [8KB], 65536KB chunk
```

```text
State : clean
Active Devices : 4
Working Devices : 4
Failed Devices : 0
Spare Devices : 0
Consistency Policy : bitmap
```

```text
pcieport ... pciehp: Slot(3-2): Link Down
ahci ... AHCI controller unavailable!
ata... Check power mode failed (err_mask=0x60)
pcieport ... pciehp: Slot(3-2): Card present
pcieport ... pciehp: Slot(3-2): No link
```

```text
EXT4-fs error (device md0p1): ... Detected aborted journal
Buffer I/O error on dev md0p1 ... lost sync page write
EXT4-fs (md0p1): I/O error while writing superblock
EXT4-fs (md0p1): Remounting filesystem read-only
```

## Test conclusions that MUST NOT be inferred

- `[UUUU]` does **not** prove RAID parity was completely scrubbed.
- `State: clean` does **not** mean all file contents were cryptographically verified.
- `tune2fs` reporting `Filesystem state: clean` is **not** a substitute for a deliberate offline `e2fsck` after an aborted journal.
- SMART `PASSED` is **not** a prediction that a drive cannot fail.
- The live cable incident was **not** a supported hot-removal test; it showed potential corruption risk.
- Only one enclosure/platform combination was verified; no statistical reliability conclusions are warranted.
- No controlled end-to-end throughput benchmark was captured for publication.
- Observed PCI BDF addresses and `/dev/sdX` order are not universal.

## Remaining validation work (separate from Phase 1)

1. Full RAID parity scrub and review of mismatch counter.
2. Offline filesystem examination after the real aborted-journal event, when practical and safely unmounted.
3. Stable power/fan, HDD standby and UPS-failure response.
4. Safe controlled Thunderbolt disconnect and re-authorize only after unmount, exporting clients stopped and md array stopped, in a disposable-data test environment.
5. More than one model/firmware/kernel and performance comparison with macOS vendor configuration.

**Repository quality note:** Detailed shell history and full sector metadata dumps were not available for all earlier experimental steps when this case study was prepared. Destructive command examples are labelled *reconstructed equivalents*, not contemporaneous exact transcripts. This is deliberate honesty, not a missing script to be fabricated.
