#!/bin/bash
set -e

echo "🚀 开始注入 OpenWrt 25.12 优化补丁（版本增强版）"

# ==================================================
# 0. 编译信息定义
# ==================================================
COMPILE_DATE=$(TZ='Asia/Shanghai' date +%Y.%m.%d)
BUILDER="cheery"

# 获取 LuCI 版本信息（如果 feeds 存在）
LUCISHORT=$(git -C feeds/luci rev-parse --short HEAD 2>/dev/null || echo unknown)
LUCIBRANCH="openwrt-25.12"

echo "📅 编译日期: $COMPILE_DATE"
echo "👤 编译者: $BUILDER"
echo "📦 LuCI版本: $LUCISHORT"

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
# 2. 默认 LAN IP
# ==================================================
echo "⚙️ 设置默认 IP: 192.168.5.1"
sed -i 's/192.168.1.1/192.168.5.1/g' package/base-files/files/bin/config_generate

# ==================================================
# 3. 强制时区 Asia/Shanghai
# ==================================================
echo "🕒 设置时区 Asia/Shanghai"
sed -i 's/UTC/CST-8/g' package/base-files/files/bin/config_generate
sed -i 's/zoneinfo\/UTC/zoneinfo\/Asia\/Shanghai/g' package/base-files/files/bin/config_generate

# ==================================================
# 4. board_detect 兜底
# ==================================================
mkdir -p package/base-files/files/etc/uci-defaults

cat > package/base-files/files/etc/uci-defaults/99-force-board-detect << "EOF"
#!/bin/sh
/bin/board_detect
exit 0
EOF

chmod +x package/base-files/files/etc/uci-defaults/99-force-board-detect

# ==================================================
# 5. Go cache 清理
# ==================================================
echo "🗑️ 清理 Go 缓存..."
rm -rf dl/go-mod-cache 2>/dev/null || true

# ==================================================
# 6. Golang 替换（已开启）
# ==================================================
echo "🔥 替换 Golang 26.x"
rm -rf feeds/packages/lang/golang
git clone https://github.com/sbwml/packages_lang_golang -b 26.x feeds/packages/lang/golang

# ==================================================
# 7. 🔥 关键：生成系统版本信息（banner + release）
# ==================================================

echo "🧩 注入版本信息（OpenWrt + LuCI）"

# 生成 banner（SSH登录显示）
cat > package/base-files/files/etc/banner <<EOF
OpenWrt 25.12-${COMPILE_DATE} compiled by ${BUILDER} / LuCI ${LUCIBRANCH} branch ${LUCISHORT}
-----------------------------------------------------
EOF

# ==================================================
# ⭐ 修正：用“写文件方式”替代 sed（更稳定）
# ==================================================

echo "🧩 生成 openwrt_release（稳定写入方式）"

cat > package/base-files/files/etc/openwrt_release <<EOF
DISTRIB_ID='OpenWrt'
DISTRIB_RELEASE='25.12-${COMPILE_DATE}'
DISTRIB_REVISION='SNAPSHOT'
DISTRIB_TARGET='x86/64'
DISTRIB_DESCRIPTION='OpenWrt 25.12-${COMPILE_DATE} compiled by ${BUILDER}'
EOF

# ==================================================
# 8. 编译结束信息
# ==================================================
echo "🚀 OpenWrt 25.12 优化补丁注入完成"
