# CalDigit T4 Thunderbolt 3 RAID on Linux

**A documented Debian 13 case study: exposing four SATA disks through Thunderbolt and running a native Linux mdadm RAID 5.**

> **Status: Phase 1 demonstrated (November 2026).** One specific CalDigit T4 Thunderbolt 3 enclosure was successfully operated on a 2012 Intel Mac mini running Debian 13. The disks were accessed as independent SATA block devices using the Linux AHCI driver, then combined into a new Linux-managed RAID 5 array. Reboot/reassembly, ext4 mounting and network access were tested. This is **not** a driver for CalDigit's proprietary RAID and **not** a nondestructive import of a CalDigit/macOS volume.
>
> **DATA LOSS WARNING:** RAID creation, metadata replacement, partitioning and formatting can permanently destroy existing data. **Do not perform the reconstruction steps on a T4 holding data you need.** Make and verify independent backups first. Start with the read-only discovery script.

## Main finding

The T4 is not an opaque single logical disk at the Thunderbolt/PCIe level in the tested configuration. Linux discovered **four ASMedia PCIe SATA/AHCI controllers** (`1b21:0613` was the matched PCI vendor/device ID in the investigation). Once the T4 had been authorized over Thunderbolt and the controllers were bound to the standard Linux `ahci` driver, the four Toshiba HDDs appeared independently. This provided the basis for a conventional Linux `mdadm` array.

The key distinction is **hardware accessibility versus RAID-format compatibility**. We demonstrated hardware accessibility and replaced the storage stack. We did not prove how every detail of CalDigit's proprietary RAID algorithm or on-disk metadata is implemented, nor did we make an existing vendor RAID readable on Linux.

## Test platform

| Item | Tested configuration |
|---|---|
| Enclosure | CalDigit T4 RAID, **Thunderbolt 3 model** (not the earlier Thunderbolt 2 T4) |
| Host | Apple Mac mini (2012, Intel) |
| OS | Debian GNU/Linux 13 (`trixie`) |
| Kernel observed | Debian 6.12-series, specifically `6.12.116+deb13-amd64` in a later diagnostic log |
| Connection | Apple Thunderbolt 3-to-Thunderbolt 2 adapter, Thunderbolt cable and enclosure power supply |
| Controllers | Four ASMedia SATA PCIe functions; `ahci` bound explicitly with `driverctl` |
| HDDs | 4 × Toshiba MD04ACA400 4 TB SATA HDD |
| Linux RAID | `/dev/md0`, RAID 5, Linux md metadata 1.2, 512 KiB chunk, left-symmetric layout, internal write-intent bitmap |
| Logical capacity | Approximately 12.00 TB decimal / 10.92 TiB |
| Filesystem | GPT on `/dev/md0`; `/dev/md0p1` formatted ext4 with 4 KiB block size |
| Mount | `/mnt/CalDigitT4` using a persistent filesystem UUID and systemd automount |
| Network access | Samba and NFS, tested on a Linux client |

*All `/dev/sdX`, PCI bus addresses, array UUIDs, serial numbers and mount paths are local to a particular installation. Never assume yours match.*

## Storage architecture

```text
             Apple 2012 Mac mini / Debian 13
                           |
                     Thunderbolt 1/2
                           |
              Apple Thunderbolt 3↔2 adapter
                           |
                       CalDigit T4
                     Thunderbolt 3
                           |
               Thunderbolt PCIe topology
                           |
             Four ASMedia SATA controllers
              (Linux ahci driver bound)
                 |      |      |      |
             Toshiba Toshiba Toshiba Toshiba
               4TB     4TB     4TB     4TB
                 \      |      |      /
                  \     |      |     /
                      mdadm RAID 5
                        /dev/md0
                12 TB decimal usable
                           |
                      GPT / md0p1
                           |
                           ext4
                           |
                     /mnt/CalDigitT4
                       /        \
                     Samba      NFS
```

**Important:** the T4 enclosure, Thunderbolt bridge, cable, adapter and power supply remain shared single points of failure. RAID 5 protects against one drive failure, not against a disappearing enclosure, power loss, data corruption or a second failure during rebuild. RAID is not a backup.

## Results observed

- Linux enumerated four PCIe AHCI controllers and subsequently the four Toshiba drives.
- Persistent `driverctl` `ahci` overrides survived a cold reboot in this setup.
- A fresh 4-disk RAID 5 completed synchronization; repeated later reports showed `4/4 [UUUU]`, `State : clean`, `Failed Devices : 0`.
- ext4 was created, mounted read/write and made available to Samba and NFS clients; sample create/read/delete checks succeeded.
- An automatic reboot/reassembly test succeeded without manual array assembly.
- SMART access to all four Toshiba disks was verified; at the recorded health snapshot all four passed SMART and key bad-sector/error attributes were zero.
- A **real** Thunderbolt interruption caused the four controllers to disappear and the ext4 journal to abort; after restoring the connection and rebooting, the array automatically reassembled `4/4 [UUUU]` and ext4 reported clean. This was an incident, **not** a controlled hot-plug test or proof of data integrity.

### What is not proven

- Nondestructive mounting or conversion of an existing CalDigit/macOS RAID.
- A replacement Linux driver implementing CalDigit's hybrid RAID format.
- Compatibility with all T4 hardware/firmware revisions or operating systems.
- Safe surprise hot-unplug while filesystems are mounted.
- A completed end-to-end full parity scrub and full offline post-interruption `e2fsck` at the time of this Phase 1 snapshot.
- Long-term operation, enclosure fan control, third-party drive compatibility or benchmark performance figures.

## How to read this repository

1. **[Architecture and macOS model](docs/ARCHITECTURE-AND-MACOS.md):** vendor claims, observed PCIe topology, hardware versus RAID software.
2. **[Discovery and implementation](docs/IMPLEMENTATION.md):** exact checks, binding technique, array characteristics and carefully marked destructive reconstruction examples.
3. **[Verified results and evidence](docs/EVIDENCE.md):** what was actually observed and when.
4. **[Risks, failures and recovery](docs/RISKS-AND-RECOVERY.md):** the real Thunderbolt disconnection and safe operational boundaries.
5. **[Deployment and maintenance](docs/OPERATIONS.md):** persistent configuration, filesystem mounting and network exports.
6. **[Sources](docs/REFERENCES.md):** vendor and upstream technical references.
7. **[Read-only reconnaissance](scripts/t4_readonly_probe.sh):** inventories the host without binding drivers, mounting storage or modifying RAID metadata.
8. **[Read-only health summary](scripts/t4_healthcheck.sh):** checks array state and reports relevant recent log messages.

Examples under `examples/` **must be adapted** before use; no destructive automatic setup script is supplied.

## Safety-first entry point

On a host with the T4 connected, after reviewing the script and authorizing the device as appropriate:

```bash
bash scripts/t4_readonly_probe.sh
```

The report can contain serial numbers, hostnames and connection identifiers. **Sanitize it before publishing or opening a GitHub issue.** Then follow the checkpoints in [IMPLEMENTATION.md](docs/IMPLEMENTATION.md). Do not run RAID creation commands on an existing volume you want to preserve.

## Project phases

**Phase 1, completed:** feasibility, PCIe discovery, kernel-driver binding, fresh Linux RAID 5, ext4, persistence, network access and observed recovery after reboot.

**Phase 2, separate and ongoing:** SMART history dashboard (Scrutiny), email and push alerts, fan and HDD standby characterization, scheduled RAID scrubs, UPS integration, and controlled hot-plug evaluation. Phase 2 features must not be presented as prerequisites or fully verified outcomes of Phase 1.

## Purpose and authorship

This project is a personal reference to keep a fully functional, expensive CalDigit T4 in service despite aging vendor software. It documents investigation of the device on an Intel Mac/macOS host and a successful adaptation to an x86-64 Debian 13 host. The material is shared to help others, without financial or reputational objective and without guarantees of working results or data safety.

## Authorship, assistance and verification

**Project owner / hands-on investigator:** Michael Bramley. Physical hardware setup, experimental decisions, terminal command execution, inspection of logs, tests, observations and acceptance of the working installation were performed by Michael Bramley.

**Technical analysis and documentation assistance:** ChatGPT (OpenAI, GPT-6) supplied investigative hypotheses, explanations, commands, troubleshooting sequences, configuration examples and this initial technical write-up in a collaborative conversation. AI-generated guidance was not automatically executed or independently bench-verified by the model. Some steps were corrected during the investigation. The model should not be described as having physically tested the device or authored a new kernel driver.

**Credits:** See [ACKNOWLEDGEMENTS.md](ACKNOWLEDGEMENTS.md) for CalDigit, Ghidra, REA, Linux/Debian, other upstream projects and the technical assistance involved.

**Independent review:** none claimed. This is a reproducible *case study*, not a certified compatibility solution or a statement of vendor support.

## Disclaimer and publication status

This is an **unofficial community research project**. Not affiliated with, approved by or supported by CalDigit, Apple, Debian or OpenAI. All marks remain with their owners. The material is offered **as-is**, without warranties, for technically competent operators who accept the risk of device malfunction and irreversible data loss. Back up important data separately and confirm every identifier before any privileged or destructive action.

**License:** Original contributions are dedicated under [CC0 1.0 Universal](LICENSE), to the extent of the author's rights. See [LICENSE-NOTICE.md](LICENSE-NOTICE.md) for the scope, third-party rights and disclaimers. This is not a license for CalDigit or Apple intellectual property.
