# Architecture and relationship to macOS / CalDigit RAID

## What the manufacturer says

The **CalDigit T4 Thunderbolt 3** is sold as a four-bay Thunderbolt storage product and advertises RAID 0, RAID 1, RAID 5 and JBOD modes. The official Thunderbolt 3 manual says the unit ships as a macOS-oriented RAID 5, with CalDigit software and a driver required for its supported Mac workflow. The T4's vendor FAQ describes its RAID as **“hybrid”**, involving a proprietary SoC and RAID kernel rather than a plain, universally interoperable host-software format. This is a **vendor description**; it is not a circuit-level reverse-engineering result.

The vendor archives list an **Intel Mac** RAID utility last updated October 31, 2019, compatible up to **macOS Catalina 10.15**, and describe it as incompatible with macOS Big Sur and later. CalDigit's original product material also states that its vendor RAID 5 behavior is restricted with third-party replacement drives. These are manufacturer compatibility claims, **not statements about independent mdadm RAID 5 on Linux**.

CalDigit confirms Thunderbolt 3 T4 can be connected to older Thunderbolt 1/2 computers through an Apple Thunderbolt 3-to-2 adapter and suitable cable. The tested host used that approach.

## What was directly observed under Linux

1. After Thunderbolt authorization, the T4 exposed four PCIe-connected ASMedia SATA controller functions in the Linux PCI topology. Matching vendor/device in the original reconnaissance was `1b21:0613`.
2. Controller functions were reported at PCI addresses `0000:09:00.0`, `0000:0a:00.0`, `0000:0b:00.0` and `0000:0c:00.0` in the investigated topology. These addresses are **not stable identifiers across all systems**.
3. The standard kernel AHCI driver bound successfully through a per-device driver override, although the controllers were represented with unusual RAID-mode identification.
4. Linux then enumerated four individual **Toshiba MD04ACA400** disks, each accessible to normal Linux block tools and SMART diagnostics.
5. The experimenter provisioned a **new** mdadm RAID 5 across those disks. That RAID is owned and assembled by Linux, *not* the CalDigit macOS RAID utility.

**Inference, not proof:** the vendor RAID functionality involves software/firmware interaction above, or alongside, the PCIe disk-access path; host access to individual drives is therefore possible even when the vendor's logical RAID is not imported. Exactly which layer implements the original T4 parity algorithms, metadata state machine and reporting remains unproven here.

## Original metadata and compatibility boundary

During the investigation, legacy CalDigit RAID metadata was considered and DDF-style RAID metadata was reported/identified in the prior working notes. **This public repository does not include sector dumps, a verified metadata parser, or a successful import of that old volume.** As a result, it does not claim that the factory RAID format is standard DDF, or that Linux can reconstruct it from metadata alone.

We intentionally **did not preserve** the original RAID as a mounted macOS-compatible array. The final `/dev/md0` uses Linux md metadata **1.2**, a Linux internal bitmap and an ext4 partition. A Mac running CalDigit Drive Utility would not automatically understand this new Linux mdadm filesystem just because it is inside a CalDigit enclosure.

The new RAID is not a format-preserving migration and should not be carried back to a Mac expecting its factory RAID configuration.

## Architecture diagram

```text
macOS supported vendor path (manufacturer documentation)
   Mac + CalDigit RAID utility / vendor driver
        -> T4 RAID management/interface
        -> four disks
   Vendor logical volume and management (exact implementation undisclosed)

Linux path demonstrated here (our experimental installation)
   Thunderbolt authorization (bolt/boltd)
        -> PCIe bridge/enumeration
        -> four ASMedia 1b21:0613 functions
        -> ahci (explicit driverctl override)
        -> four individual SATA disks
        -> /dev/md0 (native mdadm RAID5)
        -> /dev/md0p1 (ext4)
        -> Samba/NFS
```

## Why this distinction matters

Hardware access means Linux can see and address the **disk members**. RAID compatibility means Linux can correctly interpret the **existing logical array layout, metadata, write rules and failure state**. These are different capabilities. This project establishes the former and uses it to replace, **not emulate**, the latter.

## Scope limits

This case study does not establish whether the proprietary utility supports current macOS releases or whether a future reverse-engineered compatibility driver could read existing volumes. The T4 Thunderbolt 2 and Thunderbolt 3 models must not be treated as identical. No firmware patching, ROM modification or proprietary binary redistribution was involved.

See [References](REFERENCES.md) for the original CalDigit documentation, official support notes and Linux kernel references.
