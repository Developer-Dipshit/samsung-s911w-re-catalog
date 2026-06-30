#!/bin/sh
# Live Knox / device policy control via rish
set -eu

RISH="${RISH:-/data/data/com.termux/files/usr/bin/rish}"
rish_cmd() { "$RISH" -c "$*"; }

section() { echo ""; echo "── $1 ──"; }

echo "=== KNOX RUNTIME CONTROL ==="
echo "Time: $(date -Iseconds 2>/dev/null || date)"
rish_cmd "id"

section "Device policy"
rish_cmd "dumpsys device_policy 2>/dev/null | grep -iE 'Device Owner|Profile Owner|admin=|provisioningState|Restriction|USB|Camera|MTP|Knox' | head -40"

section "Knox packages"
for pkg in com.samsung.android.kgclient com.samsung.knox.securefolder com.samsung.android.knox.containercore com.sec.enterprise.knox.cloudmdm.smdms; do
  echo "  $pkg:"
  rish_cmd "dumpsys package $pkg 2>/dev/null | grep -E 'enabled=|versionName|granted=true' | head -4" || true
done

section "Active admins"
rish_cmd "dpm list-owners 2>/dev/null || dumpsys device_policy 2>/dev/null | grep -i 'admin=' | head -10"

section "User restrictions"
rish_cmd "dumpsys user 2>/dev/null | grep -iE 'restrict|disallow' | head -15"

section "Control commands available"
echo "  dpm remove-active-admin <component>     — remove rogue admin"
echo "  pm disable-user --user 0 <pkg>          — disable Knox/MDM app"
echo "  pm revoke <pkg> <android.permission.*>  — strip permission"
echo "  appops set <pkg> <OP> deny              — deny app operation"
echo "  device-admin menu 42                    — apply tiered system policy"