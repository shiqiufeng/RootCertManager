#!/system/bin/sh
# 多证书管理 - 卸载清理
# 还原 APEX mount,删除临时挂载

MODDIR=${0%/*}
LOG_FILE="/data/local/tmp/root_cert_manager.log"
APEX_CACERTS="/apex/com.android.conscrypt/cacerts"
TEMP_DIR="/data/local/tmp/root_cert_manager_apex_ca"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [uninstall] $1" >> "$LOG_FILE"
}

log ""
log "================================================="
log " 多证书管理 - 卸载"
log "================================================="

if mountpoint -q "$APEX_CACERTS" 2>/dev/null; then
    umount "$APEX_CACERTS" 2>/dev/null
    log "OK: 解除 APEX 挂载"
fi

for pid in 1 $(pidof zygote 2>/dev/null) $(pidof zygote64 2>/dev/null); do
    [ -d "/proc/$pid/ns/mnt" ] && \
        nsenter --mount=/proc/$pid/ns/mnt -- umount "$APEX_CACERTS" 2>/dev/null
done

if mountpoint -q "$TEMP_DIR" 2>/dev/null; then
    umount "$TEMP_DIR" 2>/dev/null
    log "OK: 解除 tmpfs 挂载"
fi
rm -rf "$TEMP_DIR" 2>/dev/null

log "卸载清理完成"
log "建议重启以彻底还原"
log "================================================="
