# Risks, failure modes and recovery boundaries

## 1. Irreversible data loss from RAID creation

The most serious risk is **overwriting existing proprietary RAID metadata and filesystem content**. An existing CalDigit/macOS volume must be backed up and verified *before* any attempt to create a Linux md array, partition or filesystem. `mdadm --create`, `wipefs`, `dd`, GPT operations and `mkfs.ext4` are not discovery commands. This documentation intentionally ships **no executable destructive provisioning script**.

If the aim is to recover an old CalDigit RAID: **stop at read-only inspection, image the members, and obtain specialist recovery assistance.** Do not assume the observed Linux RAID specification matches the vendor RAID's stripe ordering, parity rotation, metadata or filesystem.

## 2. Thunderbolt is a shared point of failure

An actual cable movement during the investigation led to `pciehp Link Down`; all four SATA/AHCI controllers became unavailable together. The RAID reported catastrophic member loss and ext4 reported an aborted journal and I/O errors. This was an **operational interruption**, not an independent four-drive failure.

**Do not:** unplug/reposition Thunderbolt cables while any storage is mounted, force mdadm assembly onto absent members, run `fsck` against an actively mounted filesystem, or continue copying files while the kernel reports I/O errors.

**Preferred shutdown:** stop client writes, use normal system shutdown (`sudo systemctl poweroff`), then power off or disconnect the enclosure after the host has fully shut down. Never force shutdown through inhibitors without investigating them.

## 3. If the RAID disappears unexpectedly

1. Stop all application and network writes to the affected share.
2. **Do not** format, `--create`, `--assemble --force`, `--zero-superblock`, `wipefs` or add members at random.
3. Capture diagnostics while available, emphasizing PCIe/TB controller loss, filesystem errors and md state:

   ```bash
   cat /proc/mdstat
   lsblk -o NAME,TYPE,SIZE,MODEL,FSTYPE,MOUNTPOINTS
   sudo journalctl -k -b --no-pager | grep -Ei 'pciehp|thunderbolt|ahci|I/O error|EXT4-fs error|raid5|md0' | tail -150
   ```

4. Stabilize the T4 power supply, adapter and cable. If anything is physically loose, do **not** adjust it while the filesystem is being written.
5. Only when safe and after following host/storage shutdown procedures, restore the connection; check that all four identified physical members reappear.
6. Check `cat /proc/mdstat` and `sudo mdadm --detail /dev/md0`. If degraded, **stop and diagnose**. If clean, assess filesystem health before further load.
7. Following an aborted journal, schedule an **offline** `e2fsck` on an unmounted ext4 filesystem; `tune2fs` clean state is insufficient proof of integrity. With NFS and systemd automount, unmounting may require removing active exports and stopping clients first.

Do not confuse device enumeration after reconnection with automatic filesystem integrity. A stable hardware connection is a prerequisite, not the only recovery step.

## 4. RAID 5 limitations

Four 4 TB members yield three 4 TB data-member equivalents and one parity-member equivalent. The RAID can ordinarily survive one member failure, but a second member loss before recovery can cause data loss. RAID 5 does not prevent accidental deletion, application errors, ransomware, filesystem bugs, Thunderbolt link loss, controller failure or fire/theft.

Large disks make reconstruction lengthy and stressful. Keep **independent, restorable, preferably offline** backups. Avoid claims such as 'RAID 1 is four backups' or 'RAID 5 is a backup'.

## 5. Security and operation

- Thunderbolt devices have historically carried DMA/security risks. Use device-specific `bolt` authorization. Do not authorize every new Thunderbolt device automatically.
- RAID identifiers, controller addresses and disk enumeration may change across hosts/boots. Use stable `/dev/disk/by-id/` and filesystem UUIDs appropriately.
- Public NFS shares should default to `root_squash` and restricted client lists. The lab's `no_root_squash` was an explicit local choice and is not a secure default.
- Avoid insecure legacy SMB/NT1/NTLMv1 settings unless there is an isolated compatibility requirement and explicit threat assessment.
- Expose administrative interfaces (Cockpit, monitoring dashboards) only to trusted hosts or through proper authenticated access, not unauthenticated public ports.
- SMART checks sometimes spin up sleeping disks. Do not assume `-n standby` is honored equally by every bridge.
- Keep fan airflow unobstructed and the manufacturer's appropriate power supply fitted.
- Run consistency checks when safe, and review mismatch counts. A full scrub can generate heavy I/O and should be scheduled consciously.

## 6. What remained to prove at publication

Control of the T4's fan, full HDD standby policy, hot-plug robustness, UPS failover, full parity scrub completion and a full offline ext4 examination were **outside Phase 1's verified completion criteria**. Any later findings should be appended with dates and actual measurements.

## Legal and technical disclaimers

Unofficial and unsupported research; no vendor warranty, guarantee of interoperability or fitness for a particular purpose is offered. Use at your own risk. Hardware and firmware differ. This project does not redistribute CalDigit software, drivers, reverse-engineered proprietary binaries or customer data.
