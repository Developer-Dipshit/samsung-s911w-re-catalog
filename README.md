# Samsung Galaxy S23 (SM-S911W) Reverse Engineering Catalog

Full filesystem and package inventory for reverse engineering, collected from a Samsung Galaxy S23 running Android 16.

## Device Info

| Field | Value |
|---|---|
| Model | SM-S911W |
| Codename | dm1qcsx |
| Android | 16 (SDK 36) |
| Build | BP2A.250605.031.A3 / S911WVLS7EZB6 |
| SoC | Qualcomm Snapdragon 8 Gen 2 (kalama / SM8550) |
| Fingerprint | `samsung/dm1qcsx/dm1q:16/BP2A.250605.031.A3/S911WVLS7EZB6:user/release-keys` |
| Environment | PRoot-Distro (Alpine 3.24.1) + Shizuku/RISH |

## Contents

| File | Description |
|---|---|
| `catalog/re_catalog.txt` | Master catalog — 457 system APKs, 120 system apps, 222 priv-apps, RISH scan data |
| `catalog/all_apks.txt` | Complete APK path inventory (457 files) |
| `catalog/sys_apps.txt` | System app package names (120) |
| `catalog/priv_apps.txt` | Privileged app package names (222) |
| `catalog/user_packages.txt` | User-installed packages with APK paths (61, via RISH) |
| `catalog/apex_modules.txt` | Live-mounted APEX modules (43) |
| `metadata/device_info.json` | Device properties and scan statistics |
| `scripts/rish.sh` | RISH wrapper for Shizuku elevated shell |

## Scan Statistics

- **514** total packages (453 system + 61 user)
- **457** system-partition APKs
- **43** live APEX modules
- **464** system binaries, **338** vendor binaries
- **54** vendor HAL libraries
- **1,461** system properties (getprop)

## Collection Method

1. PRoot filesystem traversal of `/system`, `/product`, `/system_ext`, `/vendor`
2. RISH (Shizuku shell, uid 2000) for `/data/app`, APEX mounts, `pm list packages`, `getprop`

## RE Priority Targets

- **Knox stack**: KnoxCore, KnoxGuard, KnoxSandbox, knoxsdk.jar
- **Biometrics**: FaceService, SamsungPass, authfw.ta APEX
- **Camera**: SamsungCamera, camera.unihal APEX, scamera_* framework JARs
- **GMS**: GmsCore, Phonesky, Velvet (product/priv-app)
- **HAL layer**: /vendor/lib64/hw/*.so

Generated: 2026-06-30