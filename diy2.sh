#!/bin/bash
set -e

echo "🚀 OpenWrt 25.12 DIY2 开始"

# ==================================================
# 1. 自适应网口
# ==================================================
echo "🔧 配置 x86 自适应网口"

BOARD_D_PATH="target/linux/x86/base-files/etc/board.d"
mkdir -p "$BOARD_D_PATH"

cat > "$BOARD_D_PATH/02_network" << "EOF"
#!/bin/sh

. /lib/functions.sh
. /lib/functions/uci-defaults.sh

board_config_update

ALL_ETH="$(ls /sys/class/net/ 2>/dev/null | grep -E '^eth[0-9]+$' | sort -V || true)"
COUNT="$(printf '%s\n' "$ALL_ETH" | sed '/^$/d' | wc -l)"

if [ "$COUNT" -ge 2 ]; then
    WAN_PORT="$(printf '%s\n' "$ALL_ETH" | head -n 1)"
    LAN_PORTS="$(printf '%s\n' "$ALL_ETH" | tail -n +2 | tr '\n' ' ')"
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
echo "⚙️ 设置默认 LAN IP -> 192.168.5.1"

CONFIG_GENERATE="package/base-files/files/bin/config_generate"

if [ -f "$CONFIG_GENERATE" ]; then
    sed -i 's/192\.168\.1\.1/192.168.5.1/g' "$CONFIG_GENERATE"
else
    echo "⚠️ 未找到 $CONFIG_GENERATE，跳过 LAN IP 修改"
fi

# ==================================================
# 3. 默认时区
# ==================================================
echo "🕒 设置默认时区 Asia/Shanghai"

mkdir -p package/base-files/files/etc/uci-defaults

cat > package/base-files/files/etc/uci-defaults/99-timezone << "EOF"
#!/bin/sh

uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'
uci commit system

exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/99-timezone

# ==================================================
# 4. 清理 Go Cache
# ==================================================
echo "🗑️ 清理 Go 模块缓存"

rm -rf dl/go-mod-cache 2>/dev/null || true

# ==================================================
# 5. SmartDNS 软件包来源整理
# ==================================================
echo "🔍 检查并整理 SmartDNS 软件包来源"

# 保留：
#   package/openwrt-passwall-packages/smartdns
#   package/luci-app-smartdns
#
# 移除官方 feeds 中的旧版定义，避免同名包冲突。
# 注意：必须在 feeds update/install 完成后执行。

OFFICIAL_SMARTDNS="feeds/packages/net/smartdns"
OFFICIAL_SMARTDNS_LUCI="feeds/luci/applications/luci-app-smartdns"

if [ -f "$OFFICIAL_SMARTDNS/Makefile" ]; then
    echo "🗑️ 移除官方 SmartDNS 定义：$OFFICIAL_SMARTDNS"
    rm -rf "$OFFICIAL_SMARTDNS"
else
    echo "ℹ️ 未发现官方 SmartDNS 目录"
fi

if [ -f "$OFFICIAL_SMARTDNS_LUCI/Makefile" ]; then
    echo "🗑️ 移除官方 LuCI SmartDNS 定义：$OFFICIAL_SMARTDNS_LUCI"
    rm -rf "$OFFICIAL_SMARTDNS_LUCI"
else
    echo "ℹ️ 未发现官方 LuCI SmartDNS 目录"
fi

# 检查保留的第三方软件包
if [ ! -f package/openwrt-passwall-packages/smartdns/Makefile ]; then
    echo "❌ 未找到 PassWall 仓库中的 SmartDNS 核心 Makefile"
    exit 1
fi

if [ ! -f package/luci-app-smartdns/Makefile ]; then
    echo "❌ 未找到 Pymumu LuCI SmartDNS Makefile"
    exit 1
fi

echo "===== 当前保留的 SmartDNS 软件包 ====="
grep -E '^(PKG_NAME|PKG_VERSION|PKG_SOURCE_VERSION):=' \
    package/openwrt-passwall-packages/smartdns/Makefile \
    package/luci-app-smartdns/Makefile || true

# ==================================================
# 6. 替换 Golang 27.x
# ==================================================
echo "🔥 替换 Golang 27.x"

GO_DIR="feeds/packages/lang/golang"

if [ -d "$GO_DIR" ]; then
    rm -rf "$GO_DIR"
fi

git clone --depth 1 \
    -b 27.x \
    https://github.com/sbwml/packages_lang_golang \
    "$GO_DIR"

if [ ! -f "$GO_DIR/Makefile" ]; then
    echo "❌ Golang 27.x 仓库检查失败"
    exit 1
fi

echo "✅ Golang 27.x 仓库已就绪"

# ==================================================
# 7. 完成
# ==================================================
echo "========================================="
echo "✅ OpenWrt 25.12 DIY2 执行完成"
echo "========================================="
