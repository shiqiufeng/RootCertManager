# Reference certificates

The `.0` files in this directory are **sample certificates** included only as
references and convenience for first-time users. They are **not** required by
the module — replace them with your own, or delete them and add your own.

| File | Subject | Issued | Expires | Notes |
| --- | --- | --- | --- | --- |
| `243f0bfb.0` | ProxyPin CA | — | 2033 | [ProxyPin](https://github.com/wanghongenpin/proxypin) debug proxy |
| `ccf56a21.0` | Reqable, LLC | 2026-03-11 | 2033-05-31 | [Reqable](https://reqable.com/) debug proxy |

## Add your own

```bash
# 1. Convert PEM → DER
openssl x509 -inform PEM -in my-ca.pem -outform DER -out my-ca.der

# 2. Compute Android filename (OpenSSL <hash>.0)
HASH=$(openssl x509 -inform DER -in my-ca.der -subject_hash_old -noout)
cp my-ca.der "module/system/etc/security/cacerts/${HASH}.0"

# 3. Re-zip the module
( cd module && zip -r ../RootCertManager.zip . )
```

> ⚠ Keep `.0` filenames in the Android `<8-hex>.0` form. The hash is the
> truncated SHA-1 of the DER-encoded subject — it's just a stable filename,
> not a security check.
