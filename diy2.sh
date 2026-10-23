#!/bin/bash
set -e

echo "========================================="
echo "🚀 OpenWrt 25.12 DIY2 开始"
echo "========================================="

# ==================================================
# 1. 自适应网口
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
    echo "⚠️ 未找到 $CONFIG_GENERATE，跳过 LAN IP 修改"
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
    echo "❌ 错误：未找到 $GO_DIR/golang/Makefile"
    echo "请检查 sbwml/packages_lang_golang 仓库目录结构及分支。"
    exit 1
fi

echo "✅ Golang 27.x 检查通过"

# ==================================================
# 6. 清理官方 feeds 中的 SmartDNS
# ==================================================
echo "🧹 检查并清理官方 SmartDNS 源目录"

OFFICIAL_SMARTDNS="feeds/packages/net/smartdns"
OFFICIAL_SMARTDNS_LUCI="feeds/luci/applications/luci-app-smartdns"

if [ -f "$OFFICIAL_SMARTDNS/Makefile" ]; then
    rm -rf "$OFFICIAL_SMARTDNS"
    echo "✅ 已删除官方 SmartDNS 核心包目录"
else
    echo "ℹ️ 官方 SmartDNS 核心包目录不存在"
fi

if [ -f "$OFFICIAL_SMARTDNS_LUCI/Makefile" ]; then
    rm -rf "$OFFICIAL_SMARTDNS_LUCI"
    echo "✅ 已删除官方 SmartDNS LuCI 目录"
else
    echo "ℹ️ 官方 SmartDNS LuCI 目录不存在"
fi

# ==================================================
# 7. 查找 SmartDNS 相关文件
# ==================================================
echo
echo "========== 1. 查找 package/feeds 中的 SmartDNS 文件 =========="

find package/feeds -path '*smartdns*' -print 2>/dev/null || true

echo
echo "========== 2. 检查 SmartDNS 相关依赖定义 =========="

grep -R -n -E \
    'smartdns-ui|PACKAGE_smartdns|INCLUDE_smartdns_ui|select.*smartdns|depends on.*smartdns' \
    package/openwrt-passwall-packages/smartdns \
    package/luci-app-smartdns \
    package/feeds \
    2>/dev/null || true

# ==================================================
# 8. 输出 PassWall SmartDNS 核心包完整 Makefile
# ==================================================
echo
echo "========== 3. PassWall SmartDNS 完整 Makefile =========="

PASSWALL_SMARTDNS="package/openwrt-passwall-packages/smartdns/Makefile"

if [ -f "$PASSWALL_SMARTDNS" ]; then
    cat "$PASSWALL_SMARTDNS"
else
    echo "⚠️ 未找到：$PASSWALL_SMARTDNS"
fi

# ==================================================
# 9. 输出第三方 LuCI SmartDNS 完整 Makefile
# ==================================================
echo
echo "========== 4. LuCI SmartDNS 完整 Makefile =========="

LUCI_SMARTDNS="package/luci-app-smartdns/Makefile"

if [ -f "$LUCI_SMARTDNS" ]; then
    cat "$LUCI_SMARTDNS"
else
    echo "⚠️ 未找到：$LUCI_SMARTDNS"
fi

# ==================================================
# 10. 检查 feeds 中可能残留的重复定义
# ==================================================
echo
echo "========== 5. 检查残留 SmartDNS Makefile =========="

for f in \
    package/feeds/packages/smartdns/Makefile \
    package/feeds/packages/smartdns-ui/Makefile \
    package/feeds/luci/luci-app-smartdns/Makefile \
    feeds/packages/net/smartdns/Makefile \
    feeds/luci/applications/luci-app-smartdns/Makefile
do
    if [ -f "$f" ]; then
        echo
        echo "----- $f -----"
        grep -n -E \
            '^(PKG_NAME|PKG_VERSION|DEPENDS|LUCI_DEPENDS|define Package/|[[:space:]]*select |[[:space:]]*config PACKAGE_)' \
            "$f" || true
    fi
done

echo
echo "========== SmartDNS 诊断结束 =========="

# ==================================================
# 11. 检查必要文件
# ==================================================
echo
echo "========== 6. 必要文件检查 =========="

for f in \
    package/openwrt-passwall-packages/smartdns/Makefile \
    package/luci-app-smartdns/Makefile \
    feeds/packages/lang/golang/golang/Makefile
do
    if [ -f "$f" ]; then
        echo "✅ 找到：$f"
    else
        echo "⚠️ 未找到：$f"
    fi
done

# ==================================================
# 完成
# ==================================================
echo
echo "========================================="
echo "✅ OpenWrt 25.12 DIY2 执行完成"
echo "========================================="
