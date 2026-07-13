# 多证书管理

> 通用 SukiSU/KernelSU 系统 CA 根证书注入模块
>
> **赞助**: [https://liushuile.dpdns.org/](https://liushuile.dpdns.org/)

**把任意 `.0` 证书文件放进 `system/etc/security/cacerts/`,打包刷入,自动注入系统。**

## 使用方式

1. 把抓包工具/代理软件导出的根证书转成 `.0` 格式
2. 放入 `system/etc/security/cacerts/` 目录
3. 打包成 zip,在 SukiSU/KernelSU 管理器安装
4. 重启
5. 设置→密码与安全→信任的凭据→系统,证书就在那里

**支持的证书数量:无限制。** 放一张也是它,放十张也是它,脚本自动扫描所有 `*.0` 文件。

## 自带证书

模块出厂自带以下两张证书:

- `243f0bfb.0` — **ProxyPin CA** (RSA 2048, 2023→2033)
- `ccf56a21.0` — **Reqable CA** (RSA, 2026→2033, Shanghai)

你也可以把它们删了换成自己的。

## 工作原理

| Android 版本 | 目标路径 | 方式 |
|---|---|---|
| ≤ 13 | `/system/etc/security/cacerts/` | SukiSU Magic Mount 自动挂载 |
| ≥ 14 | `/apex/com.android.conscrypt/cacerts/` | post-fs-data.sh 通过 `mount --bind` + `nsenter` 注入,覆盖 zygote/system_server/systemUI/settings 各命名空间 |

## 目录结构

```
根证书管理模块/
├── module.prop                 模块信息(id=root_cert_manager)
├── customize.sh                安装时脚本(显示证书列表)
├── post-fs-data.sh             ★ Android 14+ APEX 注入逻辑(自动扫描 *.0)
├── service.sh                  启动后补强(命名空间覆盖)
├── uninstall.sh                卸载清理(mount 还原)
├── sepolicy.rule               安全策略(极少需求但保留)
├── README.md                   你正在看的
└── system/
    └── etc/security/cacerts/   ← 把你的 .0 证书放这里
        ├── 243f0bfb.0   (ProxyPin, 出厂自带)
        └── ccf56a21.0   (Reqable, 出厂自带)
```

## 自定义证书

1. 用任意抓包工具导出根证书(PEM 或 DER 格式)
2. 计算 hash:

```bash
# PEM 文件
openssl x509 -subject_hash_old -in your.pem | head -1
openssl x509 -in your.pem -outform DER -out your.0
# 重命名为 hash.0,例如 243f0bfb.0
```

3. 放入 `system/etc/security/cacerts/` 替换或追加
4. 重新打包安装

> **脚本不关心证书内容,只管拷贝。** 所有 `.0` 结尾的文件都会被注入。

## 故障排查

```bash
adb shell cat /data/local/tmp/root_cert_manager.log
```

日志记录了每一步:mount 操作、zygote PID、APEX 注入结果、各个证书的可见性。

## 卸载

管理器移除模块 → 重启 → 证书消失。

## ⚠️ 从旧版本升级

如果之前装过 `proxypin_ca_sukisu` 或 `proxypin_reqable_certs`:
1. 首先在管理器卸掉旧模块
2. 重启
3. 安装本模块
4. 重启

id 不同(`root_cert_manager`),不会混淆。

## 赞助

如果这个模块帮到了你,欢迎支持:

🔗 [https://liushuile.dpdns.org/](https://liushuile.dpdns.org/)

---

- 作者: 流水
- 模块 id: `root_cert_manager`
