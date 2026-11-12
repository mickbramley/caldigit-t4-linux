#!/usr/bin/env bash
# CalDigit T4 / Thunderbolt Linux reconnaissance.
# READ-ONLY: no driver binding, mounting, filesystem writes or RAID modification.
# Adapted for publication from the original collaborative investigation.
set -u
OUT="${1:-t4-linux-probe-$(date +%Y%m%d-%H%M%S).txt}"
{
  printf 'CalDigit T4 Linux reconnaissance\nCaptured: %s\n' "$(date -Is)"
  printf 'Privilege: %s\n' "$(id -un)"
  section(){ printf '\n========== %s ==========\n' "$1"; }
  run(){ printf '\n$'; printf ' %q' "$@"; printf '\n'; "$@" 2>&1 || echo '(command returned nonzero status)'; }
  section 'Host'; run uname -a; cat /etc/os-release 2>/dev/null || true
  section 'PCI inventory'; if command -v lspci >/dev/null; then
    run lspci -Dnnk
    section 'ASMedia 1b21:0613 functions'; run lspci -Dnnvv -d 1b21:0613
  else echo 'lspci missing (pciutils)'; fi
  section 'PCI driver bindings'
  for p in /sys/bus/pci/devices/*; do
    [[ -r "$p/vendor" && -r "$p/device" ]] || continue
    v=$(cat "$p/vendor" 2>/dev/null)
    d=$(cat "$p/device" 2>/dev/null)
    if [[ "$v:$d" == '0x1b21:0x0613' ]]; then
      echo "$p"
      for f in class vendor device subsystem_vendor subsystem_device; do
        [[ -r "$p/$f" ]] && printf '  %s=%s\n' "$f" "$(cat "$p/$f")"
      done
      [[ -L "$p/driver" ]] && readlink -f "$p/driver" || echo '  (unbound)'
    fi
  done
  section 'Thunderbolt devices'
  if [[ -d /sys/bus/thunderbolt/devices ]]; then
    for p in /sys/bus/thunderbolt/devices/*; do
      [[ -e "$p" ]] || continue
      echo "$p"
      for f in vendor_name device_name authorized security unique_id; do
        [[ -r "$p/$f" ]] && printf '  %s=%s\n' "$f" "$(cat "$p/$f")"
      done
    done
  fi
  section 'boltd'; command -v boltctl >/dev/null && run boltctl list || true
  section 'Block inventory'; run lsblk -o NAME,TYPE,SIZE,MODEL,TRAN,FSTYPE,MOUNTPOINTS
  section 'Current RAID'; cat /proc/mdstat 2>/dev/null || true
  section 'Boot kernel evidence'
  if command -v journalctl >/dev/null; then
    journalctl -k -b --no-pager 2>&1 | grep -Ei 'thunderbolt|1b21|0613|ahci|scsi|ata[0-9]|raid|pcie|pci.*bridge' | tail -180 || true
  fi
  section 'Kernel drivers'; lsmod 2>/dev/null | grep -Ei '(^Module|thunderbolt|ahci|libata)' || true
} >"$OUT" 2>&1
printf 'Read-only diagnostic saved to: %s\n' "$(realpath "$OUT" 2>/dev/null || printf '%s' "$OUT")"
printf 'WARNING: report may include serials/UUIDs; sanitize before sharing.\n'
