#!/bin/sh
# Break out of PRoot emulation → real Android (SM-S911W)
# Run from PRoot dom0 or Termux

RISH="${RISH:-/data/data/com.termux/files/usr/bin/rish}"

section() { echo ""; echo "── $1 ──"; }

echo "=== EMULATION BREAKOUT DIAGNOSTIC ==="
echo "Time: $(date -Iseconds 2>/dev/null || date)"

section "1. Where am I?"
echo "PRoot rootfs: $(readlink -f /proc/self/root 2>/dev/null || echo unknown)"
echo "Kernel (maybe fake): $(uname -r)"
grep -q PRoot /proc/version 2>/dev/null && echo "⚠ INSIDE PRoot — /proc/version is emulated" || echo "Native environment"

section "2. PRoot vs Real storage"
echo "PRoot view /storage/emulated:"
ls -la /storage/emulated/ 2>/dev/null
echo ""
echo "Real Android (rish):"
"$RISH" -c 'ls -la /storage/emulated/' 2>/dev/null

section "3. Hidden siblings missing from PRoot"
"$RISH" -c 'test -d /storage/emulated/150 && echo "✓ user 150 (Secure Folder) EXISTS outside PRoot"' 2>/dev/null
"$RISH" -c 'test -d /storage/emulated/obb && echo "✓ obb mount EXISTS outside PRoot"' 2>/dev/null

section "4. Real device props"
"$RISH" -c 'getprop ro.product.model; getprop ro.kernel.qemu; getprop ro.hardware' 2>/dev/null

section "5. Hidden dot files on storage"
"$RISH" -c 'find /storage/emulated/0 -maxdepth 3 -name ".*" 2>/dev/null' 2>/dev/null | head -20

section "6. Framework staging (hook artifact)"
"$RISH" -c 'ls -la /data/local/tmp/framework_staging 2>/dev/null || echo "(none)"' 2>/dev/null

section "7. Breakout commands"
echo "  exit                    → leave PRoot to Termux"
echo "  rish -c 'id'            → real Android shell uid 2000"
echo "  rish -c 'ls /data'      → try real userdata (may need root)"
echo "  proot-distro login      → re-enter container"