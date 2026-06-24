#!/bin/bash
set -e

echo "🚀 OpenWrt 25.12 稳定补丁注入开始"

# ==================================================
# 0. 基本信息
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

ALL_ETH=$(ls /sys/class/net/ | grep -E '^eth[0-9]+$' | grep -v '@' | sort -V)
COUNT=$(echo "$ALL_ETH" | wc -l)

if [ "$COUNT" -ge 2 ]; then
    WAN_PORT=$(echo "$ALL_ETH" | head -n1)
    LAN_PORTS=$(echo "$ALL_ETH" | tail -n +2 | tr '\n' ' ' | sed 's/ $//')
    ucidef_set_interfaces_lan_wan "$LAN_PORTS" "$WAN_PORT"
elif [ "$COUNT" -eq 1 ]; then
    ucidef_set_interface_lan "$ALL_ETH"
fi

board_config_flush
exit 0
EOF

chmod +x "$BOARD_D_PATH/02_network"

# ==================================================
# 2. 默认 LAN IP（安全 sed）
# ==================================================
echo "⚙️ 设置 LAN IP -> 192.168.5.1"
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# ==================================================
# 3. 时区（稳定 UCI 写法，避免 LuCI ?）
# ==================================================
echo "🕒 设置 Asia/Shanghai"

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
# 4. Go cache
# ==================================================
echo "🗑️ 清理 Go 缓存"
rm -rf dl/go-mod-cache 2>/dev/null || true

# ==================================================
# 5. Golang（可选）
# ==================================================
echo "🔥 Golang 26.x"
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# ==================================================
# 6. ⭐ 版本信息（关键：只改字段，不覆盖文件）
# ==================================================
echo "🧩 注入版本信息（安全模式）"

# banner
cat > package/base-files/files/etc/banner <<EOF
OpenWrt 25.12-${COMPILE_DATE} compiled by ${BUILDER}
LuCI ${LUCIBRANCH} branch ${LUCISHORT}
-----------------------------------------------------
EOF

# ⚠️ 修复点：只改 DESCRIPTION，不重写文件
if [ -f package/base-files/files/etc/openwrt_release ]; then
    sed -i "s/^DISTRIB_DESCRIPTION=.*/DISTRIB_DESCRIPTION='OpenWrt 25.12-${COMPILE_DATE} compiled by ${BUILDER}'/" \
    package/base-files/files/etc/openwrt_release
fi

# ==================================================
# 7. LuCI 显示修复（避免 undefined）
# ==================================================
if [ -f package/base-files/files/usr/lib/os-release ]; then
    sed -i "s/^PRETTY_NAME=.*/PRETTY_NAME=\"OpenWrt 25.12-${COMPILE_DATE} compiled by ${BUILDER}\"/" \
    package/base-files/files/usr/lib/os-release
fi

# ==================================================
# 8. board_detect
# ==================================================
cat > package/base-files/files/etc/uci-defaults/99-force-board-detect << "EOF"
#!/bin/sh
/bin/board_detect
exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/99-force-board-detect

# ==================================================
# 9. 完成
# ==================================================
echo "🚀 注入完成（稳定版）"
