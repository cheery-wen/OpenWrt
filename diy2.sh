
#!/bin/bash
set -euo pipefail

echo "========================================="
echo "🚀 OpenWrt 25.12 DIY2 开始"
echo "========================================="

# ==================================================
# 1. 自适应网口
# 第一张网卡作为 WAN，其余网卡作为 LAN
# 只有一张网卡时作为 LAN
# ==================================================
echo "🔧 配置 x86 自适应网口"

BOARD_D_PATH="target/linux/x86/base-files/etc/board.d"
mkdir -p "$BOARD_D_PATH"

cat > "$BOARD_D_PATH/02_network" << 'EOF'
#!/bin/sh

. /lib/functions.sh
. /lib/functions/uci-defaults.sh

board_config_update

# 仅识别 eth 数字接口
# 先去掉 eth 前缀，再按数字排序，最后恢复 eth 前缀
# 避免依赖 sort -V
ALL_ETH=$(
    ls /sys/class/net/ 2>/dev/null \
        | grep -E '^eth[0-9]+$' \
        | sed 's/^eth//' \
        | sort -n \
        | sed 's/^/eth/' || true
)

if [ -n "$ALL_ETH" ]; then
    COUNT=$(printf '%s\n' "$ALL_ETH" | wc -l)
else
    COUNT=0
fi

if [ "$COUNT" -ge 2 ]; then
    WAN_PORT=$(printf '%s\n' "$ALL_ETH" | head -n 1)
    LAN_PORTS=$(printf '%s\n' "$ALL_ETH" | tail -n +2 | tr '\n' ' ')

    ucidef_set_interfaces_lan_wan "$LAN_PORTS" "$WAN_PORT"

elif [ "$COUNT" -eq 1 ]; then
    ucidef_set_interface_lan "$ALL_ETH"

else
    echo "No eth interfaces found"
fi

board_config_flush

exit 0
EOF

chmod +x "$BOARD_D_PATH/02_network"

if [ ! -x "$BOARD_D_PATH/02_network" ]; then
    echo "ERROR：网口配置文件创建失败"
    exit 1
fi

echo "网口配置文件创建完成"

# ==================================================
# 2. 默认 LAN IP
# ==================================================
echo "⚙️ 设置默认 LAN IP -> 192.168.5.1"

LAN_CONFIG="package/base-files/files/bin/config_generate"

if [ ! -f "$LAN_CONFIG" ]; then
    echo "ERROR：未找到 LAN 配置文件：$LAN_CONFIG"
    exit 1
fi

if grep -q '192\.168\.1\.1' "$LAN_CONFIG"; then
    sed -i 's/192\.168\.1\.1/192.168.5.1/g' "$LAN_CONFIG"
elif grep -q '192\.168\.5\.1' "$LAN_CONFIG"; then
    echo "LAN IP 已经是 192.168.5.1"
else
    echo "ERROR：未找到预期的默认 LAN IP，停止修改"
    exit 1
fi

if ! grep -q '192\.168\.5\.1' "$LAN_CONFIG"; then
    echo "ERROR：LAN IP 修改失败"
    exit 1
fi

echo "默认 LAN IP 设置完成"

# ==================================================
# 3. 默认时区
# ==================================================
echo "🕒 设置 Asia/Shanghai 时区"

TIMEZONE_DIR="package/base-files/files/etc/uci-defaults"
mkdir -p "$TIMEZONE_DIR"

cat > "$TIMEZONE_DIR/99-timezone" << 'EOF'
#!/bin/sh

uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'
uci commit system

exit 0
EOF

chmod +x "$TIMEZONE_DIR/99-timezone"

if [ ! -x "$TIMEZONE_DIR/99-timezone" ]; then
    echo "ERROR：时区配置文件创建失败"
    exit 1
fi

echo "默认时区配置完成"

# ==================================================
# 4. 清理 Go Cache
# ==================================================
echo "🗑️ 清理 Go 模块缓存"

rm -rf dl/go-mod-cache

# ==================================================
# 5. 替换 Golang 27.x
# 获取 27.x 分支最新代码，不固定提交版本
# ==================================================
echo "🔥 配置 Golang 27.x"

GO_REPO="https://github.com/sbwml/packages_lang_golang"
GO_BRANCH="27.x"
GO_PATH="feeds/packages/lang/golang"

rm -rf "$GO_PATH"
mkdir -p "$(dirname "$GO_PATH")"

git clone --depth 1 \
    --branch "$GO_BRANCH" \
    "$GO_REPO" \
    "$GO_PATH"

GO_MAKEFILE="$GO_PATH/golang/Makefile"

if [ ! -f "$GO_MAKEFILE" ]; then
    echo "ERROR：未找到 Golang Makefile"
    exit 1
fi

if ! grep -qE '^GO_VERSION_MAJOR_MINOR:=1\.27([[:space:]]|$)' "$GO_MAKEFILE"; then
    echo "ERROR：Golang 仓库版本不是预期的 1.27 系列"
    grep -E 'GO_VERSION_MAJOR_MINOR|GO_VERSION_PATCH' "$GO_MAKEFILE" || true
    exit 1
fi

echo "Golang 27.x 版本确认完成"
grep -E 'GO_VERSION_MAJOR_MINOR|GO_VERSION_PATCH' "$GO_MAKEFILE"

# ==================================================
# 6. SmartDNS：清理官方重复软件包
#
# 保留：
# package/openwrt-passwall-packages/smartdns
# package/luci-app-smartdns
#
# 删除官方 feeds 中的重复版本
# ==================================================
echo "🔧 整理 SmartDNS 软件包来源"

rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns

rm -rf package/feeds/packages/smartdns
rm -rf package/feeds/luci/luci-app-smartdns

echo "SmartDNS 官方重复软件包清理完成"

# ==================================================
# DIY2 完成
#
# 不执行第三方软件包检查
# 不执行 .config 软件包检查
# 不执行 SmartDNS 依赖检查
# ==================================================
echo "========================================="
echo "✅ OpenWrt 25.12 DIY2 执行完成"
echo "========================================="
