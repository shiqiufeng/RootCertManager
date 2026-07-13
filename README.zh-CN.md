# RootCertManager / 多证书管理

> 通用多证书 Magisk 模块 — 适配 **SukiSU Ultra / KernelSU / Magisk / APatch**
> 把受信任的根 CA 注入到系统信任库,支持 Android 14+ APEX 命名空间。

把任意 `.0` 证书放进 `module/system/etc/security/cacerts/`,模块就会自动安装到系统信任库,
并在 Android 14+ 上 bind-mount 到 `/apex/com.android.conscrypt/cacerts`,覆盖所有相关进程的命名空间。

> **English version**: [README.md](README.md)

## ✨ 特性

- ✅ **通用 / 多证书** — 自带 `.0` 即可,无需为每个证书单独打包
- ✅ **Android 14+ APEX 适配** — 自动注入到 `/apex/com.android.conscrypt/cacerts`,
  通过 `nsenter` + `mount --bind` 覆盖 `init`、`zygote`、`zygote64`、`system_server`、
  `systemui`、`settings` 等命名空间
- ✅ **多 root 通用** — SukiSU Ultra、KernelSU、Magisk、APatch 全部支持
- ✅ **卸载干净** — `uninstall.sh` 中正确 umount APEX 和 tmpfs
- ✅ **结构清晰** — `module/` 目录就是 zip 的内容;参考证书放在仓库根目录

## 📦 快速安装

1. 在 [Releases](../../releases) 页面下载 `RootCertManager-v1.0.zip`
   (或自己打包,见下方说明)。
2. 打开 **SukiSU / KernelSU / Magisk / APatch** 管理器 → **从文件安装** → 选择 zip → **重启**。
3. 打开 **设置 → 密码与安全 → 信任的凭据 → 系统** 验证。
4. 安装日志路径:`/data/local/tmp/root_cert_manager.log`

## 🛠 自定义打包

```bash
# 1. 把你的证书(必须是 OpenSSL <hash>.0 格式)放到这里:
cp my-ca.0 module/system/etc/security/cacerts/

# 2. 打包 - module 的目录结构就是 zip 的目录结构
( cd module && zip -r ../RootCertManager-v1.0.zip . )

# 3. 通过你的 root 管理器刷入
```

可以通过以下命令把 PEM 格式的证书转成 Android 用的 `<hash>.0` 格式:

```bash
HASH=$(openssl x509 -subject_hash_old -in your.pem | head -1)
openssl x509 -in your.pem -outform DER -out "${HASH}.0"
```

## 🧩 工作原理

| Android 版本 | 机制 |
| --- | --- |
| < 14 | `system/etc/security/cacerts/` overlay via Magic Mount — 无需额外操作 |
| ≥ 14 | `post-fs-data.sh` 挂载一个 tmpfs,内容是系统证书 + 模块证书的并集,<br>然后通过 `mount --bind` 挂载到 `/apex/com.android.conscrypt/cacerts`,<br>并覆盖 init、zygote、zygote64、system_server、systemui、settings 命名空间。<br>`service.sh` 在系统启动后补强长时间运行的进程命名空间。 |

详细中文文档见 [`module/README.md`](module/README.md)。

## 🧪 测试环境

- SukiSU Ultra 12410+ (Android 14/15)
- KernelSU 1.0.x (Android 14/15)
- Magisk 27+ (Android 14/15)

## ❤️ 赞助

- 主站: <https://liushuile.dpdns.org/>

## 📄 许可证

MIT. 见 [LICENSE](LICENSE)。

## ⚠ 免责声明

本模块仅供 **开发与调试** 使用,请勿在生产环境安装不受信任的 CA 证书。
