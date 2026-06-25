#!/bin/bash
set -e

echo "🚀 OpenWrt 25.12 DIY2 开始"

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

ALL_ETH=$(ls /sys/class/net/ 2>/dev/null | grep -E '^eth[0-9]+$' | sort -V)
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
# 2. 默认 LAN IP
# ==================================================
echo "⚙️ 设置 LAN IP -> 192.168.5.1"

sed -i 's/192.168.1.1/192.168.5.1/g' \
package/base-files/files/bin/config_generate || true

# ==================================================
# 3. 默认时区
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
# 4. 清理 Go Cache
# ==================================================
echo "🗑️ 清理 Go 缓存"

rm -rf dl/go-mod-cache 2>/dev/null || true

# ==================================================
# 5. 替换 Golang 26.x
# ==================================================
echo "🔥 替换 Golang 26.x"

rm -rf feeds/packages/lang/golang 2>/dev/null || true

git clone https://github.com/sbwml/packages_lang_golang \
-b 26.x \
feeds/packages/lang/golang

# ==================================================
# 完成
# ==================================================
echo "✅ OpenWrt 25.12 DIY2 执行完成"
