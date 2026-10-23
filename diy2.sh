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
# 5. 替换 Golang 27.x
# ==================================================
echo "🔥 替换 Golang 27.x"

rm -rf feeds/packages/lang/golang 2>/dev/null || true

git clone https://github.com/sbwml/packages_lang_golang \
    -b 27.x \
    feeds/packages/lang/golang

# ==================================================
# 6. SmartDNS：清理官方重复软件包
# ==================================================
echo "🔧 整理 SmartDNS 软件包来源"

# 保留：
# package/openwrt-passwall-packages/smartdns
# package/luci-app-smartdns
#
# 删除官方 feeds 中的重复版本，避免同名软件包冲突。
rm -rf feeds/packages/net/smartdns
rm -rf feeds/luci/applications/luci-app-smartdns

# 如果 feeds install 已创建对应链接，也清理这些链接。
rm -rf package/feeds/packages/smartdns
rm -rf package/feeds/luci/luci-app-smartdns

# ==================================================
# 7. 修正 SmartDNS LuCI 的可选 UI 依赖
# ==================================================
echo "🔧 检查 SmartDNS LuCI 依赖"

SMARTDNS_LUCI_MK="package/luci-app-smartdns/Makefile"

if [ -f "$SMARTDNS_LUCI_MK" ]; then
    python3 - "$SMARTDNS_LUCI_MK" <<'PY'
import pathlib
import re
import sys

path = pathlib.Path(sys.argv[1])
content = path.read_text()

# 移除可选 smartdns-ui 的 Kconfig 配置块。
# smartdns-ui 独立由 .config 选择，不再通过 LuCI 包的选项选择，
# 避免 PACKAGE_luci-app-smartdns 与 PACKAGE_smartdns-ui 的循环依赖。
content_new, config_count = re.subn(
    r"(?ms)^define Package/\$\(PKG_NAME\)/config\s*\n.*?^endef[ \t]*\n?",
    "",
    content,
    count=1,
)

# 将 LuCI 依赖固定为 luci-base 和 smartdns。
# smartdns-ui 如需安装，由 .config 单独选择。
content_new, dep_count = re.subn(
    r"(?m)^LUCI_DEPENDS:=.*(?:\\\n[ \t]*\+PACKAGE_\$\(PKG_NAME\)_INCLUDE_smartdns_ui:smartdns-ui)?[ \t]*$",
    "LUCI_DEPENDS:=+luci-base +smartdns",
    content_new,
    count=1,
)

if dep_count == 0:
    if "LUCI_DEPENDS:=+luci-base +smartdns" not in content_new:
        print("ERROR: 未找到可识别的 LUCI_DEPENDS 配置，未写入修改。")
        sys.exit(1)

if config_count == 0 and "INCLUDE_smartdns_ui" in content_new:
    print("ERROR: 未能移除 SmartDNS 的可选 UI 配置块。")
    sys.exit(1)

path.write_text(content_new)

print("SmartDNS LuCI Makefile 检查完成")
print("移除可选 UI 配置块：", config_count)
print("依赖配置处理次数：", dep_count)
PY
else
    echo "❌ 未找到 $SMARTDNS_LUCI_MK"
    exit 1
fi

# ==================================================
# 8. 检查关键软件包
# ==================================================
echo "🔍 检查关键软件包"

if [ ! -f package/openwrt-passwall-packages/smartdns/Makefile ]; then
    echo "❌ 未找到 PassWall packages 中的 SmartDNS Makefile"
    exit 1
fi

if [ ! -f package/luci-app-smartdns/Makefile ]; then
    echo "❌ 未找到 luci-app-smartdns Makefile"
    exit 1
fi

if [ ! -f feeds/packages/lang/golang/golang/Makefile ]; then
    echo "❌ 未找到 Golang Makefile"
    exit 1
fi

echo "✅ SmartDNS 核心、LuCI 和 Golang 检查通过"

# ==================================================
# 完成
# ==================================================
echo "✅ OpenWrt 25.12 DIY2 执行完成"
