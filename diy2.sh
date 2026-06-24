#!/bin/bash
set -e

echo "🚀 OpenWrt 25.12 稳定补丁注入开始（改进最终版）"

# ==================================================
# 0. 基本信息
# ==================================================
COMPILE_DATE=$(TZ='Asia/Shanghai' date +%Y.%m.%d)
BUILDER="cheery"

LUCISHORT=$(git -C feeds/luci rev-parse --short HEAD 2>/dev/null || echo unknown)
LUCIBRANCH="openwrt-25.12"

echo "📅 编译日期: $COMPILE_DATE"
echo "👤 编译者: $BUILDER"
echo "📦 LuCI版本: $LUCISHORT"

# ==================================================
# 1. 自适应网口（稳定增强：过滤 docker/lo）
# ==================================================
BOARD_D_PATH="target/linux/x86/base-files/etc/board.d"
mkdir -p "$BOARD_D_PATH"

cat > "$BOARD_D_PATH/02_network" << "EOF"
#!/bin/sh
. /lib/functions.sh
. /lib/functions/uci-defaults.sh

board_config_update

ALL_ETH=$(ls /sys/class/net/ 2>/dev/null | grep -E '^eth[0-9]+$' | sort -V)
COUNT=$(echo "$ALL_ETH" | wc -l)

if [ "$COUNT" -ge 2 ]; then
    WAN_PORT=$(echo "$ALL_ETH" | head -n1)
    LAN_PORTS=$(echo "$ALL_ETH" | tail -n +2 | tr '\n' ' ')
    ucidef_set_interfaces_lan_wan "$LAN_PORTS" "$WAN_PORT"
else
    ucidef_set_interface_lan "$ALL_ETH"
fi

board_config_flush
exit 0
EOF

chmod +x "$BOARD_D_PATH/02_network"

# ==================================================
# 2. LAN IP 修改（安全模式）
# ==================================================
echo "⚙️ 设置 LAN IP -> 192.168.5.1"
sed -i 's/192.168.1.1/192.168.5.1/g' \
package/base-files/files/bin/config_generate || true

# ==================================================
# 3. 时区（稳定 UCI 写法）
# ==================================================
echo "🕒 设置 Asia/Shanghai 时区"

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
# 4. Go cache 清理
# ==================================================
echo "🗑️ 清理 Go 缓存"
rm -rf dl/go-mod-cache 2>/dev/null || true

# ==================================================
# 5. Golang 26.x（稳定替换）
# ==================================================
echo "🔥 替换 Golang 26.x"
rm -rf feeds/packages/lang/golang 2>/dev/null || true
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# ==================================================
# 6. 版本信息（稳定标准版）
# ==================================================
echo "🧩 写入版本信息（LuCI识别版）"

cat > package/base-files/files/etc/openwrt_release <<EOF
DISTRIB_ID='OpenWrt'
DISTRIB_RELEASE='25.12'
DISTRIB_REVISION='SNAPSHOT'
DISTRIB_TARGET='x86/64'
DISTRIB_DESCRIPTION='OpenWrt 25.12-${COMPILE_DATE} compiled by ${BUILDER}'
EOF

# ==================================================
# 7. banner（SSH登录显示）
# ==================================================
cat > package/base-files/files/etc/banner <<EOF
OpenWrt 25.12-${COMPILE_DATE} compiled by ${BUILDER}
LuCI ${LUCIBRANCH} branch ${LUCISHORT}
-----------------------------------------------------
EOF

# ==================================================
# 8. os-release（LuCI About 页面）
# ==================================================
mkdir -p package/base-files/files/usr/lib

cat > package/base-files/files/usr/lib/os-release <<EOF
PRETTY_NAME="OpenWrt 25.12-${COMPILE_DATE} compiled by ${BUILDER}"
NAME="OpenWrt"
VERSION="25.12"
VERSION_ID="25.12"
BUILD_ID="${LUCISHORT}"
EOF

# ==================================================
# 9. board_detect（可选兼容）
# ==================================================
mkdir -p package/base-files/files/etc/uci-defaults

cat > package/base-files/files/etc/uci-defaults/99-force-board-detect << "EOF"
#!/bin/sh
/bin/board_detect
exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/99-force-board-detect

echo "🚀 OpenWrt 25.12 稳定补丁注入完成（改进最终版）"
