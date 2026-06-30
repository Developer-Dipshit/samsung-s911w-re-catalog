# Control Guide — Framework Staging + Knox Stack

## Quick reference

```bash
RISH=/data/data/com.termux/files/usr/bin/rish
STAGING=/data/local/tmp/framework_staging

# 1. Verify staging matches stock (no tampering)
$RISH -c "md5sum /system/framework/knoxsdk.jar $STAGING/system/framework/knoxsdk.jar"

# 2. Live device policy (what Knox/MDM is actually enforcing)
$RISH -c "dumpsys device_policy | head -80"

# 3. Knox enterprise license state
$RISH -c "dumpsys package com.samsung.android.knox.containercore | grep -i license"

# 4. Apply your tiered system restriction policy
python3 ~/device-admin/lib/restrict_system_apps.py --dry-run
python3 ~/device-admin/lib/restrict_system_apps.py  # apply via rish
```

---

## Control matrix

| Target | Staging (offline) | Runtime (live) |
|--------|-------------------|----------------|
| Knox RestrictionPolicy | RE in knoxsdk.jar | `dumpsys device_policy`, revoke admins |
| ApplicationPolicy | RE in knoxsdk.jar | `pm revoke`, `pm disable-user` |
| DevicePolicyManager | RE in services.jar | `dpm` commands |
| PackageManager | RE in framework.jar | `pm list/disable/revoke` |
| PermissionManager | RE in services.jar | `pm revoke`, `appops set` |
| Secure Folder | N/A | user 150 at `/storage/emulated/150` |
| Knox Guard | N/A | monitor `kgclient` — cannot disable |

---

## Staging operations

### Refresh from stock (re-copy live framework)

```bash
framework_staging_control.sh refresh
```

Copies `/system/framework`, `/system/bin`, `/vendor/etc` into staging.

### Remove staging

```bash
framework_staging_control.sh clean
```

### Export for desktop jadx

```bash
# Pull key JARs (from Termux, not PRoot)
cp $STAGING/system/framework/knoxsdk.jar ~/storage/downloads/
cp $STAGING/system/framework/services.jar ~/storage/downloads/
# Then: jadx -d out/ knoxsdk.jar
```

---

## Runtime Knox control (via device-admin)

| Menu | Action |
|------|--------|
| 6 | List device admins / profile owners |
| 15 | Knox Guard status |
| 16 | MDM enrollment check |
| 42 | Apply system restriction policy |
| 31 | Quarantine remote-control apps |

---

## Breakout reminder

PRoot hides `/storage/emulated/150` and `/data`. Always run control commands through **rish**, not from inside the PRoot dom0 container.