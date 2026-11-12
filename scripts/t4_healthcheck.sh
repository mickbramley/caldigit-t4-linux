#!/usr/bin/env bash
# Non-destructive T4 RAID status summary. No tests or repairs are initiated.
set -uo pipefail
md=${1:-/dev/md0}
echo '=== DATE / HOST ==='
date -Is
hostname
printf '\n=== MD STATUS ===\n'
cat /proc/mdstat
printf '\n=== MD DETAIL (%s) ===\n' "$md"
if [[ -b "$md" ]]; then
  if command -v mdadm >/dev/null 2>&1; then mdadm --detail "$md"
  elif [[ -x /usr/sbin/mdadm ]]; then /usr/sbin/mdadm --detail "$md"
  else echo 'mdadm not available'; fi
else echo "Not present: $md"; fi
printf '\n=== MOUNT ===\n'
findmnt -T /mnt/CalDigitT4 || true
printf '\n=== POTENTIAL STORAGE ERRORS THIS BOOT ===\n'
if command -v journalctl >/dev/null; then
  journalctl -k -b --no-pager 2>&1 | grep -Ei 'EXT4-fs error|I/O error|AHCI controller unavailable|pciehp.*Link Down|raid5.*error' | tail -40 || true
fi
printf '\nNo scrub, self-test, repair or write operation was requested by this script.\n'
