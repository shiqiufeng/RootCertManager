# RootCertManager / 多证书管理

> A generic multi-certificate Magisk module for **SukiSU Ultra / KernelSU / Magisk / APatch**
> that injects trusted root CAs into the system trust store on Android 14+.

Drop any `.0` certificate into `module/system/etc/security/cacerts/` and it will
be installed into the system trust store and (on Android 14+) bind-mounted
into `/apex/com.android.conscrypt/cacerts` for every relevant process namespace.

## ✨ Features

- ✅ **Generic / multi-certificate** — bring your own `.0` files, no per-CA build required
- ✅ **Android 14+ APEX aware** — auto-injects into `/apex/com.android.conscrypt/cacerts`
  and covers `init`, `zygote`, `zygote64`, `system_server`, `systemui`, `settings`
  namespaces via `nsenter` + `mount --bind`
- ✅ **Cross-root** — works with SukiSU Ultra, KernelSU, Magisk, APatch
- ✅ **Clean uninstall** — proper umount of APEX + tmpfs in `uninstall.sh`
- ✅ **No Magisk modules directory pollution** — the `module/` folder is exactly
  what gets zipped; sample certs live at the repo root for reference

## 📦 Quick install

1. Download `多证书管理_v1.0.zip` from the [Releases](../../releases) page
   (or build your own — see below).
2. Open **SukiSU / KernelSU / Magisk / APatch** manager → **Install from file** →
   pick the zip → **Reboot**.
3. Open **Settings → Password & security → Trusted credentials → System** to verify.
4. The installation log is at `/data/local/tmp/root_cert_manager.log`.

## 🛠 Build your own

```bash
# 1. Add your certificate(s) here (must be OpenSSL <hash>.0 format):
cp my-ca.0 module/system/etc/security/cacerts/

# 2. Zip — the module layout IS the zip layout
( cd module && zip -r ../RootCertManager-v1.0.zip . )

# 3. Flash via your root manager
```

You can grab a `<hash>.0` file by exporting it from your system, or by converting
PEM with the official `openssl x509` + `subject_hash_old` flow that ships in
`/system/bin` on every Android device.

## 🧩 How it works

| Android version | Mechanism |
| --- | --- |
| < 14 | `system/etc/security/cacerts/` overlay via Magic Mount — no extra work needed |
| ≥ 14 | `post-fs-data.sh` mounts a `tmpfs` containing the union of system + module certs, then `mount --bind`s it over `/apex/com.android.conscrypt/cacerts` in the global, init, and zygote mount namespaces. `service.sh` covers the long-running system namespaces (system_server, systemui, settings, …). |

The full Chinese write-up is in [`module/README.md`](module/README.md).

## 🧪 Tested on

- SukiSU Ultra 12410+ (Android 14/15)
- KernelSU 1.0.x (Android 14/15)
- Magisk 27+ (Android 14/15)

## ❤️ Sponsor

- 主站: <https://liushuile.dpdns.org/>

## 📄 License

MIT. See [LICENSE](LICENSE).

## ⚠ Disclaimer

This module is for **development & debugging** use only. Do not install untrusted
CAs in production environments.
