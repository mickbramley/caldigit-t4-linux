# Source references and evidence provenance

## Primary manufacturer sources

1. CalDigit, **T4 RAID Support**, https://www.caldigit.com/t4-raid-support/ — specifications, Thunderbolt 1/2 connection through TB3↔TB2 adapter, macOS RAID utility support.
2. CalDigit, **T4 RAID Thunderbolt 3 User Manual (PDF)**, https://downloads.caldigit.com/CalDigit_T4_TBT3_Manual_EN.pdf — manufacturer driver/utility workflow, RAIDs, disk handling, safety.
3. CalDigit, **T4 RAID product FAQ (archived)**, https://archive.caldigit.com/External-Hard-Drive/SSD/Thunderbolt-3/T4-RAID/ — vendor RAID/JBOD options and third-party-drive compatibility caveats.
4. CalDigit, **T4 FAQ (earlier Thunderbolt 2 line; distinguish model)**, https://archive.caldigit.com/T4/faq.asp — description of proprietary **hybrid RAID** architecture. Do not treat the two generations as electrically identical merely because the marketing name is similar.
5. CalDigit, **Legacy driver downloads**, https://downloads.caldigit.com/ — RAID utility macOS version compatibility and archives.

## Linux / Debian primary technical references

6. Linux kernel documentation, **USB4 and Thunderbolt**, https://www.kernel.org/doc/html/latest/admin-guide/thunderbolt.html — authorization, device security and DMA risk.
7. Linux kernel documentation, **Driver Binding**, https://docs.kernel.org/driver-api/driver-model/binding.html — PCI driver override semantics.
8. Debian, **driverctl manual**, https://manpages.debian.org/unstable/driverctl/driverctl.8.en.html — persistent PCI driver overrides.
9. Debian, **mdadm manual**, https://manpages.debian.org/unstable/mdadm/mdadm.8.en.html — array creation, bitmap, metadata, detail/monitoring.
10. Debian Wiki, **Software RAID**, https://wiki.debian.org/SoftwareRAID — conventional mdadm RAID setup and initramfs.
11. Linux kernel documentation, **PCI driver_override ABI**, https://www.kernel.org/doc/html/v5.19/admin-guide/abi-testing.html — driver_override constraints.

## Primary experimental evidence

12. Michael Bramley, **CalDigit T4 / Debian 13 interactive experimental sessions**, November 2026. Hardware logs, `lspci`, `boltctl`, `lsblk`, `mdadm`, smartmontools, `journalctl`, filesystem operations, Samba/NFS client checks, and boot test results supplied interactively. An anonymized selected evidence table and excerpts are in [EVIDENCE.md](EVIDENCE.md). This material is not presented as third-party peer review.
13. Collaborative diagnostic script **`t4_linux_probe.sh`**, retained from the initial read-only reconnaissance; a publishable safe version is provided under `scripts/`.

## Citation / certainty conventions

- **Manufacturer statement**: from CalDigit; not necessarily independently corroborated.
- **Observed**: confirmed by operator-supplied logs or successful user tests on one unit.
- **Reconstructed equivalent**: command matches resulting configuration but is not claimed to be a verbatim historical terminal transcript.
- **Hypothesis/inference**: technically plausible mechanism, not directly demonstrated.
- **Not tested**: explicitly absent from Phase 1 evidence.

Cite manufacturer and kernel documentation rather than treating assumptions about unknown proprietary firmware as fact.
