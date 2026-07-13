#!/system/bin/sh
# 多证书管理 - post-fs-data 阶段
# 通用系统 CA 证书注入(支持任意多张证书)
# 适配:SukiSU Ultra / KernelSU / Magisk / APatch
# 原始思路来源: Gitee wanghongenpin/Magisk-ProxyPinCA (firdausmntp)
# ════════════════════════════════════════════════
#   赞助: https://liushuile.dpdns.org/
# ════════════════════════════════════════════════

MODDIR=${0%/*}
LOG_FILE="/data/local/tmp/root_cert_manager.log"
CERT_DIR="${MODDIR}/system/etc/security/cacerts"
TEMP_DIR="/data/local/tmp/root_cert_manager_apex_ca"
APEX_CACERTS="/apex/com.android.conscrypt/cacerts"

mkdir -p /data/local/tmp 2>/dev/null
: > "$LOG_FILE"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

print_separator() {
    log "══════════════════════════════════════════════"
    log "  赞助支持: https://liushuile.dpdns.org/"
    log "══════════════════════════════════════════════"
}

log "================================================="
log " 多证书管理 - post-fs-data"
log "================================================="
print_separator
log "Module: $MODDIR"

API=$(getprop ro.build.version.sdk)
log "Android API: $API"

if [ "$KSU" = "true" ]; then
    if [ -f /data/adb/ksu/bin/ksud ] && strings /data/adb/ksu/bin/ksud 2>/dev/null | grep -qi "sukisu"; then
        log "Root: SukiSU Ultra"
    else
        log "Root: KernelSU"
    fi
elif [ "$APATCH" = "true" ]; then
    log "Root: APatch"
elif [ "$MAGISK_VER_CODE" ]; then
    log "Root: Magisk (v$MAGISK_VER_CODE)"
fi

# 扫描模块自带的所有证书(支持任意多张 *.0)
CERT_FILES=$(find "$CERT_DIR" -maxdepth 1 -type f -name "*.0" 2>/dev/null | sort)
CERT_COUNT=$(echo "$CERT_FILES" | wc -l | tr -d ' ')

if [ -z "$CERT_FILES" ]; then
    log "WARN: 未找到证书文件,无操作退出"
    print_separator
    exit 0
fi

log "证书数量: $CERT_COUNT"
for f in $CERT_FILES; do
    log "  证书: $(basename "$f")"
done

# Android < 14:Magic Mount 自动搞定
if [ "$API" -lt 34 ]; then
    log "Android < 14:依赖 Magic Mount 自动挂载,无需 APEX 注入"
    print_separator
    exit 0
fi

# === Android 14+ APEX 注入 ===
log ""
log ">>> Android 14+ APEX 注入开始 <<<"

if [ ! -d "$APEX_CACERTS" ]; then
    log "ERROR: APEX cacerts 目录不存在"
    exit 1
fi

log "挂载 tmpfs 工作目录..."
umount "$TEMP_DIR" 2>/dev/null
rm -rf "$TEMP_DIR" 2>/dev/null
mkdir -p "$TEMP_DIR"

if ! mount -t tmpfs tmpfs "$TEMP_DIR" 2>/dev/null; then
    log "ERROR: tmpfs 挂载失败"
    exit 1
fi

# 复制系统现有证书
log "复制系统证书..."
cp -a "$APEX_CACERTS"/* "$TEMP_DIR/" 2>/dev/null
ORIG_COUNT=$(ls -1 "$TEMP_DIR"/*.0 2>/dev/null | wc -l | tr -d ' ')
log "系统证书数量: $ORIG_COUNT"

# 放入所有模块证书
for f in $CERT_FILES; do
    cp -f "$f" "$TEMP_DIR/"
    log "  注入: $(basename "$f")"
done

# 权限
chown -R 0:0 "$TEMP_DIR"
chmod 755 "$TEMP_DIR"
chmod 644 "$TEMP_DIR"/*

APEX_CONTEXT=$(ls -Zd "$APEX_CACERTS" 2>/dev/null | awk '{print $1}')
if [ -n "$APEX_CONTEXT" ] && [ "$APEX_CONTEXT" != "?" ]; then
    chcon -R "$APEX_CONTEXT" "$TEMP_DIR" 2>/dev/null
    log "SELinux 上下文: $APEX_CONTEXT"
fi

TOTAL_COUNT=$(ls -1 "$TEMP_DIR"/*.0 2>/dev/null | wc -l | tr -d ' ')
log "注入后 APEX 证书总数: $TOTAL_COUNT"

log ""
log "执行 bind mount 注入..."
# 全局 mount
if mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null; then
    log "OK: 全局 mount"
fi
# PID 1 命名空间
if nsenter --mount=/proc/1/ns/mnt -- mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null; then
    log "OK: init (PID 1) 命名空间"
fi
# zygote/zygote64
for z in zygote zygote64; do
    PID=$(pidof "$z" 2>/dev/null)
    [ -n "$PID" ] && nsenter --mount=/proc/$PID/ns/mnt -- mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null && log "OK: $z (PID $PID)"
done

# 验证
ALL_INJECTED=true
for f in $CERT_FILES; do
    NAME=$(basename "$f")
    if [ -f "$APEX_CACERTS/$NAME" ]; then
        log "OK: $NAME 已注入 APEX"
    else
        log "WARN: $NAME 在 APEX 中不可见(service.sh 会再尝试)"
        ALL_INJECTED=false
    fi
done

log ""
log "post-fs-data 完成"
if [ "$ALL_INJECTED" = "true" ]; then
    log "所有证书已成功注入! ✓"
fi
print_separator
