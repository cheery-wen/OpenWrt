#!/bin/bash
set -e

echo "========================================="
echo "🚀 OpenWrt 25.12 DIY2 开始"
echo "========================================="

# ==================================================
# 1. x86 自适应网口
# ==================================================
echo "🌐 配置 x86 自适应网口"

BOARD_D_PATH="target/linux/x86/base-files/etc/board.d"
mkdir -p "$BOARD_D_PATH"

cat > "$BOARD_D_PATH/02_network" << "EOF"
#!/bin/sh

. /lib/functions.sh
. /lib/functions/uci-defaults.sh

board_config_update

ALL_ETH=$(ls /sys/class/net/ 2>/dev/null | grep -E '^eth[0-9]+$' | sort -V)
COUNT=$(echo "$ALL_ETH" | grep -c . || true)

if [ "$COUNT" -ge 2 ]; then
    WAN_PORT=$(echo "$ALL_ETH" | head -n 1)
    LAN_PORTS=$(echo "$ALL_ETH" | tail -n +2 | tr '\n' ' ')

    ucidef_set_interfaces_lan_wan "$LAN_PORTS" "$WAN_PORT"
elif [ "$COUNT" -eq 1 ]; then
    ucidef_set_interface_lan "$ALL_ETH"
fi

board_config_flush
exit 0
EOF

chmod +x "$BOARD_D_PATH/02_network"

# ==================================================
# 2. 默认 LAN IP
# ==================================================
echo "⚙️ 设置默认 LAN IP：192.168.5.1"

CONFIG_GENERATE="package/base-files/files/bin/config_generate"

if [ -f "$CONFIG_GENERATE" ]; then
    sed -i 's/192\.168\.1\.1/192.168.5.1/g' "$CONFIG_GENERATE"
else
    echo "⚠️ 未找到 $CONFIG_GENERATE"
fi

# ==================================================
# 3. 默认时区
# ==================================================
echo "🕒 设置默认时区：Asia/Shanghai"

TIMEZONE_DIR="package/base-files/files/etc/uci-defaults"
mkdir -p "$TIMEZONE_DIR"

cat > "$TIMEZONE_DIR/99-timezone" << "EOF"
#!/bin/sh

uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'
uci commit system

exit 0
EOF

chmod +x "$TIMEZONE_DIR/99-timezone"

# ==================================================
# 4. 清理 Go 模块缓存
# ==================================================
echo "🗑️ 清理 Go 模块缓存"

rm -rf dl/go-mod-cache 2>/dev/null || true

# ==================================================
# 5. 替换 Golang 27.x
# ==================================================
echo "🔥 配置 sbwml Golang 27.x"

GO_DIR="feeds/packages/lang/golang"

rm -rf "$GO_DIR"

git clone --depth 1 \
    -b 27.x \
    https://github.com/sbwml/packages_lang_golang \
    "$GO_DIR"

if [ ! -f "$GO_DIR/golang/Makefile" ]; then
    echo "❌ 未找到 $GO_DIR/golang/Makefile"
    exit 1
fi

echo "✅ Golang 27.x 源码目录检查通过"

# ==================================================
# 6. 清理官方 feeds 中的重复 SmartDNS
# ==================================================
echo "🧹 清理官方 SmartDNS 重复包"

rm -rf \
    feeds/packages/net/smartdns \
    feeds/luci/applications/luci-app-smartdns

# 清理此前 DIY1 可能克隆的另一份官方核心。
# 新版 DIY1 已不再克隆此仓库。
rm -rf package/openwrt-smartdns

# 删除 feeds install -a 生成的对应软件包入口。
# 不会删除 package/openwrt-passwall-packages 中的核心。
if [ -d package/feeds ]; then
    find package/feeds \
        -iname '*smartdns*' \
        -prune \
        -exec rm -rf {} + 2>/dev/null || true
fi

# ==================================================
# 7. 修复官方 luci-app-smartdns 的循环依赖
#
# WebUI 由 .config 中的 CONFIG_PACKAGE_smartdns-ui=y
# 独立启用，不再让 LuCI 插件通过条件依赖选择 smartdns-ui。
# ==================================================
echo "🔧 修复 SmartDNS LuCI 依赖定义"

LUCI_SMARTDNS="package/luci-app-smartdns/Makefile"

if [ ! -f "$LUCI_SMARTDNS" ]; then
    echo "❌ 未找到 $LUCI_SMARTDNS"
    exit 1
fi

python3 - <<'PY'
from pathlib import Path
import re

p = Path("package/luci-app-smartdns/Makefile")
s = p.read_text()

# 把带有可选 smartdns-ui 的条件依赖改为普通依赖。
dep_pattern = re.compile(
    r'LUCI_DEPENDS:=\+luci-base \+smartdns\s*\\\s*'
    r'\+PACKAGE_\$\(PKG_NAME\)_INCLUDE_smartdns_ui:smartdns-ui'
)

if dep_pattern.search(s):
    s = dep_pattern.sub(
        'LUCI_DEPENDS:=+luci-base +smartdns',
        s,
        count=1
    )
elif 'LUCI_DEPENDS:=+luci-base +smartdns' not in s:
    raise SystemExit(
        "❌ 未匹配到预期的 LUCI_DEPENDS 定义；"
        "请检查上游 Makefile 是否已变更。"
    )

# 删除原来用于条件选择 smartdns-ui 的 Kconfig 配置块。
config_pattern = re.compile(
    r'\ndefine Package/\$\(PKG_NAME\)/config\n'
    r'.*?\nendef\n',
    re.S
)

s, count = config_pattern.subn('\n', s, count=1)

# 如果该配置块已经不存在，允许重复执行。
if count == 0 and 'INCLUDE_smartdns_ui' in s:
    raise SystemExit(
        "❌ 仍检测到 INCLUDE_smartdns_ui，停止以避免错误修改。"
    )

p.write_text(s)
print("✅ SmartDNS LuCI 依赖定义检查完成")
PY

# 确认修改后保留必要依赖，且不再出现可选 UI 配置符号。
grep -q 'LUCI_DEPENDS:=+luci-base +smartdns' "$LUCI_SMARTDNS"

if grep -q 'INCLUDE_smartdns_ui' "$LUCI_SMARTDNS"; then
    echo "❌ SmartDNS LuCI 中仍存在 INCLUDE_smartdns_ui"
    exit 1
fi

echo "✅ SmartDNS LuCI 循环依赖配置已移除"

# ==================================================
# 8. 清理 Weechat 循环依赖入口
#
# 当前 .config 不使用 Weechat。
# 日志显示该组包自身存在 Kconfig 循环依赖，
# 因此删除 feeds install 后生成的相关入口。
# ==================================================
echo "🧹 清理未使用的 Weechat 软件包入口"

if [ -d package/feeds ]; then
    find package/feeds \
        -iname '*weechat*' \
        -prune \
        -exec rm -rf {} + 2>/dev/null || true
fi

# ==================================================
# 9. 检查 SmartDNS 核心、WebUI 和 LuCI
# ==================================================
echo
echo "========== SmartDNS 文件检查 =========="

for f in \
    package/openwrt-passwall-packages/smartdns/Makefile \
    package/luci-app-smartdns/Makefile
do
    if [ -f "$f" ]; then
        echo "✅ $f"
    else
        echo "❌ 缺少文件：$f"
        exit 1
    fi
done

echo
echo "========== SmartDNS 相关路径 =========="

find package/openwrt-passwall-packages \
    -iname '*smartdns*' \
    -print 2>/dev/null || true

find package/feeds \
    -iname '*smartdns*' \
    -print 2>/dev/null || true

echo
echo "========== SmartDNS LuCI 依赖确认 =========="

grep -n -E \
    '^(PKG_NAME|PKG_VERSION|LUCI_DEPENDS|define Package/.*config|config PACKAGE_)' \
    package/luci-app-smartdns/Makefile || true

echo
echo "========== DIY2 完成 =========="
echo "✅ 自适应网口配置完成"
echo "✅ 默认 LAN IP 配置完成"
echo "✅ 默认时区配置完成"
echo "✅ SmartDNS 重复包清理完成"
echo "✅ SmartDNS LuCI 依赖修正完成"
echo "✅ Weechat 循环依赖入口清理完成"
echo "========================================="
