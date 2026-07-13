#!/system/bin/sh
# 多证书管理 - service 阶段
# 启动后补强 APEX 注入,确保所有进程命名空间都能看到证书
# 通用版:自动扫描所有 *.0 证书,自动匹配目标进程
# ════════════════════════════════════════════════
#   赞助: https://liushuile.dpdns.org/
# ════════════════════════════════════════════════

MODDIR=${0%/*}
LOG_FILE="/data/local/tmp/root_cert_manager.log"
CERT_DIR="${MODDIR}/system/etc/security/cacerts"
TEMP_DIR="/data/local/tmp/root_cert_manager_apex_ca"
APEX_CACERTS="/apex/com.android.conscrypt/cacerts"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [service] $1" >> "$LOG_FILE"
}

first_boot_action() {
    if [ -f "$MODDIR/.sponsor_flag" ]; then
        rm -f "$MODDIR/.sponsor_flag"
        log "首次启动,打开赞助页面..."
        am start -a android.intent.action.VIEW -d "https://liushuile.dpdns.org/" >/dev/null 2>&1
    fi
}

log ""
log "================================================="
log " 多证书管理 - service"
log "================================================="
log "  ═══════════════════════════════════════════════"
log "    赞助支持: https://liushuile.dpdns.org/"
log "  ═══════════════════════════════════════════════"

API=$(getprop ro.build.version.sdk)
log "Android API: $API"

count=0
while [ "$(getprop sys.boot_completed)" != "1" ] && [ $count -lt 60 ]; do
    sleep 1
    count=$((count + 1))
done
log "boot_completed (${count}s)"

if [ "$API" -lt 34 ]; then
    log "Android < 14,service.sh 无操作"
    first_boot_action
    exit 0
fi

CERT_FILES=$(find "$CERT_DIR" -maxdepth 1 -type f -name "*.0" 2>/dev/null | sort)
CERT_COUNT=$(echo "$CERT_FILES" | wc -l | tr -d ' ')
if [ -z "$CERT_FILES" ]; then
    log "WARN: 证书未找到"
    first_boot_action
    exit 0
fi
log "证书数量: $CERT_COUNT"

# 检查各证书是否已在 APEX
NEED_REINJECT=false
for f in $CERT_FILES; do
    NAME=$(basename "$f")
    if [ ! -f "$APEX_CACERTS/$NAME" ]; then
        NEED_REINJECT=true
        log "  $NAME 不在 APEX,需重新注入"
    fi
done

if [ "$NEED_REINJECT" = "true" ]; then
    log "重新注入..."
    if ! mountpoint -q "$TEMP_DIR" 2>/dev/null; then
        mkdir -p "$TEMP_DIR"
        mount -t tmpfs tmpfs "$TEMP_DIR"
        cp -a "$APEX_CACERTS"/* "$TEMP_DIR/" 2>/dev/null
        for f in $CERT_FILES; do
            cp -f "$f" "$TEMP_DIR/"
        done
        chown -R 0:0 "$TEMP_DIR"
        chmod 755 "$TEMP_DIR"
        chmod 644 "$TEMP_DIR"/*
        APEX_CONTEXT=$(ls -Zd "$APEX_CACERTS" 2>/dev/null | awk '{print $1}')
        [ -n "$APEX_CONTEXT" ] && [ "$APEX_CONTEXT" != "?" ] && chcon -R "$APEX_CONTEXT" "$TEMP_DIR" 2>/dev/null
    fi
    mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null
    nsenter --mount=/proc/1/ns/mnt -- mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null
else
    log "所有证书已在 APEX,只做命名空间补强"
fi

# zygote 命名空间补强
log "补强进程命名空间..."
for z in zygote zygote64; do
    PID=$(pidof "$z" 2>/dev/null)
    [ -n "$PID" ] && nsenter --mount=/proc/$PID/ns/mnt -- mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null && log "  OK: $z (PID $PID)"
done
# system_server 及关键系统进程
for proc in system_server com.android.settings com.android.systemui; do
    PID=$(pidof "$proc" 2>/dev/null)
    [ -n "$PID" ] && nsenter --mount=/proc/$PID/ns/mnt -- mount --bind "$TEMP_DIR" "$APEX_CACERTS" 2>/dev/null && log "  OK: $proc (PID $PID)"
done

# 最终验证
sleep 1
ALL_OK=true
for f in $CERT_FILES; do
    NAME=$(basename "$f")
    if [ -f "$APEX_CACERTS/$NAME" ]; then
        log "OK: $NAME ✓"
    else
        log "WARN: $NAME 不可见"
        ALL_OK=false
    fi
done
APEX_COUNT=$(ls -1 "$APEX_CACERTS"/*.0 2>/dev/null | wc -l | tr -d ' ')
log "APEX 中证书总数: $APEX_COUNT"
[ "$ALL_OK" = "true" ] && log "所有证书服务就绪 ✓"
log "================================================="

first_boot_action
