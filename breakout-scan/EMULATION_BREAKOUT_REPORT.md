# Emulation Breakout Report — SM-S911W

**Generated:** 2026-06-30  
**Method:** RISH (uid 2000 shell) + PRoot container analysis  
**Device:** Samsung Galaxy S23 SM-S911W (real hardware, NOT QEMU)

---

## Executive finding

You are **not** inside an Android emulator. You are inside a **PRoot-Distro Alpine Linux container** (`dom0`) that bind-mounts a **subset** of the real phone filesystem and **fakes** kernel metadata. The real Android OS runs underneath Termux.

| Layer | What you see | Reality |
|-------|-------------|---------|
| PRoot `dom0` | Alpine root at `/`, kernel `6.17.0-PRoot-Distro` | Userspace chroot, fake `/proc/version` |
| Termux | `/data/data/com.termux/files/home` | Real Android app sandbox |
| RISH/Shizuku | `uid=2000(shell)` | Real Android privileged shell |
| Hardware | `ro.kernel.qemu=0`, `SM-S911W`, `qcom` | Physical S23 |

---

## What PRoot fakes (the emulation)

PRoot process binds **only** `/storage/self/primary` into the container:

```
--bind=/storage/self/primary:/sdcard
--bind=/storage/self/primary:/storage/emulated/0
--bind=/storage/self/primary:/storage/self/primary
```

### Hidden from PRoot (exists on real Android via rish)

| Real path | In PRoot? |
|-----------|-----------|
| `/storage/emulated/150` (Secure Folder) | **MISSING** |
| `/storage/emulated/obb` | **MISSING** |
| `/data/media/0` (on-disk backing) | **Permission denied** |
| `/data_mirror/*` (vold mirrors) | **Invisible** |
| `/mnt/knox`, `/mnt/secure`, `/mnt/runtime` | **Permission denied** |
| `/mnt/shell/privatemode` | **Exists, blocked** |
| `/mnt/pass_through/0/emulated` | **Blocked** |

### Faked proc entries (from container sysdata/)

- `/proc/version` → rewritten to `PRoot-Distro`
- `/proc/loadavg`, `/proc/stat`, `/proc/uptime`, `/proc/vmstat` → bound from fake sysdata files
- `--change-id=0:0` → fake root UID (not Android root)

**Container rootfs:** `/data/data/com.termux/files/usr/var/lib/proot-distro/containers/dom0/rootfs`

---

## How to break out

### Level 1 — Exit PRoot → Termux (native Linux on Android)

```bash
exit   # leave dom0 container
# Now in Termux proper: /data/data/com.termux/files/home
```

### Level 2 — RISH → Real Android shell (uid 2000)

```bash
/data/data/com.termux/files/usr/bin/rish -c 'id; ls -la /storage/emulated/'
# Sees user 0, 150, obb — full storage stack
```

### Level 3 — See real mount chain

```bash
rish -c 'cat /proc/self/mountinfo | grep -iE "emulated|fuse|data_mirror|pass_through"'
```

### Level 4 — Root (if available)

```bash
su -c 'ls -la /data /data/media/0 /data_mirror/storage_area'
```

---

## Storage hierarchy (real Android, above internal storage)

```
/dev/block/sda41 → dm-60 (f2fs, file encryption)
├── /data                          ← full userdata
│   ├── /data/media/0              ← on-disk files for internal storage
│   ├── /data/user/0               ← app CE storage
│   └── /data/user_de/0            ← device-encrypted storage
├── /data_mirror/ (tmpfs mode 700)
│   ├── storage_area               ← vold mirror of /data/media
│   ├── data_ce/null/0
│   └── data_de/null
├── /mnt/pass_through/0/emulated   ← direct f2fs, bypasses FUSE
├── /dev/fuse → /storage/emulated  ← what file managers see
│   ├── 0/   (primary)
│   ├── 150/ (Secure Folder)
│   └── obb/
└── /mnt/shell/
    ├── enc_emulated, enc_media
    └── privatemode/ (Samsung Private Mode)
```

---

## Hidden files found (rish scan)

### Storage dot-files

| Path | Size |
|------|------|
| `/storage/emulated/0/.$recycle_bin$/` | 15 KB |
| `/storage/emulated/0/Android/.Trash/` | **1.4 GB** |
| `/storage/emulated/0/Android/data/.nomedia` | marker |
| `/storage/emulated/0/Pictures/.thumbnails/` | cache |
| `/storage/emulated/0/Movies/.thumbnails/` | cache |
| `/storage/emulated/0/Music/.thumbnails/` | cache |
| `.../com.sec.android.gallery3d/files/.album` | hidden album |
| `.../com.alphainventor.filemanager/.localcache` | hidden cache |

### System hidden partition

| Path | Content |
|------|---------|
| `/system/hidden/INTERNAL_SDCARD/Music/Samsung/Over_the_Horizon.m4a` | 19 MB |
| `/system/hidden/SmartTutor/SmartTutor.apk` | 24 MB |

### Staging artifact (framework hook attempt)

**`/data/local/tmp/framework_staging/`** — contains copied `system/bin`, `system/framework` JARs/OATs, `vendor/`, `apex/`. This is a framework replacement staging area (RE/attack tooling).

---

## Hidden / security-relevant programs

### Disabled packages (11)

- `com.microsoft.appmanager`, `com.google.android.gms.supervision`
- `com.android.chrome`, `com.microsoft.skydrive`
- `com.samsung.android.knox.zt.framework`, `com.mygalaxy.service`
- Others — see `hidden_programs_inventory.txt`

### Privilege / RE tooling (installed)

| Package | Role |
|---------|------|
| `moe.shizuku.privileged.api` | Shell privilege bridge |
| `com.termux` / `.api` / `.styling` | Linux environment |
| `bin.mt.plus` | APK/file manager |
| `com.apk.editor` | APK modification |
| `io.github.muntashirakon.AppManager` | App control |
| `com.uptodown` | Sideload store |
| `com.revanced.net.revancedmanager` | Patched apps |

### Knox stack (system, always present)

- `com.samsung.android.kgclient` (Knox Guard)
- `com.samsung.knox.securefolder` (Secure Folder → user 150)
- `com.samsung.android.knox.containercore`
- 15+ additional Knox priv-apps

---

## Inaccessible hidden dirs (exist but shell blocked)

| Path | Purpose |
|------|---------|
| `/data`, `/data/media/0` | Real userdata |
| `/data_mirror/*` | Vold storage daemon mirrors |
| `/mnt/knox` | Knox isolated storage |
| `/mnt/secure` | Secure container |
| `/mnt/runtime` | Scoped storage views |
| `/mnt/pass_through/0/emulated` | Unfiltered storage |
| `/mnt/shell/privatemode` | Samsung Private Mode |
| `/metadata` | Encryption metadata partition |
| `/efs` | Samsung persistent radio/cal data |
| `/omr` | OMR partition |

---

## Recommendations

1. **Use rish for truth** — never trust PRoot's view of `/storage` or `/proc`
2. **Clear framework_staging** if not actively doing RE: `rish -c 'rm -rf /data/local/tmp/framework_staging'`
3. **Audit Secure Folder** user 150 separately from primary storage
4. **Rotate exposed GitHub token** if pasted in chat