#!/system/bin/sh
# 多证书管理 - 安装时脚本
# 通用系统 CA 证书注入模块
# 适配:SukiSU Ultra / KernelSU / Magisk / APatch
# 作者:流水
# ════════════════════════════════════════════════
#   赞助: https://liushuile.dpdns.org/
# ════════════════════════════════════════════════

SKIPUNZIP=0

print_banner() {
    ui_print "================================================"
    ui_print "  多证书管理"
    ui_print "  通用系统 CA 证书注入模块"
    ui_print "  作者:流水"
    ui_print "  赞助: https://liushuile.dpdns.org/"
    ui_print "================================================"
    ui_print ""
}

detect_root() {
    if [ "$KSU" = "true" ]; then
        if [ -f /data/adb/ksu/bin/ksud ] && strings /data/adb/ksu/bin/ksud 2>/dev/null | grep -qi "sukisu"; then
            ROOT_IMPL="SukiSU Ultra"
        else
            ROOT_IMPL="KernelSU"
        fi
    elif [ "$APATCH" = "true" ]; then
        ROOT_IMPL="APatch"
    elif [ -n "$MAGISK_VER_CODE" ]; then
        ROOT_IMPL="Magisk"
    else
        ROOT_IMPL="未知"
    fi
}

set_perm_recursive "$MODPATH/system" 0 0 0755 0644
set_perm "$MODPATH/post-fs-data.sh" 0 0 0755
set_perm "$MODPATH/service.sh" 0 0 0755
set_perm "$MODPATH/uninstall.sh" 0 0 0755

print_banner
detect_root
ui_print "- 检测到的 root 方案: $ROOT_IMPL"

API=$(getprop ro.build.version.sdk)
[ -z "$API" ] && API=21
ui_print "- Android API: $API"

if [ "$API" -ge 34 ]; then
    ui_print "- 检测到 Android 14+,将启用 APEX 命名空间注入"
fi

# 校验证书
CERT_DIR="$MODPATH/system/etc/security/cacerts"
CERT_COUNT=$(find "$CERT_DIR" -maxdepth 1 -type f -name "*.0" 2>/dev/null | wc -l)
CERT_COUNT=$(echo "$CERT_COUNT" | tr -d ' ')

if [ "$CERT_COUNT" -eq 0 ]; then
    ui_print ""
    ui_print "!! 警告:未在模块中找到证书文件"
    ui_print "!! 请将 .0 证书放入:"
    ui_print "!!   system/etc/security/cacerts/"
    ui_print ""
else
    ui_print ""
    ui_print "- 检测到 $CERT_COUNT 张证书:"
    for cert in "$CERT_DIR"/*.0; do
        [ -f "$cert" ] && ui_print "    $(basename "$cert")"
    done
fi

ui_print ""
ui_print "  完成后请重启,证书出现在:"
ui_print "  设置 → 密码与安全 → 信任的凭据 → 系统"
ui_print "  日志:/data/local/tmp/root_cert_manager.log"
ui_print ""
ui_print "════════════════════════════════════════════"
ui_print "  自定义证书:放入 system/etc/security/cacerts/"
ui_print "  赞助支持: https://liushuile.dpdns.org/"
ui_print "════════════════════════════════════════════"
ui_print ""

# 创建标记,service.sh 首次启动时跳转赞助页
echo "1" > "$MODPATH/.sponsor_flag"

# 立即跳转赞助页(仅在管理器有 activity 上下文时生效)
ui_print "- 正在打开赞助页面..."
am start -a android.intent.action.VIEW -d "https://liushuile.dpdns.org/" >/dev/null 2>&1
