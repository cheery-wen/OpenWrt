#!/bin/bash
set -e

echo "🚀 OpenWrt 25.12 稳定注入开始"

# ==================================================
# 0. 编译信息
# ==================================================
COMPILE_DATE=$(TZ='Asia/Shanghai' date +%Y.%m.%d)
BUILDER="cheery"

LUCISHORT=$(git -C feeds/luci rev-parse --short HEAD 2>/dev/null || echo unknown)
LUCIBRANCH="openwrt-25.12"

# ==================================================
# 1. 自适应网口
# ==================================================
BOARD_D_PATH="target/linux/x86/base-files/etc/board.d"
mkdir -p "$BOARD_D_PATH"

cat > "$BOARD_D_PATH/02_network" << "EOF"
#!/bin/sh
. /lib/functions.sh
. /lib/functions/uci-defaults.sh

board_config_update

ALL_ETH=$(ls /sys/class/net/ | grep -E '^eth[0-9]+$' | sort -V)
COUNT=$(echo "$ALL_ETH" | wc -l)

if [ "$COUNT" -ge 2 ]; then
    WAN_PORT=$(echo "$ALL_ETH" | head -n1)
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
# 2. 默认 IP
# ==================================================
echo "⚙️ 设置 LAN IP 192.168.5.1"
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# ==================================================
# 3. ⭐ 时区（安全方式：不破坏 UCI）
# ==================================================
echo "🕒 设置 Asia/Shanghai"

mkdir -p package/base-files/files/etc/uci-defaults

cat > package/base-files/files/etc/uci-defaults/99-timezone <<'EOF'
uci set system.@system[0].timezone='CST-8'
uci set system.@system[0].zonename='Asia/Shanghai'
uci commit system
exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/99-timezone

# ==================================================
# 4. Go cache
# ==================================================
rm -rf dl/go-mod-cache 2>/dev/null || true

# ==================================================
# 5. Golang
# ==================================================
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# ==================================================
# 6. 版本信息（关键修复）
# ==================================================

echo "🧩 注入版本信息"

# banner
cat > package/base-files/files/etc/banner <<EOF
OpenWrt 25.12-${COMPILE_DATE} compiled by ${BUILDER}
LuCI ${LUCIBRANCH} branch ${LUCISHORT}
-----------------------------------------------------
EOF

# openwrt_release（修复点：不写 SNAPSHOT）
cat > package/base-files/files/etc/openwrt_release <<EOF
DISTRIB_ID='OpenWrt'
DISTRIB_RELEASE='25.12'
DISTRIB_REVISION='${COMPILE_DATE}'
DISTRIB_DESCRIPTION='OpenWrt 25.12-${COMPILE_DATE} compiled by ${BUILDER}'
DISTRIB_TAINTS=''
EOF

# os-release（补齐字段，避免 LuCI undefined）
cat > package/base-files/files/usr/lib/os-release <<EOF
NAME="OpenWrt"
VERSION="25.12"
ID="openwrt"
VERSION_ID="25.12"
PRETTY_NAME="OpenWrt 25.12-${COMPILE_DATE} compiled by ${BUILDER}"
BUILD_ID="${COMPILE_DATE}"
EOF

# ==================================================
# 7. board_detect 保持
# ==================================================
cat > package/base-files/files/etc/uci-defaults/99-force-board-detect <<'EOF'
/bin/board_detect
exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/99-force-board-detect

echo "🚀 注入完成（稳定版）"
