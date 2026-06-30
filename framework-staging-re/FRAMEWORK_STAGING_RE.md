# Framework Staging Reverse Engineering — SM-S911W

**Path:** `/data/local/tmp/framework_staging`  
**Size:** 897 MB, 1263 files  
**Created:** 2026-06-27 23:50 by `uid=2000(shell)`  
**Origin:** App Manager (`io.github.muntashirakon.AppManager`) RootService extraction  
**Integrity:** Identical MD5 to stock (`knoxsdk.jar`, `services.jar` match `/system/framework/`)

---

## What it is

A **full offline mirror** of Android framework partitions for reverse engineering — NOT a live hook (yet). App Manager copied:

| Partition | Staging path | Contents |
|-----------|-------------|----------|
| system/framework | `system/framework/` | 102 JARs + boot OAT/ART/VDEX |
| system/bin | `system/bin/` | Android toolbox binaries |
| vendor/etc | `vendor/etc/` | HAL manifests, permissions, models |
| apex | `apex/` | (empty — placeholder) |

Evidence in `/data/local/tmp/am.txt`:
```
AppManager RootServiceMain → cp main.jar → app_process64
Arguments: app:io.github.muntashirakon.AppManager
```

---

## Key security JARs (control surfaces)

| JAR | Size | Control domain |
|-----|------|----------------|
| `framework.jar` | 52 MB | Core Android APIs, PackageManager, permissions |
| `services.jar` | 25 MB | system_server: DevicePolicy, LockSettings, Keyguard |
| `knoxsdk.jar` | 2 MB | Samsung Knox Enterprise SDK — **169 policy classes** |
| `knox_mtd.jar` | 25 KB | Mobile Threat Defense |
| `ztsdk.jar` | 41 KB | Zero Trust scoring |
| `esecomm.jar` | 8 KB | Secure element / Samsung Pay |
| `samsungkeystoreutils.jar` | 26 KB | Keystore operations |
| `framework-res.apk` | 11 MB | System resources / permissions XML |

---

## Knox policy API surface (extracted from staging)

169 `*Policy` classes in `knoxsdk.jar`. Key control entry points:

```
com.samsung.android.knox.EnterpriseDeviceManager
com.samsung.android.knox.EnterpriseKnoxManager
com.samsung.android.knox.restriction.RestrictionPolicy
com.samsung.android.knox.application.ApplicationPolicy
com.samsung.android.knox.keystore.CertificatePolicy
com.samsung.android.knox.net.vpn.GenericVpnPolicy
com.samsung.android.knox.container.ContainerRestrictionPolicy
com.samsung.android.knox.license.EnterpriseLicenseManager
```

Full list: `knox_policy_surface.txt`

### RestrictionPolicy capabilities (from RE + services.jar strings)

- Restrict USB Debugging / MTP / SDCard
- Restrict Camera / Bluetooth / Tethering / Screen Capture
- MDM BLOCK ON/OFF, SettingBlockUsbLock
- PasswordPolicy: lock screen rules

---

## How to control it

### A. Control the staging copy (offline RE)

```bash
# Refresh from live stock
rish -c './framework_staging_control.sh refresh'

# Verify integrity vs stock
rish -c './framework_staging_control.sh verify'

# Extract Knox policy class list
rish -c './framework_staging_control.sh extract-policies'
```

### B. Control live Knox/framework (runtime via rish)

Staging is read-only copy. **Live control** uses Android shell APIs:

| Goal | Command |
|------|---------|
| Device policy state | `dumpsys device_policy` |
| Remove rogue admin | `dpm remove-active-admin <component>` |
| Strip app perms | `pm revoke <pkg> <permission>` |
| Deny appops | `appops set <pkg> <op> deny` |
| Disable package | `pm disable-user --user 0 <pkg>` |
| Knox Guard status | `dumpsys package com.samsung.android.kgclient` |
| Secure Folder | `dumpsys package com.samsung.knox.securefolder` |

Use `device-admin` menu or `restrict_system_apps.py` for automated control.

### C. Re-create staging (App Manager)

1. Open App Manager → select system app
2. Use "Framework" / extractor feature (triggers RootService)
3. Staging repopulates at `/data/local/tmp/framework_staging`

---

## What you CANNOT do without root + reboot

- Replace live `/system/framework/*.jar` from staging (read-only partition)
- Activate framework_staging as runtime (requires unlocked bootloader + Magisk/Zygisk or recovery flash)
- Modify Knox Guard (`kgclient`) — carrier priv-app

---

## Threat assessment

| Risk | Level | Notes |
|------|-------|-------|
| Staging is modified malware | **LOW** | MD5 matches stock exactly |
| Staging enables future hook | **MEDIUM** | Has boot OAT/ART — ready for overlay injection attempt |
| App Manager root bridge | **MEDIUM** | `am.jar`/`main.jar` provide privileged IPC |
| Live Knox/MDM | **MONITOR** | kgclient enabled, no device owner |

---

## Files in this RE package

- `FRAMEWORK_STAGING_RE.md` — this document
- `CONTROL_GUIDE.md` — step-by-step control procedures
- `knox_policy_surface.txt` — 169 policy classes
- `staging_file_list.txt` — 1263 file inventory
- `framework_staging_control.sh` — refresh/verify/extract/control script
- `knox_runtime_control.sh` — live Knox/device policy commands via rish